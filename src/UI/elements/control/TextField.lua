-- UI/elements/control/TextField.lua
local OOP = require("UI.OOP")
local Label = require("UI.elements.Label")
local event = require("event")

local TextField = OOP.class("TextField", Label)

function TextField:initialize(x, y, width, height, bgColor, initialText, textColor, maxLength)
    TextField.super.initialize(self, x, y, width, height, bgColor, initialText or "", textColor)

    self.isFocused = false
    self.cursorPos = (initialText and string.len(initialText) or 0) + 1
    self.originalText = self.displayText
    self.maxLength = maxLength

    self.cursorBlinkRate = 0.5
    self.cursorTimerId = nil
    self.showCursorChar = false
    -- self.eventListeners is initialized by Region:initialize
end

-- ... (getText, getLiveText, setText remain largely the same) ...
function TextField:getText()
    if self.isFocused then
        return self.originalText
    else
        return self.displayText
    end
end

function TextField:getLiveText()
    return self.displayText
end

function TextField:setText(newText, internalSet)
    local oldText = self.displayText
    if self.maxLength and string.len(newText) > self.maxLength then
        newText = string.sub(newText, 1, self.maxLength)
    end

    if oldText ~= newText or internalSet then
        Label.setText(self, newText)
        self.cursorPos = math.min(self.cursorPos, string.len(self.displayText) + 1)
        if not internalSet and self.onTextChanged then
            self.onTextChanged(self, oldText, self.displayText)
        end
        if self.isFocused then
            self.originalText = self.displayText
        end
    end
end


function TextField:_startBlinking()
    if self.cursorTimerId then return end
    self.showCursorChar = true
    self:setNeedsRedraw(true)
    self.cursorTimerId = event.timer(self.cursorBlinkRate, function()
        if not self.isFocused then
            self:_stopBlinking()
            return
        end
        self.showCursorChar = not self.showCursorChar
        self:setNeedsRedraw(true)
    end, math.huge)
end

function TextField:_stopBlinking()
    if self.cursorTimerId then
        event.cancel(self.cursorTimerId)
        self.cursorTimerId = nil
    end
    if self.showCursorChar then
        self.showCursorChar = false
        self:setNeedsRedraw(true)
    end
end

function TextField:_handleFocusLoss(calledByUnregister)
    if not self.isFocused then return end
    self.isFocused = false
    self:_stopBlinking()
    -- Decide whether to commit or revert text. For now, assume text is live.
    -- self.displayText = self.originalText -- To revert on focus loss

    -- Unregister listeners only if not being called from unregisterListeners itself to avoid loop
    if not calledByUnregister then
        self:_unregisterSpecificInputListeners()
    end
    self:setNeedsRedraw(true)
end

function TextField:onClick()
    self:setFocus(true)
end

function TextField:setFocus(isFocused)
    if self.isFocused == isFocused then return end

    if isFocused then
        self.isFocused = true
        self.originalText = self.displayText
        self.cursorPos = string.len(self.displayText) + 1
        self:_startBlinking()
        queueOnMainThread(function() self:_registerSpecificInputListeners()  end)
    else
        queueOnMainThread(function() self:_handleFocusLoss(false) end) -- Pass false as it's a direct call to lose focus
    end
    self:setNeedsRedraw(true)
end

-- Specific handler for external touch events
function TextField:_onExternalTouchHandler(_, _, x, y, _, _)

    -- Check if the touch is outside this TextField's bounds
    if self.isFocused and not self:isCoordinateInRegion(x, y) then
        self:setFocus(false)
    end
end

-- Specific handler for key down events
function TextField:_onKeyDownHandler(eventName, address, charCode, keyCode, playerName)
    if not self.isFocused then return end -- Should not happen if listeners are managed correctly

    local char = charCode and string.char(charCode) or nil

    local textChanged = false
    local oldDisplayText = self.displayText

    -- Enter, Backspace, Delete, Arrows, Printable chars
    if keyCode == 0x1C then -- Enter
        if self.onSubmit then self.onSubmit(self) end
        self:setFocus(false)
        return
    elseif keyCode == 0x0E then -- Backspace
        if self.cursorPos > 1 then
            self.displayText = string.sub(self.displayText, 1, self.cursorPos - 2) .. string.sub(self.displayText, self.cursorPos)
            self.cursorPos = self.cursorPos - 1
            textChanged = true
        end
    elseif keyCode == 0xD3 then -- Delete
        if self.cursorPos <= string.len(self.displayText) then
            self.displayText = string.sub(self.displayText, 1, self.cursorPos - 1) .. string.sub(self.displayText, self.cursorPos + 1)
            textChanged = true
        end
    elseif keyCode == 0xCB then self.cursorPos = math.max(1, self.cursorPos - 1) -- Left
    elseif keyCode == 0xCD then self.cursorPos = math.min(string.len(self.displayText) + 1, self.cursorPos + 1) -- Right
    elseif keyCode == 0xC7 then self.cursorPos = 1 -- Home
    elseif keyCode == 0xCF then self.cursorPos = string.len(self.displayText) + 1 -- End
    elseif charCode > 0 then
        if not self.maxLength or string.len(self.displayText) < self.maxLength then
            self.displayText = string.sub(self.displayText, 1, self.cursorPos - 1) .. char .. string.sub(self.displayText, self.cursorPos)
            self.cursorPos = self.cursorPos + string.len(char)
            textChanged = true
        end
    end

    if textChanged then
        self.originalText = self.displayText
        if self.onTextChanged then self.onTextChanged(self, oldDisplayText, self.displayText) end
    end

    self.showCursorChar = true
    if self.cursorTimerId then event.cancel(self.cursorTimerId); self.cursorTimerId = nil end
    self:_startBlinking()
    self:setNeedsRedraw(true)
end

function TextField:_registerSpecificInputListeners()
    -- Ensure we don't double-register
    if not self.eventListeners["key_down"] then
        -- Create the closure ONCE and store it
        local specificKeyDownHandler = function(...) self:_onKeyDownHandler(...) end
        event.listen("key_down", specificKeyDownHandler)
        self.eventListeners["key_down"] = specificKeyDownHandler -- Store by event name
    end

    if not self.eventListeners["touch"] then
        -- Create the closure ONCE and store it
        local specificTouchHandler = function(...) self:_onExternalTouchHandler(...) end
        event.listen("touch", specificTouchHandler)
        self.eventListeners["touch"] = specificTouchHandler
    end

end

function TextField:_unregisterSpecificInputListeners()
    if self.eventListeners["key_down"] then
        local success = event.ignore("key_down", self.eventListeners["key_down"])
        if success then self.eventListeners["key_down"] = nil end
    end

    if self.eventListeners["touch"] then
        local success = event.ignore("touch", self.eventListeners["touch"])
        if success then self.eventListeners["touch"] = nil end
    end
end

-- Override Region's unregisterListeners
function TextField:unregisterListeners()
    self:_handleFocusLoss(true) -- Pass true to indicate it's part of a general unregister call
    -- This will call _unregisterSpecificInputListeners

    -- Now, let Region's unregisterListeners handle anything that might be left
    -- or anything it registered itself (though Region doesn't register any by default).
    -- At this point, self.eventListeners["key_down"] and self.eventListeners["touch"]
    -- should have been removed by _unregisterSpecificInputListeners if they were successfully ignored.
    TextField.super.unregisterListeners(self)
end

-- ... (draw method remains largely the same, ensure it uses self.displayText) ...
function TextField:draw(gpu)
    local pF = gpu.getForeground()
    local pB = gpu.getBackground()

    gpu.setBackground(self.color:get())
    gpu.fill(self.x, self.y, self.width, self.height, " ")

    gpu.setForeground(self.textColor:get())
    local currentDisplay = self.displayText or ""
    local textToRender = currentDisplay

    if self.isFocused and self.showCursorChar then
        local beforeCursor = string.sub(currentDisplay, 1, self.cursorPos - 1)
        local afterCursor = string.sub(currentDisplay, self.cursorPos)
        textToRender = beforeCursor .. "_" .. afterCursor
    end

    local visibleText = textToRender
    if string.len(textToRender) > self.width then
        if self.isFocused and self.cursorPos > self.width -1 and string.len(textToRender) > self.width then
            local sliceStart = math.max(1, self.cursorPos - self.width + 1 ) -- +1 to keep cursor visible at end
            if self.cursorPos == string.len(textToRender) +1 and textToRender:sub(-1) == "_" then -- cursor at the very end
                sliceStart = math.max(1, string.len(textToRender) - self.width )
            end
            visibleText = string.sub(textToRender, sliceStart, sliceStart + self.width -1)
        else
            visibleText = string.sub(textToRender, 1, self.width)
        end
    end

    local textX = self.x
    local textY = math.floor(self.y + (self.height - 1) / 2)
    gpu.set(textX, textY, visibleText)

    gpu.setForeground(pF)
    gpu.setBackground(pB)
    self:setNeedsRedraw(false)
end

return TextField