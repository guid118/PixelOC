local Region = require("UI.elements.Region")
local gpu = require("component").gpu

---@class Pane:Region
local Pane = setmetatable({}, { __index = Region })
Pane.__index = Pane

local content = {}

--- Default constructor for the Pane class
--- @return Pane a new Pane that spans across the whole screen
function Pane.new()
    local x, y = gpu.getResolution()
    return Pane.new(1, 1, x, y)
end

--- Normal constructor for the Pane class
--- @return Pane a new Pane
function Pane.new(x, y, height, width)
    local obj = Region.new(x, y, height, width)
    setmetatable(obj, Pane)
    obj.isEnabled = false;
    return obj
end

--- Add a region inheriting class to the pane
--- Given argument MUST INHERIT FROM REGION, or this will cause a crash when drawn!
--- @param RegionInheritor Region to add to the pane.
function Pane.add(RegionInheritor)
    table.insert(content, RegionInheritor)
end

--- Set this pane to visible, if the draw function is called while the pane is not visible, it will not draw anything.
---@param value boolean true if the pane should be visible, false otherwise.
function Pane:setVisible(value)
    self.isEnabled = value
    if (value == true) then
        self:draw()
    end
end

--- Draw function for the pane, will not draw anything if getVisible is false
function Pane:draw()
    if (self.isEnabled) then
        for _, item in ipairs(content) do
            item:draw()
        end
    end
end

--- Getter for the isEnabled value
--- @return boolean if the pane is visible or not
function Pane:getVisbible()
    return self.isEnabled
end

--- Getter for the content of the pane
--- mostly useful for determining what was pressed within the pane
--- @return table all content of the pane
function Pane:getContent()
    return content
end

return Pane
