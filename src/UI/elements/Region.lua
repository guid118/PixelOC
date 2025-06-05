--- START OF FILE Region.txt ---

local OOP = require("UI.OOP")
local event = require("event")

local Region = OOP.class("Region")

-- if you're gonna add these to a pane, (be that a normal pane, tabpane, scrollpane or otherwise), use relative coordinates.
-- e.g. your pane starts at 20,20, if you give the child region coordinates of 1,1 it will be drawn at 20,20, the top left of the pane.
function Region:initialize(x,y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self:setNeedsRedraw(true)
    self.eventListeners = {}
    self.parent = nil -- Ensure parent is initialized
end

function Region:isCoordinateInRegion(x,y)
    return x >= self.x and x <= (self.x + self.width -1) and
            y >= self.y and y <= (self.y + self.height -1)
end

function Region:unregisterListeners()
    if (self.eventListeners) then
        for eventType, listener in pairs(self.eventListeners) do
            event.ignore(eventType, listener)
        end
        self.eventListeners = {}
    end
end

function Region:setNeedsRedraw(needsRedraw)
    if self.needsRedraw == needsRedraw and self.needsRedraw ~= nil then return end

    self.needsRedraw = needsRedraw
    if self.needsRedraw and self.parent then
        if type(self.parent.setNeedsRedraw) == "function" then
            self.parent:setNeedsRedraw(true)
        elseif self.parent.needsRedraw ~= nil then
            self.parent.needsRedraw = true
        end
    end
end

-- Calculates the absolute screen position of this region's (1,1) origin
function Region:getAbsolutePosition()
    if not self.parent then
        return self.x, self.y -- Base case: Region is top-level, x & y are absolute.
    end
    -- self.x, self.y are 1-based relative offsets from the parent's content area origin.
    -- parent:getAbsolutePosition() returns absolute screen coords of parent's origin.
    local parentAbsX, parentAbsY = self.parent:getAbsolutePosition()
    return parentAbsX + self.x - 1, parentAbsY + self.y - 1 -- Corrected logic
end

-- Converts global screen coordinates to coordinates local to this region's (1,1) origin
function Region:getGlobalToLocalCoordinates(globalX, globalY)
    local regionGlobalX, regionGlobalY = self:getAbsolutePosition()
    -- Converts global screen coords to 1-based local coords for this region.
    -- E.g., a click on regionGlobalX, regionGlobalY becomes (1,1) locally.
    local localX = globalX - regionGlobalX + 1
    local localY = globalY - regionGlobalY + 1
    return localX, localY
end

return Region
--- END OF FILE Region.txt ---