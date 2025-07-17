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
local Module = RUI:NewModule(moduleName, 'AceEvent-3.0')

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
    -- Create settings panel immediately since we're already loading
    self:CreateSettingsPanel()
end

function Module:OnDisable() end

function Module:CreateSettingsPanel()
    if self.settingsPanel then
        -- Panel already exists
        return
    end
    
    -- Create main panel frame
    local panel = CreateFrame("Frame", "RetailUISettingsPanel", UIParent)
    panel.name = "RetailUI Settings"
    
    -- Set up panel appearance for standalone mode (WoW 3.3.5 compatibility)
    panel:SetSize(400, 500)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    panel:SetBackdropColor(0, 0, 0, 1)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide() -- Start hidden
    
    -- Add a close button for standalone mode (create manually for WoW 3.3.5 compatibility)
    local closeButton = CreateFrame("Button", nil, panel)
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)
    
    -- Create title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("RetailUI Settings")
    
    -- For WoW 3.3.5 compatibility, create a simple scrollable content frame instead of using templates
    local contentFrame = CreateFrame("Frame", nil, panel)
    contentFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -50)
    contentFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
    
    -- Use the content frame directly for positioning elements
    local scrollChild = contentFrame
    
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
    
    -- Create Snap to Grid checkbox (simplified for WoW 3.3.5 compatibility)
    local snapCheckbox = CreateFrame("CheckButton", nil, scrollChild)
    snapCheckbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    snapCheckbox:SetSize(24, 24)
    
    -- Set up checkbox textures manually
    snapCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    snapCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    snapCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    snapCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    
    -- Create text label for checkbox
    local snapLabel = snapCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    snapLabel:SetPoint("LEFT", snapCheckbox, "RIGHT", 4, 0)
    snapLabel:SetText("Snap to Grid")
    
    snapCheckbox:SetScript("OnClick", function(self)
        Module.snapToGrid = self:GetChecked()
        
        -- Also update the EditorMode module
        local EditorMode = RUI:GetModule('EditorMode', true)  -- true = silent
        if EditorMode and EditorMode.SetSnapToGrid then
            EditorMode:SetSnapToGrid(Module.snapToGrid)
        end
    end)
    
    yOffset = yOffset - 30
    
    self.settingsPanel = panel
    
    -- Register with Interface Options
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    else
        print("RetailUI: Interface Options not available")
    end
end

function Module:CreateScaleSlider(parent, widgetKey, displayName, yOffset)
    -- Create slider frame without template for WoW 3.3.5 compatibility
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    slider:SetSize(200, 16)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    
    -- Create slider textures manually since we're not using templates
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetSize(32, 32)
    slider:SetThumbTexture(thumb)
    
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
    bg:SetAllPoints(slider)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    
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
    if not RUI.DB or not RUI.DB.profile or not RUI.DB.profile.widgets then
        return 1.0
    end
    if not RUI.DB.profile.widgets[widgetKey] then
        return 1.0
    end
    return RUI.DB.profile.widgets[widgetKey].scale or 1.0
end

function Module:SetWidgetScale(widgetKey, scale)
    -- Ensure database is initialized
    if not RUI.DB or not RUI.DB.profile then
        print("RetailUI database not initialized")
        return
    end
    
    -- Ensure widgets table exists
    if not RUI.DB.profile.widgets then
        RUI.DB.profile.widgets = {}
    end
    
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
    if not self.settingsPanel then
        -- Try to create the panel if it doesn't exist
        self:CreateSettingsPanel()
    end
    
    if self.settingsPanel then
        -- Check if InterfaceOptionsFrame_OpenToCategory exists (it might not in WoW 3.3.5)
        if InterfaceOptionsFrame_OpenToCategory then
            -- Open Interface Options to the RetailUI Settings category
            InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
            InterfaceOptionsFrame_OpenToCategory(self.settingsPanel) -- Call twice as recommended
        else
            -- Fallback for WoW 3.3.5: Show the panel directly
            if not self.settingsPanel:IsShown() then
                self.settingsPanel:Show()
                self.settingsPanel:SetPoint("CENTER", UIParent, "CENTER")
            else
                self.settingsPanel:Hide()
            end
        end
    else
        print("RetailUI: Settings panel could not be created")
    end
end