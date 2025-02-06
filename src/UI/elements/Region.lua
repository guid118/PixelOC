local gpu = require("component").gpu

--- @class Region
---@field x number
---@field y number
---@field width number
---@field height number
---@field color number
---@field isPallette boolean
local Region = {}
Region.__index = Region

function Region:new(x, y, width, height, color, isPallette)
    local obj = setmetatable({}, self)
    obj.x = x or 0
    obj.y = y or 0
    obj.width = width or 10
    obj.height = height or 5
    obj.color = color or 0xFFFFFF
    obj.isPallette = isPallette or false
    return obj
end

function Region:draw()
    gpu.setBackground(self.color, self.isPallette)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
end

--- Set the background color and palette mode
---@param color number
---@param isPallette boolean|nil
function Region:setColor(color, isPallette)
    self.color = color
    if isPallette ~= nil then
        self.isPallette = isPallette
    end
    return self -- for chaining
end

return Region
