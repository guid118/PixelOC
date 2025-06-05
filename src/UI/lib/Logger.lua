local component = require("component")
local fs = component.filesystem

local Logger = {}
local logFile = "/ui_debug.log"
local logHandle = nil  -- Will hold the file handle for buffered writing
local logLevels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    NONE = 5
}

local currentLevel = logLevels.DEBUG

function Logger.setLogLevel(level)
    if type(level) == "string" then
        currentLevel = logLevels[level:upper()] or logLevels.DEBUG
    end
end

function Logger.getLogLevel()
    for name, level in pairs(logLevels) do
        if level == currentLevel then
            return name
        end
    end
    return "UNKNOWN"
end

local function getLogFile()
    if not logHandle then
        logHandle = io.open(logFile, "a")
        if not logHandle then
            io.stderr:write(string.format("[%s] ERROR: Failed to open log file: %s\n", 
                os.date("%H:%M:%S"), 
                logFile))
            return nil
        end
    end
    return logHandle
end

local function writeToFile(message)
    local file = getLogFile()
    if not file then return false end
    
    local success, err = pcall(function()
        file:write(message .. "\n")
        file:flush()  -- Ensure it's written to disk
        return true
    end)
    
    if not success then
        -- If writing fails, try to reopen the file
        logHandle = nil
        file = getLogFile()
        if file then
            success = pcall(function()
                file:write(message .. "\n")
                file:flush()
                return true
            end)
        end
    end
    
    if not success then
        io.stderr:write(string.format("[%s] ERROR: Failed to write to log: %s\n", 
            os.date("%H:%M:%S"), 
            tostring(err) or "unknown error"))
        return false
    end
    
    return true
end

local function formatMessage(level, message, ...)
    -- Convert all arguments to strings first
    local args = {}
    for i = 1, select('#', ...) do
        table.insert(args, tostring(select(i, ...)))
    end
    
    -- Safe string formatting
    local success, result = pcall(function()
        return message:gsub("%%([%a%%])", function(s)
            if s == "%%" then return "%" end
            if #args == 0 then return "[missing]" end
            return table.remove(args, 1) or "[nil]"
        end)
    end)
    
    if not success then
        return string.format("[%s] %s: [Invalid format: %s] %s", 
            os.date("%H:%M:%S"), 
            level, 
            tostring(message),
            table.concat(args, " "))
    end
    
    return string.format("[%s] %s: %s", 
        os.date("%H:%M:%S"),
        level,
        result
    )
end

local function log(level, message, ...)
    if logLevels[level] < currentLevel then return end
    
    -- Convert all arguments to strings and format the message
    local logMsg
    if type(message) ~= "string" then
        logMsg = string.format("[%s] %s: %s", 
            os.date("%H:%M:%S"), 
            level, 
            tostring(message))
    else
        logMsg = formatMessage(level, message, ...)
    end
    
    -- Write to file and console
    writeToFile(logMsg)
    --print(logMsg)
end

-- Log level functions
Logger.debug = function(message, ...)
    return log("DEBUG", message, ...)
end

Logger.info = function(message, ...)
    return log("INFO", message, ...)
end

Logger.warn = function(message, ...)
    return log("WARN", message, ...)
end

Logger.error = function(message, ...)
    return log("ERROR", message, ...)
end

-- Force flush any pending writes to disk
function Logger.flush()
    if logHandle then
        pcall(logHandle.flush, logHandle)
    end
end

-- Close the log file
function Logger.close()
    if logHandle then
        pcall(logHandle.flush, logHandle)
        pcall(logHandle.close, logHandle)
        logHandle = nil
    end
end

-- Set up a default close handler
local function onExit()
    Logger.close()
end

-- Register the exit handler if possible
pcall(function()
    local event = require("event")
    if event then
        event.listen("interrupted", onExit)
    end
end)

return Logger
