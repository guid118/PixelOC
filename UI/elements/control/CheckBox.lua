local Clickable = require("UI.elements.control.Clickable")

---@class CheckBox: Clickable
local CheckBox = setmetatable({}, { __index = Clickable })
CheckBox.__index = CheckBox

--- Constructor for the CheckBox class
--- @return CheckBox a new CheckBox
function CheckBox.new(x, y, width, height, color, isPalette, isEnabled)
    local obj
    if (isEnabled) then
        obj = Clickable.new(x, y, width, height, color, isPalette, "✔")
    else
        obj = Clickable.new(x, y, width, height, color, isPalette, "✖")
    end
    setmetatable(obj, CheckBox)
    obj.isEnabled = isEnabled
    return obj
end

--- Handles clicking the TextField
function CheckBox:onClick()
    if (self.isEnabled) then
        self.isEnabled = false
        self.label = "✖"
        self:draw()
        return
    else
        self.isEnabled = true
        self.label = "✔"
        self:draw()
    end
end

return CheckBox