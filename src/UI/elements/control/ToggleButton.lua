local OOP = require("UI.OOP")
local Button = require("UI.elements.control.Button")



local ToggleButton = OOP.class("ToggleButton", Button)


function ToggleButton:initialize(x, y, width, height, offColor, onColor, offDisplayText, onDisplayText, offDisplayColor, onDisplayColor, offCallback, onCallback, defaultState)
    if defaultState then
        ToggleButton.super.initialize(self,x, y, width, height, onColor, onDisplayText, onDisplayColor, onCallback)
    else
        ToggleButton.super.initialize(self,x, y, width, height, offColor, offDisplayText, offDisplayColor, offCallback)
    end
    self.offColor = offColor
    self.onColor = onColor
    self.offDisplayText = offDisplayText
    self.onDisplayText = onDisplayText
    self.offDisplayColor = offDisplayColor
    self.onDisplayColor = onDisplayColor
    self.onCallback = onCallback
    self.offCallback = offCallback
    self.state = defaultState or false
end


function ToggleButton:onClick()
    self.super:onClick()
    if (self.state) then
        self:setOnClick(self.offCallback)
        self:setText(self.offDisplayText)
        self:setTextColor(self.offDisplayColor)
        self:setColor(self.offColor)
        self:setNeedsRedraw(true)
    else
        self:setOnClick(self.onCallback)
        self:setText(self.onDisplayText)
        self:setTextColor(self.onDisplayColor)
        self:setColor(self.onColor)
        self:setNeedsRedraw(true)
    end
    self.state = not self.state
end

return ToggleButton