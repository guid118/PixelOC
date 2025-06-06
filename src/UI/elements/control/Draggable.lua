--- START OF FILE Draggable.txt ---

local OOP = require("UI.OOP")
local ColoredRegion = require("UI.elements.ColoredRegion")
local event = require("event")
local Logger = require("UI.lib.Logger")

local Draggable = OOP.class("Draggable", ColoredRegion)

-- Constructor
-- draggableDisplayRegion: The ColoredRegion that will be visually dragged.
-- boundsDisplayRegion: A ColoredRegion that defines the visual bounds and can be clicked.
function Draggable:initialize(boundsDisplayRegion, draggableDisplayRegion)
    Draggable.super.initialize(self, boundsDisplayRegion.x, boundsDisplayRegion.y, boundsDisplayRegion.width, boundsDisplayRegion.height, boundsDisplayRegion.color)
    self.knob = draggableDisplayRegion

    self.knob.parent = self -- set this as parent

    -- isDragging state, to prevent dragging when no click was registered.
    self.isDragging = false

    -- Offset from draggableDisplayRegion's top-left to mouse click point
    self.dragOffsetX = 0
    self.dragOffsetY = 0

    -- callbacks
    self.onDragMove = nil
    self.onDragDrop = nil
end

-- Helper to clamp draggableDisplayRegion's top-left position within self
-- targetX, targetY are relative to self (top left corner of area is 1,1
function Draggable:_clampPosition(targetX, targetY)
    local newX = math.max(1, targetX)
    newX = math.min(self.width - self.knob.width + 1, newX)

    local newY = math.max(1,targetY)
    newY = math.min(self.height - self.knob.height + 1, newY)
    return newX, newY
end

-- Helper to move the draggable region and call callbacks
-- newX, newY are target coordinates for draggableDisplayRegion, local (draggableDisplayRegion takes local coords)
function Draggable:_moveTo(newX, newY, isDrop)
    local clampedX, clampedY = self:_clampPosition(newX - self.dragOffsetX, newY - self.dragOffsetY)

    if self.knob.x ~= clampedX or self.knob.y ~= clampedY then
        self.knob.x = clampedX
        self.knob.y = clampedY

        self:setNeedsRedraw(true)

        if not isDrop and self.onDragMove then
            self.onDragMove(self, clampedX, clampedY)
        elseif isDrop and self.onDragDrop then
            self.onDragDrop(self, clampedX, clampedY)
        end
    elseif isDrop and self.onDragDrop then
        self.onDragDrop(self, clampedX, clampedY)
    end
end

-- if this doesn't work, impelement the globalX and globalY as 3rd and 4th arguments
function Draggable:onClick(clickX, clickY) -- clickX, clickY are relative to the nearest parent (self.parent)
    queueOnMainThread(function() self:_registerDragListeners()  end)
    self.isDragging = true
    local knob = self.knob
    -- make coordinates local to self
    local localClickX, localClickY = clickX - self.x, clickY - self.y

    local isClickInKnob = localClickX >= knob.x and localClickX < knob.x + knob.width - 1
                            and localClickY >= knob.y and localClickY < knob.y + knob.height - 1

    if not isClickInKnob then
        self.dragOffsetX = knob.width / 4
        self.dragOffsetY = knob.height / 4
        self:_moveTo(localClickX, localClickY)
    else
        self.dragOffsetX = localClickX - knob.x
        self.dragOffsetY = localClickY - knob.y
    end

end


function Draggable:_onDragListener(_, _, currentX, currentY) -- currentX and currentY are global
    if not self.isDragging then return end
    local absX, absY = self:getGlobalCoordinates()
    --Logger.debug("absolute coordinates: " .. absX .. ", " .. absY)
    local newX, newY = currentX - absX - self.dragOffsetX + 1, currentY - absY - self.dragOffsetY + 1
    --Logger.debug("make local coordinates: " .. newX .. ", " .. newY)
    self:_moveTo(newX, newY, false)
end


function Draggable:_onDropListener(_, _, currentX, currentY) -- finalX, finalY are global
    if not self.isDragging then return end
    local absX, absY = self:getGlobalCoordinates()
    local newX, newY = currentX - absX - self.dragOffsetX + 1, currentY - absY - self.dragOffsetY + 1
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

function Draggable:unregisterListeners()
    if self.isDragging then
        self.isDragging = false
        self:_unregisterDragListeners()
    end
    Draggable.super.unregisterListeners(self)
end


--- @param gpu gpu
function Draggable:draw(gpu)
    local returnBuffer = gpu.getActiveBuffer()
    local newBuffer = gpu.allocateBuffer(self.width, self.height)
    gpu.setActiveBuffer(newBuffer)


    local bgColorVal, isPalette = self.color:get()
    gpu.setBackground(bgColorVal, isPalette)

    gpu.fill(1,1, self.width, self.height, " ")
    self.knob:draw(gpu)

    gpu.bitblt(returnBuffer, self.x, self.y, self.width, self.height, newBuffer, 1, 1)
    gpu.freeBuffer()
    gpu.setActiveBuffer(returnBuffer)

    self:setNeedsRedraw(false) -- The container has redrawn its parts
end


return Draggable
--- END OF FILE Draggable.txt ---