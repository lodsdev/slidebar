-- small optimizations
local tblInsert = table.insert
local tblRemove = table.remove
local strFormat = string.format
local floor = math.floor
local ceil = math.ceil
local tblMax = table.maxn
local max = math.max
local min = math.min
local interpolate = interpolateBetween

local screenW, screenH = guiGetScreenSize()

local scrollInput = {}
local inputHover
local posI, posF
local typeProgress, tickSmooth

scrollInput.inputs = {}

-- create the scroll input
function createSliderBar(x, y, width, height, radiusBorder, minValue, maxValue, circleScale, postGUI)
    if (not (x or y)) then
        local input = (not x and "Error in argument #1. Define a position X") or (not y and "Error in argument #2. Define a position Y")
        warn(input)
    end
    if (not (width or height)) then
        local input = (not width and "Error in argument #3. Define a width") or (not height and "Error in argument #4. Define a height")
        warn(input)
    end
    if ((width == 0) or (height == 0)) then
        local input = ((width == 0) and "Error in argument #3. Define a width greater than 0") or ((height == 0) and "Error in argument #4. Define a height greater than 0")
        warn(input)
    end
    if (minValue > maxValue) then
        warn("Error in argument #5. The min value don't can't be greater than max value")
    end
    if (maxValue < minValue) then
        warn("Error in argument #6. The max value don't can't be smaller than min value")
    end

    radius = radiusBorder and height/2 or 0
    circleScale = circleScale or 10
    circleRadius = circleScale / 2 or 5

    local newX, newY = circleScale / 2, circleScale / 2

    local rawDataCircle = strFormat([[
        <svg width="%s" height="%s" xmlns="http://www.w3.org/2000/svg">
            <circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>
        </svg>
    ]], circleScale, circleScale, newX, newY, circleRadius)

    local rawDataBar = strFormat([[
        <svg width="%s" height="%s" xmlns="http://www.w3.org/2000/svg">
            <rect rx="%s" width="%s" height="%s" fill="#FFFFFF"/>
        </svg>
    ]], width, height, radius, width, height)

    local datas = {
        x = x,
        y = y,
        width = width,
        height = height,
        circlePos = 0,
        minValue = minValue or 0,
        maxValue = maxValue or 100,
        intervalValue = maxValue - minValue,
        radius = radius,
        circleScale = circleScale,
        barColor = {255, 255, 255},
        barColorHover = {255, 255},
        bgBarColor = {255, 255, 255},
        circleColor = {255, 255, 255},
        postGUI = postGUI or false,
        circle = svgCreate(circleScale, circleScale, rawDataCircle),
        barInput = svgCreate(width, height, rawDataBar),
        scrolling = false,
        scrollOffset = 100,
        -- Events Methods
        scroll_event = false,
        scrollEnd_event = false,
        -- Technicals
        endedScrolling = true
    }
    datas.circlePos = (datas.x + datas.width)

    setmetatable(datas, {__index = scrollInput})
    tblInsert(scrollInput.inputs, datas)

    if (tblMax(scrollInput.inputs) == 1) then
        addEventHandler('onClientRender', root, renderSlidebar, false, 'low-5')
        addEventHandler('onClientClick', root, clickSliderBar, false, 'low-5')
        addEventHandler('onClientKey', root, keySliderBar, false, 'low-5')
    end
    return datas
end

-- create vector images for the scroll input
local function dxDrawSVG(svg, x, y, width, height, color, postGUI)
    if (not svg) then
        warn("Error in argument #1. Define a SVG.")
    end
    if (not (width or height)) then
        local input = (not width and 'Error in argument #2. Define a width') or (not height and 'Error in argument #3. Define a height')
        warn(input)
    end

    dxSetBlendMode('add')
    dxDrawImage(x, y, width, height, svg, 0, 0, 0, color, postGUI)
    dxSetBlendMode('blend')
end

-- render the scroll input
function renderSlidebar()
    if (not scrollInput.inputs or (not (#scrollInput.inputs > 0))) then
        return
    end

    inputHover = nil

    for _, self in ipairs(scrollInput.inputs) do
        local circleY = self.y + ((self.height / 2) - (self.circleScale / 2))
        local barSelectedColor = self.barColor
        local value = ((self.circlePos - self.x) / self.width) * 100
        local barValue = self.width/100 * value

        if (typeProgress == 'in_progress') then
            local progress = (getTickCount()-tickSmooth)/250
            local newCirclePos = interpolate(posI, 0, 0, posF, 0, 0, progress, 'Linear')

            if (progress >= 1) then
                typeProgress = nil
                tickSmooth = nil
                posI = nil
                posF = nil
            end

            self.circlePos = newCirclePos
        end

        if (isCursorOnElement(self.x, self.y, ((barValue + self.circleScale) * self.width) / 100, self.height) or isCursorOnElement(self.circlePos - (self.circleScale/2), circleY, self.circleScale, self.circleScale)) then
            barSelectedColor = self.barColorHover
            inputHover = self
        end

        if (isCursorOnElement(self.x, self.y, self.width, self.height)) then
            inputHover = self
        end

        if (self.scrolling) then
            local mx, _ = getCursorPosition()
            local cursorX = mx * screenW

            self.circlePos = clamp(cursorX, self.x, (self.x + self.width))
            self.scrollOffset = floor(clamp(((self.circlePos - self.x) / self.width) * 100, self.minValue, self.maxValue))
            self.scrollOffset = clamp(self.scrollOffset, 0, 100)

            if (self.scroll_event) then
                self.scroll_event(self.scrollOffset)
            end

            barSelectedColor = self.barColorHover
        end

        dxDrawSVG(self.barInput, self.x, self.y, self.width, self.height, tocolor(unpack(self.bgBarColor)), self.postGUI) -- unselectedBar
        dxDrawSVG(self.barInput, self.x, self.y, barValue, self.height, tocolor(unpack(barSelectedColor)), self.postGUI) -- selectedBar
        dxDrawSVG(self.circle, self.circlePos - (self.circleScale/2), circleY, self.circleScale, self.circleScale, tocolor(unpack(self.circleColor)), self.postGUI) -- circle

        if (getKeyState('mouse1')) then
            if (isCursorOnElement(self.circlePos - (self.circleScale/2), circleY, self.circleScale, self.circleScale)) then
                self.scrolling = true
                if (self.endedScrolling) then
                    self.endedScrolling = false
                end
            end
        else
            if (not self.endedScrolling) then
                self.scrolling = false
                self.endedScrolling = true

                if (self.scrollEnd_event) then
                    self.scrollEnd_event(self.scrollOffset)
                end
            end
        end

        dxDrawText(inspect(self.scrollOffset), 300, 300)
    end
end

-- function to check if the cursor is on the element and change the position of circle
function clickSliderBar(button, state)
    if (not scrollInput.inputs or (not (#scrollInput.inputs > 0))) then
        return
    end

    if (inputHover) then
        if (button == 'left' and state == 'down') then
            local mx, _ = getCursorPosition()
            local cursorX = mx * screenW


            if (inputHover.smoothScroll) then
                inputHover.scrollOffset = floor(((inputHover.circlePos - inputHover.x) / inputHover.width) * 100, 0, 100)
                local newCirclePos = clamp(cursorX, inputHover.x, (inputHover.x + inputHover.width))

                typeProgress = 'in_progress'
                tickSmooth = getTickCount()
                posI, posF = inputHover.circlePos, newCirclePos
            else
                inputHover.circlePos = clamp(cursorX, inputHover.x, (inputHover.x + inputHover.width))
                inputHover.scrollOffset = floor(((inputHover.circlePos - inputHover.x) / inputHover.width) * 100, 0, 100)
            end

            if (inputHover.scroll_event) then
                inputHover.scroll_event(inputHover.scrollOffset)
            end
        end
    end
end

-- function to change the offset of slidebar on scroll
function keySliderBar(button, press)
    if (not scrollInput.inputs or (not (#scrollInput.inputs > 0))) then
        return
    end

    if (not press) then return end

    if (inputHover) then
        if (button == 'mouse_wheel_up' and inputHover.scrollOffset < inputHover.maxValue) then
            inputHover.scrollOffset = inputHover.scrollOffset + 1
            inputHover:setScrollOffset(inputHover.scrollOffset)
        elseif (button == 'mouse_wheel_down' and inputHover.scrollOffset > inputHover.minValue) then
            inputHover.scrollOffset = inputHover.scrollOffset - 1
            inputHover:setScrollOffset(inputHover.scrollOffset)
        end
    end
end

-- function to destroy the scroll input
function scrollInput:destroy()
    if (not self) then
        warn("Error in argument #1. Define a object.")
    end

    for i, v in ipairs(scrollInput.inputs) do
        if (v == self) then
            -- free memory
            if (isElement(v.circle)) then
                destroyElement(v.circle)
            end
            if (isElement(v.barInput)) then
                destroyElement(v.barInput)
            end
            tblRemove(scrollInput.inputs, i)
        end
    end

    if (not (tblMax(scrollInput.inputs) > 0)) then
        removeEventHandler('onClientRender', root, renderSlidebar)
        removeEventHandler('onClientClick', root, clickSliderBar)
        removeEventHandler('onClientKey', root, keySliderBar)
    end
end

-- change the width of bar using the value of scrolloffset
function scrollInput:setScrollOffset(value)
    if (not self) then
        warn("Error in argument #1. Define a object.")
    end

    if (not value) then
        warn("Error in argument #2. Defina a value.")
    end

    if (value < 0) then
        value = 0
    end
    if (value > 100) then
        value = 100
    end

    if (self.smoothScroll) then
        self.scrollOffset = value
        local newCirclePos = self.x + ((self.width / 100) * self.scrollOffset)
        
        typeProgress = 'in_progress'
        tickSmooth = getTickCount()
        posI, posF = self.circlePos, newCirclePos
    else
        self.scrollOffset = value
        self.circlePos = self.x + ((self.width / 100) * self.scrollOffset)
    end
end

-- function to get the scroll input
function scrollInput:onScroll(func)
    self.scroll_event = func
end

-- function to get output the scroll input
function scrollInput:onScrollEnd(func)
    self.scrollEnd_event = func
end

local changeableProperties = {
    ['x'] = true,
    ['y'] = true,
    ['width'] = true,
    ['height'] = true,
    ['minValue'] = true,
    ['maxValue'] = true,
    ['scrollOffset'] = true,
    ['smoothScroll'] = true,
    ['bgBarColor'] = true,
    ['barColor'] = true,
    ['barColorHover'] = true,
    ['circleColor'] = true,
    -- ['strokeCircle'] = true,
    -- ['strokeCircleColor'] = true,
    ['postGUI'] = true,
}

-- function to change the property of scrollbar
---comment
---@param property string
---@param value any
---@return boolean
function scrollInput:setProperty(property, value)
    if (not self) then
        warn("No elements were found.") 
    end

    if (not property or (type(property) ~= 'string')) then
        local input = (not property and "Error in argument #1. Define a property") or (type(property) ~= 'string' and "Error in argument #1. Define a valid property")
        warn(input)
    end

    for propertyIndex, active in pairs(changeableProperties) do
        if (propertyIndex == property) then
            self[propertyIndex] = value
            break
        end
    end
end

-- get the max and min of a value
function clamp(number, min, max)
	if (number < min) then
		return min
	elseif (number > max) then
		return max 
	end
	return number
end

-- function to send error in debugscript
function warn(message)
    return error(tostring(message), 2)
end

-- function to get the mouse position absolute
function isCursorOnElement(x, y, w, h)
    if (not isCursorShowing()) then return end
    local cursor = {getCursorPosition ()}
    local mx, my = cursor[1] * screenW, cursor[2] * screenH
    return (mx >= x and mx <= x + w and my >= y and my <= y + h)
end
