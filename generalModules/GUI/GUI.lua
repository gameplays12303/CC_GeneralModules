---@diagnostic disable: duplicate-set-field

---@diagnostic disable-next-line: undefined-field
local native = type(term) == "function" and term() or type(term.current) == "function" and term.current() or type(term.native) == "function" and term.native() or type(term.native) == "table" and term.native or term
local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect = require and require("generalModules.expect2") or dofile("generalModules/expect2.lua")
local expect_utils = expect
local fm = require and require("generalModules.fm") or dofile("generalModules/fm.lua")
local range = expect.range
local field = expect.field

---@diagnostic disable-next-line: cast-local-type
expect = expect.expect

local terminal_data = getmetatable(native)
---@diagnostic disable-next-line: param-type-mismatch
native = util.table.copy(native)
local GUI
---@diagnostic disable-next-line: param-type-mismatch
local function isColor(color)
    if not util.color.isColor(color)
    then
        error(("%s: invalid color"):format(color),3)
    end
end

local function restorePallet(terminal)
    for i,v in pairs(terminal.color.palette) do
        if util.color.isColor(i)
        then
            native.setPaletteColor(i,table.unpack(v))
        end
    end
end
---@class textbox
local textBox
---@class canvas
local canvas
---@class progress_bar
local progress_bar
---@class interactive
local interactive
---@class button
local button
---@class terminal
local terminal = setmetatable({},{__disabledSetMeta = true})

-- this is a custom terminal and will return a termnial
setmetatable(native,{__index = GUI})
GUI = setmetatable({
    window = {
        x = 1,
        y = 1,
        width = select(1,native.getSize()),
        height = select(2,native.getSize())
    },
    pixels = {},
    color = {back = colors.white,palette = util.table.setUp({},"palette")},
    upDating = true,
    children = setmetatable({},{__mode = "v"})
},{__index = terminal,__ProtectMeta = true})
function GUI.getSize()
    return native.getSize()
end
function GUI.setNatvieTable(Tbl)
    expect(true,1,Tbl,"table","monitor")
    native = util.table.copy(Tbl)
    GUI.terminal.height = select(2,native.getSize())
    GUI.terminal.width = select(1,native.getSize())
end
function GUI.reposition()
    return true
end
function GUI.getRealPos()
    return 1,1
end
function GUI.isUpDating()
    return true
end

--- builds a terminal to draw to
util.table.setUp(GUI,"terminal")

function terminal:reposition(new_x,new_y,new_Parent)
        expect(false,1,new_x,"number")
        expect(false,2,new_y,"number")
        expect(false,5,new_Parent,"terminal","nil")
        local meta = getmetatable(self)
        local Parent = meta.Parent
        do
            local x,y
            if new_Parent
            then
                x,y = new_Parent:getSize()
            else
                x,y = Parent:getSize()
            end
            local Current_X,Current_Y = self:getSize()
            range(1,new_x+(Current_X-1),1,x)
            range(2,new_y+(Current_Y-1),1,y)
        end
        Parent.window.x = new_x
        Parent.window.y = new_y
        if new_Parent
        then
            Parent.children[select(2,util.table.find(Parent.children,self))] = nil
            Parent = new_Parent
            table.insert(Parent.children,self)
        end
        Parent:redraw()
        return true
end

function terminal:getRealPos()
    local current = self
    local RealPosX, RealPosDepth = 0, 0

    while current do
        local x, y = current:getPosition()
        RealPosX = RealPosX + (x - 1)
        RealPosDepth = RealPosDepth + (y - 1)
        local mt = getmetatable(current)
        ---@diagnostic disable-next-line: cast-local-type
        current = mt and mt.Parent or nil
    end

    -- Add 1 to shift from zero-based to one-based position at the root
    return RealPosX + 1, RealPosDepth + 1
end
function terminal:isUpDating()
    local Parent = getmetatable(self).Parent
    while Parent do
        if not Parent.upDating then
            -- Found a parent NOT updating: child is NOT updating
            return false
        end
        local mt = getmetatable(Parent)
        Parent = mt and mt.Parent or nil
    end
    -- All parents are updating (or no parents): return own upDating
    return self.upDating
end
function terminal:redrawParent()
    local Parent = getmetatable(self).Parent
    return Parent:redraw()
end

-- this creates a new instance of the Parent terminal and then stores the new terminazl as a child in the Parent
-- the child table is a weak table meaning when you close the textBox the garbage will clean it out
---comment
---@param positionX number
---@param positionY number
---@param nWidth number
---@param nHeight number
---@param Visible boolean|nil
function terminal:create(positionX,positionY,nWidth,nHeight,Visible)
    expect(true,0,self,"terminal")
    expect(false,1,positionX,"number")
    expect(false,2,positionY,"number")
    expect(false,3,nWidth,"number")
    expect(false,4,nHeight,"number")
    expect(false,5,Visible,"boolean","nil")
    positionX = math.floor(positionX+0.5)
    positionY = math.floor(positionY+0.5)
    nWidth = math.floor(nWidth+0.5)
    nHeight = math.floor(nHeight+0.5)
    local instance
    do -- checks the termSize
        local Parent_X,Parent_Y = self:getSize()
        if Parent_Y < 0
        then
            error("check",2)
        end
        range(1,positionX,1,Parent_X)
        range(2,positionY,1,Parent_Y)
        range(3,nWidth,1,Parent_X)
        range(4,nHeight,1,Parent_Y)
    end
    local Parent = self
    instance = setmetatable({
        window = {
            x = positionX,
            y = positionY,
            width = nWidth,
            height = nHeight,
        },
        color = {back = colors.white,palette = util.table.copy(Parent.color.palette,true)},
        upDating = Visible or false,
        children = setmetatable({},{__mode = "v"})
    },{__index = terminal,Parent = self})
    util.table.setUp(instance,"terminal")
    if ProtectMeta
    then
        ProtectMeta(instance,util,expect_utils,terminal,textBox,button,progress_bar,interactive)
    end
    table.insert(self.children,instance)
    if debug and debug.protect
    then
        for _,v in pairs(instance) do
            if type(v) == "function"
            then
                debug.protect(v)
            end
        end
    end
    return instance
end

function terminal:reset()
    expect(true,0,self,"terminal")
    self.children = {}
    self:redraw()
    self:redraw(false)
end

function terminal:getSize()
    return self.window.width,self.window.height
end

function terminal:redraw(_redrawChildren)
    local nativeColor = native.getBackgroundColor()
    if self:isUpDating()
    then
        local RealPosX,RealPosY = self:getRealPos()
        local SizeX,SizeY = self:getSize()
        native.setBackgroundColor(self:getBackgroundColor())
        restorePallet(self)
        for i = 1,SizeY do
            native.setCursorPos(RealPosX,RealPosY+(i-1))
            native.write((" "):rep(SizeX))
        end
        if self.children and type(_redrawChildren) == "nil" or _redrawChildren == true
        then
            for _,v in pairs(self.children) do
                v:redraw()
            end
        end
    end
    native.setBackgroundColor(nativeColor)
end

function terminal:getPosition()
    return self.window.x,self.window.y
end

function terminal:isColor()
    return native.isColor()
end


---@param color number
---@param r number
---@param g number
---@param b number
function terminal:setPaletteColor(color,r,g,b)
    expect(false,1,color,"number")
    isColor(color)
    self.color.palette[color] = table.pack(r,g,b)
end


---@param color number
function terminal:getPaletteColor(color)
    expect(false,1,color,"number")
    isColor(color)
    return table.unpack(self.color.palette[color])
end


---@param color number
function terminal:setBackgroundColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.back = color
end

---@return number
function terminal:getBackgroundColor() 
    return self.color.back
end
function terminal:getCenter()
    local SizeX,SizeY = self:getSize()
    local PosX = math.ceil(SizeX/2)
    local PosY = math.ceil(SizeY/2)
    return ((PosX > 0  and PosX) or 1),((PosY > 0  and PosY) or 1)
end 
---makes the interface live
---@param bTrue boolean
---@return boolean
function terminal:upDate(bTrue)
    expect(false,1,bTrue,"boolean")
    self.upDating = bTrue
    return true
end




do -- just prepares the Parent for use
    for _,v in pairs(colors) do
        if type(v) == "number" and util.color.isColor(v)
        then
            GUI:setPaletteColor(v,native.getPaletteColor(v))
        end
    end
end

---@class canvas
---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
canvas = setmetatable({},{__index = terminal})

function terminal:makeCanv()
    self.pixels = {}
    self.children = nil
    do
        local meta = getmetatable(self)
        meta.__index = canvas
    end
    ---@class canvas
    ---@diagnostic disable-next-line: assign-type-mismatch
    self = self
    util.table.setUp(self,"canvas")
end

do -- canvases functions
    local tColourLookup = {}
    for n = 1, 16 do
        tColourLookup[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
    end
    
    ---loads a nfp file format in the expected format for the canvas
    ---@param sImage_file string
    ---@return table
    function terminal.loadImage(sImage_file)
        expect(false,1,sImage_file,"string")
        if not fs.exists(sImage_file)
        then
            error(("%s:not found"):format(sImage_file),3)
        end
        local result = {image = {{}},Size = {x= 0, y= 0}}
        local ext = util.file.getExtension(sImage_file)
        if ext ~= "nfp"
        then
            error("unknown file expected nfp",2)
        end
        local imageData = fm.readFile(sImage_file,"R")
        if not imageData
        then
            error(("%s:no data"):format(imageData),0)
        end
        local tImage = result.image
        local Size = result.Size
        for sLine in (imageData .. "\n"):gmatch("(.-)\n") do
            local tLine = {}
            for PosX = 1, sLine:len() do
                tLine[PosX] = tColourLookup[string.byte(sLine, PosX, PosX)] or 0
                Size.x = (PosX > Size.x and PosX) or Size.x
            end
            table.insert(tImage, tLine)
        end
        Size.y = #tImage
        return result
    end
    function canvas:drawImage(tImag,positionX,positionY)
        expect(true,0,self,"canvas")
        expect(false,1,tImag,"table")
        positionX = expect(false,2,positionX,"number","nil") or 1
        positionY = expect(false,3,positionY,"number","nil") or 1

        if not tImag.Size
        then
            error("unknown format requires Size Tbl",0)
        end
        local SizeX,SizeY = self:getSize()
        range(0,SizeX,tImag.Size.x)
        range(0,SizeY,tImag.Size.y)
        for depthPos,line in pairs(tImag.image) do
            for lenghPos,color in pairs(line) do
                if color > 0
                then
                    self:setPixel(color,lenghPos+(positionX-1),depthPos+(positionY-1))
                end
            end
        end
        if self:isUpDating()
        then
            self:redraw()
        end
    end
    function canvas:saveImage(sImage_file)
        local file,err = fs.open(util.file.withoutExtension(sImage_file)..".CImage","w")
        local result = ""
        if not file
        then
            error(err)
        end
        local SizeX,SizeY = self:getSize()
        for CurrentY = 1,SizeY do
            if self.pixels[CurrentY]
            then
                for CurrentX = 1,SizeX do
                    local CurrentColor = self.pixels[CurrentY][CurrentX]
                    if CurrentColor
                    then
                        for iD,Color in pairs(colorChar) do
                            if CurrentColor == Color
                            then
                                result = result..tostring(iD)
                                break
                            end
                        end
                    else
                        result = result.." "
                    end
                end
            end
            result = result.."\n"
        end
        file.write(result)
        file.close()
    end
    ---sets a pixel of a given spot to a requested color
    ---@param color number
    ---@paramCursorPosXnumber
    ---@param y number
    function canvas:setPixel(color,x,y)
        expect(true,0,self,"canvas")
        expect(false,1,color,"number")
        expect(false,2,x,"number")
        expect(false,3,y,"number")
        do
            local Rx,Ry = self:getSize()
            range(2,x,0,Rx)
            range(3,y,0,Ry)
        end
        isColor(color)
        self.pixels[y] = self.pixels[y] or {}
        self.pixels[y][x] = color
    end
end

function terminal:clear(_redrawChildren)
    expect(false,1,_redrawChildren,"boolean","nil")
    self.pixels = {}
    self:redraw(_redrawChildren)
end
function canvas:redraw()
    local nativeColor = native.getBackgroundColor()
    if self:isUpDating()
    then
        local RealPosX,RealPosY = self:getRealPos()
        local x,y = self:getSize()
        local CBG = self:getBackgroundColor()
        native.setBackgroundColor(CBG)
        restorePallet(self)
        for i = 1,y do
            native.setCursorPos(RealPosX,RealPosY+i-1)
            for ID = 1,x do
                if self.pixels[i] and self.pixels[i][ID]
                then
                    native.setBackgroundColor(self.pixels[i][ID])
                else
                    native.setBackgroundColor(CBG)
                end
                native.write(" ")
            end
        end
    end
    native.setBackgroundColor(nativeColor)
end

---@class textBox
---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
textBox = setmetatable({},{__index = terminal})

---comment
---@param self textBox
local function isExtended(self)
    local CurrentLine = self:getCurrentLine()
    if not CurrentLine
    then
        return false
    end
    return CurrentLine[#CurrentLine] == true
end

---turns a table into a textBox
---@param self terminal
function terminal:make_textBox(AutoWrap,tab_spaces)
    expect(true,0,self,"terminal")
    expect(false,1,AutoWrap,"boolean","nil")
    expect(false,2,tab_spaces,"number","nil")
    do
        local meta = getmetatable(self)
        meta.__index = textBox
    end
    ---@class textbox
    ---@diagnostic disable-next-line: assign-type-mismatch
    self = self
    util.table.setUp(self,"textBox")
    self.Offset = {}
    self.Offset.x = 0
    self.Offset.y = 0
    self.lines = {}
    self.tab_spaces = tab_spaces and tab_spaces or 4
    self.Cursor = {pos = {x = 1,y = 1},Blink = false}
    self.color.text = colors.black
    self.children = nil
    self.autoWrap = AutoWrap or false
    if AutoWrap
    then
        self.line_isExtended = isExtended
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function textBox:clear()
    self.lines = {}
    self:redraw()
end
function textBox:clearLine()
    local CursorPosY = select(2,self:getCursorPos())
    self.lines[CursorPosY] = {}
    self:redrawLine()
end
function textBox:removeLine()
    local CursorPosY = select(2,self:getCursorPos())
    table.remove(self.lines,CursorPosY)
    self:redraw()
end
function textBox:getCursorBlink()
    return self.Cursor.Blink
end

--fetches the cursorPos
function textBox:getCursorPos()
    return self.Cursor.pos.x,self.Cursor.pos.y
end

---comment
---@return number
function textBox:getTextColor()
    return self.color.text
end
function textBox:getOffset()
    return self.Offset.x,self.Offset.y
end
---@diagnostic disable-next-line: duplicate-set-field
function textBox:redraw()
    if self:isUpDating()
    then
        native.setCursorBlink(false)
        restorePallet(self)
        local SizeX,SizeY = self:getSize()
        local RealPosX,RealPosY = self:getRealPos()
        local offsetX,offsetY = self:getOffset()
        local CX,CY = 1,1
        local CBC = self:getBackgroundColor()
        while true do
            if CX > SizeX
            then
                CX = 1
                CY = CY + 1
                if CY > SizeY
                then
                    break
                end
            end
            local Tbl = (self.lines[CY+offsetY] or {})[CX+offsetX]
            if type(Tbl) ~= "boolean"
            then
                native.setCursorPos(RealPosX+(CX-1),RealPosY+(CY-1))
                if Tbl
                then
                    native.setBackgroundColor(Tbl.color.back)
                    native.setTextColor(Tbl.color.text)
                    native.write(Tbl.Char)
                else
                    native.setBackgroundColor(CBC)
                    native.write(" ")
                end
            end
            CX = CX + 1
        end
        native.setCursorBlink(self:getCursorBlink())
    end
end
function textBox:redrawLine()
    if self:isUpDating()
    then
        native.setCursorBlink(false)
        local y = select(2,self:getCursorPos())
        local offsetX,offsetY = self:getOffset()
        local Tbl = self.lines[y+offsetY] or {}
        offsetY = nil
        local SizeX = self:getSize()
        local Cx,count = 1,1
        restorePallet(self)
        local Y,RealPosX
        do
            local U,RealPosY = self:getRealPos()
            RealPosX = U
            Y = RealPosY+(y-1)
        end
        local CBC,CTC = self:getBackgroundColor(),self:getTextColor()
        while true do
            if Cx > SizeX
            then
                break
            end
            native.setCursorPos(RealPosX+(Cx-1),Y)
            local CT = Tbl[count+offsetX]
            if type(CT) ~= "boolean"
            then
                if not CT
                then
                    native.setBackgroundColor(CBC)
                    native.setTextColor(CTC)
                    native.write(" ")
                else
                    native.setBackgroundColor(CT.color.back)
                    native.setTextColor(CT.color.text)
                    native.write(CT.Char)
                end
            end
            count = count + 1
            Cx = Cx + 1
        end
        native.setCursorBlink(self:getCursorBlink())
    end
end
function textBox:restoreCursor()
    if self:isUpDating()
    then
        restorePallet(self)
        native.setBackgroundColor(self:getBackgroundColor())
        native.setTextColor(self:getTextColor())
        local RealPosX,RealPosY = self:getRealPos()
        local x,y = self:getCursorPos()
        native.setCursorPos(RealPosX+(x-1),RealPosY+(y-1))
        native.setCursorBlink(self:getCursorBlink())
    end
    return true
end
---comment
---@param offsetX number|nil
---@param offsetY number|nil
function textBox:setOffset(offsetX,offsetY)
    expect(false,1,offsetX,"number","nil")
    expect(false,2,offsetY,"number","nil")
    if self:is_wrapped() and offsetX ~= nil
    then
        error("can't set the screen width offset as this is a wapped textBox",2)
    end
    do
        offsetX = offsetX and range(1,offsetX,0)
        offsetY = offsetY and range(2,offsetY,0)
    end
    self.Offset.x = offsetX or self.Offset.x
    self.Offset.y = offsetY or self.Offset.y
    self:redraw()
end
---comment
-- this is used to make a new line to bypass
-- write function that would be required
--this will attach the line to the bottem of the line textBox
function textBox:newLine()
    self.lines[#self.lines+1] = {}
end
---comment
--- enables the cursor view and blinking
---@param bTrue boolean
function textBox:setCursorBlink(bTrue)
    expect(false,1,bTrue,"boolean")
    self.Cursor.Blink = bTrue
end
---comment
--- moves the Cursor to the requested position
---@param nX number|nil
---@param nY number|nil
function textBox:setCursorPos(nX,nY)
    expect(false,1,nX,"number","nil")
    expect(false,2,nY,"number","nil")
    do
        local x,y = self:getSize()
        nX = nX and range(1,nX,1,x)
        nY = nY and range(1,nY,1,y)
    end
    self.Cursor.pos.x = nX or self.Cursor.pos.x
    self.Cursor.pos.y = nY or self.Cursor.pos.y
end

---comment
---@param color number
function textBox:setTextColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.text = color
end


---writes to the text box
---@param sText string
---@param bOverWrite boolean|nil
---@param keepPos boolean|nil
---@return boolean|nil
---@return integer|nil
---@return integer|nil
function textBox:write(sText,bOverWrite,keepPos)
    expect(false,1,sText,"string")
    expect(false,2,bOverWrite,"boolean","nil")
    local windowlengh,windowDepth = self:getSize()
    local CursorPosX,CursorPosY = self:getCursorPos()
    local flagLines = false
    local update = self.upDating
    self:upDate(false)
    do  -- main draw handler
        local result = util.string.split(sText)
        ---@diagnostic disable-next-line: ambiguity-1
        --- writes the sentece to the table
        -- one charator at a time
        local offsetX,offsetY = self:getOffset()
        local wrappedFlag = self:is_wrapped()
        local color_Background,CT = self:getBackgroundColor(),self:getTextColor()
        local function checkLine()
            if type(self.lines[CursorPosY+offsetY]) == "nil"
            then
                self.lines[CursorPosY+offsetY] = {}
            end
        end
        checkLine()
        --- CursorPos management 
        local function handle()
            local Cursor_Size_flag = CursorPosX == windowlengh
            if not wrappedFlag
            then
                if Cursor_Size_flag
                then
                    offsetX = offsetX + 1
                    flagLines = true
                else
                    CursorPosX = CursorPosX + 1
                end
            elseif Cursor_Size_flag
            then
                flagLines = true
                if CursorPosY == windowDepth
                then
                    offsetY = offsetY + 1
                    CursorPosX = 1
                    checkLine()
                else
                    self.lines[CursorPosY+offsetY][windowlengh+1] = true
                    CursorPosY = CursorPosY + 1
                    CursorPosX = 1
                    checkLine()
                end
            else
                CursorPosX = CursorPosX + 1
            end
        end
        --- CursorPos managment for backspace character
        local function erase_update_cursor_routine()
            checkLine()
            if #self.lines[CursorPosY+offsetY+1] == 0
            then
                table.remove(self.lines,CursorPosY+offsetY+1)
            end
            local line = #self.lines[CursorPosY+offsetY]
            if self:is_wrapped()
            then
                line = line-1
            end
            if line > windowlengh
            then
                CursorPosX = windowlengh
                offsetX = math.abs(line-windowlengh)+1
            else
                CursorPosX = line > 0 and line or 1
            end
        end
        --- main loop
        for index=1,#sText do
            if not self.lines[CursorPosY+offsetY]
            then
                self.lines[CursorPosY+offsetX] = {}
            end
            if result[index] == "\b"
            then
                local CursorPosY_greater_flag = CursorPosY > 1
                local CursorPosX_greater_flag = CursorPosX > 1
                local offsetX_flag = offsetX > 0
                local offsetY_flag = offsetY > 0
                if CursorPosY_greater_flag or CursorPosX_greater_flag or offsetX_flag or offsetY_flag
                then
                    if CursorPosX_greater_flag
                    then
                        CursorPosX = CursorPosX - 1
                    elseif offsetX_flag
                    then
                        offsetX = offsetX - 1
                        flagLines = true
                    elseif CursorPosY_greater_flag
                    then
                        CursorPosY = CursorPosY - 1
                        erase_update_cursor_routine()
                    elseif offsetY_flag
                    then
                        offsetY = offsetY - 1
                        flagLines = true
                        erase_update_cursor_routine()
                    end
                    table.remove(self.lines[CursorPosY+offsetY],CursorPosX+offsetX)
                end
            elseif result[index] == "\n"
            then
                flagLines = true
                local moveTBl = {}
                do
                    local CurrentPointer_x = (CursorPosX)+offsetX
                    local currentLine = self.lines[CursorPosY+offsetY]
                    local k
                    while true do
                        k = currentLine[CurrentPointer_x]
                        if type(k) == "boolean"
                        then
                            table.remove(currentLine,CurrentPointer_x)
                            break
                        end
                        if k == nil
                        then
                            break
                        end
                        table.insert(moveTBl,k)
                        table.remove(currentLine,CurrentPointer_x)
                    end
                end
                if CursorPosY == windowDepth
                then
                    offsetY = offsetY + 1
                else
                    CursorPosY = CursorPosY + 1
                end
                CursorPosX = 1
                table.insert(self.lines,CursorPosY+offsetY,moveTBl)
                if offsetX > windowlengh
                then
                    offsetX = 0
                end
            elseif result[index] == "\t"
            then
                local count = 0
                repeat
                    table.insert(self.lines[CursorPosY+offsetY],(CursorPosX+offsetX),{
                        Char = " ",
                        color = {back = color_Background,text = CT}
                    })
                    handle()
                    count = count + 1
                until count == self.tab_spaces
            
            elseif not bOverWrite
            then
                table.insert(self.lines[CursorPosY+offsetY],(CursorPosX+offsetX),{
                    Char = result[index],
                    color = {back = color_Background,text = CT}
                })
                handle()
            else
                self.lines[CursorPosY+offsetY][CursorPosX+offsetX] = {
                    Char = result[index],
                    color = {back = color_Background,text = CT}
                }
                handle()
            end
        end
        if flagLines
        then
            self:setOffset(not self:is_wrapped() and offsetX or nil,offsetY)
        end
        if not keepPos
        then
            self:setCursorPos(CursorPosX,CursorPosY)
        end
    end
    self:upDate(update)
    if self:isUpDating()
    then
        if flagLines
        then
            self:redraw()
        else
            self:redrawLine()
        end
    end
    return flagLines,CursorPosX,CursorPosY
end

--[[
    this is pointing to the Current Cursor Poision.manual_offsetX and manual_offsetY are modiers,
    meaning the function will return what is relaitive
    to the cursor Position and modifers
]]
---@param manual_offsetY number|nil
---@return table|nil
function textBox:getCurrentLine(manual_offsetY)
    manual_offsetY = expect(false,2,manual_offsetY,"number","nil") or 0
    local _,offsetY = self:getOffset()
    local CursorPosY = select(2,self:getCursorPos())
    local Chartemp = self.lines[manual_offsetY+offsetY+CursorPosY]
    return Chartemp and util.table.copy(Chartemp) or nil
end

--[[
    this is how you get a line
]]
---@param manual_offsetX number|nil
---@param manual_offsetY number|nil
---@return table|nil
---@return table|nil
function textBox:getCurrentPixel(manual_offsetX,manual_offsetY)
    manual_offsetX = expect(false,1,manual_offsetX,"number","nil") or 0
    manual_offsetY = expect(false,2,manual_offsetY,"number","nil") or 0
    local offsetX = self:getOffset()
    local CursorPosX = self:getCursorPos()
    local Chartemp = self:getCurrentLine(manual_offsetY)
    return Chartemp and Chartemp[offsetX+CursorPosX+manual_offsetX]
end

---returns a single window line as a string at the current CursorPosition of depth
--- and offset
---@return string|nil
function textBox:getSentence()
    local CurrentTruePos
    do
        local CursorPosY = select(2,self:getCursorPos())
        local OffsetY = select(2,self:getOffset())
        CurrentTruePos = CursorPosY+OffsetY
    end
    local CurrentLine = self.lines[CurrentTruePos]
    if not CurrentLine
    then
        return nil
    end
    local spaceCount = 0
    local ToCountX = #CurrentLine
    local len = self.tab_spaces
    local sRaw = ""
    while true do
        if ToCountX == 0
        then
            if CurrentTruePos == 0
            then
                break
            end
            CurrentTruePos = CurrentTruePos - 1
            local newLine = self.lines[CurrentTruePos]
            if not newLine or #newLine == 0 or newLine[#newLine] ~= true
            then
                break
            end
            ToCountX = #newLine-1
            CurrentLine = newLine
        else
            local char = CurrentLine[ToCountX].Char
            if char == " "
            then
                spaceCount = spaceCount + 1
            end
            sRaw = char..sRaw
            if spaceCount == len
            then
                sRaw = string.sub(sRaw,len+1)
                sRaw = "\t"..sRaw
                spaceCount = 0
            elseif char ~= " "
            then
                spaceCount = 0
            end
            ToCountX = ToCountX - 1
        end
    end
    return sRaw
end
---comment
---@return boolean
function textBox:is_wrapped()
    expect(false,0,self,"table")
    return self.autoWrap or false
end
--  return the window as a string 
---@return string
function textBox:getVersion()
    local sRaw = ""
    local spaceCount = 0
    local len = self.tab_spaces
    for i, y in ipairs(self.lines) do
        local lineFlag = false
        for _,Pos in ipairs(y) do
            if Pos == true
            then
                lineFlag = true
                break
            end
            local Char = Pos.Char
            if Char == " " then
                spaceCount = spaceCount + 1
            else
                spaceCount = 0
            end
            -- Check if spaceCount reaches the set number to convert to tab
            if spaceCount == len  then
                sRaw = string.sub(sRaw,1,#sRaw-len+1).."\t"
                spaceCount = 0  -- Reset spaceCount after converting to tab
            else
                sRaw = sRaw .. Char
            end
        end
        if i ~= #self.lines and not lineFlag
        then
            sRaw = sRaw.."\n"
        end
    end
    return sRaw  -- Return the generated raw version
end



-- turns a terminal into a button
---@class button
---@diagnostic disable-next-line: assign-type-mismatch
button = setmetatable({},{__index = terminal})

---comment
---@param bToggle boolean|nil
---@param _bRawImage boolean|nil
---@return string|number
function terminal:make_button(bToggle,_bRawImage)
    expect(true,0,self,"terminal")
    expect(false,1,bToggle,"boolean","nil")
    ---@class Sub_Window
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.active_window = setmetatable({
        text = "button",
        color = {
            text = colors.red,
            back = colors.yellow,
        },
        self = self,
    },{__index = button})
    ---@class Sub_Window
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.default_window = setmetatable({
        text = "button",
        color = {
            text = colors.blue,
            back = colors.green,
        },
        self = self
    },{__index = button})
    self.toggle = bToggle or false
    self.text = "term"
    self.ID = math.random()
    self.children = nil
    self.active = false
    self.active_info = {
        fn = function ()
            return self.ID
        end,
        argus = {}
    }
    if bToggle
    then
        self.deactive_info = {
            fn = self.active_info.fn,
            arg = self.active_info.argus
        }
    end
    if _bRawImage
    then
        ---@diagnostic disable-next-line: param-type-mismatch
        terminal.makeCanv(self.default)
        ---@diagnostic disable-next-line: param-type-mismatch
        terminal.makeCanv(self.active_window)
        self.default.text = nil
        self.active_window.text = nil
        self.default.color.text = nil
        self.active_window.color.text = nil
        self.default.window = self.window
        self.active_window.window = self.window
    end
    do -- sets the meta system
        local meta = getmetatable(self)
        meta.__index = textBox
    end
    ---@class button 
    ---@diagnostic disable-next-line: assign-type-mismatch
    self = self

    util.table.setUp(self,"button")
    util.table.setUp(self.active_window,"Sub_Window")
    util.table.setUp(self.default_window,"Sub_Window")
    return self.ID
end

---@diagnostic disable-next-line: duplicate-set-field
---@param color number
function button:setTextColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.text = color
end
---@param self Sub_Window
---@param sText string
function button:setText(sText)
    expect(true,0,self,"Sub_Window")
    expect(false,1,sText,"string")
    local terminalLength = self.self:getSize()
    local length = #sText
    if string.sub(sText,1,1) == "["
    then
        sText = string.sub(sText,2)
    end
    if string.sub(sText,length,length) == "]"
    then
        sText = string.sub(sText,1,1)
    end
    if #sText > terminalLength-2
    then
        error("error text too big",2)
    end
    self.text = sText
end


function button:isActive()
    return self.active
end

function button:trigger()
    self.active = not self.active
    self:redraw()
    local result
    if not self.active and self.toggle
    then
        result = table.pack(pcall(self.deactive_info.fn,self.deactive_info.argus and table.unpack(self.deactive_info.argus) or nil))
    else
        result = table.pack(pcall(self.active_info.fn,self.active_info.argus and table.unpack(self.active_info.argus) or nil))
    end
    if not self.toggle
    then
        -- i do hate it but it is nessary to slow down the system as even a yield isn't good enough
        sleep(.1)
        self.active = false
        self:redraw()
    end
    if not result[1]
    then
        return false,result[2]
    end
    return table.unpack(result,2)
end
-- overrides the status of the action_state without triggering the action corresponding to the next state
function button:OverRide_status(bActive)
    expect(false,1,bActive,"boolean","nil")
    if bActive ~= nil
    then
        self.active = bActive
    else
        self.active = not self.active
    end
    self:redraw()
end

--- this handles mouse_click and touch events matching just pass the events to it and it will return true or false (not trigger the button)
function button:isClicked(event,ID,PosX,PosY)
    expect(false,1,event,"string")
    expect(false,2,ID,"string","number","nil")
    expect(false,4,PosX,"number")
    expect(false,5,PosY,"number")
    if self:isUpDating()
    then
        if event == "monitor_touch" and terminal_data == nil
        then
            return false
        elseif event == "mouse_click" and terminal_data ~= nil
        then
            return false
        elseif event == "monitor_touch" and terminal_data.name ~= ID
        then
            return false
        end
        local RealPosX,RealPosDepth = self:getRealPos()
        local SizeX,SizeY = self:getSize()
        if PosX >= RealPosX and PosY >= RealPosDepth and PosX < SizeX+RealPosX and PosY < SizeY+RealPosDepth
        then
            return true
        end
    end
    return false
end

function button:redraw()
    expect(true,0,self,"button","Sub_Window")
    if self:isUpDating()
    then
        local isActive = self:isActive()
        local window = self
        if util.table.getType(self) ~= "Sub_Window"
        then
            if isActive
            then
                window = self.active_window
            else
                window = self.default_window
            end
        end
        local SizeX,SizeY = self:getSize()
        local RealPosX,RealPosDepth = self:getRealPos()
        local Cx,Cy = self:getCenter()
        local CTC = native.getTextColor()
        local CBC = native.getBackgroundColor()
        restorePallet(self)
        native.setBackgroundColor(window.color.back)
        for PosistionY = 1,SizeY do
            for positionX = 1,SizeX do
                native.setCursorPos(RealPosX+(positionX)-1,RealPosDepth+(PosistionY)-1)
                native.write("\t")
            end
        end

        if window.text
        then
            local toDraw = window.text
            if isActive
            then
                toDraw = "["..window.text.."]"
            end
            native.setTextColor(window.color.text or colors.black)
            native.setCursorPos(RealPosX+(Cx-((toDraw:len()/2))),RealPosDepth+Cy-1)
            native.write(toDraw)
        end
        native.setTextColor(CTC)
        native.setBackgroundColor(CBC)

    end
end

function button:setID(_n)
    expect(false,1,_n,"number","string")
    self.ID = _n
end

function button:getID()
    return self.ID
end

---@param fn function
function button:setActivate(fn,...)
    expect(false,1,fn,"function")
    self.active_info.fn = fn
    self.active_info.argus = table.pack(...)
end

---@param fn function
function button:setDeactivate(fn,...)
    expect(false,1,fn,"function")
    self.deactive_info.fn = fn
    self.deactive_info.argus = table.pack(...)
end

--progress Bar
---@class progress_bar
---@diagnostic disable-next-line: assign-type-mismatch
progress_bar = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function progress_bar:redraw()
    local orginBackgroundColor = native.getBackgroundColor()
    local CursorPosX = self:getSize()
    local count = math.floor((self.checkpoints_filled/self.checkpoints)*CursorPosX)
    local absoluteX,absolutelY = self:getRealPos()
    native.setCursorPos(absoluteX,absolutelY)
    native.setBackgroundColor(self:getBackgroundColor())
    native.write((" "):rep(CursorPosX))
    native.setBackgroundColor(self.color.filled)
    native.setCursorPos(absoluteX,absolutelY)
    native.write((" "):rep(count))
    native.setBackgroundColor(orginBackgroundColor)
end
---comment
---@param _n number|nil
function progress_bar:checkPoint(_n)
    expect(false,1,_n,"number","nil")
    if self.checkpoints == self.checkpoints_filled
    then
        error("can't go beyond 100%",2)
    end
    self.checkpoints_filled = self.checkpoints_filled + (_n or 1)
end
function progress_bar:set_fill_Color(color)
    expect(false,1,color,"number")
    self.color.filled = color
end
function terminal:make_progressBar(_nCheckpoints)
    expect(true,0,self,"terminal")
    expect(false,1,_nCheckpoints,"number")
    self.children = nil
    self.checkpoints = _nCheckpoints
    self.checkpoints_filled = 0
    self.color.filled = colors.blue
    self:setBackgroundColor(colors.green)
    local meta = getmetatable(self)
    meta.__index = progress_bar
    ---@class progress_bar 
    ---@diagnostic disable-next-line: assign-type-mismatch
    self = self
    util.table.setUp(self,"progress_bar")
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
    built in functions
    thse come with the module 
    these are basic functions not made for any specific purpose
--]]


do --- builds the Chat_Box UI 
    
    --[[ 
    IMPORTANT:
    Defining `hostHighlight()` fully replaces the internal highlight system.
    If `hostHighlight()` is present, `highlight_keyword()` will NOT be called.
    Make sure to handle all desired highlighting inside `hostHighlight()`,
    as the default behavior will be overridden.
    --]]



    ---@class interactive
    ---@diagnostic disable-next-line: assign-type-mismatch
    interactive = setmetatable({},{__index = textBox})
    --- helper function returns the most recent word on the currentline
    --- not based on CursorPosX only CurrentPosY 
    function interactive:getLastword()
        local line = self:getSentence()
        if not line
        then
            return
        end
        ---@diagnostic disable-next-line: cast-local-type
        local words = util.string.split(line," ")
        return words[#words]
    end
    ---this determinds if it is a highlights_keyword (replace for customization this but return a color code if true) 
    ---@return nil|integer
    function interactive:highlight_keyword()
        local word = self:getLastword()
        if not word
        then
            return
        end
        if not self.keywords
        then
            return 
        end
        field(0,self,"keywords","table")
        for _,v in pairs(self.keywords) do
            if word == v
            then
                self.highlight = {
                    ---@type number
                    color = self.keyword_textColor,
                    ---@type string
                    word = word,
                    start = 1,
                }
            end
        end
    end
    --- this is a handler do not touch 
    function interactive:__handleHighlight()
        self:highlightKeyword()
        if self.highlight
        then
            self:drawHighlight()
        end
        self.highlight = nil
    end
    --- dose the actual high_lighting can be overwritten if overwritten; HIGHLIGHT_KEYWORD WILL NOT BE CALLED YOU MUST CALL IT MANUALLY 
    function interactive:drawHighlight()
        local info = self.highlight
        if info
        then
            self:upDate(false)
            self:write(("\b"):rep(#self.word))
            local currentTextColor = self:getTextColor()
            self:setTextColor(info.color)
            local fullReDraw = self:write(info.word)
            self:setTextColor(currentTextColor)
            self:upDate(true)
            if fullReDraw
            then
                self:redraw()
            else
                self:redrawLine()
            end
        end
    end
    function interactive:getOverWriteStatus()
        return self.OverWrite_status
    end
    function interactive:flipOverWriteStatus()
        self.OverWrite_status = not self.OverWrite_status
    end
    --- this is the default AutoComplete handler
    --- this creates a table and pusheed the matches to self.AutoList
    --- you can replace this but the output must be put in self.AutoList
    function interactive:AutoComplete()
        if not self.AutoOptions
        then
            return
        end
        field(0,self,"AutoOptions","table")
        self.AutoList = nil -- clear out the last list 
        -- Split the word by dots into a hierarchy
        local hierarchy = util.string.split(self:getLastword() or "","%.")
        local currentTable = self.AutoOptions
        local boolNoMatch = false
        -- Iterate through each part of the hierarchy of the line
        -- based on the . 
        for _, value in ipairs(hierarchy) do
            ---@diagnostic disable-next-line: need-check-nil
            local newTable = currentTable[value]
            if newTable == nil  then
                -- If the currentTable returns nil, mark as a possible incomplete match
                boolNoMatch = true
                break
            elseif type(newTable) ~= "table" then
                -- If the value isn't a table, break immediately
                return
            else
                currentTable = newTable
            end
        end
        self.lastNoMatch = boolNoMatch
        local possibleMatches = {}
        if boolNoMatch
        then
            local In_complete_word = hierarchy[#hierarchy]
            for key,value in pairs(currentTable) do
                if type(key) == "number" and string.sub(value, 1, #In_complete_word) == In_complete_word
                then
                    local toSuggest = string.sub(value,#In_complete_word+1)
                    table.insert(possibleMatches, toSuggest ~= "" and toSuggest or nil)
                elseif type(key) == "string"and string.sub(key, 1, #In_complete_word) == In_complete_word
                then
                    local toSuggest = string.sub(key,#In_complete_word+1)
                    table.insert(possibleMatches, possibleMatches, toSuggest ~= "" and toSuggest or nil)
                end
            end
        else
            for key,value in pairs(currentTable) do
                if type(key) == "number" and type(value) == "string"
                then
                    table.insert(possibleMatches,value)
                elseif type(key) == "string"
                then
                    table.insert(possibleMatches,key)
                end
            end
        end
        self.AutoList = possibleMatches
    end
    --- daws the Current selected word from AutoList
    function interactive:_drawAutoComplete()
        if self.autoflag
        then
            return 
        end
        local word = self.currentSel
        if not word
        then
            return
        end
        self:upDate(false)
        local currentTextColor,CurrentBackColor = self:getTextColor(),self:getBackgroundColor()
        self:setTextColor(self.AutoTextColor)
        self:setBackgroundColor(self.AutoBackColor)
        local full_redraw = self:write(word,false,true)
        self:setTextColor(currentTextColor)
        self:setBackgroundColor(CurrentBackColor)
        self:upDate(true)
        if full_redraw
        then
            self:redraw()
        else
            self:redrawLine()
        end
        self.autoflag = true
    end
    --- chooses the a word from the match given by AutoList or your AutoComplete
    function interactive:_chooseWord(n)
            expect(false,1,n,"number")
            range(1,n,-1,1)
            if self.autoflag
            then
                self:AutoClear()
            end
            if not self.AutoList
            then
                return
            end
            self.currentSelNumber = (self.currentSelNumber or 0) + n
            if self.currentSelNumber > #self.AutoList
            then
                self.currentSelNumber = #self.AutoList
            elseif self.currentSelNumber < 0
            then
                self.currentSelNumber = 0
                end
            self.currentSel = self.AutoList[self.currentSelNumber]
            self:_drawAutoComplete()
    end
    --- clear the Current filled AutoWord 
    function interactive:AutoClear()
        if not self.autoflag
        then
            return 
        end
        local terminalSizeLength,terminalSizeDepth = self:getSize()
        local toBeCursorPosition = #self:getCurrentLine()+1
        if toBeCursorPosition > terminalSizeLength
        then
            local CursorPosY = select(2,self:getCursorPos())+1
            toBeCursorPosition = 1
            if CursorPosY > terminalSizeDepth
            then
                self:setCursorPos(1,terminalSizeDepth)
                self:setOffset(nil,select(2,self:getOffset())+1)
            else
                self:setCursorPos(1,CursorPosY)
            end
        else
            self:setCursorPos(toBeCursorPosition)
        end
        self:setCursorPos()
        self:write(("\b"):rep(#self.currentSel))
        self.autoflag = false
    end
    --- accept the CurrentSel as final
    function interactive:AcceptCompletion()
        local word = self.currentSel
        if not self.autoflag
        then
            return
        end
        self.currentSelNumber = 0
        self:AutoClear()
        self:write(word)
    end
    local keyMap = {
        [keys.enter] = function (self)
            if self.autoWrap
            then
                self:AutoClear()
            end
            self:__handleHighlight()
            self:write("\n")
        end,
        [keys.down] = function (self)
            if self.autoflag and self.AutoList
            then
                self:AutoClear()
                self:_chooseWord(1)
            else
                local CursorPosX,CursorPosY = self:getCursorPos()
                local termSizeX,termSizeY = self:getSize()
                local offsetX,offsetY = self:getOffset()
                local redraw = false    
                local tempLines = self:getCurrentLine(1)
                if not tempLines
                then
                    return
                end
                if offsetY > 0 and CursorPosY == termSizeY
                then
                    offsetY = offsetY + 1
                    redraw = true
                elseif tempLines
                then
                    CursorPosY = CursorPosY + 1
                end
                local len = #tempLines
                if len > offsetX+(termSizeX) and not self:is_wrapped()
                then
                    CursorPosX = termSizeX
                    offsetX = (len-termSizeX)+1
                    self:setOffset(offsetX)
                    redraw = true
                elseif CursorPosX+offsetX > len
                then
                    local mth = math.abs(len-offsetX)
                    CursorPosX = mth+1
                end
                self:setOffset(nil,offsetY)
                self:setCursorPos(CursorPosX,CursorPosY)
                if redraw
                then
                    self:redraw()
                end
            end
        end,
        [keys.up] = function (self)
            if self.autoflag and self.AutoList
            then
                self:AutoClear()
                self:_chooseWord(-1)
            else
                local CursorPosX,CursorPosY = self:getCursorPos()
                local offsetX,offsetY = self:getOffset()
                local termSizeX = self:getSize()
                local CurrentY_greator_then_1_flag = CursorPosY > 1
                local offsetY_flag = offsetY > 0
                if not CurrentY_greator_then_1_flag
                then
                    return
                end
                local line_length = self:getCurrentLine(-1)
                if not line_length
                then
                    return
                end
                ---@diagnostic disable-next-line: cast-local-type
                line_length = #line_length+1
                if not self:is_wrapped()
                then
                    if line_length <= termSizeX
                    then
                        offsetX = 0
                        CursorPosX = line_length
                        self:setOffset(offsetX)
                    end
                elseif line_length >= termSizeX
                then
                    CursorPosX = termSizeX
                end
                if offsetY_flag and not CurrentY_greator_then_1_flag
                then
                    offsetY = offsetY - 1
                    self:setOffset(offsetY)
                else
                    CursorPosY = CursorPosY - 1
                end
                self:setCursorPos(CursorPosX,CursorPosY)
            end
        end,
        [keys.right] = function (self)
            if self.autoflag
            then
                self:AcceptCompletion()
                return
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local lineLen = #self:getCurrentLine()
            local offsetX,offsetY = self:getOffset()
            local termSizeX,termSizeY = self:getSize()
            local Cursor_limit_x_flag = CursorPosX == termSizeX
            if Cursor_limit_x_flag and self:is_wrapped()
            then
                if self:getCurrentLine(1) ~= true
                then
                    return
                end
                CursorPosX = 1
                if CursorPosY == termSizeY
                then
                    offsetY = offsetY + 1
                else
                    CursorPosY = CursorPosY + 1
                end
                self:setOffset(nil,offsetY)
            elseif Cursor_limit_x_flag and offsetX+CursorPosX <= lineLen
            then
                offsetX = offsetX + 1
                self:setOffset(offsetX)
            elseif CursorPosX+offsetX <= lineLen
            then
                CursorPosX = CursorPosX + 1
            end
            self:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.left] = function (self)
            if self.autoflag
            then
                self:AutoClear()
                return
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local offsetX,offsetY = self:getOffset()
            local termSizeX = self:getSize()
            local CursorPosX_greater_flag = CursorPosX > 1
            local OffsetX_flag = offsetX > 0
            local CursorPosY_flag = CursorPosY > 1
            local offsetY_flag = offsetY > 0
            if CursorPosX_greater_flag
            then
                CursorPosX = CursorPosX - 1
            elseif OffsetX_flag
            then
                offsetX = offsetX - 1
                self:setOffset(offsetX)
            elseif self:is_wrapped()
            then
                if OffsetX_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                else
                    CursorPosY = CursorPosY - 1
                end
                self:setOffset(nil,offsetY)
                CursorPosX = termSizeX
            elseif CursorPosX_greater_flag or offsetY_flag
            then
                if offsetY_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                elseif CursorPosY_flag
                then
                    CursorPosY = CursorPosY - 1
                end
                local line_length = #self:getCurrentLine(-1)
                offsetX = (line_length - termSizeX) + 1
                CursorPosX = termSizeX
                self:setOffset(offsetX,offsetY)
            end
            self:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.delete] = function (self)
            if self.autoflag
            then
                return
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local termSizeX,termSizeY = self:getSize()
            local offsetX,offsetY = self:getOffset()
            local char = self:getCurrentPixel(1,0)
            if self:is_wrapped()
            then
                if char ~= true and CursorPosX == termSizeX
                then
                    return
                end
                if CursorPosX+1 > termSizeX
                then
                    CursorPosX = 1
                    CursorPosY = CursorPosY + 1
                    if CursorPosY > termSizeY
                    then
                        CursorPosY = termSizeY
                        self:setOffset(nil,offsetY+1)
                    end
                else
                    CursorPosX = CursorPosX + 1
                end
            else
                if char == nil
                then
                    return
                end
                CursorPosX = CursorPosX + 1
                if CursorPosX > termSizeX
                then
                    CursorPosX = termSizeX
                    self:setOffset(offsetX+1)
                end
            end
            self:setCursorPos(CursorPosX,CursorPosY)
            self:write("\b")
        end,
        [keys.backspace] = function (self)
            if self.autoflag
            then
                self:AutoClear()
            end
            self:write("\b")
        end,
        [keys.home] = function (self)
            if self.autoflag
            then
                self:AutoClear()
            end
            self:setCursorPos(1)
            if not self:is_wrapped()
            then
                self:setOffset(0)
            end
        end,
        [keys.insert] = function (self)
            self.OverWrite_status = not self.OverWrite_status
        end,
        [keys["end"]] = function (self)
            local offsetX = self:getOffset()
            local CursorPosX = self:getCursorPos()
            local termSizeX = self:getSize()
            local wordLen = #self:getCurrentLine()
            if wordLen > termSizeX
            then
                if self:is_wrapped()
                then
                    return
                end
                offsetX = wordLen - termSizeX + 1
                CursorPosX = termSizeX
                self:setOffset(offsetX)
            else
                if offsetX > 0
                then
                    CursorPosX = math.abs(offsetX-wordLen)+1
                else
                    CursorPosX = wordLen+1
                end
                if CursorPosX > termSizeX
                then
                    offsetX = math.abs(CursorPosX-termSizeX)
                    CursorPosX = termSizeX
                    self:setOffset(offsetX)
                end
            end
            self:setCursorPos(CursorPosX)
        end,
        [keys.tab] = function (self)
            if self.autoflag
            then
                self:AcceptCompletion()
            else
                self:write("\t")
            end
        end,
        [keys.leftCtrl] = function (self)
            self.ComboMode = true
        end,
    }
    keyMap[keys.RightCtrl] = keyMap[keys.leftCtrl]
    local filter = {
        ["char"] = function (self,Char)
            if self.ComboMode and self.Combo
            then
                return self:Combo(Char)
            end
            if self.autoflag
            then
                self:AutoClear()
            elseif string.match(Char,"%s") and not self.OverWrite_status
            then
                if not self.OverWrite_status
                then 
                    self:__handleHighlight()
                end
                if self.upDateHost
                then
                    self:upDateHost("Char",Char)
                end
            end
            self:write(Char,self.OverWrite_status)
            local cursorPosX  = self:getCursorPos()
            if cursorPosX > #self:getCurrentLine() and self.AutoComplete
            then
                self:AutoComplete()
                if self.AutoList and #self.AutoList > 0
                then
                    self:_chooseWord(1)
                end
            end
        end,
        ["paste"] = function (self,stri)
            if self.autoflag
            then
                return
            end
            local letters = util.string.split(stri)
            for _,v in pairs(letters) do
                if v:match("%s")
                then
                    self:__handleHighlight()
                end
                self:write(v)
                if self.upDateHost
                then
                    self:upDateHost("Char",v)
                end
            end
            self:__handleHighlight()
        end,
        ["key"] = function (self,number)
            local action = keyMap[number]
            if action
            then
                if self.updateHost
                then
                    self:updateHost("int",number)
                end
                local bool,message = pcall(action,self)
                if not bool
                then
                    error(("%s:%s"):format(message,number),0)
                end
            end
        end,
        ["key_up"] = function (self,number)
            if number == keys.RightCtrl or number.leftCtrl
            then
                self.ComboMode = false
            end
        end,
        ["mouse_click"] = function (self,_,positionX,positionY)
            if self.updateHost
            then
                self.updateHost(true)
            end
            local CursorPosY = select(2,self:getCursorPos())
            local line_y = select(2,self:getCurrentLine(positionY))
            if not line_y
            then
                if positionY  == CursorPosY + 1
                then
                    self:setCursorPos(1,positionY)
                end
                return
            elseif line_y and positionX > #line_y
            then
                positionX = #line_y+1
                self:setCursorPos(#line_y+1,positionY)
            else
                self:setCursorPos(positionX,positionY)
            end
            if self.updateHost
            then
                self:upDateHost("CursorMoved",positionX,positionY)
            end
        end,
        ["mouse_scroll"] = function (self,direction)
            if self.updateHost
            then
                self.updateHost(true)
            end
            local offsetY = select(2,self:getOffset())
            if direction < 0
            then
                direction = direction-self.config.scroll
            else
                direction = direction+self.config.scroll
            end
            local newPos = offsetY+direction
            if newPos <= 0
            then
                newPos = 0
            end
            self:setOffset(nil,newPos)
            if self.updateHost
            then
                self:upDateHost("scroll",newPos)
            end
        end,
    }
    function textBox:interactive(opts)
        expect(false, 1, opts, "table","nil")
        if opts and opts.keywords then
            field(1,opts,"highlightColor","number")
            for i, v in pairs(opts.keywords) do
                field(4, opts.keywords, i, "string")
            end
        end
        field(1,opts,"AutoTextColor","number","nil")
        field(1,opts,"AutoBackColor","number","nil")
        if opts and opts.AutoOptions then
            field(1,opts,"AutoTextColor","number")
            field(1,opts,"AutoBackColor","number")
            for i, _ in pairs(opts.AutoOptions) do
                field(1, opts.AutoOptions, i, "string")
            end
        end
        ---@class interactive
        self = self
        local meta = getmetatable(self)
        meta.__index = interactive
        util.table.setUp(self, "interactive")
        self.bool_run = false
        self.ComboMode = false
        if opts
        then
            self.AutoOptions = opts.AutoOptions
            self.keywords = opts.keywords
            self.keyword_textColor = opts.highlightColor
            self.AutoTextColor = opts.AutoTextColor
            self.AutoBackColor = opts.AutoBackColor
        end
    end
    --- use to escape the loop from 
    --- interactive:run
    function interactive:breakOut()
        self.bool_run = false
    end
    --- sets up the box when called 
    ---@param sContent string
    function interactive:setUp(sContent)
        expect(false,1,sContent,"string")
        self:clear()
        self:setCursorPos(1,1)
        self:write(sContent)
    end
    --- runs the interactive
    function interactive:run()
        parallel.waitForAny(
            function ()
                while true do
                    self:restoreCursor()
                    coroutine.yield()
                end
            end,
            function ()
                self.bool_run = true -- set that to true
                while self.bool_run do
                    local event = table.pack(os.pullEventRaw())
                    local action = filter[event[1]]
                    if action
                    then
                        action(self,table.unpack(event,2))
                    end
                end
            end
        )
    end
end



-- usr input
-- this is a turns a user interface (aka user login) it can not handle control chars in the message board
    --- options
    --- 
    --- default_BackgroundColor : number|nil
    --- 
    --- default_TextColor : number|nil
    --- 
    --- AutoComplete_BackgroundColor : number|nil
    --- 
    --- AutoComplete_TextColor : number|nil
    --- 
    --- keywords : list|nil
    --- 
    --- keyword_textColor : number|nil
    --- 
    --- upDatefunction : function used to upDate calling function
    --- 
    --- AutoComplete : list|function|nil
    --- 
    --- autoRap -- raps the text menu
    --- menu : table of functions used when left or right Ctrl is clicked when called the system will give you the current Line and the window in string format
    ---@param message string|nil
    ---@param TblSettings table|nil
function textBox:Chat_Prompt(message,TblSettings)
    message = expect(false,1,message,"string","nil") or ""
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    TblSettings.default_BackgroundColor = field(2,TblSettings,"default_BackgroundColor","number","nil") or colors.white
    TblSettings.default_TextColor = field(2,TblSettings,"default_TextColor","number","nil") or colors.black
    TblSettings.AutoComplete_BackgroundColor = field(2,TblSettings,"AutoComplete_BackgroundColor","number","nil") or colors.gray
    TblSettings.AutoComplete_TextColor = field(2,TblSettings,"AutoComplete_TextColor","number","nil") or colors.white
    TblSettings.AutoComplete = field(2,TblSettings,"AutoComplete","table","function","nil")
    TblSettings.predefined_sentences = field(2,TblSettings,"predefined_sentences","table","nil")
    TblSettings.prompt_on_newLine = field(2,TblSettings,"prompt_on_newLine","boolean","nil")
    self:setTextColor(TblSettings.default_TextColor)
    self:setBackgroundColor(TblSettings.default_BackgroundColor)
    if string.find(message,"%c")
    then
        error("can not use control chars in message ",2)
    end
    if self:is_wrapped()
    then
        message = util.string.wrap(select(1,self:getSize()),message)
    end
    message = message..(TblSettings.prompt_on_newLine and "\n" or "")
    self:clear()
    self:setCursorPos(1,1)
    self:write(message)
    self:setCursorBlink(true)
    local autoList = {}
    local sContent
    local end_CursorPosX,end_CursorPosY
    local message_chunks = util.string.split(message,"\n") -- used to manage each line independently 
    local message_chunks_depth = 1
    for _,_ in string.gmatch(message,"\n") do
        message_chunks_depth = message_chunks_depth + 1
    end
    local line = message_chunks[message_chunks_depth] or {}
    local function getLastword()
        local Current_line = self:getSentence()
        if not Current_line
        then
            return ""
        end
        do
            local CursorPosY = select(2,self:getCursorPos())
            local offsetY = select(2,self:getOffset())
            local BufferY = offsetY+CursorPosY -- cursorPos relative to the buffer
            if BufferY == #message_chunks
            then
                Current_line = string.sub(Current_line,#line+1)
            end
        end
        ---@diagnostic disable-next-line: cast-local-type
        local words = util.string.split(Current_line," ")
        return words[#words] or ""
    end
    local function getAutoList()
        if TblSettings.AutoComplete == nil
        then
            return
        end
        if type(TblSettings.AutoComplete) == "function"
        then
            autoList = TblSettings.AutoComplete(getLastword())
            return
        end
        autoList = {} -- clear out the last list 
        -- Split the word by dots into a hierarchy
        local hierarchy = util.string.split(getLastword(),"%.")
        local currentTable = TblSettings.AutoComplete
        local boolNoMatch = false
    
        -- Iterate through each part of the hierarchy
        for _, value in ipairs(hierarchy) do
            ---@diagnostic disable-next-line: need-check-nil
            local newTable = currentTable[value]
            if newTable == nil then
                -- If the currentTable returns nil, mark as a possible incomplete match
                boolNoMatch = true
                break
            elseif type(newTable) ~= "table" then
                -- If the value isn't a table, return nil immediately
                return
            end
            currentTable = newTable
        end
        if boolNoMatch
        then
            local In_complete_word = hierarchy[#hierarchy]
            for key,value in pairs(currentTable) do
                if type(key) == "number" and string.sub(value, 1, #In_complete_word) == In_complete_word
                then
                    local toSuggest = string.sub(value,#In_complete_word+1)
                    table.insert(autoList, toSuggest ~= "" and toSuggest or nil)
                elseif type(key) == "string"and string.sub(key, 1, #In_complete_word) == In_complete_word
                then
                    local toSuggest = string.sub(key,#In_complete_word+1)
                    table.insert(autoList, toSuggest ~= "" and toSuggest or nil)
                end
            end
        else
            for key,value in pairs(currentTable) do
                if type(key) == "number" and type(value) == "string"
                then
                    table.insert(autoList,value)
                elseif type(key) == "string"
                then
                    table.insert(autoList,key)
                end
            end
        end
    end
    local predefined_sentences = {}
    if TblSettings.predefined_sentences
    then
        predefined_sentences = util.table.copy(TblSettings.predefined_sentences)
        for i,v in pairs(predefined_sentences) do
            local bool = pcall(expect,false,0,v,"string")
            if not bool
            then
                error(("expected in TblSettings.predefined_sentences %s string got %s"):format(tostring(i),type(v)),2)
            end
        end
    end
    local currentSel
    local run = true
    local Pos = 1
    local autoflag = false
    local predefined_sentences_count = 0
    -- redraw/draws the autocompletion to the screen
    local function reDraw()
        autoflag = true
        if #autoList == 0
        then
            autoflag = false
            return
        end
        self:upDate(false) -- disable live updates to the window
        self:setBackgroundColor(TblSettings.AutoComplete_BackgroundColor)
        self:setTextColor(TblSettings.AutoComplete_TextColor)
        local fullRedraw
        fullRedraw,end_CursorPosX,end_CursorPosY = self:write(currentSel,true,true)
        self:setBackgroundColor(TblSettings.default_BackgroundColor)
        self:setTextColor(TblSettings.default_TextColor)
        self:upDate(true)
        if not fullRedraw
        then
            self:redrawLine()
        else
            self:redraw()
        end
    end
    local function redraw_predefined_sentences()
        self:clear()
        self:setCursorPos(1,1)
        self:write(message)
        if predefined_sentences_count == 0
        then
            return
        end
        local option = predefined_sentences[predefined_sentences_count]
        if option == nil
        then
            return 
        end
        self:write(option)
    end

    --- these are the autoComplete functions
    local function AutoClear()
        self:setCursorPos(end_CursorPosX,end_CursorPosY)
        self:write(("\b"):rep(#currentSel))
        autoflag = false
    end
    local function AcceptCompletion()
        self:setBackgroundColor(TblSettings.default_BackgroundColor)
        self:setTextColor(TblSettings.default_TextColor)
        self:write(currentSel,true)
        autoflag = false
    end
    local function chooseWord(n)
        autoflag = true
        Pos = Pos + (n or 1)
        if Pos > #autoList
        then
            Pos = 0
        end
        if Pos < 0
        then
            Pos = #autoList
        end
        if Pos == 0
        then
            return
        end
        currentSel = table.concat(util.string.split(autoList[Pos]),nil,2)
        reDraw()
    end
    local keyMap = {
        [keys.enter] = function ()
            if autoflag
            then
                AutoClear()
            end
            if self:is_wrapped()
            then
                self:setOffset(nil,0)
                for i,_ in pairs(message_chunks) do
                    if i ~= message_chunks_depth
                    then
                        self:removeLine()
                    else
                        for _=1,#line do
                            self:setCursorPos(2,1)
                            self:write("\b")
                        end
                    end
                end
            else
                self:setOffset(0)
                for _=1,#message do
                    self:setCursorPos(2,1)
                    self:write("\b")
                end
            end
            sContent = self:getVersion()
            run = false
        end,
        [keys.down] = function ()
            if autoflag and autoList
            then
                AutoClear()
                chooseWord(1)
                return
            end
            if predefined_sentences_count == 0
            then
                predefined_sentences_count = #predefined_sentences
            else
                predefined_sentences_count = predefined_sentences_count -1
            end
            redraw_predefined_sentences()
        end,
        [keys.tab] = function ()
            if autoflag
            then
                AcceptCompletion()
            end
        end,
        [keys.up] = function ()
            if autoflag and autoList
            then
                AutoClear()
                chooseWord(-1)
                return
            end
            if predefined_sentences_count == #predefined_sentences
            then
                predefined_sentences_count = 0
            else
                predefined_sentences_count = predefined_sentences_count + 1
            end
            redraw_predefined_sentences()
        end,
        [keys.right] = function ()
            if autoflag
            then
                AcceptCompletion()
                return
            end
            if predefined_sentences_count ~= 0
            then
                predefined_sentences_count = 0
            end
            local termSizeX,termSizeY = self:getSize()
            local CursorPosX,CursorPosY = self:getCursorPos()
            if not self:getCurrentPixel(0,0)
            then
                return
            end
            if self:getCurrentPixel(1,0) == true
            then
                CursorPosX = 1
                if CursorPosY == termSizeY
                then
                    self:setOffset(nil,select(2,self:getOffset())+1)
                else
                    CursorPosY = CursorPosY + 1
                end
            elseif not self:is_wrapped()
            then
                if CursorPosX == termSizeX
                then
                    self:setOffset(select(1,self:getOffset())+1)
                else
                    CursorPosX = CursorPosX + 1
                end
            else
                CursorPosX = CursorPosX + 1
            end
            self:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.left] = function ()
            if autoflag
            then
                AutoClear()
            end
            if predefined_sentences_count ~= 0
            then
                predefined_sentences_count = 0
            end
            local offsetX,offsetY = self:getOffset()
            local termSizeX = self:getSize()
            local CursorPosX,CursorPosY = self:getCursorPos()
            local BufferX,BufferY = offsetX+CursorPosX,offsetY+CursorPosY -- cursorPos depth relative to buffer not screen
            if self:is_wrapped()
            then
                if BufferY == message_chunks_depth
                then
                    if CursorPosX > #line+1
                    then
                        CursorPosX = CursorPosX - 1
                    end
                else
                    if CursorPosX > 1
                    then
                        CursorPosX = CursorPosX - 1
                    elseif offsetX > 0 then
                        offsetX = offsetX - 1
                        CursorPosX = termSizeX
                    end
                end
            else
                if BufferX == #line+1
                then
                    if #line > termSizeX-1
                    then
                        self:setOffset(#line+(termSizeX/2))
                        CursorPosX = #line+1
                    else
                        self:setOffset(0)
                        CursorPosX = #line+1
                    end
                else
                    CursorPosX = CursorPosX - 1
                end
            end
            self:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.backspace] = function ()
            if autoflag
            then
                AutoClear()
            end
            if predefined_sentences_count > 0
            then
                predefined_sentences_count = 0
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local offsetX,offsetY = self:getOffset()
            local BufferX,BufferY = CursorPosX+offsetX,CursorPosY+offsetY -- cursorPosition relative to buffer
            local is_wrapped = self:is_wrapped()
            if (is_wrapped and BufferY == message_chunks_depth and CursorPosX == #line+1) or (not is_wrapped and BufferX == #line+1)
            then
                return
            end
            self:write("\b")

        end,
        [keys.delete] = function ()
            if autoflag
            then
                return
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local termSizeX,termSizeY = self:getSize()
            if autoflag
            then
                return
            end
            local offsetX,offsetY = self:getOffset()
            local char = self:getCurrentPixel(1,0)
            if self:is_wrapped()
            then
                if char ~= true and CursorPosX == termSizeX
                then
                    return
                end
                if CursorPosX+1 > termSizeX
                then
                    CursorPosX = 1
                    CursorPosY = CursorPosY + 1
                    if CursorPosY > termSizeY
                    then
                        CursorPosY = termSizeY
                        self:setOffset(nil,offsetY+1)
                    end
                else
                    CursorPosX = CursorPosX + 1
                end
            else
                if char == nil
                then
                    return
                end
                CursorPosX = CursorPosX + 1
                if CursorPosX > termSizeX
                then
                    CursorPosX = termSizeX
                    self:setOffset(offsetX+1)
                end
            end
            self:setCursorPos(CursorPosX,CursorPosY)
            self:write("\b")
        end,
        [keys.home] = function ()
            if autoflag
            then
                AutoClear()
            end
            if predefined_sentences_count ~= 0
            then
                predefined_sentences_count = 0
            end
        end,
        [keys["end"]] = function ()
            if autoflag
            then
                return
            end
            if predefined_sentences_count ~= 0
            then
                predefined_sentences_count = 0
            end
            local offsetX = self:getOffset()
            local CursorPosX = self:getCursorPos()
            local termSizeX = self:getSize()
            local wordLen = #self:getCurrentLine()
            if wordLen > termSizeX
            then
                if self:is_wrapped()
                then
                    return
                end
                offsetX = wordLen - termSizeX + 1
                CursorPosX = termSizeX
                self:setOffset(offsetX)
            else
                if offsetX > 0
                then
                    CursorPosX = math.abs(offsetX-wordLen)+1
                else
                    CursorPosX = wordLen+1
                end
                if CursorPosX > termSizeX
                then
                    offsetX = math.abs(CursorPosX-termSizeX)
                    CursorPosX = termSizeX
                    self:setOffset(offsetX)
                end
            end
            self:setCursorPos(CursorPosX)

        end,
    }
    local filter = {
        ["char"] = function (Char)
            if autoflag
            then
                AutoClear()
            end
            if predefined_sentences_count ~= 0
            then
                predefined_sentences_count = 0
            end
            self:write(Char)
            local cursorPosX = self:getCursorPos()
            if cursorPosX > #self:getCurrentLine() and TblSettings.AutoComplete
            then
                getAutoList()
                if autoList and #autoList > 0
                then
                    Pos = 0
                    chooseWord()
                end
            end
        end,
        ["paste"] = function (stri)
            if autoflag
            then
                AutoClear()
            end
            self:write(stri)
        end,
        ["key"] = function (number)
            local action = keyMap[number]
            if action
            then
                action()
            end
        end,
        ["mouse_scroll"] = function (direction)
            local offsetY = select(2,self:getOffset())
            local newOff = offsetY+direction
            if newOff > 0
            then
                self:setOffset(nil,newOff)
            end
        end,
        ["mouse_click"] = function ()
            
        end,
    }
    parallel.waitForAny(function ()
        while true do
            self:restoreCursor()
            coroutine.yield()
        end
    end,function ()
        while run do
            local event = table.pack(os.pullEventRaw())
            if self:isUpDating()
            then
                ---@type function|nil
                local action = filter[event[1]]
                if action and action(table.unpack(event,2))
                then
                    break
                end
            end
        end
    end)
    return sContent
end



-- you only get this api if you are a advance computer
-- it only uses the mouse_click event 
if native.isColor()
then
    ---comment
    -- used to handle buttons
    ---@param bLoop boolean|nil
    ---@param ... table|button
    ---@return unknown
    function terminal.buttonRun(bLoop,...)
    expect(false,1,bLoop,"boolean")
    local buttons
    do
        local argus = {...}
        if type(argus[1]) ~= "table"
        then
            error(("expected table got %s"):format(type(argus[1])))
        elseif type(argus[1]) == "table" and util.table.getType(argus[1]) ~= "button"
        then
            buttons = argus[1]
        else
            buttons = argus
        end
    end
    local choice
    parallel.waitForAny(function ()
        while true do
            for i,v in pairs(buttons) do
                expect(true,i+1,v,"button")
                v:redraw()
                coroutine.yield()
            end
        end
    end,function ()
        local run = true
        while run do
            local event = table.pack(os.pullEventRaw())
            if event[1] == "mouse_click"  or event[1] == "monitor_touch"
            then
                for i,v in pairs(buttons) do
                    expect(true,i+1,v,"button")
                    if v:isClicked(table.unpack(event))
                    then
                        choice = table.pack(v:trigger())
                        if not bLoop
                        then
                            run = false
                            break
                        end
                    end
                end
            end
        end
    end)
    return choice
    end
end


--- turns a termnial into a yes no box with prompt
---@param mess string
---@param _yesText string|nil
---@param _noText string|nil
---@return boolean
function terminal:Prompt(mess,_yesText,_noText)
    expect(true,0,self,"terminal")
    expect(false,1,mess,"string")
    expect(false,2,_yesText,"string","nil")
    expect(false,3,_noText,"string","nil")
    local bool,_bRun = false,true
    local message,Yes,No
    do -- builds the componets of the prompt program
        local x,y = self:getSize()
        range(0,x,10)
        range(0,y,4)
        message = self:create(1,1,x,y-2,true)
        local buttons_menu = self:create(1,y-3,x,3,true)
        x,y = buttons_menu:getSize()
        No = buttons_menu:create(1,1,x/2-1,y,true)
        Yes = buttons_menu:create(x/2,1,x/2,y,true)
        Yes:make_button()
        Yes:setID(1)
        No:make_button()
        Yes:setActivate(function ()
            bool = true
            _bRun = false
        end)
        Yes.default_window:setTextColor(colors.white)
        Yes.active_window:setTextColor(colors.white)
        Yes.default_window:setBackgroundColor(native.isColor() and colors.red or colors.lightGray)
        Yes.active_window:setBackgroundColor(native.isColor() and colors.blue or colors.gray)
        Yes.default_window:setText(_yesText or "yes")
        Yes.active_window:setText(_yesText or "yes")

        No:setID(0)
        No:setActivate(function ()
            bool = false
            _bRun = false
        end)
        No.default_window:setTextColor(colors.white)
        No.active_window:setTextColor(colors.white)
        No.default_window:setBackgroundColor(native.isColor() and colors.red or colors.lightGray)
        No.active_window:setBackgroundColor(native.isColor() and colors.blue or colors.gray)
        No.default_window:setText(_noText or "no")
        No.active_window:setText(_noText or "no")
    end
    message:make_textBox(true)
    self:setBackgroundColor(colors.brown)
    self:redraw()
    message:setBackgroundColor(colors.brown)
    message:setTextColor(colors.purple)
    message:write(mess)
    message:redraw()
    No:OverRide_status(true)
    Yes:OverRide_status(false)
    local options = {
        Yes,
        No,
    }
    local handle = {
        [keys.right] = function ()
            bool = true
            Yes:OverRide_status(true)
            No:OverRide_status(false)
        end,
        [keys.left] = function ()
            bool = false
            Yes:OverRide_status(false)
            No:OverRide_status(true)
        end,
        [keys.enter] = function ()
            _bRun = false
        end
    }
    while _bRun do
        local event = table.pack(os.pullEventRaw())
        if self:isUpDating()
        then
            if event[1] == "key"
            then
                local fn = handle[event[2]]
                if type(fn) == "function"
                then
                    fn()
                end
            elseif event[1] == "mouse_click"
            then
                for i=1,2 do
                    local tmp = options[i]
                    if tmp:isClicked(table.unpack(event))
                    then
                        tmp:trigger()
                        break
                    end
                end
            end
        end
    end
    return bool
end

-- self expalined
-- these are the settings used by routine
---
--- Defaut_option_textColor: number|nil
--- 
--- default_option_backgeoundColor : number|nil
--- 
--- select_option_textColor: number|nil
--- 
--- select_option_backgeoundColor: number|nil
--- 
--- message_BackgroundColor: number|nil
--- 
--- message_TextColor: number|nil
--- 
--- message: string|nil
---@param self terminal
---@param option_list table|terminal
---@param TblSettings table|nil
function terminal:run_list(option_list,TblSettings) 
    expect(true,0,self,"terminal")
    expect(false,1,option_list,"table")
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    TblSettings.Defaut_option_textColor = field(2,TblSettings,"Defaut_option_textColor","number","nil") or native.isColor() and colors.blue or colors.white
    TblSettings.default_option_backgeoundColor = field(2,TblSettings,"default_option_backgeoundColor","number","nil") or native.isColor() and colors.green or colors.lightGray
    TblSettings.select_option_textColor = field(2,TblSettings,"select_option_textColor","number","nil") or native.isColor() and colors.red or colors.white
    TblSettings.select_option_backgeoundColor = field(2,TblSettings,"select_option_backgeoundColor","number","nil") or native.isColor() and colors.blue or colors.gray
    TblSettings.message_BackgroundColor = field(2,TblSettings,"message_BackgroundColor","number","nil") or native.isColor() and colors.gray or colors.black
    TblSettings.message_TextColor  = field(2,TblSettings,"message_TextColor","number","nil") or colors.white
    TblSettings.list = field(2,TblSettings,"list","table","nil")
    if #option_list == 0
    then
        error("table is empty",2)
    end
    self:upDate(true)
    local termSizeX,termSizeY = self:getSize()
    range(0,termSizeY,2)
    local Pages = {{}}
    local canv = self:create(1,2,termSizeX,termSizeY-2,true)
    canv:setBackgroundColor(self:getBackgroundColor())
    local Page = self:create(1,termSizeY,termSizeX,1,true)
    Page:make_textBox()
    Page:setBackgroundColor(TblSettings.message_BackgroundColor or colors.white)
    Page:setTextColor(TblSettings.message_TextColor or colors.black)
    do -- sperates the tbl into pages
        local PagesCount = 1
        local Cy = 1
        for i,v in pairs(option_list) do
            if Cy > termSizeY-2
            then
                Cy = 1
                PagesCount = PagesCount + 1
                Pages[PagesCount] = {}
            end
            local option = canv:create(1,Cy,termSizeX,1,true)
            option:make_button()
            option.active_window:setText(v)
            option.default_window:setText(v)
            option.default_window:setBackgroundColor(TblSettings.default_option_backgeoundColor)
            option.default_window:setTextColor(TblSettings.Defaut_option_textColor)
            option.active_window:setBackgroundColor(TblSettings.select_option_backgeoundColor)
            option.active_window:setTextColor(TblSettings.select_option_textColor)
            option:setID(i)
            table.insert(Pages[PagesCount],option)
            Cy = Cy + 1
        end
    end
    local left,right,smallScreen
    local otpLen = #Pages
    local CurrentPage,currentSel = 1,1
    local function setPage(n)
        canv:clear(false)
        for _,v in pairs(Pages[CurrentPage]) do
            v:upDate(false)
        end
        CurrentPage = CurrentPage + n
        for i,v in pairs(Pages[CurrentPage]) do
            v:upDate(true)
            if v.active
            then
                currentSel = i
            end
        end
        currentSel = currentSel or 1
        Page:clear()
        if not smallScreen
        then
            Page:write(("Page %s of %s"):format(CurrentPage,otpLen))
        else
            Page:write(("%s/%s"):format(CurrentPage,otpLen))
        end
        Page:setCursorPos(1,1)
    end
    do -- builds the page indacator
        local stri = ("Page %s of %s"):format(1,otpLen)
        if #stri <= select(1,Page:getSize())
        then
            Page:write(stri)
        else
            Page:write(("%s/%s"):format(1,otpLen))
            smallScreen = true
        end
        Page:setCursorPos(1,1)
    end
    local Prompt
    if otpLen > 1 and GUI.buttonRun
    then
        Prompt = self:create(2,1,termSizeX-1,1)
        left = self:create(1,1,1,1,true)
        right = self:create(termSizeX,1,1,1,true)
        left:make_button(false)
        right:make_button(false)
        left.active_window:setTextColor(TblSettings.select_option_textColor)
        left.default_window:setTextColor(TblSettings.Defaut_option_textColor)
        left.active_window:setBackgroundColor(TblSettings.select_option_backgeoundColor)
        left.default_window:setBackgroundColor(TblSettings.default_option_backgeoundColor)
        left.default_window:setText("<")
        left.active_window:setText("<")
        right.default_window:setText(">")
        right.active_window:setText(">")
        right.active_window:setTextColor(TblSettings.select_option_textColor or right.active_window.color.text)
        right.active_window:setBackgroundColor(TblSettings.select_option_backgeoundColor or right.active_window.color.back)
        right.default_window:setTextColor(TblSettings.Defaut_option_textColor or right.default_window.color.text)
        right.default_window:setBackgroundColor(TblSettings.default_option_backgeoundColor or right.default_window.color.back)
        right:setActivate(function ()
            if CurrentPage < #Pages
            then
                setPage(1)
            end

        end)
        left:setActivate(function ()
            if CurrentPage > 1
            then
                setPage(-1)
            end

        end)
        left:upDate(true)
        right:upDate(true)
    else
        Prompt = self:create(1,1,termSizeX,1,true)
    end
    Prompt:make_textBox()
    do -- builds the prompt textBox
        local message = field(2,TblSettings,"message","string","nil") or "please choose"
        local x2 = select(1,Prompt:getSize())
        if #message < x2
        then
            local x3,y3 = Prompt:getCenter()
            Prompt:setCursorPos(x3-(#message/2)+1,y3)
            Prompt:setBackgroundColor(TblSettings.message_BackgroundColor or colors.white)
            Prompt:setTextColor(TblSettings.message_TextColor or colors.black)
            Prompt:write(message)
        end
    end
    Pages[1][1].active = true
    self:redraw()
    local selected = 1
    local function start()
        local run = true
        while run do
            local event = {os.pullEventRaw()}
            if self:isUpDating()
            then
                if event[1] == "key"
                then
                    if event[2] == keys.down and currentSel < #Pages[CurrentPage]
                    then
                        Pages[CurrentPage][currentSel]:OverRide_status()
                        currentSel = currentSel + 1
                        Pages[CurrentPage][currentSel]:OverRide_status()
                    elseif event[2] == keys.up and currentSel > 1
                    then
                        Pages[CurrentPage][currentSel]:OverRide_status()
                        currentSel = currentSel - 1
                        Pages[CurrentPage][currentSel]:OverRide_status()
                    elseif event[2]  == keys.enter
                    then
                        
                        selected = Pages[CurrentPage][currentSel]:trigger()
                        break
                    elseif event[2] == keys.right and CurrentPage < otpLen
                    then
                        setPage(1)
                    elseif event[2] == keys.left and CurrentPage > 1
                    then
                        setPage(-1)
                    end
                elseif event[1] == "mouse_click" or event[1] == "monitor_touch"
                then
                    for _,v in pairs(Pages[CurrentPage]) do
                        if v:isClicked(table.unpack(event))
                        then
                            selected = v:trigger()
                            run = false
                            break
                        end
                    end
                end
            end
        end
    end
    local function redraw()
        while true do
            native.setCursorBlink(false)
            for _,v in pairs(Pages[CurrentPage]) do
                v:redraw()
            end
            coroutine.yield()
        end
    end
    if GUI.buttonRun and otpLen > 1
    then
        parallel.waitForAny(function ()
            GUI.buttonRun(true,left,right)
        end,start,redraw)
    else
        parallel.waitForAny(start,redraw)
    end
    return selected
end
---time to return the GUI modules
return GUI
