local OOP = require("UI.OOP")
local Pane = require("UI.elements.panes.Pane")
local ScrollBar = require("UI.elements.control.ScrollBar")
local ColorUtils = require("UI.lib.ColorUtils")
local Logger = require("UI.lib.Logger")

local ScrollPane = OOP.class("ScrollPane", Pane)

--- Constructor for ScrollPane.
-- @param x (number) X-coordinate.
-- @param y (number) Y-coordinate.
-- @param width (number) Overall width of the ScrollPane.
-- @param height (number) Overall height of the ScrollPane.
-- @param backgroundColor (ColorUtils object) Background color for the ScrollPane itself.
-- @param scrollBarWidth (number, optional) Width of the vertical scrollbar. Defaults to 3.
--                         If 0 or nil, no scrollbar is created (content pane takes full width).
-- @param scrollBarColors (table, optional) Colors for the ScrollBar. See ScrollBar:initialize.
--   Defaults: { background = 0x333333, track = 0x404040, thumb = 0x808080, button = 0x606060, buttonText = 0xFFFFFF }
function ScrollPane:initialize(x, y, width, height, backgroundColor, scrollBarWidth, scrollBarColors)
    ScrollPane.super.initialize(self, x, y, width, height, backgroundColor)

    self.actualScrollBarWidth = scrollBarWidth == nil and 3 or scrollBarWidth
    self.scrollBarColors = scrollBarColors or {
        background = ColorUtils:new(0x333333, false), -- Scrollbar component background
        track      = ColorUtils:new(0x404040, false),
        thumb      = ColorUtils:new(0x808080, false),
        button     = ColorUtils:new(0x606060, false),
        buttonText = ColorUtils:new(0xFFFFFF, false)
    }

    -- Viewport Pane: This is where the contentPane's visible part is drawn.
    -- It uses the ScrollPane's background color by default but can be different.
    -- Its dimensions depend on whether a scrollbar is present.
    local viewportX = 1
    local viewportY = 1
    local viewportWidth = self.width
    local viewportHeight = self.height

    if self.actualScrollBarWidth > 0 then
        viewportWidth = self.width - self.actualScrollBarWidth
    end
    viewportWidth = math.max(1, viewportWidth) -- Ensure viewport has at least 1 width
    viewportHeight = math.max(1, viewportHeight) -- Ensure viewport has at least 1 height


    self.viewportPane = Pane:new(viewportX, viewportY, viewportWidth, viewportHeight, self.color)
    self.viewportPane.parent = self
    -- We directly add viewportPane to self.children so super.draw and super.onClick can find it if needed,
    -- but we will manage its drawing and clicking explicitly for clipping.
    -- ScrollPane.super.addChild(self, self.viewportPane) -- This is implicitly done by Pane:draw logic

    -- The actual content that will be scrolled.
    -- It's set via setContentPane() and becomes a child of viewportPane.
    self.contentPane = nil
    self.currentScrollValue = 0

    if self.actualScrollBarWidth > 0 then
        self.scrollBar = ScrollBar:new(
                viewportX + viewportWidth, -- Positioned to the right of the viewport
                viewportY,
                self.actualScrollBarWidth,
                self.height, -- ScrollBar takes full height of ScrollPane
                "vertical",
                self.scrollBarColors,
                0, -- minValue
                0, -- maxValue (will be updated by _updateScrollBarParameters)
                0, -- initialValue
                nil, -- stepValue (use default)
                function(sb, newValue) self:_onScroll(newValue) end
        )
        self.scrollBar.parent = self
        -- ScrollPane.super.addChild(self, self.scrollBar)
    else
        self.scrollBar = nil
    end

    self:setNeedsRedraw(true)
end

-- The width of the area available for content.
function ScrollPane:getContentViewWidth()
    return self.viewportPane.width
end

-- The height of the area available for content.
function ScrollPane:getContentViewHeight()
    return self.viewportPane.height
end

function ScrollPane:setContentPane(newContentPane)
    if self.contentPane and self.contentPane.parent == self.viewportPane then
        self.viewportPane:removeChild(self.contentPane)
        if type(self.contentPane.unregisterListeners) == "function" then
            self.contentPane:unregisterListeners()
        end
    end

    self.contentPane = newContentPane
    if self.contentPane then
        self.contentPane.x = 1 -- Content always starts at top-left of viewport conceptually
        self.contentPane.y = 1
        -- Ensure content pane's width matches the viewport's content view width
        -- This prevents horizontal overflow if not desired.
        -- If horizontal scrolling were a feature, this would be different.
        self.contentPane.width = math.max(1, self.viewportPane.width)

        self.viewportPane:addChild(self.contentPane)
    end

    self.currentScrollValue = 0
    self:_updateScrollBarParameters()
    self:_onScroll(0) -- Position content correctly & trigger redraw
    self:setNeedsRedraw(true)
end

function ScrollPane:_updateScrollBarParameters()
    if not self.scrollBar or not self.contentPane then
        if self.scrollBar then -- No content, disable scrollbar
            self.scrollBar:setValue(0)
            self.scrollBar:setThumbProportion(1.0)
            self.scrollBar.maxValue = 0
            self.scrollBar:setNeedsRedraw(true)
        end
        return
    end

    local contentHeight = self.contentPane.height
    local viewHeight = self.viewportPane.height

    if contentHeight <= viewHeight then
        -- Content fits, no scrolling needed
        self.scrollBar:setValue(0)
        self.scrollBar:setThumbProportion(1.0)
        self.scrollBar.maxValue = 0
    else
        -- Content is taller, scrolling needed
        self.scrollBar.maxValue = contentHeight - viewHeight
        local thumbProportion = viewHeight / contentHeight
        self.scrollBar:setThumbProportion(thumbProportion)
        -- Restore current scroll value, clamped by new max
        self.scrollBar:setValue(self.currentScrollValue)
    end
    self.scrollBar:setNeedsRedraw(true)
end

function ScrollPane:_onScroll(newValue)
    self.currentScrollValue = newValue
    if self.contentPane then
        self.contentPane.y = 1 - math.floor(self.currentScrollValue)
        -- The contentPane itself doesn't need redraw, but its container (viewportPane) does
        -- because the contentPane's position relative to viewportPane changed.
        self.viewportPane:setNeedsRedraw(true)
    end
end

function ScrollPane:draw(gpu)

    -- ScrollPane acts as a Pane, using its superclass draw logic
    -- which creates a buffer, fills its background, then draws children.
    -- Pane:draw will call draw on self.viewportPane and self.scrollBar
    -- if they are added as children to self.children table.
    -- However, to ensure correct drawing order and direct control:

    local scrollPaneBuffer = gpu.allocateBuffer(self.width, self.height)
    if not scrollPaneBuffer then
        Logger.error("ScrollPane: Failed to allocate buffer for ScrollPane.")
        self:setNeedsRedraw(true)
        return
    end
    local originalActiveBuffer = gpu.getActiveBuffer()
    gpu.setActiveBuffer(scrollPaneBuffer)

    -- 1. Draw ScrollPane's own background
    local bgColorVal, bgColorIsPalette = self.color:get()
    gpu.setBackground(bgColorVal, bgColorIsPalette)
    gpu.fill(1, 1, self.width, self.height, " ")

    -- 2. Draw the viewportPane (which handles clipping its contentPane)
    -- The viewportPane draws into its own buffer, then blits to the scrollPaneBuffer.
    if self.viewportPane then
        self.viewportPane:draw(gpu)
    end

    -- 3. Draw the scrollBar on top of (or next to) the viewport
    if self.scrollBar then
        self.scrollBar:draw(gpu)
    end

    -- Blit the combined result to the original target buffer
    gpu.setActiveBuffer(originalActiveBuffer)
    gpu.bitblt(originalActiveBuffer, self.x, self.y, self.width, self.height, scrollPaneBuffer, 1, 1)
    gpu.freeBuffer(scrollPaneBuffer)

    self:setNeedsRedraw(false)
end


function ScrollPane:onClick(clickX, clickY) -- clickX, clickY relative to PARENT of ScrollPane
    if not self:isCoordinateInRegion(clickX, clickY) then return end

    local localX = clickX - self.x + 1 -- Convert to coords relative to ScrollPane's 1,1
    local localY = clickY - self.y + 1

    -- Priority to scrollbar if clicked
    if self.scrollBar and self.scrollBar:isCoordinateInRegion(localX, localY) then
        self.scrollBar:onClick(localX, localY) -- ScrollBar's onClick expects coords relative to its parent (ScrollPane)
        return
    end

    -- Then, check viewport
    if self.viewportPane and self.viewportPane:isCoordinateInRegion(localX, localY) then
        -- viewportPane's onClick expects coords relative to its parent (ScrollPane)
        -- It will then translate and delegate to its children (the contentPane).
        self.viewportPane:onClick(localX, localY)
        return
    end

    -- If click was on ScrollPane's border/background (not scrollbar or viewport),
    -- potentially handle here or call super.onClick if ScrollPane itself needs to react.
    -- For now, do nothing more.
end

function ScrollPane:unregisterListeners()
    ScrollPane.super.unregisterListeners(self) -- From Pane, handles self.children if Pane.addChild was used
    if self.scrollBar and type(self.scrollBar.unregisterListeners) == "function" then
        self.scrollBar:unregisterListeners()
    end
    if self.viewportPane and type(self.viewportPane.unregisterListeners) == "function" then
        -- This will also unregister listeners of its children (i.e., the contentPane)
        self.viewportPane:unregisterListeners()
    end
    self.scrollBar = nil
    self.viewportPane = nil
    self.contentPane = nil -- contentPane is managed by viewportPane
end

--- Overrides Pane's setNeedsRedraw to ensure children are also marked if ScrollPane needs full redraw.
-- function ScrollPane:setNeedsRedraw(needsRedraw)
--     if self.needsRedraw == needsRedraw and self.needsRedraw ~= nil then return end
--     ScrollPane.super.setNeedsRedraw(self, needsRedraw) -- Call Pane's setNeedsRedraw

--     if self.needsRedraw then
--         if self.viewportPane then self.viewportPane:setNeedsRedraw(true) end
--         if self.scrollBar then self.scrollBar:setNeedsRedraw(true) end
--         -- contentPane redraw is managed by viewportPane or direct interaction (_onScroll)
--     end
-- end


return ScrollPane