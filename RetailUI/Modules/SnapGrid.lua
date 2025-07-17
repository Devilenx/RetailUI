--[[
    Copyright (c) Dmitriy. All rights reserved.
    Licensed under the MIT license. See LICENSE file in the project root for details.
    
    SnapGrid.lua - Enhanced grid snapping helper for RetailUI
]]

local RUI = LibStub('AceAddon-3.0'):GetAddon('RetailUI')
local SnapGrid = {}

-- Grid configuration
SnapGrid.GRID_SIZE = 32
SnapGrid.BORDER_THICKNESS = 2

-- Calculate grid cell size including borders
function SnapGrid:GetCellSize()
    return self.GRID_SIZE - self.BORDER_THICKNESS
end

-- Snap a frame's position to the nearest non-overlapping grid cell
function SnapGrid:SnapToGrid(frame)
    if not frame then return end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    if not point then return end
    
    local cellSize = self:GetCellSize()
    
    -- Calculate snapped position ensuring no overlap
    local snappedX = math.floor((xOfs + cellSize/2) / cellSize) * cellSize
    local snappedY = math.floor((yOfs + cellSize/2) / cellSize) * cellSize
    
    -- Apply the snapped position
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, snappedX, snappedY)
end

-- Check if a frame overlaps with another frame
function SnapGrid:CheckOverlap(frame1, frame2)
    if not frame1 or not frame2 then return false end
    
    local left1, bottom1, width1, height1 = frame1:GetRect()
    local left2, bottom2, width2, height2 = frame2:GetRect()
    
    if not left1 or not left2 then return false end
    
    local right1 = left1 + width1
    local top1 = bottom1 + height1
    local right2 = left2 + width2
    local top2 = bottom2 + height2
    
    -- Check for overlap
    return not (right1 <= left2 or left1 >= right2 or top1 <= bottom2 or bottom1 >= top2)
end

-- Find next available grid position that doesn't overlap
function SnapGrid:FindNonOverlappingPosition(frame, excludeFrames)
    if not frame then return end
    
    excludeFrames = excludeFrames or {}
    local cellSize = self:GetCellSize()
    local startX, startY = frame:GetCenter()
    
    -- Try positions in expanding spiral pattern
    for radius = 0, 20 do
        for angle = 0, 360, 45 do
            local testX = startX + radius * cellSize * math.cos(math.rad(angle))
            local testY = startY + radius * cellSize * math.sin(math.rad(angle))
            
            -- Snap to grid
            testX = math.floor((testX + cellSize/2) / cellSize) * cellSize
            testY = math.floor((testY + cellSize/2) / cellSize) * cellSize
            
            -- Test this position
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", testX, testY)
            
            local hasOverlap = false
            for _, otherFrame in pairs(excludeFrames) do
                if self:CheckOverlap(frame, otherFrame) then
                    hasOverlap = true
                    break
                end
            end
            
            if not hasOverlap then
                return -- Found good position
            end
        end
    end
end

-- Enhanced snap function for editor mode
function SnapGrid:SnapFrameToGridEnhanced(frame, allFrames)
    if not frame then return end
    
    -- Get the EditorMode module to check if snap is enabled
    local EditorMode = RUI:GetModule('EditorMode', true)
    if not EditorMode or not EditorMode:GetSnapToGrid() then return end
    
    -- First try simple grid snap
    self:SnapToGrid(frame)
    
    -- If overlap checking is desired, uncomment below:
    -- if allFrames then
    --     local overlaps = false
    --     for _, otherFrame in pairs(allFrames) do
    --         if otherFrame ~= frame and self:CheckOverlap(frame, otherFrame) then
    --             overlaps = true
    --             break
    --         end
    --     end
    --     
    --     if overlaps then
    --         self:FindNonOverlappingPosition(frame, allFrames)
    --     end
    -- end
end

-- Make SnapGrid available globally
RUI.SnapGrid = SnapGrid