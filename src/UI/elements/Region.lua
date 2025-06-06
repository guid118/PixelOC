--- START OF FILE Region.txt ---

local OOP = require("UI.OOP")
local event = require("event")
local Logger = require("UI.lib.Logger")
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

function Region:getGlobalCoordinates()
    if not self.parent or not (type(self.parent.getGlobalCoordinates) == "function") then
        --Logger.debug("Found top-level parent: " .. self.__name)
        --Logger.debug("Starting with coordinates: " .. self.x .. ", " .. self.y)
        return self.x, self.y
    end
    local parentAbsX, parentAbsY = self.parent:getGlobalCoordinates()
    --Logger.debug("determining coordinates, step: " .. self.__name)
    --Logger.debug("Current coordinates: " .. parentAbsX .. ", " .. parentAbsY)
    return parentAbsX + self.x - 1, parentAbsY + self.y - 1
end

function Region:globalToLocal(globalX, globalY)
    local regionGlobalX, regionGlobalY = self:getGlobalCoordinates()
    return globalX - regionGlobalX + 1, globalY - regionGlobalY + 1
end


return Region
--- END OF FILE Region.txt ---