--region requires
local event = require("event")
local component = require("component")
local gpu = component.gpu
local os = require("os") -- for os.sleep for button feedback
local thread = require("thread")
local Logger = require("UI.lib.Logger")

local OOP = require("UI.OOP")
--endregion

--region MODULE-LEVEL fields (these will be managed by Scene instances)
local _activeSceneUiElements = {} -- Renamed for clarity
local _activeSceneShouldQuit = false -- Renamed for clarity
--endregion

local Scene = OOP.class("Scene")

function Scene:initialize(elements)
    self.instanceUiElements = elements -- Store on the instance if needed for other instance methods
    -- For the module-level functions to work, they need access to these elements.
    -- We'll set them when 'show' is called.
end

--region drawing (These functions use module-level variables)
local function drawAll()
    gpu.setBackground(0x202020, false) -- Main background
    local screenWidth, screenHeight = gpu.getResolution()
    gpu.fill(1, 1, screenWidth, screenHeight, " ")

    for _, element in ipairs(_activeSceneUiElements) do -- Use module-level variable
        if element and type(element.draw) == "function" then
            gpu.freeAllBuffers()
            element:draw(gpu)
        end
    end
end

local function redrawDirtyElements()
    for _, element in ipairs(_activeSceneUiElements) do -- Use module-level variable
        if element and element.needsRedraw and type(element.draw) == "function" then
            gpu.freeAllBuffers()
            element:draw(gpu)
        end
    end
end
--endregion

--region touch listener (Uses module-level variables)
local function onTouch(x, y)
    for i = #_activeSceneUiElements, 1, -1 do -- Use module-level variable
        local element = _activeSceneUiElements[i]
        if element and type(element.isCoordinateInRegion) == "function" and element:isCoordinateInRegion(x, y) then
            if type(element.onClick) == "function" then
                element:onClick(x, y)
                return
            end
        end
    end
end

local function touchListener(_, _, x, y)
    thread.create(function()
        onTouch(x, y)
    end)
end
--endregion

--region Main loop (Uses module-level variables)
local function shutdown()
    print("Shutting down UI test...")
    event.ignore("touch", touchListener) -- Make sure to unregister the one we registered
    for _, element in ipairs(_activeSceneUiElements) do -- Use module-level variable
        if element and type(element.unregisterListeners) == "function" then
            element:unregisterListeners()
        end
    end
    gpu.setBackground(0x000000, false)
    gpu.setForeground(0xFFFFFF, false)
    if gpu.getActiveBuffer and gpu.setActiveBuffer then
        pcall(function()
            gpu.setActiveBuffer(0)
        end)
    end
    local width, height = gpu.getResolution() -- gpu.fill was missing
    gpu.fill(1, 1, width, height, " ")
    print("UITest finished.")
end

local mainThreadQueue = {}
-- This function might be better as a global utility or part of a global event manager
-- if multiple scenes or modules need it. For now, it's fine here.
function queueOnMainThread(fn) -- No 'local' so it's accessible if needed by elements.
    table.insert(mainThreadQueue, fn)
end
_G.queueOnMainThread = queueOnMainThread -- Make it globally accessible for elements

local function run()
    drawAll()
    local count = 0
    while not _activeSceneShouldQuit do -- Use module-level variable
        os.sleep(0.05)
        redrawDirtyElements()
        while #mainThreadQueue > 0 do
            local task = table.remove(mainThreadQueue, 1)
            pcall(task)
        end
        if (count >= 100) then
            drawAll()
            count = 0
        end
        count = count + 1
    end
end

-- Public method for the Scene instance to request a quit
function Scene:requestQuit()
    _activeSceneShouldQuit = true
end

function Scene:show()
    -- Critical: Set the module-level variables to this instance's data
    _activeSceneUiElements = self.instanceUiElements
    _activeSceneShouldQuit = false -- Reset quit flag for this scene's show() call

    -- Register event listeners specific to this scene's lifecycle
    event.listen("touch", touchListener)
    local function interruptHandler()
        if not _activeSceneShouldQuit then
            print("Interrupt signal (Ctrl+C) received. Signaling quit...")
            _activeSceneShouldQuit = true
        end
    end
    event.listen("interrupted", interruptHandler)

    local ok, err = xpcall(run, function(err_msg)
        pcall(function()
            gpu.setBackground(0x000000, false)
            gpu.setForeground(0xFFFFFF, false)
            if gpu.getActiveBuffer and gpu.setActiveBuffer then
                pcall(function()
                    gpu.setActiveBuffer(0)
                end)
            end
            local width, height = gpu.getResolution()
            gpu.fill(1, 1, width, height, " ")
            print("Error occurred:")
            print(debug.traceback(err_msg, 2))
        end)
        return err_msg
    end)

    shutdown() -- This will use _activeSceneUiElements

    -- Clean up listeners specific to this scene's show() call
    event.ignore("touch", touchListener)
    event.ignore("interrupted", interruptHandler)


    if not ok then
        print("Program terminated due to an error: " .. tostring(err))
    end
end
--endregion

-- REMOVE these global event listeners as they are now managed by Scene:show()
-- event.listen("touch", touchListener)
-- event.listen("interrupted", function() ... end)

return Scene