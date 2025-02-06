local Clickable = require("UI.elements.control.Clickable")

---@class CheckBox: Clickable
local CheckBox = setmetatable({}, { __index = Clickable })
CheckBox.__index = CheckBox

function CheckBox.new(x, y, width, height, color, isPallette, isEnabled)
    local obj
    if (isEnabled) then
        obj = Clickable.new(x, y, width, height, color, isPallette, "✔")
    else
        obj = Clickable.new(x, y, width, height, color, isPallette, "✖")
    end
    setmetatable(obj, CheckBox)
    obj.isEnabled = true
    return obj
end

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