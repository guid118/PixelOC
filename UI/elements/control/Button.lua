local Clickable = require("UI.elements.control.Clickable")
---@class Button : Clickable
---@field onClickAction function
---@field onClickColor number
local Button = setmetatable({}, { __index = Clickable })
Button.__index = Button

function Button.new(x, y, width, height, color, isPallette, label, onClickAction, ...)
    local obj = Clickable.new(x, y, width, height, color, isPallette, label)
    setmetatable(obj, Button)  -- Set metatable to Labeled for the instance
    obj.onClickAction = onClickAction
    obj.clickArguments = {...}
    return obj
end

function Button:onClick()
    if self.onClickAction then
        self.onClickAction(self, self.clickArguments)
    end
end


function Button:setOnClick(onClickAction, ...)
    self.onClickAction = onClickAction
    self.clickArguments = {...}
end

return Button