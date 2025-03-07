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
    obj.onClickAction = nil
    return obj
end

--- Toggle the button as if it was pressed.
function ToggleButton:toggleEnabled()
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

--- Handles clicking the ToggleButton
function ToggleButton:onClick()
    if self.onClickAction ~= nil then
        if pcall(self.onClickAction) then
            return
        end
    end
    self:toggleEnabled()
end



function ToggleButton:setOnClick(operation)
    self.onClickAction = operation
end

return ToggleButton