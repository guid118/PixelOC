local Clickable = require("UI.elements.control.Clickable")

---@class ToggleButton: Clickable
local ToggleButton = setmetatable({}, { __index = Clickable })
ToggleButton.__index = ToggleButton

--- Constructor for the ToggleButton class
--- @return ToggleButton a new ToggleButton
function ToggleButton.new(x, y, width, height, ONColor, ONPalette, ONLabel, OFFColor, OFFPalette, OFFLabel, isEnabled)
    local obj
    if (isEnabled) then
        obj = Clickable.new(x, y, width, height, ONColor, ONPalette, ONLabel)
    else
        obj = Clickable.new(x, y, width, height, OFFColor, OFFPalette, OFFLabel)
    end
    setmetatable(obj, ToggleButton)
    obj.isEnabled = isEnabled
    obj.ONButton = Clickable.new(x, y, width, height, ONColor, ONPalette, ONLabel)
    obj.OFFButton = Clickable.new(x, y, width, height, OFFColor, OFFPalette, OFFLabel)
    return obj
end

--- Handles clicking the TextField
function ToggleButton:onClick()
    if (self.isEnabled) then
        self.isEnabled = false
        self.color = self.OFFButton.color
        self.isPalette = self.OFFButton.isPalette
        self.label = self.OFFButton.label
        self:draw()
        return
    else
        self.isEnabled = true
        self.color = self.ONButton.color
        self.isPalette = self.ONButton.isPalette
        self.label = self.ONButton.label
        self:draw()
    end
end
return ToggleButton