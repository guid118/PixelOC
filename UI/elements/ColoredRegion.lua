local gpu = require("component").gpu
local Region = require("UI.elements.Region")

---@class ColoredRegion:Region
local ColoredRegion = setmetatable({}, { __index = Region })
ColoredRegion.__index = ColoredRegion

--- Constructor for the ColoredRegion class
--- @return ColoredRegion a new ColoredRegion
function ColoredRegion.new(x, y, width, height, color, ispalette)
    local obj = Region.new(x, y, width, height)
    setmetatable(obj, ColoredRegion)
    obj.color = color or 0xFFFFFF
    obj.ispalette = ispalette or false
    return obj
end

--- Draw the ColoredRegion
function ColoredRegion:draw()
    gpu.setBackground(self.color, self.ispalette)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
end

--- Set the background color and palette mode
---@param color number
---@param ispalette boolean|nil
function ColoredRegion:setColor(color, ispalette)
    self.color = color
    if ispalette ~= nil then
        self.ispalette = ispalette
    end
    return self -- for chaining
end

return ColoredRegion
