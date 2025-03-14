local Region = require("UI.elements.Region")
local gpu = require("component").gpu
local ElementUtils = require("UI.lib.ElementUtils")
local Clickable = require("UI.elements.control.Clickable")

---@class Pane:Region
local Pane = setmetatable({}, { __index = Region })
Pane.__index = Pane

--- Default constructor for the Pane class
--- @return Pane a new Pane that spans across the whole screen
function Pane.new()
    local x, y = gpu.getResolution()
    return Pane.new(1, 1, x, y)
end

--- Normal constructor for the Pane class
--- @return Pane a new Pane
function Pane.new(x, y, width, height)
    return Pane.new(x, y, width, height, true)
end

--- Constructor for the Pane, with an extra isVisible field to set the default visibility
--- @return Pane a new Pane
function Pane.new(x, y, width, height, isVisible)
    local obj = Region.new(x, y, width, height)
    setmetatable(obj, Pane)
    obj.isEnabled = isVisible;
    obj.content = {}
    return obj
end

--- Add a region inheriting class to the pane
--- Coordinates of the region will be local coordinates in the pane (so region.x = region.x + pane.x and the same for y)
--- Given argument MUST INHERIT FROM REGION, or this will cause a crash!
--- @param RegionInheritor Region to add to the pane.
function Pane:add(RegionInheritor)
    RegionInheritor:setX(RegionInheritor.x + self.x - 1)
    RegionInheritor:setY(RegionInheritor.y + self.y - 1)
    table.insert(self.content, RegionInheritor)
end

--- Set this pane to visible, if the draw function is called while the pane is not visible, it will not draw anything.
---@param value boolean true if the pane should be visible, false otherwise.
function Pane:setEnabled(value)
    self.isEnabled = value
    if (value == true) then
        self:draw()
    end
end

--- Draw function for the pane, will not draw anything if getVisible is false
function Pane:draw()
    if (self.isEnabled) then
        gpu.setForeground(0x000000, false)
        gpu.setBackground(0x000000, false)
        gpu.fill(self.x, self.y, self.width, self.height, " ")
        for _, item in ipairs(self.content) do
            if (item.x >= self.x - 1 and item.x + item.width <= self.x + self.width
                    and item.y >= self.y - 1 and item.y + item.height <= self.y + self.height) then
                item:draw()
            end
        end
    end
end

--- Getter for the isEnabled value
--- @return boolean if the pane is visible or not
function Pane:getEnabled()
    return self.isEnabled
end

--- Get the clickable that is at the given coordinates
--- @return Clickable of the pane at the given coordinates.
function Pane:getClickableAt(x, y)
    if (self.isEnabled) then
        if (self:isCoordinateInRegion(x, y)) then
            for _, item in ipairs(self.content) do
                if (ElementUtils.inheritsFrom(item, Pane)) then
                    return item:getClickableAt(x, y)
                elseif ElementUtils.inheritsFrom(item, Clickable) then
                    if (item:isCoordinateInRegion(x, y)) then
                        return item
                    end
                end
            end
        end
    end
end

function Pane:unregisterListeners()
    for _, item in pairs(self.content) do
        if (ElementUtils.inheritsFrom(item, Region)) then
            item:unregisterListeners()
        end
    end
end

return Pane
