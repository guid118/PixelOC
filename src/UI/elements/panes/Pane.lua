--- START OF FILE Pane.txt ---
-- File: UI/elements/panes/Pane.txt

local OOP = require("UI.OOP")
local ColoredRegion = require("UI.elements.ColoredRegion")


local Pane = OOP.class("Pane", ColoredRegion)

function Pane:initialize(x, y, width, height, color)
    Pane.super.initialize(self, x, y, width, height, color)
    self.children = {}
    self:setNeedsRedraw(true) -- Pane itself needs initial draw
end

function Pane:addChild(element)
    table.insert(self.children, element)
    element.parent = self -- Set parent reference for redraw propagation
    self:setNeedsRedraw(true) -- Adding a child requires redraw
end

function Pane:removeChild(element)
    for i = #self.children, 1, -1 do
        if self.children[i] == element then
            table.remove(self.children, i)
            element.parent = nil -- Clear parent reference
            self:setNeedsRedraw(true) -- Removing a child requires redraw
            return
        end
    end
end


--- @param gpu gpu
function Pane:draw(gpu)

    local tempBufferId = gpu.allocateBuffer(self.width, self.height)

    local drawSuccess, drawingError = pcall(function()
        local originalActiveBuffer = gpu.getActiveBuffer()

        gpu.setActiveBuffer(tempBufferId)

        local pGpuBgColor, pGpuBgPalette = gpu.getBackground()
        local bgColorVal, bgColorIsPalette = self.color:get()
        gpu.setBackground(bgColorVal, bgColorIsPalette)
        gpu.fill(1, 1, self.width, self.height, " ")
        gpu.setBackground(pGpuBgColor, pGpuBgPalette)

        for _, child in ipairs(self.children) do
            if child and type(child.draw) == "function" then
                child:draw(gpu)
            end
        end

        gpu.setActiveBuffer(originalActiveBuffer) -- Switch back to the buffer we were originally drawing on.
        gpu.bitblt(originalActiveBuffer, self.x, self.y, self.width, self.height, tempBufferId, 1, 1) -- copy draw to the previous buffer
    end)

    gpu.freeBuffer(tempBufferId)

    if not drawSuccess then
        self:setNeedsRedraw(true) -- Error occurred, so it likely needs redraw
    else
        self:setNeedsRedraw(false) -- The pane has been redrawn
    end
end

function Pane:onClick(clickX, clickY)
    if not self:isCoordinateInRegion(clickX, clickY) then
        return
    end

    local relativeToPaneX = clickX - self.x + 1
    local relativeToPaneY = clickY - self.y + 1

    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child and type(child.isCoordinateInRegion) == "function" and type(child.onClick) == "function" then
            if child:isCoordinateInRegion(relativeToPaneX, relativeToPaneY) then
                child:onClick(relativeToPaneX, relativeToPaneY)
                return
            end
        end
    end
    return
end

function Pane:setNeedsRedraw(needsRedraw)
    if self.needsRedraw == needsRedraw then return end

    self.needsRedraw = needsRedraw
    if self.needsRedraw and self.parent then
        if type(self.parent.setNeedsRedraw) == "function" then
            self.parent:setNeedsRedraw(true)
        elseif self.parent.needsRedraw ~= nil then
            self.parent.needsRedraw = true
        end
    end
end

function Pane:unregisterListeners()
    Pane.super.unregisterListeners(self)
    if self.children then
        for _, child in ipairs(self.children) do
            if child and type(child.unregisterListeners) == "function" then
                child:unregisterListeners()
            end
        end
        self.children = {}
    end
end

return Pane
