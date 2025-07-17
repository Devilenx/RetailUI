--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local moduleName = 'InterfaceOptions'
local Module = RUI:NewModule(moduleName, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local optionsFrame = nil

-- Module definitions
local moduleData = {
    ActionBar = { name = "Action Bars", module = nil },
    UnitFrame = { name = "Unit Frames", module = nil },
    Minimap = { name = "Minimap", module = nil },
    CastingBar = { name = "Casting Bars", module = nil },
    VehicleUI = { name = "Vehicle UI", module = nil }
}

function Module:OnEnable()
    -- Get module references
    moduleData.ActionBar.module = RUI:GetModule("ActionBar")
    moduleData.UnitFrame.module = RUI:GetModule("UnitFrame")
    moduleData.Minimap.module = RUI:GetModule("Minimap")
    moduleData.CastingBar.module = RUI:GetModule("CastingBar")
    moduleData.VehicleUI.module = RUI:GetModule("VehicleUI")
    
    self:CreateOptionsPanel()
end

function Module:OnDisable() end

function Module:CreateOptionsPanel()
    -- Create main options frame
    optionsFrame = CreateFrame("Frame", "RetailUISettingsPanel", UIParent)
    optionsFrame.name = "RetailUI Settings"
    optionsFrame:SetSize(400, 500)
    optionsFrame:Hide()

    -- Title
    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("RetailUI Settings")

    local yOffset = -50
    local checkboxes = {}
    local sliders = {}

    -- Create checkboxes and sliders for each module
    for moduleKey, moduleInfo in pairs(moduleData) do
        -- Module enable checkbox
        local checkbox = CreateFrame("CheckButton", "RetailUI" .. moduleKey .. "EnableCheckbox", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 20, yOffset)
        checkbox:SetScript("OnClick", function(self)
            self:GetParent().UpdateModuleState(moduleKey, self:GetChecked())
        end)
        
        local checkboxText = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkboxText:SetText("Enable " .. moduleInfo.name)
        
        checkboxes[moduleKey] = checkbox

        -- Module scale slider
        local slider = CreateFrame("Slider", "RetailUI" .. moduleKey .. "ScaleSlider", optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 40, yOffset - 30)
        slider:SetSize(200, 20)
        slider:SetMinMaxValues(0.5, 2.0)
        slider:SetValue(1.0)
        slider:SetValueStep(0.1)
        slider:SetScript("OnValueChanged", function(self, value)
            self:GetParent().UpdateModuleScale(moduleKey, value)
            getglobal(self:GetName() .. "Text"):SetText(moduleInfo.name .. " Scale: " .. string.format("%.1f", value))
        end)
        
        getglobal(slider:GetName() .. "Low"):SetText("0.5")
        getglobal(slider:GetName() .. "High"):SetText("2.0")
        getglobal(slider:GetName() .. "Text"):SetText(moduleInfo.name .. " Scale: 1.0")
        
        sliders[moduleKey] = slider

        yOffset = yOffset - 80
    end

    -- Snap to Grid checkbox for editor mode
    local snapCheckbox = CreateFrame("CheckButton", "RetailUISnapToGridCheckbox", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    snapCheckbox:SetPoint("TOPLEFT", 20, yOffset)
    snapCheckbox:SetScript("OnClick", function(self)
        RUI.DB.profile.snapToGrid = self:GetChecked()
    end)
    
    local snapText = snapCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    snapText:SetPoint("LEFT", snapCheckbox, "RIGHT", 5, 0)
    snapText:SetText("Snap to Grid (Editor Mode)")

    -- Open Grid Layout button
    local gridButton = CreateFrame("Button", "RetailUIGridLayoutButton", optionsFrame, "UIPanelButtonTemplate")
    gridButton:SetPoint("TOPLEFT", 20, yOffset - 40)
    gridButton:SetSize(120, 25)
    gridButton:SetText("Open Grid Layout")
    gridButton:SetScript("OnClick", function()
        local EditorMode = RUI:GetModule('EditorMode')
        if EditorMode:IsShown() then
            EditorMode:Hide()
        else
            EditorMode:Show()
        end
    end)

    -- Reset to Default button
    local resetButton = CreateFrame("Button", "RetailUIResetButton", optionsFrame, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", gridButton, "RIGHT", 10, 0)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        self:ResetToDefaults()
    end)

    -- Update functions
    optionsFrame.UpdateModuleState = function(moduleKey, enabled)
        RUI.DB.profile.modules = RUI.DB.profile.modules or {}
        RUI.DB.profile.modules[moduleKey] = RUI.DB.profile.modules[moduleKey] or {}
        RUI.DB.profile.modules[moduleKey].enabled = enabled
        
        local module = moduleData[moduleKey].module
        if module then
            if enabled then
                if module.Enable then module:Enable() end
            else
                if module.Disable then module:Disable() end
            end
        end
    end

    optionsFrame.UpdateModuleScale = function(moduleKey, scale)
        RUI.DB.profile.modules = RUI.DB.profile.modules or {}
        RUI.DB.profile.modules[moduleKey] = RUI.DB.profile.modules[moduleKey] or {}
        RUI.DB.profile.modules[moduleKey].scale = scale
        
        local module = moduleData[moduleKey].module
        if module and module.UpdateWidgets then
            module:UpdateWidgets()
        end
    end

    -- Store references
    optionsFrame.checkboxes = checkboxes
    optionsFrame.sliders = sliders
    optionsFrame.snapCheckbox = snapCheckbox

    -- Initialize values from saved settings
    self:LoadSavedSettings()

    -- Add to interface options
    InterfaceOptions_AddCategory(optionsFrame)
end

function Module:LoadSavedSettings()
    if not optionsFrame then return end
    
    RUI.DB.profile.modules = RUI.DB.profile.modules or {}
    
    -- Load module states and scales
    for moduleKey, _ in pairs(moduleData) do
        local moduleSettings = RUI.DB.profile.modules[moduleKey] or { enabled = true, scale = 1.0 }
        
        if optionsFrame.checkboxes[moduleKey] then
            optionsFrame.checkboxes[moduleKey]:SetChecked(moduleSettings.enabled)
        end
        
        if optionsFrame.sliders[moduleKey] then
            optionsFrame.sliders[moduleKey]:SetValue(moduleSettings.scale or 1.0)
        end
    end
    
    -- Load snap to grid setting
    if optionsFrame.snapCheckbox then
        optionsFrame.snapCheckbox:SetChecked(RUI.DB.profile.snapToGrid or false)
    end
end

function Module:ResetToDefaults()
    -- Reset all modules to default
    local UnitFrameModule    = RUI:GetModule("UnitFrame")
    local CastingBarModule   = RUI:GetModule("CastingBar")
    local ActionBarModule    = RUI:GetModule("ActionBar")
    local MinimapModule      = RUI:GetModule("Minimap")
    local QuestTrackerModule = RUI:GetModule("QuestTracker")
    local BuffFrameModule    = RUI:GetModule("BuffFrame")
    local VehicleUIModule    = RUI:GetModule("VehicleUI")

    if ActionBarModule and ActionBarModule.LoadDefaultSettings then
        ActionBarModule:LoadDefaultSettings()
        ActionBarModule:UpdateWidgets()
    end

    if UnitFrameModule and UnitFrameModule.LoadDefaultSettings then
        UnitFrameModule:LoadDefaultSettings()
        UnitFrameModule:UpdateWidgets()
    end

    if CastingBarModule and CastingBarModule.LoadDefaultSettings then
        CastingBarModule:LoadDefaultSettings()
        CastingBarModule:UpdateWidgets()
    end

    if MinimapModule and MinimapModule.LoadDefaultSettings then
        MinimapModule:LoadDefaultSettings()
        MinimapModule:UpdateWidgets()
    end

    if QuestTrackerModule and QuestTrackerModule.LoadDefaultSettings then
        QuestTrackerModule:LoadDefaultSettings()
        QuestTrackerModule:UpdateWidgets()
    end

    if BuffFrameModule and BuffFrameModule.LoadDefaultSettings then
        BuffFrameModule:LoadDefaultSettings()
        BuffFrameModule:UpdateWidgets()
    end

    if VehicleUIModule and VehicleUIModule.LoadDefaultSettings then
        VehicleUIModule:LoadDefaultSettings()
        VehicleUIModule:UpdateWidgets()
    end

    -- Reset module states to defaults
    RUI.DB.profile.modules = {}
    for moduleKey, _ in pairs(moduleData) do
        RUI.DB.profile.modules[moduleKey] = { enabled = true, scale = 1.0 }
    end
    
    -- Reset snap to grid
    RUI.DB.profile.snapToGrid = false
    
    -- Reload settings in UI
    self:LoadSavedSettings()
    
    print("RetailUI: Settings reset to defaults")
end