local OOP = require("UI.OOP")
local ColoredRegion = require("UI.elements.ColoredRegion")
local utils = require("UI.lib.utils")
local Logger = require("UI.lib.Logger")

local Label = OOP.class("Label", ColoredRegion)

function Label:initialize(x, y, width, height, color, displayText, textColor)
    Label.super.initialize(self, x, y, width, height, color)
    self.displayText = displayText
    self.textColor = textColor
end

function Label:getText()
    return self.displayText
end

function Label:setText(displayText)
    self.displayText = displayText
    self:setNeedsRedraw(true)
end

function Label:getTextColor()
    return self.textColor
end

function Label:setTextColor(color)
    self.textColor = color
    self:setNeedsRedraw(true)
end

--- @param gpu gpu
function Label:draw(gpu)
    local pF = gpu.getForeground()
    local pB = gpu.getBackground()
    gpu.setForeground(self.textColor:get())
    gpu.setBackground(self.color:get())
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    local textWidth = string.len(self.displayText)
    local textHeight = 1

    -- TODO line wrapping
    if textWidth > self.width then
        textWidth = self.width
        self.displayText = string.sub(self.displayText, 0, self.width)
    end

    local textX = math.max(self.x, utils.round(self.x + (self.width - textWidth) / 2))
    local textY = math.floor(self.y + (self.height - textHeight) / 2)

    gpu.set(textX, textY, self.displayText)

    gpu.setForeground(pF)
    gpu.setBackground(pB)
    self:setNeedsRedraw(false)
end

return Label