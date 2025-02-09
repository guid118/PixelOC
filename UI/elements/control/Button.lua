local Clickable = require("UI.elements.control.Clickable")

---@class Button : Clickable
local Button = setmetatable({}, { __index = Clickable })
Button.__index = Button

--- Constructor for the Button class
---@return Button a new Button
function Button.new(x, y, width, height, color, ispalette, label, onClickAction, ...)
    local obj = Clickable.new(x, y, width, height, color, ispalette, label)
    setmetatable(obj, Button)  -- Set metatable to Label for the instance
    obj.onClickAction = onClickAction
    obj.clickArguments = { ... }
    return obj
end

--- onClick function for the button, activates the onClickAction with given arguments
function Button:onClick()
    if self.onClickAction then
        self.onClickAction(self, self.clickArguments)
    end
end

--- setOnClick function for the button, sets the action to be run when the button is clicked
--- @param onClickAction function function to be run
--- @param ... any arguments for the function
function Button:setOnClick(onClickAction, ...)
    self.onClickAction = onClickAction
    self.clickArguments = { ... }
end

return Button