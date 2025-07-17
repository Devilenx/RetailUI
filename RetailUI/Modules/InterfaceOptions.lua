--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'InterfaceOptions'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local optionsFrame = nil
local scrollFrame = nil
local scrollChild = nil

-- Scale slider definitions in exact order requested
local scaleSliders = {
    { key = "questTracker", name = "QuestTrackerFrame Scale", frameRef = "QuestMapFrame" },
    { key = "buffFrame", name = "BuffFrame Scale", frameRef = "BuffFrame" },
    { key = "boss1Frame", name = "Boss1Frame Scale", frameRef = "Boss1TargetFrame" },
    { key = "playerFrame", name = "PlayerFrame Scale", frameRef = "PlayerFrame" },
    { key = "targetFrame", name = "TargetFrame Scale", frameRef = "TargetFrame" },
    { key = "totFrame", name = "ToTFrame Scale", frameRef = "TargetFrameToT" },
    { key = "petFrame", name = "PetFrame Scale", frameRef = "PetFrame" },
    { key = "minimap", name = "Minimap Scale", frameRef = "MinimapCluster" },
    { key = "microMenuBar", name = "MicroMenuBar Scale", frameRef = "MicroButtonAndBagsBar" },
    { key = "bagsBar", name = "BagsBar Scale", frameRef = "MicroButtonAndBagsBar" },
    { key = "actionBar1", name = "Action Bar 1 Scale", frameRef = "ActionButton1" },
    { key = "actionBar2", name = "Action Bar 2 Scale", frameRef = "MultiBarBottomLeftButton1" },
    { key = "actionBar3", name = "Action Bar 3 Scale", frameRef = "MultiBarBottomRightButton1" },
    { key = "actionBar4", name = "Action Bar 4 Scale", frameRef = "MultiBarRightButton1" },
    { key = "actionBar5", name = "Action Bar 5 Scale", frameRef = "MultiBarLeftButton1" },
    { key = "actionBar6", name = "Action Bar 6 Scale", frameRef = "MultiBarRightButton7" },
    { key = "actionBar7", name = "Action Bar 7 Scale", frameRef = "MultiBarLeftButton7" }
}

function Module:OnEnable()
    self:CreateOptionsPanel()
end

function Module:OnDisable() end

function Module:CreateOptionsPanel()
    -- Create main options frame with modern styling
    optionsFrame = CreateFrame("Frame", "RetailUISettingsPanel", UIParent)
    optionsFrame.name = "RetailUI Settings"
    optionsFrame:SetSize(650, 550)
    optionsFrame:Hide()

    -- Modern background
    local bg = optionsFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

    -- Title with modern styling
    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("RetailUI Settings")
    title:SetTextColor(1, 0.82, 0, 1) -- Gold color

    -- Subtitle
    local subtitle = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Adjust UI element scales - changes apply immediately")
    subtitle:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Create scroll frame for all content
    scrollFrame = CreateFrame("ScrollFrame", "RetailUIScrollFrame", optionsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 80)

    -- Modern scroll bar styling
    local scrollBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName().."ScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0.7)
    end

    -- Create scroll child with padding
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(580, 800) -- Increased height for all sliders
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -20
    local sliders = {}

    -- Create all scale sliders in exact order requested
    for i, sliderData in ipairs(scaleSliders) do
        local slider = self:CreateScaleSlider(sliderData, yOffset)
        sliders[sliderData.key] = slider
        yOffset = yOffset - 45 -- Increased spacing for better visibility
    end

    yOffset = yOffset - 30

    -- Modern section separator
    local separator = scrollChild:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", 0, yOffset)
    separator:SetSize(560, 2)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    yOffset = yOffset - 40

    -- Snap to Grid checkbox with modern styling
    local snapCheckbox = CreateFrame("CheckButton", "RetailUISnapToGridCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
    snapCheckbox:SetPoint("TOPLEFT", 0, yOffset)
    snapCheckbox:SetScript("OnClick", function(self)
        RUI.DB.profile.snapToGrid = self:GetChecked()
        local EditorMode = RUI:GetModule('EditorMode')
        if EditorMode then
            EditorMode:SetSnapToGrid(self:GetChecked())
        end
    end)
    
    local snapText = snapCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    snapText:SetPoint("LEFT", snapCheckbox, "RIGHT", 5, 0)
    snapText:SetText("Snap to Grid (Editor Mode)")
    snapText:SetTextColor(0.9, 0.9, 0.9, 1)

    yOffset = yOffset - 50

    -- Modern button styling
    local function CreateModernButton(name, text, width, onClickFunc)
        local button = CreateFrame("Button", name, scrollChild, "UIPanelButtonTemplate")
        button:SetSize(width, 32)
        button:SetText(text)
        button:SetScript("OnClick", onClickFunc)
        
        -- Modern button styling
        button:SetNormalFontObject("GameFontNormal")
        button:GetNormalTexture():SetColorTexture(0.2, 0.2, 0.2, 0.8)
        button:GetHighlightTexture():SetColorTexture(0.3, 0.3, 0.3, 0.8)
        button:GetPushedTexture():SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        return button
    end

    -- Open Grid Layout button
    local gridButton = CreateModernButton("RetailUIGridLayoutButton", "Open Grid Layout", 140, function()
        local EditorMode = RUI:GetModule('EditorMode')
        if EditorMode:IsShown() then
            EditorMode:Hide()
        else
            EditorMode:Show()
        end
    end)
    gridButton:SetPoint("TOPLEFT", 0, yOffset)

    -- Reset to Default button
    local resetButton = CreateModernButton("RetailUIResetButton", "Reset to Default", 140, function()
        Module:ResetToDefaults()
    end)
    resetButton:SetPoint("LEFT", gridButton, "RIGHT", 15, 0)

    -- Store references
    optionsFrame.sliders = sliders
    optionsFrame.snapCheckbox = snapCheckbox

    -- Initialize values from saved settings
    self:LoadSavedSettings()

    -- Add to interface options
    InterfaceOptions_AddCategory(optionsFrame)
end

function Module:CreateScaleSlider(sliderData, yOffset)
    local slider = CreateFrame("Slider", "RetailUI" .. sliderData.key .. "ScaleSlider", scrollChild, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, yOffset)
    slider:SetSize(350, 20)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValue(1.0)
    slider:SetValueStep(0.05) -- Finer control
    
    -- Modern slider styling
    slider:GetThumbTexture():SetColorTexture(1, 0.82, 0, 1) -- Gold thumb
    
    slider:SetScript("OnValueChanged", function(self, value)
        Module:UpdateFrameScale(sliderData.key, sliderData.frameRef, value)
        -- Update text without chat feedback
        local sliderText = getglobal(self:GetName() .. "Text")
        if sliderText then
            sliderText:SetText(sliderData.name .. ": " .. string.format("%.2f", value))
        end
    end)
    
    -- Set slider labels with modern styling
    local lowText = getglobal(slider:GetName() .. "Low")
    local highText = getglobal(slider:GetName() .. "High") 
    local titleText = getglobal(slider:GetName() .. "Text")
    
    if lowText then
        lowText:SetText("0.5")
        lowText:SetTextColor(0.7, 0.7, 0.7, 1)
    end
    if highText then
        highText:SetText("2.0")
        highText:SetTextColor(0.7, 0.7, 0.7, 1)
    end
    if titleText then
        titleText:SetText(sliderData.name .. ": 1.00")
        titleText:SetTextColor(0.9, 0.9, 0.9, 1)
    end
    
    return slider
end

function Module:UpdateFrameScale(key, frameRef, scale)
    -- Save scale setting
    RUI.DB.profile.widgets = RUI.DB.profile.widgets or {}
    RUI.DB.profile.widgets[key] = RUI.DB.profile.widgets[key] or {}
    RUI.DB.profile.widgets[key].scale = scale
    
    -- Apply scale directly to the appropriate frame without chat feedback
    if key == "questTracker" then
        if QuestMapFrame then
            QuestMapFrame:SetScale(scale)
        end
    elseif key == "buffFrame" then
        if BuffFrame then
            BuffFrame:SetScale(scale)
        end
    elseif key == "boss1Frame" then
        if Boss1TargetFrame then
            Boss1TargetFrame:SetScale(scale)
        end
    elseif key == "playerFrame" then
        if PlayerFrame then
            PlayerFrame:SetScale(scale)
        end
        -- Also update widget system
        SaveUIFrameScale(tostring(scale), "player")
    elseif key == "targetFrame" then
        if TargetFrame then
            TargetFrame:SetScale(scale)
        end
        SaveUIFrameScale(tostring(scale), "target")
    elseif key == "totFrame" then
        if TargetFrameToT then
            TargetFrameToT:SetScale(scale)
        end
        SaveUIFrameScale(tostring(scale), "targetOfTarget")
    elseif key == "petFrame" then
        if PetFrame then
            PetFrame:SetScale(scale)
        end
        SaveUIFrameScale(tostring(scale), "pet")
    elseif key == "minimap" then
        if MinimapCluster then
            MinimapCluster:SetScale(scale)
        end
    elseif string.find(key, "actionBar") or key == "microMenuBar" or key == "bagsBar" then
        -- Handle action bars through widget system
        local actionBarModule = RUI:GetModule("ActionBar")
        if actionBarModule and actionBarModule.UpdateWidgets then
            actionBarModule:UpdateWidgets()
        end
    end
end

function Module:LoadSavedSettings()
    if not optionsFrame then return end
    
    RUI.DB.profile.widgets = RUI.DB.profile.widgets or {}
    
    -- Load scale settings for all sliders
    for i, sliderData in ipairs(scaleSliders) do
        local slider = optionsFrame.sliders[sliderData.key]
        if slider then
            local scale = 1.0
            
            -- Get current scale from saved settings or live frame
            if RUI.DB.profile.widgets[sliderData.key] then
                scale = RUI.DB.profile.widgets[sliderData.key].scale or 1.0
            elseif sliderData.key == "playerFrame" then
                scale = GetUIFrameScale("player") or 1.0
            elseif sliderData.key == "targetFrame" then
                scale = GetUIFrameScale("target") or 1.0
            elseif sliderData.key == "totFrame" then
                scale = GetUIFrameScale("targetOfTarget") or 1.0
            elseif sliderData.key == "petFrame" then
                scale = GetUIFrameScale("pet") or 1.0
            else
                -- For other frames, try to get scale from actual frame
                local frame = getglobal(sliderData.frameRef)
                if frame and frame.GetScale then
                    scale = frame:GetScale() or 1.0
                end
            end
            
            slider:SetValue(scale)
            local sliderText = getglobal(slider:GetName() .. "Text")
            if sliderText then
                sliderText:SetText(sliderData.name .. ": " .. string.format("%.2f", scale))
            end
        end
    end
    
    -- Load snap to grid setting
    if optionsFrame.snapCheckbox then
        optionsFrame.snapCheckbox:SetChecked(RUI.DB.profile.snapToGrid or false)
    end
end

function Module:ResetToDefaults()
    -- Reset all scale sliders to 1.0
    for i, sliderData in ipairs(scaleSliders) do
        local slider = optionsFrame.sliders[sliderData.key]
        if slider then
            slider:SetValue(1.0)
            -- Apply the reset scale
            Module:UpdateFrameScale(sliderData.key, sliderData.frameRef, 1.0)
        end
    end
    
    -- Reset all modules to default via their LoadDefaultSettings
    local modules = {"UnitFrame", "CastingBar", "ActionBar", "Minimap", "QuestTracker", "BuffFrame"}
    for _, moduleName in pairs(modules) do
        local module = RUI:GetModule(moduleName)
        if module and module.LoadDefaultSettings then
            module:LoadDefaultSettings()
            if module.UpdateWidgets then
                module:UpdateWidgets()
            end
        end
    end
    
    -- Reset widget scales
    RUI.DB.profile.widgets = {}
    
    -- Reset snap to grid
    RUI.DB.profile.snapToGrid = false
    
    -- Reload settings in UI
    self:LoadSavedSettings()
end