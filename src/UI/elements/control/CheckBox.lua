local OOP = require("UI.OOP")
local ToggleButton = require("UI.elements.control.ToggleButton")
local ColorUtils = require("UI.lib.ColorUtils")

local CheckBox = OOP.class("CheckBox", ToggleButton)

function CheckBox:initialize(x, y, width, height, color, offCallback, onCallback, defaultState)
    local white = ColorUtils:new(0xFFFFFF, false)
    CheckBox.super.initialize(self,
            x, y, width, height,
            color, color,
            "✖", "✔",
            white, white,
            offCallback, onCallback,
            defaultState or false
    )
end

return CheckBox
