
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

return Region