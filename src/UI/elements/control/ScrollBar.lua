local OOP = require("UI.OOP")
local Region = require("UI.elements.Region")
local Button = require("UI.elements.control.Button")
local Draggable = require("UI.elements.control.Draggable")
local ColoredRegion = require("UI.elements.ColoredRegion")
local ColorUtils = require("UI.lib.ColorUtils")

local ScrollBar = OOP.class("ScrollBar", Region)

--[[
    totalContentHeight: The total height of the content being scrolled.
    visibleContentHeight: The height of the viewport showing the content.
    These two are used to determine the scroll range and thumb size.
--]]
function ScrollBar:initialize(x, y, width, height, buttonHeight, thumbMinHeight, totalContentHeight, visibleContentHeight, bgColor, thumbColor, buttonColor)
    ScrollBar.super.initialize(self, x, y, width, height)

    self.buttonHeight = buttonHeight
    self.thumbMinHeight = math.max(1, thumbMinHeight) -- Thumb must be at least 1px high
    self.bgColor = bgColor
    self.thumbColor = thumbColor
    self.buttonColor = buttonColor

    self.value = 0 -- Current scroll offset from the top (in content units, e.g., pixels or lines)
    self._totalContentHeight = totalContentHeight or 100 -- Default if not provided
    self._visibleContentHeight = visibleContentHeight or 10 -- Default if not provided
    self._maxScrollValue = math.max(0, self._totalContentHeight - self._visibleContentHeight)

    self.onValueChanged = nil

    -- Create child components
    self:_createComponents()
    self:_updateThumb() -- Initial thumb position and size
end

function ScrollBar:_createComponents()
    -- Up Button
    self.upButton = Button:new(self.x, self.y, self.width, self.buttonHeight,
            self.buttonColor, "^", ColorUtils:new(0xFFFFFF, false), -- Assuming white text for button
            function()
                self:scrollBy(-self:_getStepAmount())
            end)

    -- Down Button
    local downButtonY = self.y + self.height - self.buttonHeight
    self.downButton = Button:new(self.x, downButtonY, self.width, self.buttonHeight,
            self.buttonColor, "v", ColorUtils:new(0xFFFFFF, false),
            function()
                self:scrollBy(self:_getStepAmount())
            end)

    -- Track Region (where the thumb slides)
    local trackY = self.y + self.buttonHeight
    local trackHeight = self.height - (2 * self.buttonHeight)
    if trackHeight < self.thumbMinHeight then
        -- Not enough space for track + min thumb
        trackHeight = self.thumbMinHeight
        -- This might mean buttons overlap or scrollbar is too small.
    end
    self.trackRegion = ColoredRegion:new(self.x, trackY, self.width, trackHeight, self.bgColor)

    -- Thumb (Draggable part)
    -- Initial thumb height and Y will be set by _updateThumb
    local thumbDisplay = ColoredRegion:new(self.x, trackY, self.width, self.thumbMinHeight, self.thumbColor)
    self.thumbDraggable = Draggable:new(thumbDisplay, self.trackRegion) -- Bounds is the track

    local self_scrollbar = self -- Capture self for callbacks
    self.thumbDraggable.onDragMove = function(draggable, newThumbX, newThumbY)
        local trackPixelRange = self_scrollbar.trackRegion.height - self_scrollbar.thumbDraggable.draggableDisplayRegion.height
        if trackPixelRange <= 0 then
            return
        end -- Cannot move if thumb fills track

        local thumbOffsetInTrack = newThumbY - self_scrollbar.trackRegion.y
        local scrollRatio = thumbOffsetInTrack / trackPixelRange
        local newValue = scrollRatio * self_scrollbar._maxScrollValue
        self_scrollbar:setValue(newValue, true) -- true means fromThumbDrag
    end
    -- onDragDrop is implicitly handled as the last onDragMove

    -- Handle clicks on the track for page up/down
    -- This needs a custom click handler for the ScrollBar itself if trackRegion is not a clickable
    -- For now, we will handle it in ScrollBar:onClick
end

function ScrollBar:setContentDimensions(totalContentHeight, visibleContentHeight)
    self._totalContentHeight = totalContentHeight
    self._visibleContentHeight = visibleContentHeight
    self._maxScrollValue = math.max(0, self._totalContentHeight - self._visibleContentHeight)
    self.value = math.min(self.value, self._maxScrollValue) -- Clamp current value
    self:_updateThumb()
    self:setNeedsRedraw(true)
end

function ScrollBar:_getStepAmount()
    -- Scroll by 10% of visible height or at least 1 unit
    return math.max(1, math.floor(self._visibleContentHeight * 0.1))
end

function ScrollBar:_getPageAmount()
    -- Scroll by roughly the visible height (thumb height in pixels)
    return self._visibleContentHeight
end

function ScrollBar:scrollBy(amount)
    self:setValue(self.value + amount)
end

function ScrollBar:setValue(newValue, fromThumbDrag)
    local clampedValue = math.max(0, math.min(newValue, self._maxScrollValue))
    clampedValue = math.floor(clampedValue + 0.5) -- Round to nearest whole number

    if self.value ~= clampedValue then
        self.value = clampedValue
        if not fromThumbDrag then
            self:_updateThumb()
        end
        if self.onValueChanged then
            self.onValueChanged(self, self.value)
        end
        self:setNeedsRedraw(true)
    end
end

function ScrollBar:_updateThumb()
    if not self.trackRegion or not self.thumbDraggable then
        return
    end -- Not initialized yet

    local trackPixelHeight = self.trackRegion.height
    local thumb = self.thumbDraggable.draggableDisplayRegion

    if self._maxScrollValue <= 0 or self._visibleContentHeight >= self._totalContentHeight then
        -- No scroll needed or content fits
        thumb.height = trackPixelHeight
        thumb.y = self.trackRegion.y
    else
        -- Calculate thumb height based on ratio of visible to total content
        local thumbHeightRatio = self._visibleContentHeight / self._totalContentHeight
        local calculatedThumbHeight = math.max(self.thumbMinHeight, math.floor(trackPixelHeight * thumbHeightRatio))
        calculatedThumbHeight = math.min(calculatedThumbHeight, trackPixelHeight) -- Cannot be taller than track
        thumb.height = calculatedThumbHeight

        -- Calculate thumb Y position
        local scrollablePixelRange = trackPixelHeight - thumb.height
        local valueRatio = self.value / self._maxScrollValue
        thumb.y = self.trackRegion.y + math.floor(scrollablePixelRange * valueRatio + 0.5)
    end

    thumb.x = self.trackRegion.x -- Keep thumb X aligned with track
    thumb.width = self.trackRegion.width -- Keep thumb width same as track

    thumb.needsRedraw = true
    self:setNeedsRedraw(true) -- Scrollbar itself needs redraw
end

function ScrollBar:onClick(clickX, clickY)
    if self.upButton:isCoordinateInRegion(clickX, clickY) then
        self.upButton:onClick()
    elseif self.downButton:isCoordinateInRegion(clickX, clickY) then
        self.downButton:onClick()
    elseif self.thumbDraggable.draggableDisplayRegion:isCoordinateInRegion(clickX, clickY) then
        -- Let Draggable handle its own onClick to initiate dragging
        self.thumbDraggable:onClick(clickX, clickY)
    elseif self.trackRegion:isCoordinateInRegion(clickX, clickY) then
        -- Clicked on track (not thumb)
        local thumbCenterY = self.thumbDraggable.draggableDisplayRegion.y + math.floor(self.thumbDraggable.draggableDisplayRegion.height / 2)
        if clickY < thumbCenterY then
            self:scrollBy(-self:_getPageAmount()) -- Page Up
        else
            self:scrollBy(self:_getPageAmount()) -- Page Down
        end
    end
    -- Superclass onClick if Region had one: ScrollBar.super.onClick(self)
end

-- Override isCoordinateInRegion to be true if click is anywhere on the scrollbar
-- The Region's default uses self.x,y,w,h which is the overall scrollbar, which is correct.
--- @param gpu gpu
function ScrollBar:draw(gpu)

    self.trackRegion:draw(gpu)
    self.thumbDraggable:draw(gpu) -- Draggable draws its thumb
    self.upButton:draw(gpu)
    self.downButton:draw(gpu)

    self:setNeedsRedraw(false)
end

function ScrollBar:unregisterListeners()
    if self.upButton then
        self.upButton:unregisterListeners()
    end
    if self.downButton then
        self.downButton:unregisterListeners()
    end
    if self.thumbDraggable then
        self.thumbDraggable:unregisterListeners()
    end
    -- No specific listeners for ScrollBar itself other than its children's

    ScrollBar.super.unregisterListeners(self) -- Call Region's unregister
end

return ScrollBar