local OOP = require("UI.OOP")
local Region = require("UI.elements.Region")
local ColoredRegion = require("UI.elements.ColoredRegion")
local Button = require("UI.elements.control.Button")
local Draggable = require("UI.elements.control.Draggable")
local ColorUtils = require("UI.lib.ColorUtils")
local Logger = require("UI.lib.Logger")

local ScrollBar = OOP.class("ScrollBar", Region)

--- Constructor for ScrollBar.
--- @param x (number) X-coordinate.
--- @param y (number) Y-coordinate.
--- @param width (number) Width of the scrollbar.
--- @param height (number) Height of the scrollbar.
--- @param orientation (string, optional) "vertical" (default) or "horizontal".
--- @param colors (table, optional) Table with color definitions:
---   { background, track, thumb, button, buttonText }, e.g., ColorUtils:new(0xRRGGBB).
--- @param minValue (number, optional) Minimum scroll value (default 0).
--- @param maxValue (number, optional) Maximum scroll value (default 100).
--- @param initialValue (number, optional) Initial scroll value (default minValue).
--- @param stepValue (number, optional) Value to change by when buttons are clicked.
---   Defaults to 5% of range or 1.
--- @param onValueChangedCallback (function, optional) Callback function(self, newValue)
---   triggered when the scroll value changes.
function ScrollBar:initialize(x, y, width, height, orientation, colors, minValue, maxValue, initialValue, stepValue, onValueChangedCallback)
    ScrollBar.super.initialize(self, x, y, width, height)

    self.orientation = orientation or "vertical"
    self.colors = colors or {
        background = ColorUtils:new(0x2C2C2C, false), -- ScrollBar background (slightly darker than default track)
        track = ColorUtils:new(0x404040, false),      -- Track background
        thumb = ColorUtils:new(0x808080, false),      -- Thumb color
        button = ColorUtils:new(0x606060, false),     -- Button color
        buttonText = ColorUtils:new(0xFFFFFF, false)  -- Button text color
    }

    self.minValue = minValue or 0
    self.maxValue = maxValue or 100
    self.currentValue = initialValue or self.minValue
    self.userStepValue = stepValue -- Store user-provided step, nil if not given
    self.onValueChanged = onValueChangedCallback

    -- Dimensions for internal components
    if self.orientation == "vertical" then
        self.buttonHeight = math.max(1, self.width) -- Square-ish buttons
        self.buttonWidth = self.width
    else -- horizontal
        self.buttonWidth = math.max(1, self.height) -- Square-ish buttons
        self.buttonHeight = self.height
    end
    self.buttonWidth = math.max(1, self.buttonWidth)
    self.buttonHeight = math.max(1, self.buttonHeight)


    self:_initComponents()
    self:setThumbProportion(0.2) -- Default thumb proportion (20% of track)
    self:setValue(self.currentValue) -- Ensure initial position and callback
end

function ScrollBar:_initComponents()
    local buttonTextColor = self.colors.buttonText
    local buttonBgColor = self.colors.button

    local upChar = (self.orientation == "vertical") and "^" or "<"
    self.upButton = Button:new(
            1, 1, -- Relative to ScrollBar's top-left
            self.buttonWidth, self.buttonHeight,
            buttonBgColor, upChar, buttonTextColor,
            function() self:_onUpButtonClick() end
    )
    self.upButton.parent = self

    local downChar = (self.orientation == "vertical") and "v" or ">"
    local downButtonX, downButtonY
    if self.orientation == "vertical" then
        downButtonX = 1
        downButtonY = self.height - self.buttonHeight + 1
    else -- horizontal
        downButtonX = self.width - self.buttonWidth + 1
        downButtonY = 1
    end
    self.downButton = Button:new(
            downButtonX, downButtonY,
            self.buttonWidth, self.buttonHeight,
            buttonBgColor, downChar, buttonTextColor,
            function() self:_onDownButtonClick() end
    )
    self.downButton.parent = self

    local trackX, trackY, trackWidth, trackHeight
    if self.orientation == "vertical" then
        trackX = 1
        trackY = 1 + self.buttonHeight
        trackWidth = self.width
        trackHeight = self.height - (2 * self.buttonHeight)
    else -- horizontal
        trackX = 1 + self.buttonWidth
        trackY = 1
        trackWidth = self.width - (2 * self.buttonWidth)
        trackHeight = self.height
    end
    trackWidth = math.max(0, trackWidth) -- Track can be 0 if buttons take all space
    trackHeight = math.max(0, trackHeight)

    -- This ColoredRegion defines the visual appearance of the track for the Draggable
    local trackVisualRegion = ColoredRegion:new(
            trackX, trackY, trackWidth, trackHeight,
            self.colors.track
    )
    trackVisualRegion.parent = self -- For correct coordinate context if needed

    -- Thumb knob visual
    local thumbInitialWidth = (self.orientation == "vertical") and math.max(1,trackWidth) or math.max(1, math.floor(trackWidth * 0.2))
    local thumbInitialHeight = (self.orientation == "vertical") and math.max(1, math.floor(trackHeight * 0.2)) or math.max(1,trackHeight)

    local thumbKnobVisual = ColoredRegion:new(
            1, 1, -- Relative to Draggable's bounds (which is the trackVisualRegion)
            thumbInitialWidth, thumbInitialHeight,
            self.colors.thumb
    )
    -- thumbKnobVisual.parent is implicitly set by Draggable to be the Draggable instance.

    -- The Draggable component uses trackVisualRegion for its bounds and appearance.
    -- The Draggable itself will be positioned at trackX, trackY within the ScrollBar.
    self.thumbDraggable = Draggable:new(trackVisualRegion, thumbKnobVisual)
    self.thumbDraggable.parent = self -- Draggable is a child of ScrollBar
    -- Draggable:initialize copies x,y,w,h,color from trackVisualRegion.
    -- So self.thumbDraggable.x = trackX, self.thumbDraggable.y = trackY relative to ScrollBar.

    local originalDraggableOnClick = self.thumbDraggable.onClick
    self.thumbDraggable.onClick = function(instance, clickXRelToParent, clickYRelToParent)
        -- clickX/YRelToParent are relative to ScrollBar (parent of thumbDraggable)
        -- Need to convert to be relative to thumbDraggable (the track area) for isClickInKnob check.
        local clickXRelToDraggable = clickXRelToParent - instance.x + 1
        local clickYRelToDraggable = clickYRelToParent - instance.y + 1

        local knob = instance.knob
        local isClickInKnob = clickXRelToDraggable >= knob.x and clickXRelToDraggable < (knob.x + knob.width)
                and clickYRelToDraggable >= knob.y and clickYRelToDraggable < (knob.y + knob.height)

        if isClickInKnob then
            -- Call Draggable's original onClick, passing coords relative to its parent (ScrollBar)
            originalDraggableOnClick(instance, clickXRelToParent, clickYRelToParent)
        else
            -- Click was on the track, not the knob. Implement page up/down.
            -- Pass coordinates relative to the Draggable (track area)
            self:_onTrackClick(clickXRelToDraggable, clickYRelToDraggable)
        end
    end

    self.thumbDraggable.onDragMove = function(_, knobX, knobY) self:_onThumbDrag(knobX, knobY) end
    self.thumbDraggable.onDragDrop = function(_, knobX, knobY) self:_onThumbDrag(knobX, knobY) end
end

function ScrollBar:_calculateStep()
    if self.userStepValue ~= nil then
        return self.userStepValue
    end
    local range = self.maxValue - self.minValue
    if range > 0 then
        return math.max(1, range * 0.05) -- Default to 5% of range or 1
    end
    return 1 -- Default to 1 if no range
end

function ScrollBar:_onUpButtonClick()
    self:setValue(self.currentValue - self:_calculateStep())
end

function ScrollBar:_onDownButtonClick()
    self:setValue(self.currentValue + self:_calculateStep())
end

function ScrollBar:_onTrackClick(clickXRelToTrack, clickYRelToTrack) -- clickX/Y relative to the track area
    local thumbKnob = self.thumbDraggable.knob
    local track = self.thumbDraggable -- The Draggable instance IS the track
    local range = self.maxValue - self.minValue
    if range <= 0 then return end

    local pageSizeInValueUnits
    if self.orientation == "vertical" then
        if track.height <= 0 then return end -- No track height to page through
        local thumbProportionOfTrack = thumbKnob.height / track.height
        pageSizeInValueUnits = thumbProportionOfTrack * range
    else -- horizontal
        if track.width <= 0 then return end
        local thumbProportionOfTrack = thumbKnob.width / track.width
        pageSizeInValueUnits = thumbProportionOfTrack * range
    end
    pageSizeInValueUnits = math.max(1, pageSizeInValueUnits)

    local newValue
    if self.orientation == "vertical" then
        if clickYRelToTrack < thumbKnob.y then
            newValue = self.currentValue - pageSizeInValueUnits
        else
            newValue = self.currentValue + pageSizeInValueUnits
        end
    else -- horizontal
        if clickXRelToTrack < thumbKnob.x then
            newValue = self.currentValue - pageSizeInValueUnits
        else
            newValue = self.currentValue + pageSizeInValueUnits
        end
    end
    self:setValue(newValue)
end

function ScrollBar:_onThumbDrag(knobX, knobY) -- knobX, knobY are relative to the track (Draggable's bounds)
    local range = self.maxValue - self.minValue
    if range <= 0 then return end -- Avoid division by zero and no-op

    local thumbKnob = self.thumbDraggable.knob
    local track = self.thumbDraggable

    local newValue
    if self.orientation == "vertical" then
        local trackPixelRange = track.height - thumbKnob.height
        if trackPixelRange <= 0 then -- Thumb fills track or track too small
            newValue = self.minValue -- Or could be (minValue+maxValue)/2, but minValue is safer
        else
            local ratio = (knobY - 1) / trackPixelRange
            newValue = self.minValue + ratio * range
        end
    else -- horizontal
        local trackPixelRange = track.width - thumbKnob.width
        if trackPixelRange <= 0 then
            newValue = self.minValue
        else
            local ratio = (knobX - 1) / trackPixelRange
            newValue = self.minValue + ratio * range
        end
    end
    self:setValue(newValue, true) -- Pass true to indicate value set by dragging
end

function ScrollBar:setValue(newValue, fromInteraction)
    local oldVal = self.currentValue
    self.currentValue = math.max(self.minValue, math.min(self.maxValue, newValue))

    local valueChanged = (oldVal ~= self.currentValue)

    if valueChanged or fromInteraction then
        if not fromInteraction then -- If value set programmatically or by buttons/track click
            self:_updateThumbPositionFromValue()
        end
        if valueChanged and self.onValueChanged then
            self.onValueChanged(self, self.currentValue)
        end
        self:setNeedsRedraw(true)
    end
end

function ScrollBar:getValue()
    return self.currentValue
end

function ScrollBar:setThumbProportion(proportion)
    proportion = math.max(0.05, math.min(1.0, proportion)) -- Min 5% size, max 100%

    local thumbKnob = self.thumbDraggable.knob
    local track = self.thumbDraggable -- Draggable acts as the track

    if self.orientation == "vertical" then
        if track.height <= 0 then return end -- No track to size thumb in
        local newHeight = math.max(1, math.floor(track.height * proportion))
        if thumbKnob.height ~= newHeight then
            thumbKnob.height = newHeight
            self:_updateThumbPositionFromValue() -- Recalculate position due to size change
            self.thumbDraggable:setNeedsRedraw(true) -- Thumb (knob) needs redraw
        end
    else -- horizontal
        if track.width <= 0 then return end
        local newWidth = math.max(1, math.floor(track.width * proportion))
        if thumbKnob.width ~= newWidth then
            thumbKnob.width = newWidth
            self:_updateThumbPositionFromValue()
            self.thumbDraggable:setNeedsRedraw(true)
        end
    end
end

function ScrollBar:_updateThumbPositionFromValue()
    local range = self.maxValue - self.minValue
    local thumbKnob = self.thumbDraggable.knob
    local track = self.thumbDraggable

    if track.width <= 0 and self.orientation == "horizontal" then return end
    if track.height <= 0 and self.orientation == "vertical" then return end


    if range <= 0 then -- No range, thumb takes full space or stays minimal
        if self.orientation == "vertical" then
            thumbKnob.y = 1
            thumbKnob.height = math.max(1, track.height)
        else
            thumbKnob.x = 1
            thumbKnob.width = math.max(1, track.width)
        end
        self.thumbDraggable:setNeedsRedraw(true)
        return
    end

    local ratio = (self.currentValue - self.minValue) / range
    ratio = math.max(0, math.min(1, ratio)) -- Clamp ratio

    if self.orientation == "vertical" then
        local trackPixelRange = track.height - thumbKnob.height
        -- If thumbKnob.height > track.height, trackPixelRange is negative.
        -- This can happen if buttons take up too much space.
        -- In this case, clamp knob Y to 1.
        if trackPixelRange < 0 then trackPixelRange = 0 end

        local newY = 1 + math.floor(ratio * trackPixelRange)
        -- Clamp newY to be within track, considering thumb height
        newY = math.max(1, math.min(newY, 1 + track.height - thumbKnob.height))
        if thumbKnob.y ~= newY then
            thumbKnob.y = newY
            self.thumbDraggable:setNeedsRedraw(true)
        end
    else -- horizontal
        local trackPixelRange = track.width - thumbKnob.width
        if trackPixelRange < 0 then trackPixelRange = 0 end

        local newX = 1 + math.floor(ratio * trackPixelRange)
        newX = math.max(1, math.min(newX, 1 + track.width - thumbKnob.width))
        if thumbKnob.x ~= newX then
            thumbKnob.x = newX
            self.thumbDraggable:setNeedsRedraw(true)
        end
    end
end

function ScrollBar:draw(gpu)

    local scrollBarBuffer = gpu.allocateBuffer(self.width, self.height)
    if not scrollBarBuffer then
        Logger.error("ScrollBar: Failed to allocate buffer for ScrollBar.")
        self:setNeedsRedraw(true)
        return
    end
    local originalActiveBuffer = gpu.getActiveBuffer()
    gpu.setActiveBuffer(scrollBarBuffer)

    local mainBgColorVal, mainBgIsPalette = self.colors.background:get()
    gpu.setBackground(mainBgColorVal, mainBgIsPalette)
    gpu.fill(1, 1, self.width, self.height, " ")

    if self.upButton then self.upButton:draw(gpu) end
    if self.downButton then self.downButton:draw(gpu) end
    if self.thumbDraggable then self.thumbDraggable:draw(gpu) end -- Draggable draws its track and knob

    gpu.setActiveBuffer(originalActiveBuffer)
    gpu.bitblt(originalActiveBuffer, self.x, self.y, self.width, self.height, scrollBarBuffer, 1, 1)
    gpu.freeBuffer(scrollBarBuffer)

    self:setNeedsRedraw(false)
end

function ScrollBar:onClick(clickX, clickY) -- clickX, clickY relative to PARENT of ScrollBar
    if not self:isCoordinateInRegion(clickX, clickY) then return end

    local localX = clickX - self.x + 1 -- Convert to coords relative to ScrollBar's 1,1
    local localY = clickY - self.y + 1

    if self.upButton and self.upButton:isCoordinateInRegion(localX, localY) then
        self.upButton:onClick(localX, localY) -- Button onClick expects coords relative to its parent (ScrollBar)
        return
    end
    if self.downButton and self.downButton:isCoordinateInRegion(localX, localY) then
        self.downButton:onClick(localX, localY)
        return
    end
    if self.thumbDraggable and self.thumbDraggable:isCoordinateInRegion(localX, localY) then
        -- thumbDraggable (Draggable) onClick expects coords relative to its parent (ScrollBar)
        self.thumbDraggable:onClick(localX, localY)
        return
    end
end

function ScrollBar:unregisterListeners()
    ScrollBar.super.unregisterListeners(self)
    if self.upButton and self.upButton.unregisterListeners then self.upButton:unregisterListeners() end
    if self.downButton and self.downButton.unregisterListeners then self.downButton:unregisterListeners() end
    if self.thumbDraggable and self.thumbDraggable.unregisterListeners then self.thumbDraggable:unregisterListeners() end
    self.upButton = nil
    self.downButton = nil
    self.thumbDraggable = nil
end

return ScrollBar