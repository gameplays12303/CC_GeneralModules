---@diagnostic disable: duplicate-set-field

---@diagnostic disable-next-line: undefined-field
local native = type(term) == "function" and term() or type(term.current) == "function" and term.current() or type(term.native) == "function" and term.native() or type(term.native) == "table" and term.native or term
local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect = require and require("generalModules.expect2") or dofile("generalModules/expect2.lua")
local fm = require and require("generalModules.fm") or dofile("generalModules/fm.lua")
local range = expect.range
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect

---@diagnostic disable-next-line: param-type-mismatch
native = util.table.copy(native)
local terminal_data = getmetatable(native)

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

---@class terminal
local terminal = setmetatable({},{__disabledSetMeta = true})

-- this is a custom terminal and will return a termnial
setmetatable(native,{__index = GUI})
GUI = setmetatable({
    terminal = {
        CursorPosX= 1,
        y = 1,
        width = select(1,native.getSize()),
        height = select(2,native.getSize())
    },
    pixels = {},
    color = {back = colors.white,palette = util.table.setType({},"palette")},
    visible = false,
    children = setmetatable({},{__mode = "v"})
},{__index = terminal})
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
util.table.setType(GUI,"terminal") 

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
    },{__index = terminal})
    util.table.setType(instance,"terminal")
    table.insert(self.children,instance)
    function instance:reposition(new_x,new_y,new_width,new_height,new_Parent)
        expect(false,1,new_x,"number")
        expect(false,2,new_y,"number")
        expect(false,3,new_width,"number")
        expect(false,4,new_height,"number")
        expect(false,5,new_Parent,"terminal","nil")
        do
            local x,y
            if new_Parent
            then
                x,y = new_Parent:getSize()
            else
                x,y = Parent:getSize()
            end
            range(1,new_x,1,x)
            range(2,new_y,1,y)
            range(3,new_width,1,x-new_x+1)
            range(4,new_height,1,y-new_y+1)
        end
        instance.window.x = new_x
        instance.window.y = new_y
        instance.window.width = new_width
        instance.window.height = new_height
        if new_Parent
        then
            Parent.children[select(2,util.table.find(Parent.children,instance))] = nil
            Parent = new_Parent
            table.insert(Parent.children,instance)
        end
        Parent:redraw()
        return true
    end
    function instance:getRealPos()
        local x,y = instance:getPosition()
        local RealPosX,RealPosDepth = Parent:getRealPos()
        return RealPosX+(x-1),RealPosDepth+(y-1)
    end
    function instance:isUpDating()
        if Parent:isUpDating()
        then
            return instance.upDating
        end
        return false
    end
    function instance:redrawParent()
        return Parent:redraw()
    end
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
---comment
---@param color number
---@param r number
---@param g number
---@param b number
function terminal:setPaletteColor(color,r,g,b)
    expect(false,1,color,"number")
    isColor(color)
    self.color.palette[color] = table.pack(r,g,b)
end
---comment
---@param color number
function terminal:getPaletteColor(color)
    expect(false,1,color,"number")
    isColor(color)
    return table.unpack(self.color.palette[color])
end
---comment
---@param color number
function terminal:setBackgroundColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.back = color
end
---comment
---@return number
function terminal:getBackgroundColor() 
    return self.color.back
end
function terminal:getCenter()
    local SizeX,SizeY = self:getSize()
    local PosX = math.ceil( SizeX/2)
    local PosY = math.ceil(SizeY/2)
    return ((PosX > 0  and PosX) or 1),((PosY > 0  and PosY) or 1)
end 
---comment
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


---@class canvis
---@diagnostic disable-next-line: assign-type-mismatch
local canvis = setmetatable({},{__index = terminal})

function terminal:makeCanv()
    self.pixels = {}
    self.children = nil
    setmetatable(self,{__index = canvis})
    util.table.setType(self,"canvis")
end

do -- canvises functions
    local colorChar = { -- is the compression Map
        [1] = colors.white,
        [2] = colors.black,
        [3] = colors.green,
        [4] = colors.red,
        [5] = colors.black,
        [6] = colors.magenta,
        [7] = colors.lightBlue,
        [8] = colors.yellow,
        [9] = colors.lime,
        ["A"] = colors.pink,
        ["B"] = colors.gray,
        ["C"] = colors.lightGray,
        ["D"] = colors.cyan,
        ["E"] = colors.purple,
        ["F"] = colors.blue,
        ["G"] = colors.brown,
    }
    local parseImage
    do -- contains copied code for backword capablity none of it is mine
        --[[
            these are from the paintutils API
            they are under this copyright
            and are not exposed to the user

            -- SPDX-FilecopyrightText: 2017 Daniel Ratcliffe
            -- SPDX-License-Identifier: LicenseRef-CCPL
            --- An API for advanced systems which can draw pixels and lines, load and draw
            -- image files. You can use the `colors` API for easier color manipulation. In
            -- CraftOS-PC, this API can also be used in grRealPosDepthics mode.
            --
            -- @module paintutils
            -- @since 1.45
        ]]
        --- Parses an image from a multi-line string
        --
        -- @tparam string image The string containing the raw-image data.
        -- @treturn table The parsed image data, suitable for use with
        -- @{paintutils.drawImage}.
        -- @since 1.80pr1
        local tColourLookup = {}
        for n = 1, 16 do
            tColourLookup[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
        end
        parseImage = function (image)
            local tImage = {}
            local Size = {x = 0, y = 0}
            for sLine in (image .. "\n"):gmatch("(.-)\n") do
                local tLine = {}
                for PosX = 1, sLine:len() do
                    tLine[PosX] = tColourLookup[string.byte(sLine, PosX, PosX)] or 0
                    Size.x = PosX > Size.x or Size.x
                end
                table.insert(tImage, tLine)
            end
            Size.y = #tImage
            return tImage,Size
        end
    end
    --- end of copyRight
    function canvis:loadImage(sImage_file)
        expect(false,1,sImage_file,"string")
        if not fs.exists(sImage_file)
        then
            error(("%s:not found"):format(sImage_file),3)
        end
        local result = {image = {{}},Size = {}}
        local ext = util.file.getExtension(sImage_file)
        if ext == "nfp"
        then
            local imageData = fm.readFile(sImage_file,"R")
            if not imageData
            then
                error(("%s:no data"):format(imageData),0)
            end
            result.image,result.Size = parseImage(imageData)
        elseif ext == "CImage"
        then
            local ImageWidth,ImageHeight = 0,0
            local width = 1
            local file,err = fs.open(sImage_file,"r")
            if not file
            then
                error(err,2)
            end
            while true do
                local Char = file.read()
                if Char == nil
                then
                    break
                end
                if Char == "\n"
                then
                    ImageHeight = ImageHeight + 1
                    table.insert(result.image,{})
                    width = 0
                end
                local Color = colorChar[tonumber(Char) or Char]
                if Char ~= " " and Color
                then
                    ImageWidth = width > ImageWidth and width or ImageWidth
                    result.image[#result.image][width] = Color
                end
                width = width + 1
            end
            file.close()
            result.Size.x = ImageWidth
            result.Size.y = ImageHeight
        else
            error("unknown format",0)
        end
        return result
    end
    function canvis:drawImage(tImag,positionX,positionY)
        expect(true,0,self,"canvis")
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
        for Y,Obj in pairs(tImag) do
            if Obj and #Obj ~= 0
            then
                for X,color in pairs(Obj) do
                    if color > 0
                    then
                        self:setPixel(color,X+positionX-1,Y+positionY-1)
                    end
                end
            end
        end
        if self:isUpDating()
        then
            self:redraw()
        end
    end
    function canvis:saveImage(sImage_file)
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
    ---comment
    ---@param color number
    ---@paramCursorPosXnumber
    ---@param y number
    function canvis:setPixel(color,x,y)
        expect(true,0,self,"canvis")
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
function canvis:redraw()
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



-- turns a terminal into a textBox to draw text to
---@class textBox
---@diagnostic disable-next-line: assign-type-mismatch
local textBox = setmetatable({},{__index = terminal})

---turns a table into a textBox
---@param self terminal
function terminal:make_textBox(AutoWrap,tab_spaces)
    expect(true,0,self,"terminal")
    expect(false,1,AutoWrap,"boolean","nil")
    expect(false,2,tab_spaces,"number","nil")
    do
        local meta = getmetatable(self) or {}
        meta.__index = textBox
        setmetatable(self,meta)
    end
    util.table.setType(self,"textBox")
    self.Offset = {}
    self.Offset.x = 0
    self.Offset.y = 0
    self.lines = {}
    self.tab_spaces = tab_spaces and tab_spaces or 4
    self.Cursor = {pos = {x = 1,y = 1},Blink = false}
    self.color.text = colors.black
    self.children = nil
    self.autoWrap = AutoWrap or false
end

---@diagnostic disable-next-line: duplicate-set-field
function textBox:clear()
    expect(true,0,self,"textBox")
    self.lines = {}
    self:redraw()
end
function textBox:clearLine()
    expect(true,0,self,"textBox")
    local CursorPosY = select(2,self:getCursorPos())
    if not self:iswrapped()
    then
        self.lines[CursorPosY] = {}
    end
    self:redrawLine()
end
function textBox:getCursorBlink()
    expect(true,0,self,"textBox")
    return self.Cursor.Blink
end
function textBox:getCursorPos()
    expect(true,0,self,"textBox")
    return self.Cursor.pos.x,self.Cursor.pos.y
end
---comment
---@return number
function textBox:getTextColor()
    expect(true,0,self,"textBox")
    return self.color.text
end
function textBox:getOffset()
    return self.Offset.x,self.Offset.y
end
---@diagnostic disable-next-line: duplicate-set-field
function textBox:redraw()
    expect(true,0,self,"textBox")
    if self:isUpDating()
    then
        native.setCursorBlink(false)
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
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
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
        native.setCursorBlink(self:getCursorBlink())
    end

end
function textBox:redrawLine()
    expect(true,0,self,"textBox")
    if self:isUpDating()
    then
        native.setCursorBlink(false)
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
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
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
        native.setCursorBlink(self:getCursorBlink())
    end
end
function textBox:restoreCursor()
    expect(true,0,self,"textBox")
    if self:isUpDating()
    then
        restorePallet(self)
        native.setBackgroundColor(self:getBackgroundColor())
        native.setTextColor(self:getTextColor())
        do
            local RealPosX,RealPosY = self:getRealPos()
            local x,y = self:getCursorPos()
            native.setCursorPos(RealPosX+(x-1),RealPosY+(y-1))
        end
        native.setCursorBlink(self:getCursorBlink())
    end
    return true
end
---comment
---@param offsetX number|nil
---@param offsetY number|nil
function textBox:setOffset(offsetX,offsetY)
    if self:iswrapped() and offsetX ~= nil
    then
        error("can't set the screen width offset as this is a wapped textBox",2)
    end
    expect(false,1,offsetX,"number","nil")
    expect(false,2,offsetY,"number","nil")
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
    expect(true,0,self,"textBox")
    expect(false,1,bTrue,"boolean")
    self.Cursor.Blink = bTrue
end
---comment
--- moves the Cursor to the requested position
---@param nX number|nil
---@param nY number|nil
function textBox:setCursorPos(nX,nY)
    expect(true,0,self,"textBox")
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
    expect(true,0,self,"textBox")
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
    expect(true,0,self,"textBox")
    expect(false,1,sText,"string")
    expect(false,2,bOverWrite,"boolean","nil")
    local textBoxlengh,textBoxDepth = self:getSize()
    ---@diagnostic disable-next-line: param-type-mismatch

    local CursorPosX,CursorPosY = self:getCursorPos()
    ---@diagnostic disable-next-line: cast-local-type
    local result = util.string.split(sText)
    local flagLines = false
    do  --- writes the sentece to the table
        -- one charator at a time
        local offsetX,offsetY = self:getOffset()
        local wrappedFlag = self:iswrapped()
        local CB,CT = self:getBackgroundColor(),self:getTextColor()
        local function checkLine()
            if type(self.lines[CursorPosY+offsetY]) == "nil"
            then
                self.lines[CursorPosY+offsetY] = {}
            end
        end
        checkLine()
        local function handle()
            local Cursor_Size_flag = CursorPosX == textBoxlengh
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
                local temp = self.lines[CursorPosY+offsetY]
                temp[#temp+1] = true
                CursorPosY = CursorPosY + 1
                if CursorPosY > textBoxDepth
                then
                    offsetY = offsetY + 1
                    CursorPosY = textBoxDepth
                else
                    CursorPosX = 1
                end
                flagLines = true
                checkLine()
            else
                CursorPosX = CursorPosX + 1
            end
        end
        local function UpDateCursorPos()
            checkLine()
            if #self.lines[CursorPosY+offsetY+1] == 0
            then
                table.remove(self.lines,CursorPosY+offsetY+1)
            end
            local line = #self.lines[CursorPosY+offsetY]
            if self:iswrapped()
            then
                line = line-1
            end
            if line > textBoxlengh
            then
                CursorPosX = textBoxlengh
                offsetX = math.abs(line-textBoxlengh)+1
            else
                CursorPosX = line > 0 and line or 1
            end
        end
        for index=1,#sText do
            if not self.lines[CursorPosY+offsetY]
            then
                self.lines[CursorPosY+offsetX] = {}
            end
            if result[index] == "\b"
            then
                local CursorPosY_greator_flag = CursorPosY > 1
                local CursorPosX_greator_flag = CursorPosX > 1
                local offsetX_flag = offsetX > 0
                local offsetY_flag = offsetY > 0
                if CursorPosY_greator_flag or CursorPosX_greator_flag or offsetX_flag or offsetY_flag
                then
                    if CursorPosX_greator_flag
                    then
                        CursorPosX = CursorPosX - 1
                    elseif offsetX_flag
                    then
                        offsetX = offsetX - 1
                        flagLines = true
                    elseif CursorPosY_greator_flag
                    then
                        CursorPosY = CursorPosY - 1
                        UpDateCursorPos()
                    elseif offsetY_flag
                    then
                        offsetY = offsetY - 1
                        flagLines = true
                        UpDateCursorPos()
                    end
                    table.remove(self.lines[CursorPosY+offsetY],CursorPosX+offsetX)
                end
            elseif result[index] == "\n"
            then
                local moveTBl = {}
                do
                    local CurrentPointer_x = (CursorPosX)+offsetX
                    local currentLine = self.lines[CursorPosY+offsetY]
                    local k
                    while true do
                        k = currentLine[CurrentPointer_x]
                        if type(k) == "boolean" or k == nil
                        then
                            break
                        end
                        table.insert(moveTBl,k)
                        table.remove(currentLine,CurrentPointer_x)
                    end
                end
                if CursorPosY == textBoxDepth
                then
                    offsetY = offsetY + 1
                    flagLines = true
                else
                    CursorPosY = CursorPosY + 1
                end
                CursorPosX = 1
                table.insert(self.lines,CursorPosY+offsetY,moveTBl)
                if offsetX > textBoxlengh
                then
                    offsetX = 0
                    flagLines = true
                end
            elseif result[index] == "\t"
            then
                local count = 0
                repeat
                    table.insert(self.lines[CursorPosY+offsetY],(CursorPosX+offsetX),{
                        Char = " ",
                        color = {back = CB,text = CT}
                    })
                    handle()
                    count = count + 1
                until count == self.tab_spaces
            
            elseif not bOverWrite
            then
                table.insert(self.lines[CursorPosY+offsetY],(CursorPosX+offsetX),{
                    Char = result[index],
                    color = {back = CB,text = CT}
                })
                handle()
            else
                self.lines[CursorPosY+offsetY][CursorPosX+offsetX] = {
                    Char = result[index],
                    color = {back = CB,text = CT}
                }
                handle()
            end
        end
        if flagLines
        then
            self:setOffset(not self:iswrapped() and offsetX or nil,offsetY)
        end
        if not keepPos
        then
            self:setCursorPos(CursorPosX,CursorPosY)
        end
    end
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
---comment
---@param manual_offsetX number|nil
---@param manual_offsetY number|nil
---@return table|nil
---@return table|nil
function textBox:getCurrentLine(manual_offsetX,manual_offsetY)
    manual_offsetX = expect(false,1,manual_offsetX,"number","nil") or 0
    manual_offsetY = expect(false,2,manual_offsetY,"number","nil") or 0
    local CursorPosX,CursorPosY = self:getCursorPos()
    local offsetX,offsetY = self:getOffset()
    local Chartemp = self.lines[CursorPosY+offsetY+manual_offsetY]
    Chartemp = Chartemp and util.table.copy(Chartemp) or nil
    if self:iswrapped() and Chartemp ~= nil
    then
        if type(Chartemp[#Chartemp]) == "boolean"
        then
            table.remove(Chartemp,#Chartemp)
            CursorPosX = CursorPosX - 1
        end
    end
    return Chartemp and Chartemp[CursorPosX+offsetX+manual_offsetX],Chartemp
end

--[[
    this is how you get a line
]]
---@param positionX number|nil
---@param positionY number|nil
---@return table|nil
---@return table|nil
function textBox:getLine(positionX,positionY)
    positionX = expect(false,1,positionX,"number","nil") or 1
    positionY = expect(false,2,positionY,"number","nil") or 1
    local offsetX,offsetY = self:getOffset()
    local Chartemp = self.lines[positionY+offsetY]
    Chartemp = Chartemp and util.table.copy(Chartemp) or nil
    if self:iswrapped() and Chartemp ~= nil
    then
        if type(Chartemp[#Chartemp]) == "boolean"
        then
            table.remove(Chartemp,#Chartemp)
        end
    end
    return Chartemp and Chartemp[positionX+offsetX],Chartemp
end

---returns a single window line as a string at the current CursorPosistion of depth
--- and offset
---@return string
function textBox:getSentence()
    local CursorPosY = select(2,self:getCursorPos())
    local OffsetY = select(2,self:getOffset())
    local temp = self.lines[CursorPosY+OffsetY]
    local spaceCount = 0
    local count_x,count_y = #temp,(CursorPosY+OffsetY)
    local len = self.tab_spaces
    local sRaw = ""
    while true do
        if count_x == 0
        then
            count_y = count_y - 1
            if count_y <= 0
            then
                break
            end
            local temp2 = #self.lines[count_y]
            count_x = temp2
            local temp3 = self.lines[count_y][count_x] == true
            if temp3
            then
                count_x = count_x - 1
            else
                break
            end
        end
        local Char = self.lines[count_y][count_x].Char
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
        count_x = count_x - 1
    end
    return string.reverse(sRaw)
end
---comment
---@return boolean
function textBox:iswrapped()
    expect(false,0,self,"table")
    return self.autoWrap or false
end
--  return the window as a string 
---@return string
function textBox:getVersion()
    expect(true, 0, self, "textBox")
    local sRaw = ""
    local spaceCount = 0
    local len = self.tab_spaces
    for i, y in pairs(self.lines) do
        local lineFlag = false
        for _,Pos in pairs(y) do
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
local button = setmetatable({},{__index = terminal})

---comment
---@param bToggle boolean|nil
---@param _bRawImage boolean|nil
---@return string|number
function terminal:make_button(bToggle,_bRawImage)
    expect(true,0,self,"terminal")
    expect(false,1,bToggle,"boolean","nil")
    self.active_window = setmetatable({
        text = "button",
        color = {
            text = colors.red,
            back = colors.yellow,
        },
        self = self,
    },{__index = button})
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
    setmetatable(self,{__index = button})
    util.table.setType(self,"button")
    util.table.setType(self.active_window,"button_window")
    util.table.setType(self.default_window,"button_window")
    return self.ID
end

---@diagnostic disable-next-line: duplicate-set-field
---@param color number
function button:setTextColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.text = color
end
---@param sText string
function button:setText(sText)
    expect(false,1,sText,"string")
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
        -- i do hate it but it is nessary to slow down the system
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

function button:redraw()
    expect(true,0,self,"button","button_window")
    if self:isUpDating()
    then
        local window = self
        if util.table.getType(self) ~= "button_window"
        then
            if self:isActive()
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
        if window.text and window.text:len() <=SizeX
        then
            native.setTextColor(window.color.text or colors.black)
            native.setCursorPos(RealPosX+(Cx-((window.text:len()/2))),RealPosDepth+Cy-1)
            native.write(window.text)
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
local progress_bar = setmetatable({},{__index = terminal})
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
function progress_bar:setfilledColor(color)
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
    setmetatable(self,{__index = progress_bar})
    util.table.setType(self,"progress_bar")
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
    built in functions
    thse come with the module 
    these are basic functions not made for any specific purpose
--]]

-- usr input
-- this is a turns a user interface (aka editor window or prompt)
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
    --- AutoComplete : list|nil
    --- 
    --- autoRap -- raps the text menu
    --- menu : table of functions used when left or right Ctrl is clicked when called the system will give you the current Line and the window in string format
    ---@param sContent string|nil
    ---@param TblSettings table|nil
function terminal:Chat_Box(sContent,TblSettings)
    expect(true,0,self,"terminal")
    sContent = expect(false,1,sContent,"string","nil") or ""
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    TblSettings.default_BackgroundColor = field(2,TblSettings,"default_BackgroundColor","number","nil") or colors.white
    TblSettings.default_TextColor = field(2,TblSettings,"default_TextColor","number","nil") or colors.black
    TblSettings.AutoComplete_BackgroundColor = field(2,TblSettings,"AutoComplete_BackgroundColor","number","nil") or colors.gray
    TblSettings.AutoComplete_TextColor = field(2,TblSettings,"AutoComplete_TextColor","number","nil") or colors.white
    TblSettings.keywords = field(2,TblSettings,"keywords","table","function","nil")
    TblSettings.keyword_textColor = field(2,TblSettings,"keyword_textColor","number","nil") or colors.blue
    TblSettings.AutoComplete = field(2,TblSettings,"AutoComplete","table","function","nil")
    TblSettings.menu = field(2,TblSettings,"menu","table","nil") or {}
    TblSettings.AutoWrap = field(2,TblSettings,"autoWrap","boolean","nil")
    TblSettings.scroll = field(2,TblSettings,"scroll","number","nil")
    TblSettings.tab_spaces = field(2,TblSettings,"tab_spaces","number","nil")
    local chatBox,menu
    local run = true
    TblSettings.menu.exit = function (word)
        sContent = chatBox:getVersion()
        run = false
    end
    do -- sets up the windows
        local termSizeX,termSizeY = self:getSize()
        TblSettings.scroll = field(2,TblSettings,"scroll","number","nil") or termSizeY
        if not pcall(range,0,termSizeX,20) or not pcall(range,0,termSizeY,10)
        then
            error("terminal size minimum of 10 by 10",2)
        end
        chatBox = self:create(1,1,termSizeX,termSizeY)
        chatBox:upDate(true)
        chatBox:make_textBox(TblSettings.AutoWrap,TblSettings.tab_spaces)
        chatBox:setCursorBlink(true)
        local terminal_centerX,terminal_centerY = self:getCenter()
        menu = self:create(terminal_centerX-7,terminal_centerY-5,15,10)
    end

    local function getLastword()
        local line = chatBox:getSentence()
        ---@diagnostic disable-next-line: cast-local-type
        local words = util.string.split(line," ")
        return words[#words]
    end

    local function highlight_keyword()
        local word = getLastword()
        local highlight = false
        if type(TblSettings.keywords) == "function"
        then
            highlight = TblSettings.keywords(word)
        elseif TblSettings.keywords
        then
            for _,v in pairs(TblSettings.keywords) do
                if word == v
                then
                    highlight = TblSettings.keyword_textColor
                    break
                end
            end
        end
        if highlight
        then
            chatBox:upDate(false)
            chatBox:write(("\b"):rep(#word))
            chatBox:setTextColor(highlight)
            local fullReDraw = chatBox:write(word)
            chatBox:setTextColor(TblSettings.default_TextColor)
            chatBox:upDate(true)
            if fullReDraw
            then
                chatBox:redraw()
            else
                chatBox:redrawLine()
            end
        end
    end
    do -- loads and highlights the text
        chatBox:setTextColor(TblSettings.default_TextColor)
        chatBox:setBackgroundColor(TblSettings.default_BackgroundColor)
        chatBox:clear()
        chatBox:upDate(false)
        local letters = util.string.split(sContent)
        for _,v in pairs(letters) do
            if string.match(v,"%s")
            then
                highlight_keyword()
            end
            chatBox:write(v)
        end
        chatBox:upDate(true)
        chatBox:redraw()
    end

    local autoList = {}
    local function getAutoList()
        local incompleteWord = getLastword()
        if type(TblSettings.AutoComplete) == "function"
        then
            autoList = TblSettings.AutoComplete(incompleteWord)
        else
            local lastincompleteChar = incompleteWord:sub(#incompleteWord)
            local Matches = {}
            for _, choice in pairs(TblSettings.AutoComplete) do
                local Choice_Char = choice:sub(1,1)
                if Choice_Char == lastincompleteChar and Choice_Char ~= " "
                then
                    table.insert(Matches,choice)
                end
            end
            autoList = Matches
        end
    end
    local menu_list = {}
    local end_CursorPosX,end_CursorPosY
    local currentSel
    for i in pairs(TblSettings.menu) do
        table.insert(menu_list,i)
    end
    local primaryMode = true
    local Pos = 1
    local autoflag = false
    -- redraw/draws the autocompletion to the screen
    local function reDraw()
        autoflag = true
        if #autoList == 0
        then
            autoflag = false
            return
        end
        chatBox:upDate(false) -- disable live updates to the window
        chatBox:setBackgroundColor(TblSettings.AutoComplete_BackgroundColor)
        chatBox:setTextColor(TblSettings.AutoComplete_TextColor)
        local fullRedraw
        fullRedraw,end_CursorPosX,end_CursorPosY = chatBox:write(currentSel,true,true)
        chatBox:setBackgroundColor(TblSettings.default_BackgroundColor)
        chatBox:setTextColor(TblSettings.default_TextColor)
        chatBox:upDate(true)
        if not fullRedraw
        then
            chatBox:redrawLine()
        else
            chatBox:redraw()
        end
    end
    --- these are the autoComplete functions
    local function AutoClear()
        if not autoflag
        then
            return
        end
        chatBox:setCursorPos(end_CursorPosX,end_CursorPosY)
        chatBox:write(("\b"):rep(#currentSel+1))
        autoflag = false
    end
    local function AcceptCompletion()
        chatBox:setBackgroundColor(TblSettings.default_BackgroundColor)
        chatBox:setTextColor(TblSettings.default_TextColor)
        chatBox:write(currentSel,true)
        autoflag = false
    end
    local function chooseWord(n)
        if #autoList == 0
        then
            return
        end
        autoflag = true
        Pos = Pos + (n or 1)
        if Pos > #autoList
        then
            Pos = 0
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
            highlight_keyword()
            chatBox:write("\n")
        end,
        [keys.down] = function ()
            if autoflag and autoList
            then
                AutoClear()
                chooseWord(1)
            else
                local CursorPosX,CursorPosY = chatBox:getCursorPos()
                local termSizeX,termSizeY = chatBox:getSize()
                local offsetX,offsetY = chatBox:getOffset()
                local redraw = false    
                local tempLines = select(2,chatBox:getCurrentLine(nil,1))
                if not tempLines
                then
                    return
                end
                if offsetY > 0 and CursorPosY == termSizeY
                then
                    offsetY = offsetY + 1
                    redraw = true
                else
                    CursorPosY = CursorPosY + 1
                end
                local len = #tempLines
                if len > offsetX+(termSizeX)
                then
                    CursorPosX = termSizeX
                    offsetX = (len-termSizeX)+1
                    chatBox:setOffset(offsetX)
                    redraw = true
                elseif CursorPosX+offsetX > len
                then
                    local mth = math.abs(len-offsetX)
                    CursorPosX = mth+1
                end
                chatBox:setOffset(nil,offsetY)
                chatBox:setCursorPos(CursorPosX,CursorPosY)
                if redraw
                then
                    chatBox:redraw()
                end
            end
        end,
        [keys.up] = function ()
            if autoflag and autoList
            then
                AutoClear()
                chooseWord(-1)
            else
                local CursorPosX,CursorPosY = chatBox:getCursorPos()
                local offsetX,offsetY = chatBox:getOffset()
                local termSizeX = chatBox:getSize()
                local CurrentY_greator_then_1_flag = CursorPosY > 1
                local offsetY_flag = offsetY > 0
                if not CurrentY_greator_then_1_flag
                then
                    return
                end
                local line_length = select(2,chatBox:getCurrentLine(nil,-1))
                if not line_length
                then
                    return
                end
                ---@diagnostic disable-next-line: cast-local-type
                line_length = #line_length+1
                if not chatBox:iswrapped()
                then
                    if line_length <= termSizeX
                    then
                        offsetX = 0
                        CursorPosX = line_length
                        chatBox:setOffset(offsetX)
                    end
                elseif line_length >= termSizeX
                then
                    CursorPosX = termSizeX
                else
                    CursorPosX = line_length
                end
                if offsetY_flag and not CurrentY_greator_then_1_flag
                then
                    offsetY = offsetY - 1
                    chatBox:setOffset(offsetY)
                else
                    CursorPosY = CursorPosY - 1
                end
                chatBox:setCursorPos(CursorPosX,CursorPosY)
            end
        end,
        [keys.right] = function ()
            if autoflag
            then
                AcceptCompletion()
            else
                local CursorPosX,CursorPosY = chatBox:getCursorPos()
                local wordLen = #select(2,chatBox:getCurrentLine())
                local offsetX,offsetY = chatBox:getOffset()
                local termSizeX,termSizeY = chatBox:getSize()
                local Cursor_limit_x_flag = CursorPosX == termSizeX
                if Cursor_limit_x_flag and chatBox:iswrapped()
                then
                    if chatBox:getCurrentLine(1) ~= true
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
                    chatBox:setOffset(nil,offsetY)
                elseif Cursor_limit_x_flag and offsetX+CursorPosX <= wordLen
                then
                    offsetX = offsetX + 1
                    chatBox:setOffset(offsetX)
                elseif CursorPosX+offsetX <= wordLen
                then
                    CursorPosX = CursorPosX + 1
                end
                chatBox:setCursorPos(CursorPosX,CursorPosY)
            end
        end,
        [keys.left] = function ()
            if autoflag
            then
                AutoClear()
                return
            end
            local CursorPosX,CursorPosY = chatBox:getCursorPos()
            local offsetX,offsetY = chatBox:getOffset()
            local termSizeX = chatBox:getSize()
            local CursorPosX_greator_flag = CursorPosX > 1
            local OffsetX_flag = offsetX > 0
            local CursorPosY_flag = CursorPosY > 1
            local offsetY_flag = offsetY > 0
            if CursorPosX_greator_flag
            then
                CursorPosX = CursorPosX - 1
            elseif OffsetX_flag
            then
                offsetX = offsetX - 1
                chatBox:setOffset(offsetX)
            elseif chatBox:iswrapped()
            then
                if OffsetX_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                else
                    CursorPosY = CursorPosY - 1
                end
                chatBox:setOffset(nil,offsetY)
                CursorPosX = termSizeX
            elseif CursorPosX_greator_flag or offsetY_flag
            then
                if offsetY_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                elseif CursorPosY_flag
                then
                    CursorPosY = CursorPosY - 1
                end
                local line_length = #chatBox:getCurrentLine(nil,-1)
                offsetX = (line_length - termSizeX) + 1
                CursorPosX = termSizeX
                chatBox:setOffset(offsetX,offsetY)

            end
            chatBox:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.delete] = function ()
            if autoflag
            then
                return
            end
            local CursorPosX = chatBox:getCursorPos()
            if autoflag or CursorPosX == #select(2,chatBox:getCurrentLine())+1
            then
                return
            end
            chatBox:setCursorPos(CursorPosX+1)
            chatBox:write("\b")
        end,
        [keys.backspace] = function ()
            if autoflag
            then
                AutoClear()
            end
            chatBox:write("\b")
        end,
        [keys.home] = function ()
            if autoflag
            then
                AutoClear()
            end
            chatBox:setCursorPos(1)
            if not chatBox:iswrapped()
            then
                chatBox:setOffset(0)
            end
        end,
        [keys["end"]] = function ()
            local offsetX = chatBox:getOffset()
            local CursorPosX = chatBox:getCursorPos()
            local termSizeX = chatBox:getSize()
            local wordLen = #select(2,chatBox:getCurrentLine())
            if wordLen > termSizeX
            then
                if chatBox:iswrapped()
                then
                    return
                end
                offsetX = wordLen - termSizeX + 1
                CursorPosX = termSizeX
                chatBox:setOffset(offsetX)
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
                    chatBox:setOffset(offsetX)
                end
            end
            chatBox:setCursorPos(CursorPosX)
        end,
        [keys.tab] = function ()
            if autoflag
            then
                AcceptCompletion()
            else
                chatBox:write("\t")
            end
        end,
        [keys.leftShift] = function ()
            primaryMode = not primaryMode
        end,
        [keys.rightShift] = function ()
            primaryMode = not primaryMode
        end,
        [keys.leftCtrl] = function ()
            local action
            parallel.waitForAny(function ()
                while true do
                    local key = select(2,os.pullEventRaw("key"))
                    if key == keys.rightCtrl or key == keys.leftCtrl
                    then
                        menu:upDate(false)
                        chatBox:redraw()
                        break
                    end
                end
            end,function ()
                menu:upDate(true)
                local index = menu:run_list(menu_list,{message = "Menu"})
                action = TblSettings.menu[menu_list[index]]
            end)
            if action
            then
                action()
            end
            menu:upDate(false)
            chatBox:redraw()
            chatBox:restoreCursor()
        end,
    }
    keyMap[keys.rightCtrl] = keyMap[keys.leftCtrl]
    local filter = {
        ["char"] = function (Char)
            if autoflag
            then
                AutoClear()
            elseif string.match(Char,"%s")
            then
                highlight_keyword()
            end
            chatBox:write(Char)
            local cursorPosX,CursorPosY = chatBox:getCursorPos()
            if cursorPosX > #chatBox.lines[CursorPosY] and TblSettings.AutoComplete
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
                return
            end
            local letters = util.string.split(stri)
            for _,v in pairs(letters) do
                if v:match("%s")
                then
                    highlight_keyword()
                end
                chatBox:write(v)
            end
        end,
        ["key"] = function (number)
            local action = keyMap[number]
            if action
            then
                action()
            end
        end,
        ["mouse_click"] = function (_,positionX,positionY)
            local CursorPosY = select(2,chatBox:getCursorPos())
            local line_y = select(2,chatBox:getLine(nil,positionY))
            if not line_y
            then
                if positionY  == CursorPosY + 1
                then
                    chatBox:setCursorPos(1,positionY)
                end
                return
            elseif line_y and positionX > #line_y
            then
                chatBox:setCursorPos(#line_y+1,positionY)
            else
                chatBox:setCursorPos(positionX,positionY)
            end
        end,
        ["mouse_scroll"] = function (direction)
            local offsetY = select(2,chatBox:getOffset())
            if direction < 0
            then
                direction = direction-TblSettings.scroll
            else
                direction = direction+TblSettings.scroll
            end
            local newPos = offsetY+direction
            if newPos <= 0
            then
                newPos = 0
            end
            chatBox:setOffset(nil,newPos)
        end,
    }
    parallel.waitForAny(function ()
        while true do
            chatBox:restoreCursor()
            coroutine.yield()
        end
    end,function ()
        while run do
            local event = table.pack(os.pullEventRaw())
            ---@type function|nil
            local action = filter[event[1]]
            if action
            then
                action(table.unpack(event,2))
            end
        end
    end)
    return sContent
end

-- usr input
-- this is a turns a user interface (aka editor window or prompt)
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
    --- AutoComplete : list|nil
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
    self:setTextColor(TblSettings.default_TextColor)
    self:setBackgroundColor(TblSettings.default_BackgroundColor)
    self:clear()
    self:setCursorPos(1,1)
    self:write(message)
    self:setCursorBlink(true)
    local function getLastword()
        local line = self:getSentence()
        ---@diagnostic disable-next-line: cast-local-type
        local words = util.string.split(line," ")
        return words[#words]
    end
    local autoList = {}
    local function getAutoList()
        local incompleteWord = getLastword()
        if type(TblSettings.AutoComplete) == "function"
        then
            autoList = TblSettings.AutoComplete(incompleteWord)
        else
            local lastincompleteChar = incompleteWord:sub(#incompleteWord)
            local Matches = {}
            for _, choice in pairs(TblSettings.AutoComplete) do
                local Choice_Char = choice:sub(1,1)
                if Choice_Char == lastincompleteChar and Choice_Char ~= " "
                then
                    table.insert(Matches,choice)
                end
            end
            autoList = Matches
        end
    end
    local sContent
    local end_CursorPosX,end_CursorPosY
    local messageLen = #message 
    local currentSel
    local run = true
    local Pos = 1
    local autoflag = false
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
        currentSel = table.concat(util.string.split(autoList[Pos]),nil,2)
        reDraw()
    end
    local keyMap = {
        [keys.enter] = function ()
            if autoflag
            then
                AutoClear()
            end
            self:setCursorPos(messageLen+1,1)
            self:write(("\b"):rep(messageLen+1))

            sContent = self:getVersion()
            run = false
        end,
        [keys.down] = function ()
            if autoflag and autoList
            then
                AutoClear()
                chooseWord(1)
            end
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
            end
        end,
        [keys.right] = function ()
            if autoflag
            then
                AcceptCompletion()
            else
                local CursorPosX,CursorPosY = self:getCursorPos()
                local wordLen = #select(2,self:getCurrentLine())
                local offsetX,offsetY = self:getOffset()
                local termSizeX,termSizeY = self:getSize()
                local Cursor_limit_x_flag = CursorPosX == termSizeX
                if Cursor_limit_x_flag and self:iswrapped()
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
                elseif Cursor_limit_x_flag and offsetX+CursorPosX <= wordLen
                then
                    offsetX = offsetX + 1
                    self:setOffset(offsetX)
                elseif CursorPosX+offsetX <= wordLen
                then
                    CursorPosX = CursorPosX + 1
                end
                self:setCursorPos(CursorPosX,CursorPosY)
            end
        end,
        [keys.left] = function ()
            if autoflag
            then
                AutoClear()
                return
            end
            local CursorPosX,CursorPosY = self:getCursorPos()
            local offsetX,offsetY = self:getOffset()
            local termSizeX = self:getSize()
            local CursorPosX_greator_flag = CursorPosX > 1
            local OffsetX_flag = offsetX > 0
            local CursorPosY_flag = CursorPosY > 1
            local offsetY_flag = offsetY > 0
            local effectivePos = offsetX + CursorPosX
            if CursorPosX_greator_flag
            then
                if effectivePos - 1 <= messageLen and offsetX > 0
                then
                    offsetX = offsetX - 1
                    self:setOffset(offsetX)
                elseif effectivePos - 1 > messageLen
                then
                    CursorPosX = CursorPosX - 1
                end
            elseif OffsetX_flag
            then
                if effectivePos -1 >= messageLen
                then
                    CursorPosX = CursorPosX + 1
                end
                offsetX = offsetX - 1
                self:setOffset(offsetX)
            elseif self:iswrapped()
            then
                if OffsetX_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                else
                    CursorPosY = CursorPosY - 1
                end
                self:setOffset(nil,offsetY)
                CursorPosX = termSizeX
            elseif offsetY_flag
            then
                if offsetY_flag and not CursorPosY_flag
                then
                    offsetY = offsetY - 1
                elseif CursorPosY_flag
                then
                    CursorPosY = CursorPosY - 1
                end
                local line_length = #self:getCurrentLine(nil,-1)
                offsetX = (line_length - termSizeX) + 1
                CursorPosX = termSizeX
                self:setOffset(offsetX,offsetY)
            end
            self:setCursorPos(CursorPosX,CursorPosY)
        end,
        [keys.delete] = function ()
            if autoflag
            then
                return
            end
            local CursorPosX = self:getCursorPos()
            if autoflag or CursorPosX == #select(2,self:getCurrentLine())+1
            then
                return
            end
            self:setCursorPos(CursorPosX+1)
            self:write("\b")
        end,
        [keys.backspace] = function ()
            if autoflag
            then
                AutoClear()
            end
            local CursorPosX = self:getCursorPos()
            local offsetX = self:getOffset()
            local true_Pos = CursorPosX+offsetX
            if true_Pos <= messageLen+1
            then
                return
            end
            self:write("\b")
        end,
        [keys.home] = function ()
            if autoflag
            then
                AutoClear()
            end
            self:setCursorPos(1)
            if not self:iswrapped()
            then
                self:setOffset(0)
            end
        end,
        [keys["end"]] = function ()
            local offsetX = self:getOffset()
            local CursorPosX = self:getCursorPos()
            local termSizeX = self:getSize()
            local wordLen = #select(2,self:getCurrentLine())
            if wordLen > termSizeX
            then
                if self:iswrapped()
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
            self:write(Char)
            local cursorPosX,CursorPosY = self:getCursorPos()
            if cursorPosX > #self.lines[CursorPosY] and TblSettings.AutoComplete
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
                return
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
        ["mouse_click"] = function (_,positionX,positionY)
            local CursorPosY = select(2,self:getCursorPos())
            local line_y = select(2,self:getLine(nil,positionY))
            if not line_y
            then
                if positionY  == CursorPosY + 1
                then
                    self:setCursorPos(1,positionY)
                end
                return
            elseif line_y and positionX > #line_y
            then
                self:setCursorPos(#line_y+1,positionY)
            else
                self:setCursorPos(positionX,positionY)
            end
        end,
        ["mouse_scroll"] = function (direction)
            local offsetY = select(2,self:getOffset())
            self:setOffset(nil,offsetY+direction)
        end,
    }
    parallel.waitForAny(function ()
        while true do
            self:restoreCursor()
            os.pullEventRaw()
        end
    end,function ()
        while run do
            local event = table.pack(os.pullEventRaw())
            ---@type function|nil
            local action = filter[event[1]]
            if action
            then
                action(table.unpack(event,2))
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
    function GUI.buttonRun(bLoop,...)
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
            if event[1] == "mouse_click" or event[1] == "monitor_touch"
            then
                local isScreen = true
                if event[1] == "monitor_touch" and terminal_data == nil
                then
                    isScreen = false
                elseif event[1] == "mouse_click" and terminal_data ~= nil
                then
                    isScreen = false
                elseif event[1] == "monitor_touch" and terminal_data.name ~= event[2]
                then
                    isScreen = false
                end
                if isScreen
                then
                    for i,v in pairs(buttons) do
                        expect(true,i+1,v,"button")
                        local RealPosX,RealPosDepth = v:getRealPos()
                        local SizeX,SizeY = v:getSize()
                        local PosX,PosY = event[3],event[4]
                        if PosX >= RealPosX and PosY >= RealPosDepth and PosX <= SizeX+RealPosX and SizeY <= SizeY+RealPosDepth
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
function terminal:prompt(mess,_yesText,_noText)
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
        Yes = buttons_menu:create(1,1,x/2,y,true)
        Yes:make_button()
        Yes:setID(1)
        No = buttons_menu:create(x/2+1,1,x/2+1,y,true)
        No:make_button()
        Yes:setActivate(function ()
            bool = true
            _bRun = false
        end)
        Yes.default_window:setTextColor(colors.white)
        Yes.active_window:setTextColor(colors.white)
        Yes.default_window:setBackgroundColor(colors.red)
        Yes.active_window:setBackgroundColor(colors.blue)
        Yes.default_window:setText(_yesText or "yes")
        Yes.active_window:setText(_yesText or "yes")

        No:setID(0)
        No:setActivate(function ()
            bool = false
            _bRun = false
        end)
        No.default_window:setTextColor(colors.white)
        No.active_window:setTextColor(colors.white)
        No.default_window:setBackgroundColor(colors.red)
        No.active_window:setBackgroundColor(colors.blue)
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
            bool = false
            Yes:OverRide_status()
            No:OverRide_status()
        end,
        [keys.left] = function ()
            bool = true
            Yes:OverRide_status()
            No:OverRide_status()
        end,
        [keys.enter] = function ()
            _bRun = false
        end
    }
    while _bRun do
        local event = table.pack(os.pullEvent())
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
                local RealPosX,RealPosY = tmp:getRealPos()
                local SizeX,SizeY = tmp:getSize()
                local PosX,PosY = event[3],event[4]
                if PosX >= RealPosX and PosY >= RealPosY and PosX <= SizeX+RealPosX and PosY <= SizeY+RealPosY
                then
                    tmp:trigger()
                    break
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
---@param OTbl table|terminal
---@param TblSettings table|nil
function terminal:run_list(OTbl,TblSettings) 
    expect(true,0,self,"terminal")
    expect(false,1,OTbl,"table")
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    TblSettings.Defaut_option_textColor = field(2,TblSettings,"Defaut_option_textColor","number","nil") or colors.blue
    TblSettings.default_option_backgeoundColor = field(2,TblSettings,"default_option_backgeoundColor","number","nil") or colors.green
    TblSettings.select_option_textColor = field(2,TblSettings,"select_option_textColor","number","nil") or colors.red
    TblSettings.select_option_backgeoundColor = field(2,TblSettings,"select_option_backgeoundColor","number","nil") or colors.purple
    TblSettings.message_BackgroundColor = field(2,TblSettings,"message_BackgroundColor","number","nil") or colors.gray
    TblSettings.message_TextColor  = field(2,TblSettings,"message_TextColor","number","nil") or colors.white
    if #OTbl == 0
    then
        error("table is empty",2)
    end
    self:upDate(true)
    local termSizeX,termSizeY = self:getSize()
    range(0,termSizeY,2)
    local Pages = {{}}
    local Prompt = self:create(1,1,termSizeX,1,true)
    Prompt:make_textBox()
    local canv = self:create(1,2,termSizeX,termSizeY-2,true)
    canv:setBackgroundColor(self:getBackgroundColor())
    local Page = self:create(1,termSizeY,termSizeX,1,true)
    Page:make_textBox()
    Page:setBackgroundColor(TblSettings.message_BackgroundColor or colors.white)
    Page:setTextColor(TblSettings.message_TextColor or colors.black)
    do -- sperates the tbl into pages
        local PagesCount = 1
        local Cy = 1
        for i,v in pairs(OTbl) do
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
    if otpLen > 1 and GUI.buttonRun
    then
        Prompt:reposition(2,1,termSizeX-1,1)
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
    end
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
        else
            ---@diagnostic disable-next-line: cast-local-type
            Prompt = nil
        end
    end
    Pages[1][1].active = true
    self:redraw()
    local selected = 1
    local function start()
        local run = true
        while run do
            if self:isUpDating()
            then
                local event = {os.pullEventRaw()}
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
                elseif event[1] == "mouse_click"
                then
                    for _,v in pairs(Pages[CurrentPage]) do
                        local Posx,Posy = v.getRealPos()
                        local SizeX,SizeY = v:getSize()
                        SizeX = ( SizeX + Posx )-1
                        SizeY = (SizeY + Posy)-1
                        if event[3] >= Posx and event[3] <=SizeX and event[4] >= Posy and event[4] <= SizeY
                        then
                            selected = v:trigger()
                            run = false
                            break
                        end
                    end
                end
            else
                coroutine.yield()
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
