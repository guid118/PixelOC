
---@class Region
---@field x number
---@field y number
---@field width number
---@field height number
local Region = {}



function Region.new(x,y,width,height)
    local obj = setmetatable({}, self)
    obj.x = x or 0
    obj.y = y or 0
    obj.width = width or 10
    obj.height = height or 5
    return obj
end

function Region:isCoordinateInRegion(x,y)
    local xmax = self.x + self.width - 1
    local ymax = self.y + self.height - 1
    if x >= self.x and x <= xmax then
        if y >= self.y and y <= ymax then
            return true
        end
    end
    return false
end

return Region