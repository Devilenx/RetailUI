--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
    
    Settings Module - Provides a clean, modern in-game settings panel
    Features:
    - Scale sliders for all major UI modules (50%-200% range)
    - Reset to Default button
    - Open Grid Layout button for /rui edit mode
    - Snap to Grid checkbox for grid-aligned positioning
    - Accessible via /rui command or Interface Options
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'Settings'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

Module.settingsPanel = nil
Module.snapToGrid = false

-- Module configuration for sliders
local moduleConfigs = {
    { key = "targetOfTarget", name = "Target of Target Frame", module = "UnitFrame" },
    { key = "player", name = "Player Frame", module = "UnitFrame" },
    { key = "target", name = "Target Frame", module = "UnitFrame" },
    { key = "playerCastingBar", name = "Cast Bar Frame", module = "CastingBar" },
    { key = "buffs", name = "Buff Frame", module = "BuffFrame" },
    { key = "actionBar1", name = "Action Bar 1 (Main)", module = "ActionBar" },
    { key = "actionBar2", name = "Action Bar 2", module = "ActionBar" },
    { key = "actionBar3", name = "Action Bar 3", module = "ActionBar" },
    { key = "actionBar4", name = "Action Bar 4", module = "ActionBar" },
    { key = "actionBar5", name = "Action Bar 5", module = "ActionBar" },
    { key = "actionBar7", name = "Action Bar 7 (Shapeshift)", module = "ActionBar" }
}

function Module:OnEnable()
    -- Delay panel creation to ensure other modules are loaded
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "RetailUI" then
            Module:CreateSettingsPanel()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

function Module:OnDisable() end

function Module:CreateSettingsPanel()
    -- Create main panel frame
    local panel = CreateFrame("Frame", "RetailUISettingsPanel", UIParent)
    panel.name = "RetailUI Settings"
    
    -- Create title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("RetailUI Settings")
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 16)
    
    -- Create scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1) -- Will be resized later
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Variables for positioning
    local yOffset = -20
    local elementHeight = 50
    
    -- Create scale sliders for each module
    for i, config in ipairs(moduleConfigs) do
        local slider = self:CreateScaleSlider(scrollChild, config.key, config.name, yOffset)
        yOffset = yOffset - elementHeight
    end
    
    -- Add spacing before buttons
    yOffset = yOffset - 20
    
    -- Create Reset to Default button
    local resetButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetButton:SetSize(140, 24)
    resetButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        self:ResetToDefault()
    end)
    
    -- Create Open Grid Layout button
    local gridButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    gridButton:SetSize(140, 24)
    gridButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    gridButton:SetText("Open Grid Layout")
    gridButton:SetScript("OnClick", function()
        self:OpenGridLayout()
    end)
    
    yOffset = yOffset - 40
    
    -- Create Snap to Grid checkbox
    local snapCheckbox = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
    snapCheckbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    snapCheckbox.Text:SetText("Snap to Grid")
    snapCheckbox:SetScript("OnClick", function(self)
        Module.snapToGrid = self:GetChecked()
        
        -- Also update the EditorMode module
        local EditorMode = RUI:GetModule('EditorMode')
        if EditorMode then
            EditorMode:SetSnapToGrid(Module.snapToGrid)
        end
    end)
    
    yOffset = yOffset - 30
    
    -- Set scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 40)
    
    self.settingsPanel = panel
    
    -- Register with Interface Options
    InterfaceOptions_AddCategory(panel)
end

function Module:CreateScaleSlider(parent, widgetKey, displayName, yOffset)
    -- Create slider frame
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    slider:SetSize(200, 16)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    
    -- Get current scale value or default to 1.0
    local currentScale = self:GetWidgetScale(widgetKey) or 1.0
    slider:SetValue(currentScale)
    
    -- Create label
    local label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    label:SetText(displayName)
    
    -- Create value text
    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 4)
    valueText:SetText(string.format("%.0f%%", currentScale * 100))
    
    -- Set slider labels
    slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 0)
    slider.Low:SetText("50%")
    
    slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 0)
    slider.High:SetText("200%")
    
    -- Handle value changes
    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(string.format("%.0f%%", value * 100))
        Module:SetWidgetScale(widgetKey, value)
    end)
    
    return slider
end

function Module:GetWidgetScale(widgetKey)
    if not RUI.DB.profile.widgets[widgetKey] then
        return 1.0
    end
    return RUI.DB.profile.widgets[widgetKey].scale or 1.0
end

function Module:SetWidgetScale(widgetKey, scale)
    -- Ensure widget entry exists
    if not RUI.DB.profile.widgets[widgetKey] then
        RUI.DB.profile.widgets[widgetKey] = {}
    end
    
    -- Save scale
    RUI.DB.profile.widgets[widgetKey].scale = scale
    
    -- Update the appropriate module
    self:UpdateModuleScale(widgetKey, scale)
end

function Module:UpdateModuleScale(widgetKey, scale)
    -- Handle different widget types
    if widgetKey == "playerCastingBar" then
        if CastingBarFrame then
            CastingBarFrame:SetScale(scale)
        end
    elseif widgetKey == "buffs" then
        if BuffFrame then
            BuffFrame:SetScale(scale)
        end
    elseif widgetKey == "player" then
        if PlayerFrame then
            PlayerFrame:SetScale(scale)
        end
    elseif widgetKey == "target" then
        if TargetFrame then
            TargetFrame:SetScale(scale)
        end
    elseif widgetKey == "targetOfTarget" then
        if TargetFrameToT then
            TargetFrameToT:SetScale(scale)
        end
    elseif string.find(widgetKey, "actionBar") then
        -- Handle action bars
        local ActionBarModule = RUI:GetModule("ActionBar")
        if ActionBarModule and ActionBarModule.actionBars then
            local barNumber = tonumber(string.match(widgetKey, "actionBar(%d+)"))
            if barNumber and ActionBarModule.actionBars[barNumber] then
                ActionBarModule.actionBars[barNumber]:SetScale(scale)
            end
        end
    end
    
    -- Also try to call the existing UnitFrame module update if it's a unit frame
    if widgetKey == "player" or widgetKey == "target" or widgetKey == "targetOfTarget" then
        local UnitFrameModule = RUI:GetModule("UnitFrame")
        if UnitFrameModule and UnitFrameModule.UpdateWidgets then
            UnitFrameModule:UpdateWidgets()
        end
    end
end

function Module:ResetToDefault()
    -- Call the existing default command functionality
    local UnitFrameModule    = RUI:GetModule("UnitFrame")
    local CastingBarModule   = RUI:GetModule("CastingBar")
    local ActionBarModule    = RUI:GetModule("ActionBar")
    local MinimapModule      = RUI:GetModule("Minimap")
    local QuestTrackerModule = RUI:GetModule("QuestTracker")
    local BuffFrameModule    = RUI:GetModule("BuffFrame")

    if ActionBarModule then
        ActionBarModule:LoadDefaultSettings()
        ActionBarModule:UpdateWidgets()
    end

    if UnitFrameModule then
        UnitFrameModule:LoadDefaultSettings()
        UnitFrameModule:UpdateWidgets()
    end

    if CastingBarModule then
        CastingBarModule:LoadDefaultSettings()
        CastingBarModule:UpdateWidgets()
    end

    if MinimapModule then
        MinimapModule:LoadDefaultSettings()
        MinimapModule:UpdateWidgets()
    end

    if QuestTrackerModule then
        QuestTrackerModule:LoadDefaultSettings()
        QuestTrackerModule:UpdateWidgets()
    end

    if BuffFrameModule then
        BuffFrameModule:LoadDefaultSettings()
        BuffFrameModule:UpdateWidgets()
    end
    
    -- Refresh the settings panel if it's open
    self:RefreshPanel()
end

function Module:OpenGridLayout()
    local EditorMode = RUI:GetModule('EditorMode')
    if EditorMode then
        if EditorMode:IsShown() then
            EditorMode:Hide()
        else
            EditorMode:Show()
        end
    end
end

function Module:RefreshPanel()
    -- Update slider values without recreating the entire panel
    if self.settingsPanel and self.settingsPanel:IsVisible() then
        -- Close and reopen the panel to refresh values
        self.settingsPanel:Hide()
        self:OpenSettings()
    end
end

function Module:OpenSettings()
    if self.settingsPanel then
        -- Open Interface Options to the RetailUI Settings category
        InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.settingsPanel) -- Call twice as recommended
    end
end