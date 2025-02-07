
---@class ElementUtils
local ElementUtils = {}

--- Function that checks wether the object given is a (distant) inheritor from the base given
--- @param obj any the object to figure out if it is an inheritor
--- @param base any the object to compare to. please use a class reference, not an instance of it.
function ElementUtils.inheritsFrom(obj, base)
    local mt = getmetatable(obj)
    while mt do
        if mt == base then
            return true
        end
        mt = getmetatable(mt) -- Get the metatable of the current metatable
        if mt then
            mt = mt.__index -- Move up the inheritance chain
        end
    end
    return false
end


return ElementUtils