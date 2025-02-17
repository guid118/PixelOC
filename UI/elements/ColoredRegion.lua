local gpu = require("component").gpu
local Region = require("UI.elements.Region")

---@class ColoredRegion:Region
local ColoredRegion = setmetatable({}, { __index = Region })
ColoredRegion.__index = ColoredRegion

--- Constructor for the ColoredRegion class
--- @return ColoredRegion a new ColoredRegion
function ColoredRegion.new(x, y, width, height, color, isPalette)
    local obj = Region.new(x, y, width, height)
    setmetatable(obj, ColoredRegion)
    obj.color = color or 0xFFFFFF
    obj.isPalette = isPalette or false
    return obj
end

--- Draw the ColoredRegion
function ColoredRegion:draw()
    gpu.setBackground(self.color, self.isPalette)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
end

--- Set the background color and palette mode
---@param color number
---@param isPalette boolean|nil
function ColoredRegion:setColor(color, isPalette)
    self.color = color
    if isPalette ~= nil then
        self.isPalette = isPalette
    end
    return self -- for chaining
end

return ColoredRegion
