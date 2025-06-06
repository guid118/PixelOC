-- normal_UITest.txt

local event = require("event")
local component = require("component")
local gpu = component.gpu
local os = require("os") -- for os.sleep for button feedback
local thread = require("thread")
local Logger = require("UI.lib.Logger")

-- UI Elements
local ColoredRegion = require("UI.elements.ColoredRegion")
local Label = require("UI.elements.Label")
local Button = require("UI.elements.control.Button")
local CheckBox = require("UI.elements.control.CheckBox")
local ToggleButton = require("UI.elements.control.ToggleButton")
local TextField = require("UI.elements.control.TextField")
local Draggable = require("UI.elements.control.Draggable")
local ScrollBar = require("UI.elements.control.ScrollBar")
local Pane = require("UI.elements.panes.Pane")
local TabPane = require("UI.elements.panes.TabPane") -- Added
local ScrollPane = require("UI.elements.panes.ScrollPane") -- Added

-- UI Utils
local ColorUtils = require("UI.lib.ColorUtils")

-- Global/Upvalue for the label instance needed by a callback in the top-right pane
local paneChildLabelInstance = nil

--region Callbacks
-- --- Callbacks ---
local function buttonClick(button)
    local originalText = button:getText()
    button:setText("Clicked!")
    os.sleep(0.2)
    button:setText(originalText)
end

local function checkBoxOff(checkbox) end
local function checkBoxOn(checkbox) end
local function toggleButtonOff(toggleButton) end
local function toggleButtonOn(toggleButton) end
local function textFieldChanged(textField, oldText, newText) end
local function textFieldSubmit(textField) end
local function onDraggableMove(draggableInstance, newX, newY) end
local function onDraggableDrop(draggableInstance, finalX, finalY) end
local function onDraggableBoundsClick(draggableInstance, targetX, targetY) end
local function scrollBarChanged(scrollbar, newValue) end

local shouldQuitProgram = false
local function quitButtonClick()
    print("Quit button clicked. Signaling shutdown...")
    shouldQuitProgram = true
end

local function paneButtonClickCallback(button) -- Uses paneChildLabelInstance
    if paneChildLabelInstance then
        paneChildLabelInstance:setText("Pane Btn Mod!")
    end
    local originalText = button:getText()
    button:setText("P-Clicked!")
    os.sleep(0.5)
    button:setText(originalText)
    if paneChildLabelInstance then
        os.sleep(0.5)
        paneChildLabelInstance:setText("Label in Pane")
    end
end
--endregion

--region UI Initialization Sub-functions

local function _initBasicFlowElements(elementsToReturn, currentYPos, spacing)
    local yPos = currentYPos

    local coloredRegion = ColoredRegion:new(1, yPos, 10, 5, ColorUtils:new(0xFF0000, false)) -- Red
    table.insert(elementsToReturn, coloredRegion)
    yPos = yPos + coloredRegion.height + spacing

    local label = Label:new(1, yPos, 20, 3, ColorUtils:new(0x00FF00, false), "Test Label", ColorUtils:new(0x000000, false))
    table.insert(elementsToReturn, label)
    yPos = yPos + label.height + spacing

    local button = Button:new(1, yPos, 12, 3, ColorUtils:new(0x0000FF, false), "Click Me", ColorUtils:new(0xFFFFFF, false), buttonClick)
    table.insert(elementsToReturn, button)
    yPos = yPos + button.height + spacing

    return yPos
end

local function _initControlFlowElements(elementsToReturn, currentYPos, spacing)
    local yPos = currentYPos

    local checkBox = CheckBox:new(
            2, yPos, 4, 3, ColorUtils:new(0x808080, false),
            checkBoxOff, checkBoxOn, true
    )
    table.insert(elementsToReturn, checkBox)

    local toggleButton = ToggleButton:new(
            checkBox.x + checkBox.width + spacing, yPos, 15, 3,
            ColorUtils:new(0xFF8C00, false), ColorUtils:new(0x32CD32, false),
            "Disabled", "Enabled",
            ColorUtils:new(0xFFFFFF, false), ColorUtils:new(0x000000, false),
            toggleButtonOff, toggleButtonOn, false
    )
    table.insert(elementsToReturn, toggleButton)
    yPos = yPos + checkBox.height + spacing

    return yPos
end

local function _initTextFieldFlowElements(elementsToReturn, currentYPos, spacing)
    local yPos = currentYPos

    local textField1 = TextField:new(1, yPos, 25, 1, ColorUtils:new(0x404040, false), "Edit me!", ColorUtils:new(0xFFFFFF, false), 30)
    textField1.onTextChanged = textFieldChanged
    textField1.onSubmit = textFieldSubmit
    table.insert(elementsToReturn, textField1)
    yPos = yPos + textField1.height + spacing

    local textField2 = TextField:new(1, yPos, 30, 1, ColorUtils:new(0x505050, false), "Another field", ColorUtils:new(0xFFFF00, false))
    table.insert(elementsToReturn, textField2)
    yPos = yPos + textField2.height + spacing

    return yPos
end

local function _initDraggableFlowElement(elementsToReturn, currentYPos, spacing)
    local yPos = currentYPos

    local boundsVis = ColoredRegion:new(1, yPos, 40, 8, ColorUtils:new(0x303030, false))
    local knobVis = ColoredRegion:new(1, 1, 8, boundsVis.height - 2, ColorUtils:new(0x007ACC, false))
    local draggableElement = Draggable:new(boundsVis, knobVis)
    draggableElement.onDragMove = onDraggableMove
    draggableElement.onDragDrop = onDraggableDrop
    table.insert(elementsToReturn, draggableElement)
    yPos = yPos + boundsVis.height + spacing

    return yPos
end

local function _initTopRightLegacyPane(elementsToReturn, screenWidth)
    -- This is the original simple Pane that was positioned top-right
    local paneWidth = 50
    local paneHeight = 14
    local paneX = screenWidth - paneWidth - 2
    local testPane = Pane:new(paneX, 2, paneWidth, paneHeight, ColorUtils:new(0x343434, false))

    local paneChildRegion = ColoredRegion:new(1, 1, 10, 3, ColorUtils:new(0xAAAAAA, false))
    testPane:addChild(paneChildRegion)

    -- paneChildLabelInstance is an upvalue
    paneChildLabelInstance = Label:new(12, 1, paneWidth - 14, 1, testPane.color, "Label in Pane", ColorUtils:new(0xEEEEEE, false))
    testPane:addChild(paneChildLabelInstance)

    local paneChildButton = Button:new(
            2, paneChildRegion.y + paneChildRegion.height + 1, paneWidth - 4, 3,
            ColorUtils:new(0x00AACC, false), "Pane Button", ColorUtils:new(0xFFFFFF, false),
            paneButtonClickCallback
    )
    testPane:addChild(paneChildButton)

    local draggableBoundsVis = ColoredRegion:new(2, paneChildButton.y + paneChildButton.height + 1, paneWidth - 4, 5, ColorUtils:new(0x303030, false))
    local draggableKnobVis = ColoredRegion:new(draggableBoundsVis.x + 1, draggableBoundsVis.y + 1, 8, draggableBoundsVis.height - 2, ColorUtils:new(0x007ACC, false))
    local innerDraggable = Draggable:new(draggableBoundsVis, draggableKnobVis)
    innerDraggable.onDragMove = onDraggableMove
    innerDraggable.onDragDrop = onDraggableDrop
    testPane:addChild(innerDraggable)

    table.insert(elementsToReturn, testPane)
    -- This pane is positioned absolutely, so it doesn't affect yPos flow.
end

local function _initStandaloneScrollBar(elementsToReturn)
    local scrollBarX = 45
    local scrollBarY = 1
    local scrollBarWidth = 3
    local scrollBarHeight = 20
    local sbBgColor = ColorUtils:new(0x333333, false)    -- For ScrollBar component background
    local sbThumbColor = ColorUtils:new(0x888888, false) -- For Thumb
    local sbButtonColor = ColorUtils:new(0x555555, false) -- For Buttons

    -- Prepare the colors table for the new ScrollBar constructor
    local scrollBarComponentColors = {
        background = sbBgColor,                        -- ScrollBar's own background
        track      = ColorUtils:new(0x404040, false),  -- Default distinct track color
        thumb      = sbThumbColor,                     -- Thumb color
        button     = sbButtonColor,                    -- Button color
        buttonText = ColorUtils:new(0xFFFFFF, false)   -- Default button text color
    }

    -- The scrollBarChanged callback function should be defined elsewhere in your UITest file.
    -- For example: local function scrollBarChanged(scrollbar, newValue) print("Standalone Scrollbar:", newValue) end

    local myScrollBar = ScrollBar:new(
            scrollBarX, scrollBarY, scrollBarWidth, scrollBarHeight, -- x, y, width, height
            "vertical",                                -- orientation
            scrollBarComponentColors,                  -- colors table
            0,                                         -- minValue (defaulted)
            200,                                       -- maxValue (from old 7th param)
            20,                                        -- initialValue (from old 8th param)
            3,                                         -- stepValue (from old 5th param)
            scrollBarChanged                           -- onValueChangedCallback
    )
    myScrollBar.onValueChanged = scrollBarChanged
    table.insert(elementsToReturn, myScrollBar)
    -- Positioned absolutely, no yPos change.
end

local function _initMainTabPaneWithScrollPane(elementsToReturn, currentYPos, spacing, screenWidth)
    local yPos = currentYPos

    local tpX = 1
    local tpY = yPos
    local tpWidth = screenWidth - 25
    local tpHeight = 20 -- Increased height to better showcase ScrollPane

    local tabPaneInstance = TabPane:new(
            tpX, tpY, tpWidth, tpHeight,
            ColorUtils:new(0x2D2D2D, false), 3,
            ColorUtils:new(0x454545, false), ColorUtils:new(0xE0E0E0, false),
            ColorUtils:new(0x606060, false)
    )

    -- Content for Tab 1 (Simple Info)
    local tab1ContentWidth = tpWidth
    local tab1ContentHeight = tpHeight - tabPaneInstance.tabHeight
    local tab1Content = Pane:new(1, 1, tab1ContentWidth, tab1ContentHeight, ColorUtils:new(0x3333AA, false))
    local tab1Label = Label:new(2, 2, 20, 1, tab1Content.color, "Content of Tab 1", ColorUtils:new(0xFFFFFF, false))
    tab1Content:addChild(tab1Label)
    tabPaneInstance:addTab("Info", tab1Content)

    -- Content for Tab 2 (Simple Settings)
    local tab2Content = Pane:new(1, 1, tab1ContentWidth, tab1ContentHeight, ColorUtils:new(0xAA3333, false))
    local tab2Label = Label:new(2, 2, 30, 1, tab2Content.color, "Settings (Tab 2)", ColorUtils:new(0xFFFFFF, false))
    tab2Content:addChild(tab2Label)
    local tab2Button = Button:new(2, 4, 18, 3, ColorUtils:new(0x008800, false), "Do Something", ColorUtils:new(0xFFFFFF, false),
            function() tab2Label:setText("T2 Clicked!") os.sleep(0.5) tab2Label:setText("Settings (Tab 2)") end)
    tab2Content:addChild(tab2Button)
    local textFieldX = 2
    local textFieldY = tab2Button.y + tab2Button.height + 1 -- Position it below the button with 1 row spacing
    local textFieldWidth = 30 -- Or tab1ContentWidth - textFieldX - 1 if you want it to span more
    local textFieldHeight = 3 -- Standard height for a text field with a border, or 1 if just a line
    local textFieldBgColor = ColorUtils:new(0x3A3A3A, false) -- A dark background for the text field
    local textFieldInitialText = "Type here..."
    local textFieldTextColor = ColorUtils:new(0xE0E0E0, false) -- Light text color
    local textFieldMaxLength = 25

    -- Ensure the TextField fits within the tab content area height
    if textFieldY + textFieldHeight -1 > tab1ContentHeight then
        Logger.warn("TextField might be too tall or positioned too low for tab2Content.")
        -- You might want to adjust textFieldY or textFieldHeight here, or make tab1ContentHeight larger
        textFieldHeight = math.max(1, tab1ContentHeight - textFieldY + 1) -- Adjust height to fit
    end

    if textFieldWidth > 0 and textFieldHeight > 0 then -- Only add if dimensions are valid
        local settingsTextField = TextField:new(
                textFieldX,
                textFieldY,
                textFieldWidth,
                textFieldHeight,
                textFieldBgColor,
                textFieldInitialText,
                textFieldTextColor,
                textFieldMaxLength
        )
        tab2Content:addChild(settingsTextField)
    else
        Logger.warn("Skipping TextField creation due to invalid dimensions for tab2Content.")
    end
    tabPaneInstance:addTab("Settings", tab2Content)



    -- Create ScrollPane Tab (Tab 3)
    local scrollBarSpecificColors = {
        background = ColorUtils:new(0x333333, false),  -- Default from ScrollPane's definition for scrollBarColors.background
        track      = ColorUtils:new(0x404040, false),  -- Mapped from old 'bgColor'
        thumb      = ColorUtils:new(0x909090, false),  -- Mapped from old 'thumbColor'
        button     = ColorUtils:new(0x606060, false),  -- Mapped from old 'buttonColor'
        buttonText = ColorUtils:new(0xFFFFFF, false)   -- Default from ScrollPane's definition for scrollBarColors.buttonText
    }

    local scrollPaneForTab = ScrollPane:new(
            1, 1, -- Relative to TabPane's content area
            tab1ContentWidth, tab1ContentHeight, -- ScrollPane takes full content area of the tab
            ColorUtils:new(0x252525, false), -- ScrollPane's own background color
            3, -- Scrollbar width
            scrollBarSpecificColors -- The fully defined scrollBarColors table
    )

    -- Create the tall content for the ScrollPane
    local scrollableContentHeight = 100 -- Make this taller than scrollPaneForTab's view height
    local scrollableContent = Pane:new(
            1, 1, -- Relative to ScrollPane's content view area
            scrollPaneForTab:getContentViewWidth(), -- Changed: Added ()
            scrollableContentHeight,
            ColorUtils:new(0x303040, false)
    )
    local itemY = 1
    for i = 1, 25 do
        local itemLabel = Label:new(2, itemY, scrollPaneForTab:getContentViewWidth(), 1, scrollableContent.color, "Scrollable Item #" .. i, ColorUtils:new(0xCCCCCC, false))
        scrollableContent:addChild(itemLabel)
        itemY = itemY + 2
        if i % 3 == 0 then
            local itemButton = Button:new(5, itemY, scrollPaneForTab:getContentViewWidth(), 3, ColorUtils:new(0x5C5C8A, false), "Btn " .. i, ColorUtils:new(0xFFFFFF, false), -- Changed: Added ()
                    function(btn) local orig = btn:getText() btn:setText("Active " .. i) os.sleep(0.3) btn:setText(orig) end
            )
            scrollableContent:addChild(itemButton)
            itemY = itemY + 4
        end
    end
    scrollPaneForTab:setContentPane(scrollableContent)
    tabPaneInstance:addTab("Scrolling Demo", scrollPaneForTab)

    table.insert(elementsToReturn, tabPaneInstance)
    yPos = yPos + tabPaneInstance.height + spacing
    return yPos
end

local function _initQuitButton(elementsToReturn, screenWidth, screenHeightGPU)
    local quitButton = Button:new(
            screenWidth - 12, screenHeightGPU - 4, 10, 3,
            ColorUtils:new(0xFF4500, false), "QUIT", ColorUtils:new(0xFFFFFF, false),
            quitButtonClick
    )
    table.insert(elementsToReturn, quitButton)
    -- Positioned absolutely, no yPos change.
end

--endregion

-- Initialize UI components
local function initUI()
    local elementsToReturn = {}
    local yPos = 1
    local spacing = 1
    local screenWidth, screenHeightGPU = gpu.getResolution()

    yPos = _initBasicFlowElements(elementsToReturn, yPos, spacing)
    yPos = _initControlFlowElements(elementsToReturn, yPos, spacing)
    yPos = _initTextFieldFlowElements(elementsToReturn, yPos, spacing)
    yPos = _initDraggableFlowElement(elementsToReturn, yPos, spacing)

    -- Absolutely positioned elements, do not affect yPos flow from here
    _initTopRightLegacyPane(elementsToReturn, screenWidth)
    _initStandaloneScrollBar(elementsToReturn)

    -- TabPane is part of the yPos flow
    yPos = _initMainTabPaneWithScrollPane(elementsToReturn, yPos, spacing, screenWidth)

    _initQuitButton(elementsToReturn, screenWidth, screenHeightGPU)

    return elementsToReturn
end

local uiElements = initUI()

--region Main Loop & Event Handling
local function drawAll()
    gpu.freeAllBuffers()
    gpu.setBackground(0x202020, false) -- Main background
    local screenWidth, screenHeight = gpu.getResolution()
    gpu.fill(1, 1, screenWidth, screenHeight, " ")

    for _, element in ipairs(uiElements) do
        if element and type(element.draw) == "function" then
            element:draw(gpu)
        end
    end
end

local function redrawDirtyElements()
    gpu.freeAllBuffers()
    for _, element in ipairs(uiElements) do
        if element and element.needsRedraw and type(element.draw) == "function" then
            element:draw(gpu)
        end
    end
end

local function onTouch(x, y)
    for i = #uiElements, 1, -1 do
        local element = uiElements[i]
        if element and type(element.isCoordinateInRegion) == "function" and element:isCoordinateInRegion(x, y) then
            if type(element.onClick) == "function" then
                element:onClick(x, y)
                return
            end
        end
    end
end

local function touchListener(_, _, x, y)
    thread.create(function() onTouch(x, y) end)
end

local function shutdown()
    print("Shutting down UI test...")
    event.ignore("touch", touchListener)
    for _, element in ipairs(uiElements) do
        if element and type(element.unregisterListeners) == "function" then
            element:unregisterListeners()
        end
    end
    gpu.setBackground(0x000000, false)
    gpu.setForeground(0xFFFFFF, false)
    if gpu.getActiveBuffer and gpu.setActiveBuffer then
        pcall(function() gpu.setActiveBuffer(0) end)
    end
    local width, height = gpu.getResolution()
    print("UITest finished.")
end

local mainThreadQueue = {}
function queueOnMainThread(fn)
    table.insert(mainThreadQueue, fn)
end

local function run()
    drawAll()
    local count = 0
    while not shouldQuitProgram do
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

local function main()
    local ok, err = xpcall(run, function(err_msg)
        pcall(function()
            gpu.setBackground(0x000000, false)
            gpu.setForeground(0xFFFFFF, false)
            if gpu.getActiveBuffer and gpu.setActiveBuffer then
                pcall(function() gpu.setActiveBuffer(0) end)
            end
            local width, height = gpu.getResolution()
            gpu.fill(1, 1, width, height, " ")
            print("Error occurred:")
            print(debug.traceback(err_msg, 2))
        end)
        return err_msg
    end)

    shutdown()
    if not ok then
        print("Program terminated due to an error: " .. tostring(err))
    end
end

event.listen("interrupted", function()
    if not shouldQuitProgram then
        print("Interrupt signal (Ctrl+C) received. Signaling quit...")
        shouldQuitProgram = true
    end
end)

event.listen("touch", touchListener)
main()
--endregion