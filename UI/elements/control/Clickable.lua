local Labeled = require("UI.elements.Labeled")



---@class Clickable:Labeled
local Clickable = setmetatable({}, { __index = Labeled })
Clickable.__index = Clickable

function Clickable:onClick()
    print("NOT IMPLEMENTED")
end

function Clickable:setOnClick(operation)
    print("NOT IMPLEMENTED")
end

return Clickable