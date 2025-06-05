local OOP = require("UI.OOP")
local Pane = require("UI.elements.panes.Pane")
local ScrollBar = require("UI.elements.control.ScrollBar")
local ColorUtils = require("UI.lib.ColorUtils")
local Logger = require("UI.lib.Logger")

local ScrollPane = OOP.class("ScrollPane", Pane)

function ScrollPane:initialize(x, y, width, height, color, scrollBarWidth, scrollBarColors)
    Pane.super.initialize(self, x, y, width, height, color)

    self.scrollBarWidth = scrollBarWidth or 3

    local defaultSbColors = {
        bgColor = ColorUtils:new(0x333333, false),
        thumbColor = ColorUtils:new(0x888888, false),
        buttonColor = ColorUtils:new(0x555555, false)
    }
    self.scrollBarColors = scrollBarColors or defaultSbColors

    self.contentPane = nil
    self.scrollOffsetX = 0 -- For horizontal scrolling (not implemented yet)
    self.scrollOffsetY = 0 -- For vertical scrolling

    -- These are coordinates and dimensions for the area where content is drawn,
    -- relative to the ScrollPane's own x,y.
    self.contentViewX = 1 -- Content always starts at 1,1 within its drawable area
    self.contentViewY = 1
    self.contentViewWidth = self.width - self.scrollBarWidth
    self.contentViewHeight = self.height

    if self.contentViewWidth <= 0 then
        Logger.warn("ScrollPane: Content view width is zero or negative (" .. self.contentViewWidth .. "). ScrollPane may not render content correctly.")
        self.contentViewWidth = 1
    end
    if self.contentViewHeight <= 0 then
        Logger.warn("ScrollPane: Content view height is zero or negative (" .. self.contentViewHeight .. "). ScrollPane may not render content correctly.")
        self.contentViewHeight = 1
    end

    self:_createScrollBar()
    self:setNeedsRedraw(true)
end

function ScrollPane:_createScrollBar()
    -- ScrollBar's x,y are relative to the ScrollPane's x,y
    local sbRelativeX = 1 + self.width - self.scrollBarWidth
    local sbRelativeY = 1

    self.scrollBar = ScrollBar:new(
            sbRelativeX, sbRelativeY, self.scrollBarWidth, self.height,
            self.scrollBarWidth, -- buttonHeight (square-ish for vertical scrollbar)
            self.scrollBarWidth * 2, -- thumbMinHeight (arbitrary good value)
            self.contentViewHeight, -- totalContentHeight (initial: assumes content fits)
            self.contentViewHeight, -- visibleContentHeight
            self.scrollBarColors.bgColor,
            self.scrollBarColors.thumbColor,
            self.scrollBarColors.buttonColor
    )
    self.scrollBar.parent = self -- For event propagation / redraw needs

    local self_scrollPane = self
    self.scrollBar.onValueChanged = function(scrollbar, newValue)
        self_scrollPane:setScrollOffsetY(newValue, true) -- true indicates fromScrollbar
    end
end

function ScrollPane:setContentPane(pane)
    if self.contentPane and self.contentPane.parent == self then
        self.contentPane.parent = nil
    end
    self.contentPane = pane
    if self.contentPane then
        self.contentPane.parent = self -- For redraw propagation

        -- contentPane's x,y are its position *within its own full canvas*.
        -- Typically, you design a pane to be drawn starting at 1,1 of its intended space.
        self.contentPane.x = 1
        self.contentPane.y = 1

        self.scrollBar:setContentDimensions(
                self.contentPane.height,      -- totalContentHeight
                self.contentViewHeight        -- visibleContentHeight
        )
        -- Clamp current scrollOffsetY and update scrollbar
        local maxScroll = math.max(0, self.contentPane.height - self.contentViewHeight)
        self.scrollOffsetY = math.min(self.scrollOffsetY, maxScroll)
        self.scrollBar:setValue(self.scrollOffsetY) -- Sync scrollbar with potentially clamped value
    else
        -- No content, so scrollbar reflects an empty, fitting view
        self.scrollBar:setContentDimensions(self.contentViewHeight, self.contentViewHeight)
        self.scrollOffsetY = 0
        self.scrollBar:setValue(0)
    end
    self:setNeedsRedraw(true)
end

function ScrollPane:setScrollOffsetY(offsetY, fromScrollbar)
    local newOffsetY = math.max(0, offsetY) -- Cannot scroll above top
    if self.contentPane then
        local maxScroll = math.max(0, self.contentPane.height - self.contentViewHeight)
        newOffsetY = math.min(newOffsetY, maxScroll) -- Cannot scroll beyond content
    else
        newOffsetY = 0 -- No content, no scroll
    end

    newOffsetY = math.floor(newOffsetY + 0.5) -- Round to nearest integer

    if self.scrollOffsetY ~= newOffsetY then
        self.scrollOffsetY = newOffsetY
        if not fromScrollbar then -- If scroll changed programmatically, update scrollbar visual
            self.scrollBar:setValue(self.scrollOffsetY)
        end
        self:setNeedsRedraw(true)
    end
end

function ScrollPane:draw(gpu)
    -- ScrollPane uses the same double-buffering strategy as Pane.
    -- It draws its background, then its content (clipped and offset), then its scrollbar
    -- into its own temporary buffer, which is then blitted to the parent's drawing surface.

    local tempBufferId = gpu.allocateBuffer(self.width, self.height)
    if not tempBufferId then
        Logger.error("ScrollPane: Failed to allocate buffer for drawing.")
        self:setNeedsRedraw(true)
        return
    end

    local drawSuccess, drawingError = pcall(function()
        local originalActiveBuffer = gpu.getActiveBuffer()
        gpu.setActiveBuffer(tempBufferId)

        -- 1. Draw ScrollPane's own background for its entire area (into tempBufferId)
        local pGpuBgColor, pGpuBgPalette = gpu.getBackground() -- Save current GPU state within tempBufferId
        local bgColorVal, bgColorIsPalette = self.color:get()
        gpu.setBackground(bgColorVal, bgColorIsPalette)
        gpu.fill(1, 1, self.width, self.height, " ") -- Fill entire ScrollPane area in tempBufferId

        -- 2. Draw Content (clipped and offset) into a sub-region of tempBufferId
        if self.contentPane and self.contentViewWidth > 0 and self.contentViewHeight > 0 then
            -- Store original positions of contentPane, as Pane.draw uses self.x, self.y
            -- for its *own* blitting calculations IF it were blitting to 'originalActiveBuffer'.
            -- Here, contentPane will draw into a *further* nested buffer.
            local originalContentPaneX = self.contentPane.x
            local originalContentPaneY = self.contentPane.y

            -- Set contentPane's drawing origin for its internal Pane:draw logic.
            -- This tells Pane:draw where to blit ITS internal buffer onto OUR tempBufferId.
            self.contentPane.x = self.contentViewX - self.scrollOffsetX -- Stays contentViewX for vertical only
            self.contentPane.y = self.contentViewY - self.scrollOffsetY

            -- When self.contentPane:draw(gpu) is called:
            -- - GPU active buffer is 'tempBufferId'.
            -- - contentPane (being a Pane) will:
            --   - Allocate its own buffer (contentPaneBuffer) of contentPane.width x contentPane.height.
            --   - Draw its background and children into contentPaneBuffer.
            --   - Blit contentPaneBuffer to the *currently active GPU buffer* (which is tempBufferId)
            --     at self.contentPane.x, self.contentPane.y (which we've just set to be scrolled).
            --   - It will be clipped automatically if contentPane.width/height is larger than
            --     the remaining space in tempBufferId from its (scrolled) blit origin.
            --     However, we want to explicitly clip it to contentViewWidth/Height.
            --     The Pane:draw's bitblt `width, height` are `self.contentPane.width, self.contentPane.height`.
            --     This needs care: we only want to show the contentViewWidth/Height portion.
            --
            --     This means the contentPane.draw needs to be drawing onto a surface
            --     that is ALREADY the size of contentViewWidth, contentViewHeight.
            --     This is what the TabPane model does for its content.
            --     Let's adapt THAT approach:

            local contentClipBuffer = gpu.allocateBuffer(self.contentViewWidth, self.contentViewHeight)
            if contentClipBuffer then
                local prevActive = gpu.getActiveBuffer()
                gpu.setActiveBuffer(contentClipBuffer)
                gpu.setBackground(bgColorVal, bgColorIsPalette) -- Fill clip buffer too
                gpu.fill(1,1, self.contentViewWidth, self.contentViewHeight, " ")

                -- Now, contentPane draws into contentClipBuffer, but its (0,0) should map to a scrolled position
                self.contentPane.x = 1 - self.scrollOffsetX
                self.contentPane.y = 1 - self.scrollOffsetY
                self.contentPane:draw(gpu) -- Draws into contentClipBuffer, scrolled

                gpu.setActiveBuffer(prevActive) -- Back to tempBufferId
                gpu.bitblt(tempBufferId, self.contentViewX, self.contentViewY,
                        self.contentViewWidth, self.contentViewHeight,
                        contentClipBuffer, 1, 1)
                gpu.freeBuffer(contentClipBuffer)
            else
                Logger.error("ScrollPane: Failed to allocate contentClipBuffer.")
            end

            -- Restore original contentPane conceptual positions
            self.contentPane.x = originalContentPaneX
            self.contentPane.y = originalContentPaneY
        end

        -- 3. Draw ScrollBar on top, relative to ScrollPane's origin (1,1 in tempBufferId)
        if self.scrollBar and type(self.scrollBar.draw) == "function" then
            -- ScrollBar's x, y are already relative to ScrollPane, so they draw correctly in tempBufferId
            self.scrollBar:draw(gpu)
        end

        gpu.setBackground(pGpuBgColor, pGpuBgPalette) -- Restore GPU state for tempBufferId
        gpu.setActiveBuffer(originalActiveBuffer) -- Switch back to parent's buffer
        -- Blit the fully composed ScrollPane (bg, content, scrollbar) from tempBufferId to originalActiveBuffer
        gpu.bitblt(originalActiveBuffer, self.x, self.y, self.width, self.height, tempBufferId, 1, 1)

    end)

    gpu.freeBuffer(tempBufferId)

    if not drawSuccess then
        Logger.error("ScrollPane: Error during draw sequence: " .. tostring(drawingError))
        -- Attempt to restore contentPane original positions if error occurred and contentPane exists
        if self.contentPane and originalContentPaneX then
            self.contentPane.x = originalContentPaneX
            self.contentPane.y = originalContentPaneY
        end
        self:setNeedsRedraw(true)
    else
        self:setNeedsRedraw(false)
    end
end

function ScrollPane:onClick(clickX, clickY)
    -- clickX, clickY are relative to the ScrollPane's parent (e.g., screen or a containing Pane).
    -- We need to make them relative to the ScrollPane's own (1,1) for child hit-testing.
    local relativeClickX = clickX - self.x + 1
    local relativeClickY = clickY - self.y + 1

    -- Check scrollbar first. ScrollBar's x,y are relative to ScrollPane.
    if self.scrollBar and self.scrollBar:isCoordinateInRegion(relativeClickX, relativeClickY) then
        self.scrollBar:onClick(relativeClickX, relativeClickY) -- Pass relative coords
        return
    end

    -- Check if click is within the content view area (excluding scrollbar)
    local isClickInContentView = relativeClickX >= self.contentViewX and
            relativeClickX < self.contentViewX + self.contentViewWidth and
            relativeClickY >= self.contentViewY and
            relativeClickY < self.contentViewY + self.contentViewHeight

    if self.contentPane and isClickInContentView and type(self.contentPane.onClick) == "function" then
        -- Translate click coordinates to be relative to the contentPane's *unscrolled* (1,1)
        local clickInContentViewX = relativeClickX - self.contentViewX + 1
        local clickInContentViewY = relativeClickY - self.contentViewY + 1

        local relativeToContentOriginX = clickInContentViewX + self.scrollOffsetX
        local relativeToContentOriginY = clickInContentViewY + self.scrollOffsetY

        self.contentPane:onClick(relativeToContentOriginX, relativeToContentOriginY)
        return
    end
end

function ScrollPane:setNeedsRedraw(needsRedraw)
    if self.needsRedraw == needsRedraw and self.needsRedraw ~= nil then return end
    ScrollPane.super.setNeedsRedraw(self, needsRedraw) -- From Region/Pane

    if self.needsRedraw then
        if self.scrollBar then self.scrollBar:setNeedsRedraw(true) end
        if self.contentPane and self.contentPane.setNeedsRedraw then
            self.contentPane:setNeedsRedraw(true)
        end
    end
end

function ScrollPane:unregisterListeners()
    ScrollPane.super.unregisterListeners(self) -- From Region/Pane
    if self.scrollBar then
        self.scrollBar:unregisterListeners()
    end
    if self.contentPane and type(self.contentPane.unregisterListeners) == "function" then
        self.contentPane:unregisterListeners()
    end
end

return ScrollPane