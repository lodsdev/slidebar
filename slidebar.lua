--[[credits:

    author: LODS,
    description: "A simple slidebar",
    version: "1.0"

]]--

-- small optimizations
local tblInsert = table.insert
local tblRemove = table.remove
local strFormat = string.format
local floor = math.floor
local tblMax = table.maxn
local max = math.max
local min = math.min

local screenW, screenH = guiGetScreenSize()

local inputHover
local scrollInput = {}

scrollInput.inputs = {}

-- create the scroll input
function createScrollInput(x, y, width, height, radiusBorder, minValue, maxValue, circleScale, postGUI)
    if (not (x or y)) then
        local input = (not x and "Erro no argumento #1. Defina uma posição X") or (not y and "Erro no argumento #2. Defina uma posição Y")
        error(input, 2)
    end
    if (not (width or height)) then
        local input = (not width and "Erro no argumento #3. Defina uma largura") or (not height and "Erro no argumento #4. Defina uma altura")
        error(input, 2)
    end
    if ((width == 0) or (height == 0)) then
        local input = ((width == 0) and "Erro no argumento #3. Defina uma largura maior que 0") or ((height == 0) and "Erro no argumento #4. Defina uma altura maior que 0")
        error(input, 2)
    end
    if (minValue > maxValue) then
        error("Erro no argumento #5. O valor mínimo não pode ser maior que o valor máximo.", 2)
    end
    if (maxValue < minValue) then
        error("Erro no argumento #6. O valor máximo não pode ser menor que o valor mínimo.", 2)
    end

    radius = radiusBorder and height/2 or 0
    circleScale = circleScale or 10
    circleRadius = circleScale / 2 or 5

    local newX, newY = circleScale / 2, circleScale / 2

    local rawDataCircle = strFormat([[
        <svg width="%s" height="%s" xmlns="http://www.w3.org/2000/svg">
            <circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" />
        </svg>
    ]], circleScale, circleScale, newX, newY, circleRadius)

    local rawDataBar = strFormat([[
        <svg width="%s" height="%s" xmlns="http://www.w3.org/2000/svg">
            <rect rx="%s" width="%s" height="%s" fill="#FFFFFF" />
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
        selectedBarColor = tocolor(255, 255, 255, 255),
        selectedBarColorHover = tocolor(255, 255, 255),
        unselectedBarColor = tocolor(255, 255, 255, 255),
        circleColor = tocolor(255, 255, 255, 255),
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

    dxSetTextureEdge(datas.circle, "mirror")
    dxSetTextureEdge(datas.barInput, "mirror")
    setmetatable(datas, {__index = scrollInput})
    tblInsert(scrollInput.inputs, datas)

    if (tblMax(scrollInput.inputs) == 1) then
        addEventHandler('onClientRender', root, renderScrollInput, false, 'low-5')
        addEventHandler('onClientClick', root, clickScrollInput, false, 'low-5')
    end
    return datas
end

-- create vector images for the scroll input
local function dxDrawSVG(svg, x, y, width, height, color, postGUI)
    if (not svg) then
        error('Erro no argumento #1. Defina um svg.', 2)
    end
    if (not (width or height)) then
        local input = (not width and 'Erro no argumento #2. Defina uma largura') or (not height and 'Erro no argumento #3. Defina uma altura')
        error(input, 2)
    end

    dxSetBlendMode('add')
    dxDrawImage(x, y, width, height, svg, 0, 0, 0, color, postGUI)
    dxSetBlendMode('blend')
end

-- render the scroll input
function renderScrollInput()
    if (not scrollInput.inputs or (not (#scrollInput.inputs > 0))) then
        return
    end

    inputHover = nil

    for _, self in ipairs(scrollInput.inputs) do
        local circleY = self.y + ((self.height / 2) - (self.circleScale / 2))
        local barSelectedColor = self.selectedBarColor
        local value = ((self.circlePos - self.x) / self.width) * 100
        local barValue = self.width/100 * value

        if (isCursorOnElement(self.x, self.y, ((barValue + self.circleScale) * self.width) / 100, self.height) or isCursorOnElement(self.circlePos - (self.circleScale/2), circleY, self.circleScale, self.circleScale)) then
            barSelectedColor = self.selectedBarColorHover
        end

        if (isCursorOnElement(self.x, self.y, self.width, self.height)) then
            inputHover = self
        end

        if (self.scrolling) then
            local mx, _ = getCursorPosition()
            local cursorX = mx * screenW

            self.circlePos = max(self.x, min((self.x + self.width), cursorX))
            self.scrollOffset = floor(max(self.minValue, min(self.maxValue, ((self.circlePos - self.x) / self.width) * 100)))
            
            if (self.scrollOffset < 0) then
                self.scrollOffset = 0
            end
            if (self.scrollOffset > 100) then
                self.scrollOffset = 100
            end

            if (self.scroll_event) then
                self.scroll_event(self.scrollOffset)
            end

            barSelectedColor = self.selectedBarColorHover
        end

        dxDrawSVG(self.barInput, self.x, self.y, self.width, self.height, self.unselectedBarColor, self.postGUI) -- unselectedBar
        dxDrawSVG(self.barInput, self.x, self.y, barValue, self.height, barSelectedColor, self.postGUI) -- selectedBar
        dxDrawSVG(self.circle, self.circlePos - (self.circleScale/2), circleY, self.circleScale, self.circleScale, self.circleColor, self.postGUI) -- circle

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
    end
end

-- function to check if the cursor is on the element and change the position of circle
function clickScrollInput(b, s)
    if (not scrollInput.inputs or (not (#scrollInput.inputs > 0))) then
        return
    end

    if (b == 'left' and s == 'down') then
        if (inputHover) then
            local mx, _ = getCursorPosition()
            local cursorX = mx * screenW

            inputHover.circlePos = max(inputHover.x, min((inputHover.x + inputHover.width), cursorX))
            inputHover.scrollOffset = floor(((inputHover.circlePos - inputHover.x) / inputHover.width) * 100)

            if (inputHover.scrollOffset < 0) then
                inputHover.scrollOffset = 0
            end
            if (inputHover.scrollOffset > 100) then
                inputHover.scrollOffset = 100
            end

            if (inputHover.scroll_event) then
                inputHover.scroll_event(inputHover.scrollOffset)
            end
        end
    end
end

-- function to destroy the scroll input
function scrollInput:destroy()
    if (not self) then
        error("Erro no argumento #1. Defina um objeto.", 2)
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
        removeEventHandler('onClientRender', root, renderScrollInput)
        removeEventHandler('onClientClick', root, clickScrollInput)
    end
end

-- function to set scrolloffset
function scrollInput:setScrollOffset(value)
    if (not self) then
        error("Erro no argumento #1. Defina um objeto.", 2)
    end

    if (not value) then
        error("Erro no argumento #2. Defina um valor.", 2)
    end

    if (value < 0) then
        value = 0
    end
    if (value > 100) then
        value = 100
    end

    self.scrollOffset = value
    self.circlePos = self.x + ((self.width / 100) * self.scrollOffset)
end

-- function to get the scroll input
function scrollInput:onScroll(func)
    self.scroll_event = func
end

-- function to get output the scroll input
function scrollInput:onScrollEnd(func)
    self.scrollEnd_event = func
end

function isCursorOnElement(x, y, w, h)
    if (not isCursorShowing()) then return end
    local cursor = {getCursorPosition ()}
    local mx, my = cursor[1] * screenW, cursor[2] * screenH
    return (mx >= x and mx <= x + w and my >= y and my <= y + h)
end
