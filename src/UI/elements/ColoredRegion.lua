local OOP = require("UI.OOP")
local Region = require("UI.elements.Region")


local ColoredRegion = OOP.class("ColoredRegion", Region)

function ColoredRegion:initialize(x,y,width,height, colorObj)
    ColoredRegion.super.initialize(self, x,y,width,height)
    self.color = colorObj
end

function ColoredRegion:draw(gpu)
    local pB = gpu.getBackground()
    local bgColorVal, isPalette = self.color:get()
    gpu.setBackground(bgColorVal, isPalette)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.setBackground(pB)
    self:setNeedsRedraw(false)
end

function ColoredRegion:setColor(newColorObj)
    self.color = newColorObj
    self:setNeedsRedraw(true)
end

return ColoredRegion