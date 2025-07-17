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
    CastingBar = { name = "Casting Bars", module = nil }
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
    optionsFrame:SetSize(500, 400)
    optionsFrame:Hide()

    -- Title
    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("RetailUI Settings")

    local yOffset = -40
    local checkboxes = {}
    local sliders = {}
    local moduleIndex = 0

    -- Create checkboxes and sliders for each module in two columns
    for moduleKey, moduleInfo in pairs(moduleData) do
        local column = (moduleIndex % 2)
        local row = math.floor(moduleIndex / 2)
        local xOffset = column == 0 and 20 or 260
        local currentYOffset = yOffset - (row * 65)
        
        -- Module enable checkbox
        local checkbox = CreateFrame("CheckButton", "RetailUI" .. moduleKey .. "EnableCheckbox", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", xOffset, currentYOffset)
        checkbox:SetScript("OnClick", function(self)
            self:GetParent().UpdateModuleState(moduleKey, self:GetChecked())
        end)
        
        local checkboxText = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkboxText:SetText("Enable " .. moduleInfo.name)
        
        checkboxes[moduleKey] = checkbox

        -- Module scale slider (smaller and more compact)
        local slider = CreateFrame("Slider", "RetailUI" .. moduleKey .. "ScaleSlider", optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", xOffset + 20, currentYOffset - 25)
        slider:SetSize(180, 15)
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
        moduleIndex = moduleIndex + 1
    end

    -- Calculate position for controls below the modules (2 rows of modules = 130px)
    local controlsYOffset = yOffset - 130

    -- Snap to Grid checkbox for editor mode
    local snapCheckbox = CreateFrame("CheckButton", "RetailUISnapToGridCheckbox", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    snapCheckbox:SetPoint("TOPLEFT", 20, controlsYOffset)
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

    -- Open Grid Layout button
    local gridButton = CreateFrame("Button", "RetailUIGridLayoutButton", optionsFrame, "UIPanelButtonTemplate")
    gridButton:SetPoint("TOPLEFT", 20, controlsYOffset - 35)
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
        
        -- Use proper AceAddon APIs for enabling/disabling modules
        if enabled then
            RUI:EnableModule(moduleKey)
        else
            RUI:DisableModule(moduleKey)
        end
    end

    optionsFrame.UpdateModuleScale = function(moduleKey, scale)
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
        elseif moduleKey == "ActionBar" then
            -- Handle action bar scale using widget system
            local actionBarModule = moduleData.ActionBar.module
            if actionBarModule then
                -- Update all action bar widgets
                for index = 1, 5 do
                    local widgetKey = 'actionBar' .. index
                    if RUI.DB.profile.widgets[widgetKey] then
                        RUI.DB.profile.widgets[widgetKey].scale = scale
                    end
                end
                -- Update special bars
                if RUI.DB.profile.widgets.microMenuBar then
                    RUI.DB.profile.widgets.microMenuBar.scale = scale
                end
                if RUI.DB.profile.widgets.bagsBar then
                    RUI.DB.profile.widgets.bagsBar.scale = scale
                end
                if RUI.DB.profile.widgets.repExpBar then
                    RUI.DB.profile.widgets.repExpBar.scale = scale
                end
                actionBarModule:UpdateWidgets()
            end
        elseif moduleKey == "Minimap" then
            -- Handle minimap scale using widget system
            local minimapModule = moduleData.Minimap.module
            if minimapModule then
                if RUI.DB.profile.widgets.minimap then
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
            elseif moduleKey == "ActionBar" then
                -- Get action bar scale from first action bar widget
                if RUI.DB.profile.widgets and RUI.DB.profile.widgets.actionBar1 then
                    scale = RUI.DB.profile.widgets.actionBar1.scale or 1.0
                end
            elseif moduleKey == "Minimap" then
                -- Get minimap scale from widget
                if RUI.DB.profile.widgets and RUI.DB.profile.widgets.minimap then
                    scale = RUI.DB.profile.widgets.minimap.scale or 1.0
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
    
    print("RetailUI: Settings reset to defaults")
end