local event = require("event")
local Clickable = require("UI.elements.control.Clickable")
local gpu = require("component").gpu
local Region = require("UI.elements.Region")

---@class TextField : Clickable
local TextField = setmetatable({}, { __index = Clickable })
TextField.__index = TextField

--- Constructor for the TextField class
--- @return TextField a new TextField
function TextField.new(x, y, width, height, color, ispalette, defaultText)
    local obj = Clickable.new(x, y, width, height, color, ispalette, defaultText)
    setmetatable(obj, TextField)
    obj.focused = false
    obj.eventListeners = {}
    obj.cursorTimer = nil
    obj.cursorLocationX = defaultText:len()
    return obj
end

--- Getter for the entered text
--- @return string the text in the field. returns the previous value if the text is currently being edited.
function TextField:getValue()
    if self.focused then
        return self.originalText
    else
        return self.label
    end
end

--- Handles touch event (check if clicked outside)
--- Unfocuses and unregisters listeners if the click was somewhere outside of this TextField's bounds
function TextField:handleTouch(x, y)
    if x < self.x or x >= self.x + self.width or y ~= self.y then
        self:setLabel(self.originalText)
        self:unregisterListeners()
    end
end

--- Handles keyboard input
--- getValue function will return the original text for as long as the user is typing
function TextField:handleKeyDown(char, code)
    if not self.focused then
        self:unregisterListeners()
        return
    end
    if code == 28 then
        -- Enter key (submit)

        self:setLabel(self.label)
        self:unregisterListeners()
    elseif code == 14 then
        -- Backspace key
        if self.cursorLocationX > 0 then
            self.label = self.label:sub(1, self.cursorLocationX - 1) .. self.label:sub(self.cursorLocationX + 1)
            self.cursorLocationX = self.cursorLocationX - 1
        end
    elseif code == 211 then
        -- Delete key
        self.label = self.label:sub(1, self.cursorLocationX) .. self.label:sub(self.cursorLocationX + 2)
        if self.cursorLocationX < self.label:len() and self.cursorLocationX > 0 then
            self.cursorLocationX = self.cursorLocationX - 1
        end
    elseif code == 203 then
        --left
        if (self.cursorLocationX > 0) then
            self.cursorLocationX = self.cursorLocationX - 1
        end
        self.cursorVisible = true
        self:blinkCursor()
    elseif code == 205 then
        -- right
        if (self.cursorLocationX < self.label:len()) then
            self.cursorLocationX = self.cursorLocationX + 1
        end
        self.cursorVisible = true
        self:blinkCursor()
    elseif char > 0 then
        -- Ensure valid printable characters
        if self.label:len() < self.width then
            self.label = self.label:sub(1, self.cursorLocationX) .. string.char(char) .. self.label:sub(self.cursorLocationX + 1)
            if self.cursorLocationX < self.width-1 then
                self.cursorLocationX = self.cursorLocationX + 1
            end
        end
    end
    self:draw()
end

--- Start the typing cursor blinking behind the last letter of the label
function TextField:startCursorBlinking()
    if self.cursorTimer then
        return
    end -- Prevent multiple timers
    self.cursorVisible = false

    self.cursorTimer = event.timer(0.5,
            function()
                self:blinkCursor()
            end
    , math.huge) -- Runs indefinitely until canceled
end

function TextField:blinkCursor()
    if self.focused then
        local cursorPosX = self.x + (self.width / 2) - (string.len(self.label) / 2) + self.cursorLocationX
        local cursorPosY = self.y + (self.height / 2)
        if self.cursorVisible == true and cursorPosX < self.x + self.width then
            gpu.setForeground(0xFFFFFF, false)
            gpu.setBackground(self.color, self.ispalette)
            gpu.set(cursorPosX, cursorPosY, self:getCursorChar()) -- Draw cursor
            self.cursorVisible = false
        else
            gpu.setBackground(0xFFFFFF, false)
            gpu.setForeground(self.color, self.ispalette)
            gpu.set(cursorPosX, cursorPosY, self:getCursorChar()) -- Erase cursor
            self.cursorVisible = true
        end
    end
end

function TextField:getCursorChar()
    local character = self.label:sub(self.cursorLocationX + 1, self.cursorLocationX + 1)
    if (character == "") then
        character = " "
    end
    return character
end

--- Unregisters listeners and remove focus
function TextField:unregisterListeners()
    if not self.focused then
        return
    end
    self.focused = false
    if self.cursorTimer then
        event.cancel(self.cursorTimer)
        self.cursorTimer = nil
    end
    Region.unregisterListeners(self)
end

function TextField:setLabel(label)
    self.label = label
end

--- Handles clicking the TextField
function TextField:onClick()
    -- if we're already focussed, do nothing
    -- TODO add cursor navigation
    if (self.focused) then
        return
    end

    self.focused = true
    self.originalText = self.label
    self.cursorLocationX = self.label:len()
    self:startCursorBlinking()

    -- Register touch event listener
    local touchListenerFunction = function(_, _, x, y)
        self:handleTouch(x, y)
    end
    event.listen("touch", touchListenerFunction)
    self.eventListeners["touch"] = touchListenerFunction

    -- Register key_down event listener
    local keyDownListenerFunction = function(_, _, char, code)
        self:handleKeyDown(char, code)
    end
    event.listen("key_down", keyDownListenerFunction)
    self.eventListeners["key_down"] = keyDownListenerFunction
end

return TextField

