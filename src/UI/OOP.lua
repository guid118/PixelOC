-- src/UI/oop.lua
local OOP = {}

-- Create a new class
function OOP.class(name, super)
    local class = {}
    class.__name = name
    class.__index = class

    -- Set up inheritance
    if super then
        setmetatable(class, { __index = super })
        class.super = super
    end

    -- Create a constructor
    function class:new(...)
        local instance = setmetatable({}, class)
        if instance.initialize then
            instance:initialize(...)
        end
        return instance
    end

    return class
end

-- Simple inheritance
function OOP.extends(class, name)
    return setmetatable({}, { __index = class, __call = class.new }), class
end

return OOP