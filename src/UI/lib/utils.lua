local gpu = require("component").gpu
local utils = {}


-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function utils.tprint (tbl, indent)
    gpu.setActiveBuffer(0)
    if not indent then indent = 0 end
    if indent >= 4 then return "" end
    for k, v in ipairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            utils.tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

function utils.serializeTableNoCycles(t)
    local seen = {} -- Table to track visited tables

    local function serialize(tbl)
        if seen[tbl] then
            -- Handle cyclic reference by printing the first field of the cyclic table
            local firstFieldKey, firstFieldValue = next(tbl)
            if firstFieldKey then
                local keyStr = '"' .. tostring(firstFieldKey) .. '"'
                local valueStr
                if type(firstFieldValue) == "string" then
                    valueStr = '"' .. firstFieldValue .. '"'
                else
                    valueStr = tostring(firstFieldValue)
                end
                return "{" .. keyStr .. ":" .. valueStr .. "}" -- Serialize the first field
            else
                return '"/* empty cyclic table */"'
            end
        end

        seen[tbl] = true -- Mark the current table as visited

        local result = {}
        for key, value in pairs(tbl) do
            -- Serialize the key
            local keyStr = '"' .. tostring(key) .. '"'

            -- Serialize the value
            local valueStr
            if type(value) == "table" then
                valueStr = serialize(value) -- Recursively serialize nested tables
            elseif type(value) == "string" then
                valueStr = '"' .. value .. '"'
            else
                valueStr = tostring(value)
            end

            table.insert(result, keyStr .. ":" .. valueStr)
        end

        return "{" .. table.concat(result, ", ") .. "}"
    end

    return serialize(t)
end

function utils.removeLoops(t)
    local seen = {} -- Table to track visited tables

    local function process(tbl)
        if seen[tbl] then
            -- Mark cyclic references with a special indicator in the table
            return { "__cyclic_reference__" }
        end

        seen[tbl] = true -- Mark the current table as visited

        local result = {}
        for key, value in pairs(tbl) do
            -- Process the key
            local processedKey = tostring(key)

            -- Process the value
            local processedValue
            if type(value) == "table" then
                processedValue = process(value) -- Recursively process nested tables
            elseif type(value) == "string" then
                processedValue = value
            else
                processedValue = tostring(value)
            end

            result[processedKey] = processedValue
        end

        return result
    end

    return process(t)
end


function utils.round(n)
    return math.floor(n + 0.5)
end

return utils