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

-- Module definitions (removed VehicleUI)
local moduleData = {
    ActionBar = { name = "Action Bars", module = nil },
    UnitFrame = { name = "Unit Frames", module = nil },
    Minimap = { name = "Minimap", module = nil },
    CastingBar = { name = "Casting Bars", module = nil }
}

-- Action bar definitions for individual control
local actionBarData = {
    actionBar1 = { name = "Action Bar 1", frame = "ActionButton" },
    actionBar2 = { name = "Action Bar 2", frame = "MultiBarBottomLeftButton" },
    actionBar3 = { name = "Action Bar 3", frame = "MultiBarBottomRightButton" },
    actionBar4 = { name = "Action Bar 4", frame = "MultiBarRightButton" },
    actionBar5 = { name = "Action Bar 5", frame = "MultiBarLeftButton" },
    actionBar6 = { name = "Action Bar 6", frame = "MultiBarRightButton" },
    actionBar7 = { name = "Action Bar 7", frame = "MultiBarLeftButton" },
    microMenuBar = { name = "Micro Menu", frame = "MicroButtonAndBagsBar" },
    bagsBar = { name = "Bags Bar", frame = "MicroButtonAndBagsBar" }
}

function Module:OnEnable()
    -- Get module references
    moduleData.ActionBar.module = RUI:GetModule("ActionBar")
    moduleData.UnitFrame.module = RUI:GetModule("UnitFrame")
    moduleData.Minimap.module = RUI:GetModule("Minimap")
    moduleData.CastingBar.module = RUI:GetModule("CastingBar")
    
    self:CreateOptionsPanel()
end

function Module:OnDisable() end

function Module:CreateOptionsPanel()
    -- Create main options frame
    optionsFrame = CreateFrame("Frame", "RetailUISettingsPanel", UIParent)
    optionsFrame.name = "RetailUI Settings"
    optionsFrame:SetSize(600, 500)
    optionsFrame:Hide()

    -- Title
    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("RetailUI Settings")

    -- Create scroll frame to prevent overflow
    scrollFrame = CreateFrame("ScrollFrame", "RetailUIScrollFrame", optionsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

    -- Create scroll child
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(550, 1000) -- Large enough for all content
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -10
    local checkboxes = {}
    local sliders = {}

    -- Create module enable checkboxes
    for moduleKey, moduleInfo in pairs(moduleData) do
        -- Module enable checkbox
        local checkbox = CreateFrame("CheckButton", "RetailUI" .. moduleKey .. "EnableCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 0, yOffset)
        checkbox:SetScript("OnClick", function(self)
            Module:UpdateModuleState(moduleKey, self:GetChecked())
        end)
        
        local checkboxText = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkboxText:SetText("Enable " .. moduleInfo.name)
        
        checkboxes[moduleKey] = checkbox
        yOffset = yOffset - 35
    end

    yOffset = yOffset - 20

    -- Create individual action bar sliders
    local actionBarSliders = {}
    for barKey, barInfo in pairs(actionBarData) do
        local slider = CreateFrame("Slider", "RetailUI" .. barKey .. "ScaleSlider", scrollChild, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 0, yOffset)
        slider:SetSize(300, 15)
        slider:SetMinMaxValues(0.5, 2.0)
        slider:SetValue(1.0)
        slider:SetValueStep(0.1)
        slider:SetScript("OnValueChanged", function(self, value)
            Module:UpdateActionBarScale(barKey, value)
            getglobal(self:GetName() .. "Text"):SetText(barInfo.name .. " Scale: " .. string.format("%.1f", value))
        end)
        
        getglobal(slider:GetName() .. "Low"):SetText("0.5")
        getglobal(slider:GetName() .. "High"):SetText("2.0")
        getglobal(slider:GetName() .. "Text"):SetText(barInfo.name .. " Scale: 1.0")
        
        actionBarSliders[barKey] = slider
        yOffset = yOffset - 35
    end

    -- Create other module sliders
    for moduleKey, moduleInfo in pairs(moduleData) do
        if moduleKey ~= "ActionBar" then -- Skip action bars as they have individual controls
            local slider = CreateFrame("Slider", "RetailUI" .. moduleKey .. "ScaleSlider", scrollChild, "OptionsSliderTemplate")
            slider:SetPoint("TOPLEFT", 0, yOffset)
            slider:SetSize(300, 15)
            slider:SetMinMaxValues(0.5, 2.0)
            slider:SetValue(1.0)
            slider:SetValueStep(0.1)
            slider:SetScript("OnValueChanged", function(self, value)
                Module:UpdateModuleScale(moduleKey, value)
                getglobal(self:GetName() .. "Text"):SetText(moduleInfo.name .. " Scale: " .. string.format("%.1f", value))
            end)
            
            getglobal(slider:GetName() .. "Low"):SetText("0.5")
            getglobal(slider:GetName() .. "High"):SetText("2.0")
            getglobal(slider:GetName() .. "Text"):SetText(moduleInfo.name .. " Scale: 1.0")
            
            sliders[moduleKey] = slider
            yOffset = yOffset - 35
        end
    end

    yOffset = yOffset - 20

    -- Snap to Grid checkbox for editor mode
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

    yOffset = yOffset - 40

    -- Open Grid Layout button
    local gridButton = CreateFrame("Button", "RetailUIGridLayoutButton", scrollChild, "UIPanelButtonTemplate")
    gridButton:SetPoint("TOPLEFT", 0, yOffset)
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
    local resetButton = CreateFrame("Button", "RetailUIResetButton", scrollChild, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", gridButton, "RIGHT", 10, 0)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        Module:ResetToDefaults()
    end)

    -- Store references
    optionsFrame.checkboxes = checkboxes
    optionsFrame.sliders = sliders
    optionsFrame.actionBarSliders = actionBarSliders
    optionsFrame.snapCheckbox = snapCheckbox

    -- Initialize values from saved settings
    self:LoadSavedSettings()

    -- Add to interface options
    InterfaceOptions_AddCategory(optionsFrame)
end

function Module:UpdateModuleState(moduleKey, enabled)
    RUI.DB.profile.modules = RUI.DB.profile.modules or {}
    RUI.DB.profile.modules[moduleKey] = RUI.DB.profile.modules[moduleKey] or {}
    RUI.DB.profile.modules[moduleKey].enabled = enabled
    
    -- Use proper AceAddon APIs for enabling/disabling modules
    local module = RUI:GetModule(moduleKey, true)
    if module then
        if enabled then
            if not module:IsEnabled() then
                RUI:EnableModule(moduleKey)
            end
        else
            if module:IsEnabled() then
                RUI:DisableModule(moduleKey)
            end
        end
    end
end

function Module:UpdateActionBarScale(barKey, scale)
    -- Handle individual action bar scaling
    if RUI.DB.profile.widgets then
        if RUI.DB.profile.widgets[barKey] then
            RUI.DB.profile.widgets[barKey].scale = scale
        end
    end
    
    local actionBarModule = moduleData.ActionBar.module
    if actionBarModule and actionBarModule.UpdateWidgets then
        actionBarModule:UpdateWidgets()
    end
end

function Module:UpdateModuleScale(moduleKey, scale)
    -- For unit frames, use the existing widget-based scale system
    if moduleKey == "UnitFrame" then
        local widgets = {"player", "target", "focus", "targetOfTarget", "pet"}
        for _, widget in pairs(widgets) do
            SaveUIFrameScale(tostring(scale), widget)
        end
    elseif moduleKey == "CastingBar" then
        -- Handle casting bar scale
        if CastingBarFrame then
            CastingBarFrame:SetScale(scale)
        end
    elseif moduleKey == "Minimap" then
        -- Handle minimap scale - call SetScale on MinimapCluster
        if MinimapCluster then
            MinimapCluster:SetScale(scale)
        end
        -- Also update widget system
        local minimapModule = moduleData.Minimap.module
        if minimapModule then
            if RUI.DB.profile.widgets and RUI.DB.profile.widgets.minimap then
                RUI.DB.profile.widgets.minimap.scale = scale
            end
            minimapModule:UpdateWidgets()
        end
    else
        -- For other modules, store in module settings
        RUI.DB.profile.modules = RUI.DB.profile.modules or {}
        RUI.DB.profile.modules[moduleKey] = RUI.DB.profile.modules[moduleKey] or {}
        RUI.DB.profile.modules[moduleKey].scale = scale
        
        local module = moduleData[moduleKey].module
        if module and module.UpdateWidgets then
            module:UpdateWidgets()
        end
    end
end

function Module:LoadSavedSettings()
    if not optionsFrame then return end
    
    RUI.DB.profile.modules = RUI.DB.profile.modules or {}
    
    -- Load module states and scales
    for moduleKey, _ in pairs(moduleData) do
        local moduleSettings = RUI.DB.profile.modules[moduleKey] or { enabled = true, scale = 1.0 }
        
        if optionsFrame.checkboxes[moduleKey] then
            -- Check if module is actually enabled using AceAddon API
            local module = RUI:GetModule(moduleKey, true)
            local isEnabled = module and module:IsEnabled() or false
            optionsFrame.checkboxes[moduleKey]:SetChecked(isEnabled)
        end
        
        if optionsFrame.sliders[moduleKey] then
            local scale = 1.0
            -- Get scale from appropriate source
            if moduleKey == "UnitFrame" then
                -- Use player frame scale as representative
                scale = GetUIFrameScale("player") or 1.0
            elseif moduleKey == "CastingBar" then
                -- Get casting bar scale
                if CastingBarFrame then
                    scale = CastingBarFrame:GetScale() or 1.0
                end
            elseif moduleKey == "Minimap" then
                -- Get minimap scale from MinimapCluster
                if MinimapCluster then
                    scale = MinimapCluster:GetScale() or 1.0
                end
            else
                scale = moduleSettings.scale or 1.0
            end
            
            optionsFrame.sliders[moduleKey]:SetValue(scale)
            local sliderText = getglobal(optionsFrame.sliders[moduleKey]:GetName() .. "Text")
            if sliderText then
                sliderText:SetText(moduleData[moduleKey].name .. " Scale: " .. string.format("%.1f", scale))
            end
        end
    end
    
    -- Load action bar scales
    if optionsFrame.actionBarSliders then
        for barKey, slider in pairs(optionsFrame.actionBarSliders) do
            local scale = 1.0
            if RUI.DB.profile.widgets and RUI.DB.profile.widgets[barKey] then
                scale = RUI.DB.profile.widgets[barKey].scale or 1.0
            end
            
            slider:SetValue(scale)
            local sliderText = getglobal(slider:GetName() .. "Text")
            if sliderText then
                sliderText:SetText(actionBarData[barKey].name .. " Scale: " .. string.format("%.1f", scale))
            end
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

    -- Reset module states to defaults
    RUI.DB.profile.modules = {}
    for moduleKey, _ in pairs(moduleData) do
        RUI.DB.profile.modules[moduleKey] = { enabled = true, scale = 1.0 }
    end
    
    -- Reset snap to grid
    RUI.DB.profile.snapToGrid = false
    
    -- Reload settings in UI
    self:LoadSavedSettings()
end