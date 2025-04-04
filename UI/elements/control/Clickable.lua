local Label = require("UI.elements.Label")

---@class Clickable:Label
local Clickable = setmetatable({}, { __index = Label })
Clickable.__index = Clickable

--- any class extending Clickable must implement the onClick method
function Clickable:onClick()
    print("CLICK NOT IMPLEMENTED")
end
--- any class extending Clickable must implement the setOnClick method
function Clickable:setOnClick(operation)
    print("SET CLICK NOT IMPLEMENTED")
end

return Clickable