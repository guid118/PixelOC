local Pane = require("UI.elements.panes.Pane")
local ToggleButton = require("UI.elements.control.ToggleButton")

---@class TabPane:Pane
local TabPane = setmetatable({}, { __index = Pane })
TabPane.__index = TabPane


--- Constructor for the TabPane class
--- @param x number start x of the pane
--- @param y number start y of the pane
--- @param width number width of the pane
--- @param height number height of the pane, this includes the tabHeight
--- @param tabHeight number the height of the tab region within the given size
function TabPane.new(x, y, width, height, tabHeight)
    local obj = Pane.new(x, y, width, height)
    setmetatable(obj, TabPane)
    obj.isEnabled = true
    obj.tabHeight = tabHeight
    obj.tabPane = Pane.new(x, y, width, tabHeight, true)
    obj.contentPane = Pane.new(x, y + tabHeight, width, height, true)
    obj.currentTabButton = ToggleButton.new(1,1,1,1,0x000000, false, "", function() end)
    table.insert(obj.content, obj.tabPane)
    table.insert(obj.content, obj.contentPane)
    return obj
end

--- Add a tab to the pane.
--- @param button ToggleButton ToggleButton to control switching to this tab
--- @param contentPane Pane Pane that contains the content
function TabPane:addTab(button, contentPane)
    local x = self:getNextTabLocation()
    button.x = x
    button.y = 1
    button.width = button.label:len() + 2
    button.height = self.tabHeight
    if (#self.tabPane.content == 0) then
        self.currentTabButton = button
    end
    self.tabPane:add(button)
    contentPane.x = self.x
    contentPane.y = self.y + self.tabHeight
    contentPane.width = self.width
    contentPane.height = self.height
    button:setOnClick(function()
        if (self.currentTabButton ~= button) then
            self.currentTabButton:toggleEnabled()
            self.currentTabButton = button
            button:toggleEnabled()
            self.contentPane = contentPane
            self:draw()
            self.contentPane:draw()
        end
    end)


    if (contentPane.content ~= {}) then
        for _, item in ipairs(contentPane.content) do
            item.x = item.x + self.contentPane.x - 1
            item.y = item.y + self.contentPane.y - 1
        end
    end
end

--- get the x location of the next tab
function TabPane:getNextTabLocation()
    local x = 0
    for _, item in ipairs(self.tabPane.content) do
        x = x + item.width
    end
    return x
end

--- Get the clickable that is at the given coordinates
--- @return Clickable of the pane at the given coordinates.
function TabPane:getClickableAt(x, y)
    if (y < self.y + self.tabHeight) then
        return self.tabPane:getClickableAt(x, y)
    else
        return self.contentPane:getClickableAt(x, y)
    end
end

--- draw function for TabPane. draws both the tabs and the content.
function TabPane:draw()
    self.tabPane:draw()
    self.contentPane:draw()
end

return TabPane