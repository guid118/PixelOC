---
---
---
---
local gpu = require("component").gpu

---@class DebugUtils
---@field safePrint nil print a text to the bottom of the screen
local DebugUtils = {}
local lines = {}

function DebugUtils.safePrint(string)
    table.insert(lines, string)  -- Add new line to the end
    if #lines > 10 then
        table.remove(lines, 1)  -- Remove the first line if more than 5 exist
    end
    DebugUtils.draw()
end

function DebugUtils.draw()
    gpu.setBackground(0x000000, false)
    gpu.setForeground(0xFFFFFF, false)
    local _, y = gpu.getResolution()
    gpu.fill(0, y - #lines, 160, #lines, " ")
    for i, line in ipairs(lines) do
        gpu.set(0, y - i, line)
    end
end


return DebugUtils