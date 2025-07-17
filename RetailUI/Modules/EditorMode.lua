--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'EditorMode'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local UnitFrameModule, CastingBarModule, ActionBarModule, MinimapModule, QuestTrackerModule, BuffFrameModule

Module.editorGridFrame = nil

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
    self.snapToGrid = false  -- Initialize snap-to-grid setting
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

-- Snap a coordinate to the nearest grid position
function Module:SnapToGrid(coord, gridSize)
    gridSize = gridSize or 32
    return math.floor(coord / gridSize + 0.5) * gridSize
end

-- Snap a frame to grid using its own dimensions to prevent overlap
function Module:SnapFrameToGrid(frame)
    if not frame or not self:IsSnapToGridEnabled() then
        return
    end
    
    local x, y = frame:GetLeft(), frame:GetTop()
    if not x or not y then
        return -- Frame position not available
    end
    
    -- Use fixed 32px grid size for consistent snapping
    local gridSize = 32
    local parent = UIParent
    
    -- Calculate position relative to parent
    local parentLeft = parent:GetLeft() or 0
    local parentTop = parent:GetTop() or UIParent:GetHeight()
    
    local relativeX = x - parentLeft
    local relativeY = parentTop - y
    
    -- Snap to grid
    local snappedX = math.floor(relativeX / gridSize + 0.5) * gridSize
    local snappedY = math.floor(relativeY / gridSize + 0.5) * gridSize
    
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", snappedX, -snappedY)
end

-- Enable or disable snap-to-grid functionality
function Module:SetSnapToGrid(enabled)
    self.snapToGrid = enabled
    
    -- If we have access to the Settings module, sync the setting
    local SettingsModule = RUI:GetModule('Settings')
    if SettingsModule then
        SettingsModule.snapToGrid = enabled
    end
end

-- Check if snap-to-grid is enabled
function Module:IsSnapToGridEnabled()
    -- Check Settings module first, fallback to local setting
    local SettingsModule = RUI:GetModule('Settings')
    if SettingsModule then
        return SettingsModule.snapToGrid
    end
    return self.snapToGrid or false
end
