--- START OF FILE Draggable.txt ---

local OOP = require("UI.OOP")
local Region = require("UI.elements.Region")
local ColoredRegion = require("UI.elements.ColoredRegion") -- Assuming bounds might be a ColoredRegion
local event = require("event")
local Logger = require("UI.lib.Logger")

local Draggable = OOP.class("Draggable", Region) -- It's a Region that manages other regions

-- Constructor
-- draggableDisplayRegion: The ColoredRegion that will be visually dragged.
-- boundsDisplayRegion: A ColoredRegion that defines the visual bounds and can be clicked.
function Draggable:initialize(draggableDisplayRegion, boundsDisplayRegion)
    -- The Draggable's own x,y,w,h will be based on the bounds region for hit detection.
    Draggable.super.initialize(self, boundsDisplayRegion.x, boundsDisplayRegion.y, boundsDisplayRegion.width, boundsDisplayRegion.height)

    self.draggableDisplayRegion = draggableDisplayRegion
    self.boundsDisplayRegion = boundsDisplayRegion -- This is also what self.x,y,w,h refer to
    self.draggableDisplayRegion.parent = self -- Set parent for draggableDisplayRegion if it needs to propagate setNeedsRedraw
    self.boundsDisplayRegion.parent = self -- Set parent for boundsDisplayRegion

    self.isDragging = false
    self.dragOffsetX = 0 -- Offset from draggableDisplayRegion's top-left to mouse click point
    self.dragOffsetY = 0

    self.onDragMove = nil
    self.onDragDrop = nil
    self.onBoundsClickMove = nil -- Called when bounds are clicked to jump draggable
    -- self.eventListeners is initialized by Region:initialize
end

-- Helper to clamp draggableDisplayRegion's top-left position within boundsDisplayRegion
-- targetX, targetY are relative to draggableDisplayRegion's parent (same as boundsDisplayRegion's parent)
function Draggable:_clampPosition(targetX, targetY)
    local newX = targetX
    local newY = targetY

    -- Clamping needs to happen in the coordinate system of draggableDisplayRegion,
    -- relative to the boundsDisplayRegion.
    -- Assuming boundsDisplayRegion and draggableDisplayRegion share the same parent,
    -- their .x and .y are in the same coordinate space.

    -- boundsDisplayRegion.x, .y are relative to ITS parent.
    -- draggableDisplayRegion will also be positioned relative to this same parent.

    -- Top-left of draggable cannot go before top-left of bounds
    newX = math.max(self.boundsDisplayRegion.x, newX)
    -- Top-left of draggable cannot go so far that its right edge is past bounds' right edge
    newX = math.min(self.boundsDisplayRegion.x + self.boundsDisplayRegion.width - self.draggableDisplayRegion.width, newX)

    newY = math.max(self.boundsDisplayRegion.y, newY)
    newY = math.min(self.boundsDisplayRegion.y + self.boundsDisplayRegion.height - self.draggableDisplayRegion.height, newY)

    return newX, newY
end

-- Helper to move the draggable region and call callbacks
-- newX, newY are target coordinates for draggableDisplayRegion, local (draggableDisplayRegion takes local coords)
function Draggable:_moveTo(newX, newY, isDrop)
    local prevX, prevY = self.draggableDisplayRegion.x, self.draggableDisplayRegion.y
    local clampedX, clampedY = self:_clampPosition(newX - self.dragOffsetX, newY - self.dragOffsetY)

    if self.draggableDisplayRegion.x ~= clampedX or self.draggableDisplayRegion.y ~= clampedY then
        self.draggableDisplayRegion.x = clampedX
        self.draggableDisplayRegion.y = clampedY
        self.draggableDisplayRegion:setNeedsRedraw(true)
        self:setNeedsRedraw(true)

        if not isDrop and self.onDragMove then
            self.onDragMove(self, clampedX, clampedY)
        elseif isDrop and self.onDragDrop then
            self.onDragDrop(self, clampedX, clampedY)
        elseif self.onBoundsClickMove and not self.isDragging then
            self.onBoundsClickMove(self, clampedX, clampedY)
        end
    elseif isDrop and self.onDragDrop then
        self.onDragDrop(self, clampedX, clampedY)
    end
end


function Draggable:onClick(clickX, clickY) -- clickX, clickY are relative to the nearest parent (self.parent)
    local knob = self.draggableDisplayRegion
    -- Check if click is on the draggable part (knob)
    -- knob:isCoordinateInRegion expects coordinates relative to knob's parent.
    -- We need knob's absolute position to check against global clickX, clickY.
    local clickIsInKnob = (clickX >= knob.x and clickX < knob.x + knob.width and
            clickY >= knob.y and clickY < knob.y + knob.height)
    queueOnMainThread(function() self:_registerDragListeners() end)
    self.isDragging = true

    if clickIsInKnob then
        -- dragOffset is the vector from knob's top-left to the mouse click.
        -- knobAbsX, knobAbsY are already knob's top-left global.
        self.dragOffsetX = clickX - knob.x
        self.dragOffsetY = clickY - knob.y

    else
        -- Check if click is on the bounds part
        -- self.boundsDisplayRegion:isCoordinateInRegion expects coords relative to its parent.
        -- self.x,y of Draggable are from boundsDisplayRegion, relative to Draggable's parent.
        local clickIsInBounds = (clickX >= self.x and clickX < self.x + self.width and
                clickY >= self.y and clickY < self.y + self.height)

        if clickIsInBounds then
            -- Clicked on bounds, not on the draggable part: jump draggable's center to click
            self.dragOffsetX = knob.width / 2
            self.dragOffsetY = knob.height / 2
            self:_moveTo(clickX, clickY, false)
        end
    end

end


function Draggable:_onDragListener(_, _, currentX, currentY) -- currentX and currentY are global
    if not self.isDragging then return end

    local newX, newY = currentX - self.dragOffsetX, currentY - self.dragOffsetY
    self:_moveTo(newX, newY, false)
end


function Draggable:_onDropListener(_, _, currentX, currentY) -- finalX, finalY are global
    if not self.isDragging then return end

    local newX, newY = currentX - self.dragOffsetX, currentY - self.dragOffsetY
    self:_moveTo(newX, newY, false)
    self.isDragging = false
    self:_unregisterDragListeners()
end

function Draggable:_registerDragListeners()

    if not self.eventListeners["drag"] then
        local dragHandler = function(...) self:_onDragListener(...) end
        event.listen("drag", dragHandler)
        self.eventListeners["drag"] = dragHandler
    end
    if not self.eventListeners["drop"] then
        local dropHandler = function(...) self:_onDropListener(...) end
        event.listen("drop", dropHandler)
        self.eventListeners["drop"] = dropHandler
    end
end

function Draggable:_unregisterDragListeners()
    if self.eventListeners["drag"] then
        if event.ignore("drag", self.eventListeners["drag"]) then
            self.eventListeners["drag"] = nil
        end
    end
    if self.eventListeners["drop"] then
        if event.ignore("drop", self.eventListeners["drop"]) then
            self.eventListeners["drop"] = nil
        end
    end
end

function Draggable:draw(gpu)
    -- Draw bounds first, then draggable on top
    if self.boundsDisplayRegion and type(self.boundsDisplayRegion.draw) == "function" then
        self.boundsDisplayRegion:draw(gpu)
    end
    if self.draggableDisplayRegion and type(self.draggableDisplayRegion.draw) == "function" then
        self.draggableDisplayRegion:draw(gpu)
    end
    self:setNeedsRedraw(false) -- The container has redrawn its parts
end

function Draggable:unregisterListeners()
    if self.isDragging then
        self.isDragging = false
        self:_unregisterDragListeners()
    end
    Draggable.super.unregisterListeners(self)
end

return Draggable
--- END OF FILE Draggable.txt ---