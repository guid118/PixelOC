local gpu = require("component").gpu
local ColoredRegion = require("UI.elements.ColoredRegion")

---@class Label: Region
local Label = setmetatable({}, { __index = ColoredRegion })  -- Correct inheritance setup
Label.__index = Label

--- Constructor for the Label class
--- @return Label a new Label
function Label.new(x, y, width, height, color, isPalette, label)
    local obj = ColoredRegion.new(x, y, width, height, color, isPalette)
    setmetatable(obj, Label)  -- Set metatable to Label for the instance
    obj.label = label or ""
    return obj
end

--- Draw the Label
function Label:draw()
    ColoredRegion.draw(self)
    gpu.setForeground(0xFFFFFF)
    gpu.set(
            math.floor((self.x + self.width / 2) - (#self.label / 2)),
            math.floor(self.y + self.height / 2),
            self.label
    )
    gpu.setBackground(0x000000, false)  -- Reset background
end

function ColoredRegion:drawToBuffer(index)
    gpu.setActiveBuffer(index)
    ColoredRegion.drawToBuffer(self)
    gpu.setForeground(0xFFFFFF)
    gpu.set(
            math.floor((self.x + self.width / 2) - (#self.label / 2)),
            math.floor(self.y + self.height / 2),
            self.label
    )
    gpu.setBackground(0x000000, false)  -- Reset background
    gpu.setActiveBuffer(0)
end

return Label
