local Clickable = require("UI.elements.control.Clickable")
---@class Button : Clickable
---@field onClickAction function
---@field onClickColor number
local Button = setmetatable({}, { __index = Clickable })
Button.__index = Button

function Button:new(x, y, width, height, color, isPallette, label, onClickColor, onClickAction)
    local obj = Clickable.new(self, x, y, width, height, color, isPallette, label)
    setmetatable(obj, Button)  -- Set metatable to Labeled for the instance
    obj.onClickColor = onClickColor
    obj.onClickAction = onClickAction
    return obj
end

function Button:onClick()
    local originalColor = self.color
    self.setColor(self, self.onClickColor, self.isPallette)
    self.draw(self)

    os.sleep(0.1)
    self.setColor(self, originalColor, self.isPallette)
    self.draw(self)

    if self.onClickAction then
        self.onClickAction()
    end
end


function Button:setOnClick(onClickAction)
    self.onClickAction = onClickAction
end

return Button