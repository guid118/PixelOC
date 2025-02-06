local gpu = require("component").gpu
local Region = require("UI.elements.Region")
---@class ColoredRegion:Region
---@field color number
---@field isPallette boolean
local ColoredRegion = setmetatable({}, { __index = Region })
ColoredRegion.__index = ColoredRegion

function ColoredRegion:new(x, y, width, height, color, isPallette)
    local obj = Region.new(x,y,width,height)
    setmetatable(obj, ColoredRegion)
    obj.color = color or 0xFFFFFF
    obj.isPallette = isPallette or false
    return obj
end

function ColoredRegion:draw()
    gpu.setBackground(self.color, self.isPallette)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
end

--- Set the background color and palette mode
---@param color number
---@param isPallette boolean|nil
function ColoredRegion:setColor(color, isPallette)
    self.color = color
    if isPallette ~= nil then
        self.isPallette = isPallette
    end
    return self -- for chaining
end

return ColoredRegion
