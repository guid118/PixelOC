local event = require("event")

---@class Region
---@field x number
---@field y number
---@field width number
---@field height number
local Region = {}

--- Constructor for the Region class
---@return Region new instance of Region
function Region.new(x, y, width, height)
    local obj = setmetatable({}, self)
    obj.x = x or 0
    obj.y = y or 0
    obj.width = width or 10
    obj.height = height or 5
    obj.eventListeners = {}
    return obj
end

--- @param x number x value
--- @param y number y value
--- @return boolean true if the given coordinates are within the limits of this region, false otherwise
function Region:isCoordinateInRegion(x, y)
    local xmax = self.x + self.width - 1
    local ymax = self.y + self.height - 1
    if x >= self.x and x <= xmax then
        if y >= self.y and y <= ymax then
            return true
        end
    end
    return false
end

--- unregister all listeners in the eventListeners list
--- classes may have to unregister timers and other event listeners not in the list themselves
function Region:unregisterListeners()
    if (self.eventListeners) then
        for eventType, listener in pairs(self.eventListeners) do
            event.ignore(eventType, listener)
        end
        self.eventListeners = {}
    end
end


function Region:setX(x)
    self.x = x
end

function Region:setY(y)
    self.y = y
end

return Region