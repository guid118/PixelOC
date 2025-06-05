local OOP = require("UI.OOP")
local Pane = require("UI.elements.panes.Pane")
local Button = require("UI.elements.control.Button")
local ColorUtils = require("UI.lib.ColorUtils")
local Logger = require("UI.lib.Logger")

local TabPane = OOP.class("TabPane", Pane)

function TabPane:initialize(x, y, width, height, color, tabHeight, tabButtonColor, tabButtonTextColor, activeTabButtonColor)
    Pane.super.initialize(self, x, y, width, height, color) -- The overall TabPane area

    self.tabHeight = tabHeight or 3 -- Default height for the tab bar area
    self.tabButtonColor = tabButtonColor or ColorUtils:new(0x555555, false)
    self.tabButtonTextColor = tabButtonTextColor or ColorUtils:new(0xFFFFFF, false)
    self.activeTabButtonColor = activeTabButtonColor or ColorUtils:new(0x777777, false)

    self.tabs = {} -- Stores { name = "Tab1", button = Button, contentPane = Pane }
    self.tabOrder = {} -- Array of tab names to maintain order for button placement
    self.activeTabName = nil

    -- Define areas within the TabPane
    self.tabBarX = self.x
    self.tabBarY = self.y
    self.tabBarWidth = self.width
    self.tabBarHeight = self.tabHeight -- Actual height of the bar for buttons

    self.contentAreaX = self.x
    self.contentAreaY = self.y + self.tabBarHeight
    self.contentAreaWidth = self.width
    self.contentAreaHeight = self.height - self.tabBarHeight

    if self.contentAreaHeight <= 0 then
        Logger.warn("TabPane: Content area height is zero or negative. TabPane might not render correctly.")
        self.contentAreaHeight = 1 -- Ensure minimum 1 pixel for buffer
    end
    if self.tabBarHeight <= 0 then
        Logger.warn("TabPane: Tab bar height is zero or negative. Tabs might not render correctly.")
        self.tabBarHeight = 1 -- Ensure minimum 1 pixel
    end
end

function TabPane:addTab(tabName, contentPane)
    if self.tabs[tabName] then
        Logger.error("TabPane: Tab with name '" .. tostring(tabName) .. "' already exists.")
        return
    end

    local tabButton = Button:new(
            0, 0, -- x, y will be set by _layoutTabs
            0, self.tabBarHeight, -- width will be set by _layoutTabs, height is tabBarHeight
            self.tabButtonColor,
            tabName,
            self.tabButtonTextColor,
            function() self:setActiveTab(tabName) end
    )
    tabButton.parent = self -- For redraw propagation if button changes state

    self.tabs[tabName] = {
        name = tabName,
        button = tabButton,
        contentPane = contentPane
    }
    table.insert(self.tabOrder, tabName)

    contentPane.parent = self -- For redraw propagation and coordinate context

    if not self.activeTabName then
        self:setActiveTab(tabName)
    else
        -- New tab is inactive by default if another is already active
        contentPane:setNeedsRedraw(false) -- Ensure it's not drawn if not active
    end

    self:_layoutTabs()
    self:setNeedsRedraw(true)
end

function TabPane:_layoutTabs()
    if #self.tabOrder == 0 then return end

    local totalButtonWidth = 0
    for _, tabName in ipairs(self.tabOrder) do
        -- Simple width: equally distributed. Could be based on text length later.
        totalButtonWidth = totalButtonWidth + (string.len(tabName) + 2) -- +2 for padding
    end

    local actualButtonWidth = self.tabBarWidth / #self.tabOrder
    local currentX = self.tabBarX

    for i, tabName in ipairs(self.tabOrder) do
        local tabData = self.tabs[tabName]
        local w = math.floor(actualButtonWidth)
        if i == #self.tabOrder then -- Last button takes remaining space
            w = self.tabBarX + self.tabBarWidth - currentX
        end

        tabData.button.x = currentX
        tabData.button.y = self.tabBarY
        tabData.button.width = w
        tabData.button.height = self.tabBarHeight -- Use full tab bar height
        tabData.button:setNeedsRedraw(true)
        currentX = currentX + w
    end
end

function TabPane:setActiveTab(tabName)
    if not self.tabs[tabName] then
        Logger.warn("TabPane: Attempted to set non-existent tab '" .. tostring(tabName) .. "' active.")
        return
    end
    if self.activeTabName == tabName then
        return -- Already active
    end

    -- Deactivate previous tab
    if self.activeTabName and self.tabs[self.activeTabName] then
        local oldTabData = self.tabs[self.activeTabName]
        oldTabData.button:setColor(self.tabButtonColor)
        oldTabData.button:setNeedsRedraw(true)
        if oldTabData.contentPane.setNeedsRedraw then
            oldTabData.contentPane:setNeedsRedraw(true) -- To clear it / mark for update
        end
    end

    self.activeTabName = tabName

    -- Activate new tab
    local newTabData = self.tabs[self.activeTabName]
    newTabData.button:setColor(self.activeTabButtonColor)
    newTabData.button:setNeedsRedraw(true)
    if newTabData.contentPane.setNeedsRedraw then
        newTabData.contentPane:setNeedsRedraw(true)
    end

    self:setNeedsRedraw(true)
end

function TabPane:getActiveTabName()
    return self.activeTabName
end

function TabPane:getActiveContentPane()
    return self.activeTabName and self.tabs[self.activeTabName] and self.tabs[self.activeTabName].contentPane
end

function TabPane:draw(gpu)
    -- TabPane's `color` (from Pane superclass) is background for content area.
    -- Tab bar area is implicitly backgrounded by elements underneath or screen bg,
    -- unless explicitly drawn here.

    -- Draw tab buttons
    for _, tabName in ipairs(self.tabOrder) do
        local tabData = self.tabs[tabName]
        if tabData.button and type(tabData.button.draw) == "function" then
            tabData.button:draw(gpu)
        end
    end

    -- Draw content area background
    local pGpuBgColor, pGpuBgPalette = gpu.getBackground() -- Save current GPU background
    local contentBgColorVal, contentBgIsPalette = self.color:get()
    gpu.setBackground(contentBgColorVal, contentBgIsPalette)
    gpu.fill(self.contentAreaX, self.contentAreaY, self.contentAreaWidth, self.contentAreaHeight, " ")

    -- Draw active content pane
    local activePane = self:getActiveContentPane()
    if activePane and type(activePane.draw) == "function" and self.contentAreaWidth > 0 and self.contentAreaHeight > 0 then
        local tempBufferId = gpu.allocateBuffer(self.contentAreaWidth, self.contentAreaHeight)
        if not tempBufferId then
            Logger.error("TabPane: Failed to allocate buffer for content pane.")
            gpu.setBackground(pGpuBgColor, pGpuBgPalette) -- Restore GPU background
            self:setNeedsRedraw(true) -- Try again later
            return
        end

        local drawSuccess, drawingError = pcall(function()
            local originalActiveBuffer = gpu.getActiveBuffer()
            gpu.setActiveBuffer(tempBufferId)

            -- The activePane should draw itself as if its top-left is (1,1)
            -- and its dimensions fit within the content area.
            -- Pane:draw uses its own self.x, self.y. So, temporarily adjust for the draw call.
            local origPaneX, origPaneY = activePane.x, activePane.y
            -- Panes are usually designed with x=1, y=1 if they are children.
            -- We assume the contentPane is designed to be drawn starting at (1,1) of its allocated space.
            activePane.x = 1
            activePane.y = 1
            -- We don't force activePane.width/height; it draws with its own configured size into the buffer.
            -- If it's larger than contentArea, it will be clipped by the bitblt.

            activePane:draw(gpu) -- activePane draws into the tempBuffer

            activePane.x, activePane.y = origPaneX, origPaneY -- Restore original

            gpu.setActiveBuffer(originalActiveBuffer)
            gpu.bitblt(originalActiveBuffer, self.contentAreaX, self.contentAreaY, self.contentAreaWidth, self.contentAreaHeight, tempBufferId, 1, 1)
        end)

        gpu.freeBuffer(tempBufferId)

        if not drawSuccess then
            Logger.error("TabPane: Error drawing active content pane: " .. tostring(drawingError))
            self:setNeedsRedraw(true) -- Mark for redraw on error
        end
    end

    gpu.setBackground(pGpuBgColor, pGpuBgPalette) -- Restore original GPU background
    self:setNeedsRedraw(false)
end

function TabPane:onClick(clickX, clickY)
    -- Check tab buttons first
    for _, tabName in ipairs(self.tabOrder) do
        local tabData = self.tabs[tabName]
        if tabData.button:isCoordinateInRegion(clickX, clickY) then
            tabData.button:onClick(clickX, clickY) -- Button's onClick calls self:setActiveTab
            return
        end
    end

    -- Check content area if no tab button was clicked
    if clickX >= self.contentAreaX and clickX < self.contentAreaX + self.contentAreaWidth and
            clickY >= self.contentAreaY and clickY < self.contentAreaY + self.contentAreaHeight then

        local activePane = self:getActiveContentPane()
        if activePane and type(activePane.onClick) == "function" then
            -- Translate click coordinates to be relative to the activePane's drawing origin (1,1 within contentArea)
            local relativeToContentX = clickX - self.contentAreaX + 1
            local relativeToContentY = clickY - self.contentAreaY + 1
            activePane:onClick(relativeToContentX, relativeToContentY)
            return
        end
    end
    -- Potentially call Pane.super.onClick(self, clickX, clickY) if TabPane itself should react to clicks on its frame
end

function TabPane:unregisterListeners()
    TabPane.super.unregisterListeners(self) -- From Region

    for _, tabData in pairs(self.tabs) do
        if tabData.button and type(tabData.button.unregisterListeners) == "function" then
            tabData.button:unregisterListeners()
        end
        if tabData.contentPane and type(tabData.contentPane.unregisterListeners) == "function" then
            tabData.contentPane:unregisterListeners()
        end
    end
    self.tabs = {}
    self.tabOrder = {}
end

function TabPane:setNeedsRedraw(needsRedraw)
    if self.needsRedraw == needsRedraw and self.needsRedraw ~= nil then return end
    TabPane.super.setNeedsRedraw(self, needsRedraw) -- Call Region's setNeedsRedraw

    if self.needsRedraw and self.tabs then
        for _, tabData in pairs(self.tabs) do
            if tabData.button then tabData.button:setNeedsRedraw(true) end
        end
        local activeContent = self:getActiveContentPane()
        if activeContent and activeContent.setNeedsRedraw then
            activeContent:setNeedsRedraw(true)
        end
    end
end

return TabPane