--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'EditorMode'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local UnitFrameModule, CastingBarModule, ActionBarModule, MinimapModule, QuestTrackerModule, BuffFrameModule

Module.editorGridFrame = nil
Module.snapToGrid = false

local function CreateEditorGridFrame()
    local editorGridFrame = CreateFrame("Frame", 'RUI_EditorGridFrame', UIParent)
    editorGridFrame:SetPoint("TOPLEFT", 0, 0)
    editorGridFrame:SetSize(GetScreenWidth(), GetScreenHeight())
    editorGridFrame:SetFrameLevel(0)
    editorGridFrame:SetFrameStrata("BACKGROUND")

    do
        local texture = editorGridFrame:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(editorGridFrame)
        texture:SetTexture("Interface\\AddOns\\RetailUI\\Textures\\UI\\EditorGrid.blp", "REPEAT", "REPEAT")
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertTile(true)
        texture:SetHorizTile(true)
        texture:SetSize(32, 32)
        texture:SetAlpha(0.4)
    end

    editorGridFrame:Hide()
    return editorGridFrame
end

function Module:OnEnable()
    UnitFrameModule      = RUI:GetModule("UnitFrame")
    CastingBarModule     = RUI:GetModule("CastingBar")
    ActionBarModule      = RUI:GetModule("ActionBar")
    MinimapModule        = RUI:GetModule("Minimap")
    QuestTrackerModule   = RUI:GetModule("QuestTracker")
    BuffFrameModule      = RUI:GetModule("BuffFrame")

    self.editorGridFrame = CreateEditorGridFrame()
    
    -- Hook scale changes for dynamic edit box sizing
    self:HookScaleChanges()
end

function Module:OnDisable() end

function Module:Show()
    if InCombatLockdown() then
        self:Printf(DEFAULT_CHAT_FRAME, "Cannot open settings while in combat")
        return
    end

    self.editorGridFrame:Show()

    ActionBarModule:ShowEditorTest()
    UnitFrameModule:ShowEditorTest()
    CastingBarModule:ShowEditorTest()
    MinimapModule:ShowEditorTest()
    QuestTrackerModule:ShowEditorTest()
    BuffFrameModule:ShowEditorTest()
    
    -- Update all edit box sizes to match current frame scales
    self:UpdateAllEditBoxSizes()
end

function Module:Hide()
    self.editorGridFrame:Hide()

    ActionBarModule:HideEditorTest(true)
    UnitFrameModule:HideEditorTest(true)
    CastingBarModule:HideEditorTest(true)
    MinimapModule:HideEditorTest(true)
    QuestTrackerModule:HideEditorTest(true)
    BuffFrameModule:HideEditorTest(true)
end

function Module:IsShown()
    return self.editorGridFrame:IsShown()
end

function Module:GetSnapToGrid()
    return RUI.DB.profile.snapToGrid or false
end

function Module:SetSnapToGrid(enabled)
    RUI.DB.profile.snapToGrid = enabled
    self.snapToGrid = enabled
end

-- Function to snap a frame to grid if snap-to-grid is enabled
function Module:SnapFrameToGrid(frame)
    if not self:GetSnapToGrid() then return end
    
    -- Use enhanced snap functionality if available
    if RUI.SnapGrid then
        RUI.SnapGrid:SnapFrameToGridEnhanced(frame)
    else
        -- Fallback to original snap logic
        local gridSize = 32 -- Grid size in pixels
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        
        if not point then return end
        
        -- Snap offsets to nearest grid position with non-overlapping alignment
        xOfs = math.floor((xOfs + gridSize/2) / gridSize) * gridSize
        yOfs = math.floor((yOfs + gridSize/2) / gridSize) * gridSize
        
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
    end
end

-- Function to update edit box size to match the actual frame size
function Module:UpdateEditBoxSize(editFrame, actualFrame)
    if not editFrame or not actualFrame then return end
    
    local width, height = actualFrame:GetSize()
    local scale = actualFrame:GetScale() or 1.0
    
    -- Apply scale to the edit box size
    editFrame:SetSize(width * scale, height * scale)
end

-- Hook into scale changes to update edit boxes dynamically
function Module:HookScaleChanges()
    local function CreateScaleHook(frameName, editBoxName)
        local frame = getglobal(frameName)
        local editBox = getglobal(editBoxName)
        
        if frame and editBox then
            -- Hook SetScale to update edit box size
            if not frame.originalSetScale then
                frame.originalSetScale = frame.SetScale
                frame.SetScale = function(self, scale)
                    frame.originalSetScale(self, scale)
                    Module:UpdateEditBoxSize(editBox, frame)
                end
            end
        end
    end
    
    -- Hook scale changes for key frames
    CreateScaleHook("PlayerFrame", "RUI_PlayerFrame")
    CreateScaleHook("TargetFrame", "RUI_TargetFrame") 
    CreateScaleHook("TargetFrameToT", "RUI_ToTFrame")
    CreateScaleHook("PetFrame", "RUI_PetFrame")
    CreateScaleHook("MinimapCluster", "RUI_MinimapFrame")
    CreateScaleHook("BuffFrame", "RUI_BuffFrame")
    
    -- Hook for quest tracker and boss frames if they exist
    if QuestMapFrame then
        CreateScaleHook("QuestMapFrame", "RUI_QuestTrackerFrame")
    end
    if Boss1TargetFrame then
        CreateScaleHook("Boss1TargetFrame", "RUI_Boss1Frame")
    end
end

-- Update all edit box sizes to match their corresponding frames
function Module:UpdateAllEditBoxSizes()
    local framePairs = {
        {"PlayerFrame", "RUI_PlayerFrame"},
        {"TargetFrame", "RUI_TargetFrame"},
        {"TargetFrameToT", "RUI_ToTFrame"},
        {"PetFrame", "RUI_PetFrame"},
        {"MinimapCluster", "RUI_MinimapFrame"},
        {"BuffFrame", "RUI_BuffFrame"}
    }
    
    -- Add conditional frames
    if QuestMapFrame then
        table.insert(framePairs, {"QuestMapFrame", "RUI_QuestTrackerFrame"})
    end
    if Boss1TargetFrame then
        table.insert(framePairs, {"Boss1TargetFrame", "RUI_Boss1Frame"})
    end
    
    for _, pair in ipairs(framePairs) do
        local actualFrame = getglobal(pair[1])
        local editFrame = getglobal(pair[2])
        if actualFrame and editFrame then
            self:UpdateEditBoxSize(editFrame, actualFrame)
        end
    end
end
