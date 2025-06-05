local Label = require("UI.elements.Label")
local OOP = require("UI.OOP")

local Button = OOP.class("Button", Label)

function Button:initialize(x, y, width, height, color, displayText, textColor, onClickCallback)
    Button.super.initialize(self,x, y, width, height, color, displayText, textColor)
    self.onClickCallback = onClickCallback
end

function Button:setOnClick(callback)
    self.onClickCallback = callback
end

function Button:getOnClick()
    return self.onClickCallback
end

function Button:onClick()
    if (self.onClickCallback) then
        self.onClickCallback(self)
    end
end

return Button
