local ElementUtils = require("UI.lib.ElementUtils")
local Region = require("UI.elements.Region")
local Clickable = require("UI.elements.control.Clickable")
local gpu = require("component").gpu
local Serialization = require("serialization")

---@class Pane:Region
local Pane = setmetatable({}, {__index = Region})
Pane.__index = Pane


local content = {}

function Pane.new()
    local x,y = gpu.getResolution()
    return Pane.new(1,1,x,y)
end

function Pane.new(x,y, height, width)
    local obj = Region.new(x,y,height, width)
    setmetatable(obj, Pane)
    obj.isEnabled = false;
    return obj
end

function Pane.add(RegionInheritor)
--[[    if (ElementUtils.inheritsFrom(RegionInheritor, Region)) then
        table.insert(content, RegionInheritor)
    end]]
    table.insert(content, RegionInheritor)
end

function Pane:setVisible(value)
    self.isEnabled = value
    if (value == true) then
        self:draw()
    end
end

function Pane:draw()
    if (self.isEnabled) then
        for _,item in ipairs(content) do
            item:draw()
        end
    end
end

function Pane:getContent()
    return content
end



return Pane
