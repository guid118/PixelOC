local component = require("component")
local gpu = component.gpu  -- fallback if not provided

ColorUtils = {}
ColorUtils.__index = ColorUtils

-- Shared static state
ColorUtils.palette = {}
ColorUtils.usedIndices = {}
ColorUtils.nextFree = 0

-- Constructor: create color instance
function ColorUtils:new(color, isPalette)
    local self = setmetatable({}, ColorUtils)
    self.color = color
    self.isPalette = isPalette or false
    return self
end

-- Bind GPU (optional if you want to override the default one)
function ColorUtils.setGPU(gpuObj)
    gpu = gpuObj
end

-- Force set palette color at a given index
function ColorUtils.setPalette(index, color)
    if index < 0 or index > 15 then
        error("Palette index must be in range 0–15")
    end
    gpu.setPaletteColor(index, color)
    ColorUtils.palette[index] = color
    ColorUtils.usedIndices[index] = true
end

-- Request a palette slot for the given RGB color (0xRRGGBB)
function ColorUtils.requestPaletteColor(color)
    -- Reuse if already assigned
    for i = 0, 15 do
        if ColorUtils.palette[i] == color then
            return ColorUtils:new(i, true)
        end
    end

    -- Allocate next available index
    while ColorUtils.nextFree <= 15 do
        if not ColorUtils.usedIndices[ColorUtils.nextFree] then
            local index = ColorUtils.nextFree
            ColorUtils.setPalette(index, color)
            ColorUtils.nextFree = index + 1
            return ColorUtils:new(index, true)
        end
        ColorUtils.nextFree = ColorUtils.nextFree + 1
    end

    error("No free palette indices available")
end

-- Return GPU-compatible values
function ColorUtils:get()
    return self.color, self.isPalette
end

return ColorUtils