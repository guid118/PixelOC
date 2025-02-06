local gpu = require("component").gpu
local Region = require("UI.elements.Region")

---@class Labeled: Region
---@field label string
local Labeled = setmetatable({}, { __index = Region })  -- Correct inheritance setup
Labeled.__index = Labeled

function Labeled:new(x, y, width, height, color, isPallette, label)
    local obj = Region.new(self, x, y, width, height, color, isPallette)
    setmetatable(obj, Labeled)  -- Set metatable to Labeled for the instance
    obj.label = label or ""
    return obj
end

function Labeled:draw()
    Region.draw(self)  -- Call parent draw method
    gpu.set(
            math.floor((self.x + self.width / 2) - (#self.label / 2)),
            math.floor(self.y + self.height / 2),
            self.label
    )
    gpu.setBackground(0x000000, false)  -- Reset background
end

return Labeled
