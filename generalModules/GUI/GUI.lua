---@diagnostic disable: duplicate-set-field, undefined-field

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
-- this is a custom terminal and will return a textBox
---@class terminal
local terminal = setmetatable({},{__disabledSetMeta = true})
setmetatable(native,{__index = GUI})
GUI = setmetatable({
    textBox = {
        x = 1,
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
end
function GUI.reposition()
    return true
end
function GUI.getABS()
    return 1,1
end
function GUI.isVisible()
    return true  
end
function GUI.redrawAll()
    return true
end

--- builds a terminal to draw to
util.table.setType(GUI,"terminal")
function terminal:reset()
    self.children = {}
    self:redraw(false)
end
function terminal:getSize()
    return self.window.width,self.window.height
end
function terminal:redraw(_redrawChildren)
    local nativeColor = native.getBackgroundColor()
    if self:isVisible()
    then
        local aX,aY = self:getABS()
        local x,y = self:getSize()
        native.setBackgroundColor(self:getBackgroundColor())
        restorePallet(self)
        for i = 0,y do
            native.setCursorPos(aX,aY+i)
            native.write((" "):rep(x))
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
    local Sx,Sy = self:getSize()
    local x = math.ceil(Sx/2)
    local y = math.ceil(Sy/2)
    return ((x > 0  and x) or 1),((y > 0  and y) or 1)
end 
---comment
---@param bTrue boolean
---@return boolean
function terminal:setVisible(bTrue)
    expect(false,1,bTrue,"boolean")
    self.visible = bTrue
    return true
end

-- this creates a new instance of the Parent terminal and then stores the new terminazl as a child in the Parent
-- the child table is a weak table meaning when you close the textBox the garbage will clean it out
---comment
---@param nX number
---@param nY number
---@param nWidth number
---@param nHeight number
---@param Visible boolean|nil
function terminal:create(nX,nY,nWidth,nHeight,Visible)
    expect(true,0,self,"terminal")
    expect(false,1,nX,"number")
    expect(false,2,nY,"number")
    expect(false,3,nWidth,"number")
    expect(false,4,nHeight,"number")
    expect(false,5,Visible,"boolean","nil")
    local instance
    do
        local x,y = self:getSize()
        range(1,nX,1,x)
        range(2,nY,1,y)
        range(3,nWidth,1,x-nX+1)
        range(4,nHeight,1,y-nY+1)
    end
    instance = setmetatable({
        window = {
            x = nX,
            y = nY,
            width = nWidth,
            height = nHeight,
        },
        pixels = {},
        color = {back = colors.white,palette = util.table.copy(self.color.palette,true)},
        visible = Visible or false,
        children = setmetatable({},{__mode = "v"})
    },{__index = terminal})
    util.table.setType(instance,"terminal")
    table.insert(self.children,instance)
    function instance.reposition(new_x,new_y,new_width,new_height,new_Parent)
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
                x,y = self:getSize()
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
            self.children[select(2,util.table.find(self.children,instance))] = nil
            self = new_Parent
            table.insert(self.children,instance)
        end
        self:redraw()
        return true
    end
    function instance.getABS()
        local x,y = instance:getPosition()
        local Px,Py = self:getABS()
        return Px+(x-1),Py+(y-1)
    end
    function instance.isVisible()
        if self:isVisible()
        then
            return instance.visible
        end
        return false
    end
    function instance.redrawParent()
        return self:redraw()
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

            -- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
            -- SPDX-License-Identifier: LicenseRef-CCPL
            --- An API for advanced systems which can draw pixels and lines, load and draw
            -- image files. You can use the `colors` API for easier color manipulation. In
            -- CraftOS-PC, this API can also be used in graphics mode.
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
                for x = 1, sLine:len() do
                    tLine[x] = tColourLookup[string.byte(sLine, x, x)] or 0
                    Size.x = x > Size.x or Size.x
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
        if self:isVisible()
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
    ---@param x number
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
    if self:isVisible()
    then
        local aX,aY = self:getABS()
        local x,y = self:getSize()
        local CBG = self:getBackgroundColor()
        native.setBackgroundColor(CBG)
        restorePallet(self)
        for i = 1,y do
            native.setCursorPos(aX,aY+i-1)
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
function terminal:makeCanv()
    self.pixels = {}
    self.children = nil
    setmetatable(self,{__index = canvis})
    util.table.setType(self,"canvis")
end



-- turns a terminal into a textBox to draw text to
---@class textBox
---@diagnostic disable-next-line: assign-type-mismatch
local textBox = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function textBox:clear()
    expect(true,0,self,"textBox")
    self.lines = {}
    self:redraw()
end
function textBox:clearLine()
    expect(true,0,self,"textBox")
    local y = select(2,self:getCursorPos())
    if self.lines[y] ~= nil
    then
        self.lines[y] = nil
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
---@return table
function textBox:getLine()
    expect(true,0,self,"textBox")
    local y = select(2,self:getCursorPos())
    return self.lines[y]
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
    if self:isVisible()
    then
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
        restorePallet(self)
        local x,y = self:getSize()
        local Ax,Ay = self:getABS()
        local offX,offY = self:getOffset()
        local CX,CY = 1,1
        local CBC = self:getBackgroundColor()
        while true do
            if CX > x
            then
                CX = 1
                CY = CY + 1
                if CY > y
                then
                    break
                end
            end
            local Tbl = (self.lines[CY+offY] or {})[CX+offX]
            native.setCursorPos(Ax+(CX-1),Ay+(CY-1))
            if Tbl
            then
                native.setBackgroundColor(Tbl.color.back)
                native.setTextColor(Tbl.color.text)
                native.write(Tbl.Char)
            else
                native.setBackgroundColor(CBC)
                native.write(" ")
            end
            CX = CX + 1
        end
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
    end

end
function textBox:redrawLine()
    expect(true,0,self,"textBox")
    if self:isVisible()
    then
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
        local y = select(2,self:getCursorPos())
        local offX,offY = self:getOffset()
        local Tbl = self.lines[y+offY] or {}
        offY = nil
        local x = self:getSize()
        local Cx,count= 1,1
        restorePallet(self)
        local Y,Ax
        do
            local U,Ay = self:getABS()
            Ax = U
            Y = Ay+(y-1)
        end
        local CBC,CTC = self:getBackgroundColor(),self:getTextColor()
        while true do
            if Cx > x
            then
                break
            end
            native.setCursorPos(Ax+(Cx-1),Y)
            local CT = Tbl[count+offX]
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
            count = count + 1
            Cx = Cx + 1
        end
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
    end
end
function textBox:restoreCursor()
    expect(true,0,self,"textBox")
    if self:isVisible()
    then
        restorePallet(self)
        native.setBackgroundColor(self:getBackgroundColor())
        native.setTextColor(self:getTextColor())
        do
            local Ax,Ay = self:getABS()
            local x,y = self:getCursorPos()
            native.setCursorPos(Ax+(x-1),Ay+(y-1))
        end
        native.setCursorBlink(self:getCursorBlink())
    end
    return true
end
---comment
---@param offX number
---@param offY number
function textBox:setOffset(offX,offY)
    if self.autoWrap
    then
        error("can't use offsets as this is a wrapped textBox",2)
    end
    expect(false,1,offX,"number","nil")
    expect(false,2,offY,"number","nil")
    do
        local SizeX,SizeY = self:getSize()
        offX = offX and range(1,offX,0,SizeX) or offX
        offY = offY and range(2,offY,0,SizeY) or offY
    end
    self.Offset.x = offX or self.Offset.x
    self.Offset.y = offY or self.Offset.y
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
---@param nX number
---@param nY number
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
---comment
---@param sText string
---@param bOverWrite boolean
---@param keepPos boolean|nil
function textBox:write(sText,bOverWrite,keepPos)
    expect(true,0,self,"textBox")
    expect(false,1,sText,"string")
    expect(false,2,bOverWrite,"boolean","nil")
    local textBoxlengh = self:getSize()
    if self.autoWrap
    then
        ---@diagnostic disable-next-line: cast-local-type
        sText = util.string.wrap(textBoxlengh,sText)
    end
        ---@diagnostic disable-next-line: param-type-mismatch
    local result = util.string.split(sText)
    local flagLines = false
    local X,Y = self:getCursorPos()
    do
        --- writes the sentece to the table
        -- one charator at a time
        local flagOffset = false
        self.lines[Y] = self.lines[Y] or {}
        local offX,offY = self:getOffset()
        local CB,CT = self:getBackgroundColor(),self:getTextColor()
        for index=1,#sText do
            if not self.lines[Y+offY]
            then
                self.lines[Y+offY] = {}
            end
            if result[index] == "\b"
            then
                if X == textBoxlengh and offX > 0
                then
                    offX = offX - 1
                elseif X > 1
                then
                    X = X - 1
                end
                table.remove(self.lines[Y+offY],(X+offX))
            elseif result[index] == "\n"
            then
                Y = Y + 1
                X = 1
                flagLines = true
                self.lines[Y+offY] = self.lines[Y+offY] or {}
                if offX > 0
                then
                    offX = 0
                    flagOffset = true
                end
            elseif result[index] == "\t"
            then
                local count = 0
                repeat
                    table.insert(self.lines[Y+offY],(X+offX),{
                        Char = " ",
                        color = {back = CB,text = CT}
                    })
                    if X == textBoxlengh
                    then
                        offX = offX + 1
                        flagOffset = true
                    else
                        X = X + 1
                    end
                    count = count + 1
                until count == self.tab_spaces
            elseif not bOverWrite
            then
                table.insert(self.lines[Y+offY],(X+offX),{
                    Char = result[index],
                    color = {back = CB,text = CT}
                })
                if X == textBoxlengh
                then
                    offX = offX + 1
                    flagOffset = true
                else
                    X = X + 1
                end
            else
                self.lines[Y+offY][X+offX] = {
                    Char = result[index],
                    color = {back = CB,text = CT}
                }
                if X == textBoxlengh
                then
                    offX = offX + 1
                    flagOffset = true
                else
                    X = X + 1
                end
            end
        end
        if flagOffset and not self.autoWrap
        then
            self:setOFFX(offX)
        end
        if not keepPos
        then
            self:setCursorPos(X,Y)
        end
    end
    -- requests a redraw
    if self:isVisible()
    then
        if not flagLines -- dose not runs if only one line was effected
        then
            self:redrawLine()
        else
            self:redraw()
        end
    end
end
---comment
---@return string
function textBox:getRawVersion()
    expect(true, 0, self, "textBox")
    local sRaw = ""
    local spaceCount = 0
    local excape = false
    for c, y in pairs(self.lines) do
        for _, x in pairs(y) do
            if x.Char == " " then
                spaceCount = spaceCount + 1
            else
                spaceCount = 0
            end
            print(x.Char)
            -- Check if spaceCount reaches 4 to convert to tab
            if spaceCount == self.tab_spaces  then
                sRaw = string.sub(sRaw,1,#sRaw-self.tab_spaces) .. "\\t"
                spaceCount = 0  -- Reset spaceCount after converting to tab
            else
                sRaw = sRaw .. x.Char
            end
        end
        if c ~= self.lines
        then
            sRaw = sRaw.."\n"
        end
    end
    return sRaw  -- Return the generated raw version
end
---comment
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



-- turns a terminal into a button
---@class button
---@diagnostic disable-next-line: assign-type-mismatch
local button = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
---comment
---@param color number
function button:setTextColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.text = color
end
---comment
---@param sText string
function button:setText(sText)
    expect(false,1,sText,"string")
    self.text = sText
end
function button:redraw()
    if self.self:isVisible()
    then
        local SX,SY = self.self:getSize()
        local APX,APH = self.self:getABS()
        local Cx,Cy = self.self:getCenter()
        local CTC = native.getTextColor()
        local CBC = native.getBackgroundColor()
        restorePallet(self.self)
        native.setBackgroundColor(self.color.back)
        for y = 1,SY do
            for x = 1,SX do
                native.setCursorPos(APX+(x-1),APH+(y-1))
                native.write("\t")
            end
        end
        if self.text and self.text:len() <= SX
        then
            native.setTextColor(self.color.text or colors.black)
            native.setCursorPos(APX+(Cx-((self.text:len()/2))),APH+Cy-1)
            native.write(self.text)
        end
        native.setTextColor(CTC)
        native.setBackgroundColor(CBC)
    end
end
function button:setID(_n)
    expect(false,1,_n,"number","string")
    self.self.ID = _n
end
function button:getID()
    return self.self.ID
end
---comment
---@param fn function
function button:setActivate(fn)
    expect(false,1,fn,"function")
    self.self.Activate = fn
end
---comment
---@param fn function
function button:setDeactivate(fn)
    expect(false,1,fn,"function")
    self.self.Deactivate = fn
end

---comment
---@param bToggle boolean
---@param _bRawImage boolean|nil
---@return string|number
function terminal:make_button(bToggle,_bRawImage)
    expect(true,0,self,"terminal")
    expect(false,1,bToggle,"boolean","nil")
    self.self = self
    self.selected = setmetatable({
        self = self,
        text = "button",
        color = {
            text = colors.red,
            back = colors.yellow,
        },
    },{__index = button})
    self.default = setmetatable({
        self = self,
        text = "button",
        color = {
            text = colors.blue,
            back = colors.green,
        },
    },{__index = button})
    self.toggle = bToggle or false
    self.active = false
    self.Activate = function ()
        return nil
    end
    if _bRawImage
    then
        ---@diagnostic disable-next-line: param-type-mismatch
        terminal.makeCanv(self.default)
        ---@diagnostic disable-next-line: param-type-mismatch
        terminal.makeCanv(self.selected)
        self.default.text = nil
        self.selected.text = nil
        self.default.color.text = nil
        self.selected.color.text = nil
        self.default.window = self.window
        self.selected.window = self.window
    end
    local ID = math.random()
    self.text = "term"
    self.ID = ID
    self.children = nil
    setmetatable(self,{__index = button})
    util.table.setType(self,"button")
    return ID
end
--progress Bar
local progress_bar = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function progress_bar:redraw()
    local orginBackgroundColor = native.getBackgroundColor()
    local x = self:getSize()
    local count = math.floor((self.checkpoints_filled/self.checkpoints)*x)
    local absoluteX,absolutelY = self:getABS()
    native.setCursorPos(absoluteX,absolutelY)
    native.setBackgroundColor(self:getBackgroundColor())
    native.write((" "):rep(x))
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

do -- usr inputs
    -- Function to calculate Levenshtein distance between two strings
    local function levenshtein(s1, s2)
    local len1, len2 = #s1, #s2
    local matrix = {}
    for i = 0, len1 do
        matrix[i] = {[0] = i}
    end
    for j = 0, len2 do
        matrix[0][j] = j
    end
    for i = 1, len1 do
        for j = 1, len2 do
            local cost = s1:sub(i, i) == s2:sub(j, j) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,
                matrix[i][j-1] + 1,
                matrix[i-1][j-1] + cost
            )
        end
    end
    return matrix[len1][len2]
    end

    local function findClosestMatch(incompleteWord, choices)
        local minDistance = math.huge
        local closestMatches = {}
        for _, choice in ipairs(choices) do
            local distance = levenshtein(incompleteWord, choice)
            if distance < minDistance then
                minDistance = distance
                closestMatches = { choice }
            elseif distance == minDistance then
                table.insert(closestMatches, choice)
            end
        end
        return closestMatches
    end
    -- multiple line UsrInput
    ---comment
    ---@param _sContent string
    ---@param Tblsettings table|nil
    ---@return string|nil
    function terminal:Usrinput(_sContent,Tblsettings)
        expect(true,0,self,"terminal")
        _sContent = expect(false,1,_sContent,"string","nil") or ""
        Tblsettings = expect(false,2,Tblsettings,"table","nil") or {}
        local ParentSizeX,ParentSizeY = self:getSize()
        range(0,ParentSizeX,25)
        range(0,ParentSizeY,12)
        Tblsettings.menu = util.table.copy(field(2,Tblsettings,"menu","table","nil") or {})
        local run = true
        Tblsettings.menu.exist = function ()
            run = false
        end
        for i,v in pairs(Tblsettings.menu) do
            if not pcall(expect,false,0,v,"function")
            then
                error(("expected %s of Tblsettings.menu to be function got %s"):format(i,type(v)),2)
            end
        end
        Tblsettings.defualt_BackgroundColor = field(2,Tblsettings,"defualt_BackgroundColor","number","nil") or colors.black
        Tblsettings.complete_BackgroundColor = field(2,Tblsettings,"complete_BackgroundColor","number","nil") or colors.gray
        Tblsettings.defualt_TextColor = field(2,Tblsettings,"defualt_TextColor","number","nil") or colors.white
        Tblsettings.complete_TextColor = field(2,Tblsettings,"complete_TextColor","number","nil") or colors.blue
        Tblsettings.update = field(2,Tblsettings,"update","function","nil") or function (Content)
        end
        Tblsettings.autoComplete = field(2,Tblsettings,"autoComplete","function","table","nil") or function ()
            return nil
        end
        local textbox = self:create(1,1,ParentSizeX,ParentSizeY,true)
        textbox:make_textBox()
        local autoWord = nil
        local Pos = 1
        local autoList = {}
        local autoflag,insert = false,true
        local menu
        do
            local centerX,centerY = self:getSize()
            menu = self:create(centerX-5,centerY-3,10,6,true)
        end
        local function get_autoComplete_list(lastWord)
            if type(Tblsettings.autoComplete) == "function"
            then
                ---@diagnostic disable-next-line: redundant-parameter
                return Tblsettings.autoComplete(lastWord)
            end
            return Tblsettings.autoComplete or {}
        end
        local function clearAuto()

        end
        local function acceptCompletion()
        end
        local keyMap = {
            [keys.backspace] = function ()
                if autoflag
                then
                    clearAuto()
                end
                textbox:write("\b")
            end,
            [keys.leftCtrl] = function ()
                if autoflag
                then
                    clearAuto()
                end
                local list = {}
                for i,_ in pairs(Tblsettings.menu) do
                    table.insert(list,i)
                end
                parallel.waitForAny(function ()
                    while true do
                        if os.pullEventRaw("key")[2] == keys.leftCtrl
                        then
                            break
                        end
                    end
                end,function ()
                    local choice = menu:run_list(list,{mess = "options menu"})
                    local bool,err = pcall(Tblsettings.menu[list[choice]],textbox:getRawVersion())
                    if not bool
                    then
                        error(("%s from Tblsettings.menu has crashed because of %s"):format(list[choice],err),0)
                    end
                end)
            end,
            [keys.insert] = function ()
                insert = not insert
            end,
            [keys.delete] = function ()
                if autoflag
                then
                    return
                end
                local cursorPosX = textbox:getCursorPos()
                textbox:setCursorPos(cursorPosX+1)
                textbox:write("\b")
            end,
            [keys.home] = function ()
                if autoflag
                then
                    clearAuto()
                end
                textbox:setCursorPos(1)
            end,
            [keys["end"]] = function ()
                if autoflag
                then
                    return
                end
                local cursorPosY = select(2,textbox:getCursorPos())
                textbox:setCursorPos(#textbox.lines[cursorPosY])
            end,
            [keys.enter] = function ()
                if autoflag
                then
                    clearAuto()
                end
                textbox:write("\n")
            end,
            [keys.tab] = function ()
                if autoflag
                then
                    acceptCompletion()
                else
                    textbox:write("\t")
                end
            end,
            [keys.left] = function ()
                if autoflag
                then
                    clearAuto()
                end
                local cursorPosX = textbox:getCursorPos()
                if cursorPosX > 1
                then
                    textbox:setCursorPos(cursorPosX-1)
                end
            end,
            [keys.right] = function ()
                if autoflag
                then
                    acceptCompletion()
                    return
                end
                local cursorPosX,cursorPosY = textbox:getCursorPos()
                local nextPos = cursorPosX+1
                if nextPos < #textbox.lines[cursorPosY]
                then
                    textbox:setCursorPos(nextPos)
                end
            end,
            [keys.up] = function ()
                if autoflag
                then

                else
                end

            end,
            [keys.down] = function ()
                if autoflag
                then
                else
                end
            end,
        }
        while run do
            local events = table.pack(os.pullEvent())
            if self:isVisible()
            then
                if events[1] == "char"
                then
                    local CurrentPosX = select(1,textbox:getCursorPos())
                    local textBoxSizeX = select(1,textbox:getSize())
                    if CurrentPosX == textBoxSizeX
                    then
                        local offset = select(2,textbox:getOffset())
                        textbox:setOffset(offset+1)
                    else
                        textbox:setOffset(CurrentPosX+1)
                    end
                    textbox:write(events[2])
                    local lastWord = {}
                    while true do
                        
                    end
                elseif events[1] == "key"
                then
                    local choice = keyMap[events[2]]
                    if choice
                    then
                        choice()
                    end
                elseif events[1] == "mouse_click"
                then

                elseif events[1] == "mouse_scroll"
                then 
                    if events[2] == 1
                    then

                    else
                        keyMap[keys.down]()
                    end
                end
            end
        end
    end
end

-- you only get this api if you are a advance computer
-- it only uses the mouse_click event 
if native.isColor()
then
    ---comment
    ---@param bnot_Loop boolean|nil
    ---@param ... table|button
    ---@return unknown
    function GUI.buttonRun(bnot_Loop,...)
    expect(false,1,bnot_Loop,"boolean")
    local Pages = {}
    do
        local argus = {...}
        for i,v in pairs(argus) do
            expect(false,i+1,v,"table")
        end
        if #argus == 0
        then
            error("no button APIs",2)
        end
        if util.table.getType(argus[1]) ~= "button"
        then
            for _,v in pairs(argus[1]) do
                if util.table.getType(v) == "button"
                then
                    table.insert(Pages,v)
                end
            end
            if #Pages == 0
            then
                error("button APIs not found",2)
            end
        else
            for _,v in pairs(argus) do
                if util.table.getType(v) == "button"
                then
                    table.insert(Pages,v)
                end
            end
        end
    end
    for _,v in pairs(Pages) do
        v.self:setVisible(true)
    end
    local choice
    parallel.waitForAny(
        function ()
            while true do
                for _,v in pairs(Pages) do
                    if v.active
                    then
                        v.selected:redraw()
                    else
                        v.default:redraw()
                    end
                end
                coroutine.yield()
            end
        end,
        function ()
            local run = true
            while run do
                local event = table.pack(os.pullEventRaw())
                if event[1] == "mouse_click" or event[1] == "monitor_touch"
                then
                    for _,v in pairs(Pages) do
                        local Px,Py = v.self:getABS()
                        local Sx,SY = v.self:getSize()
                        local x,y = event[3],event[4]
                        if x >= Px and x <= (Sx+Px)-1 and y >= Py and y <= (SY+Py)-1 and v:isVisible()
                        then
                            if v.self.toggle
                            then
                                if v.self.active
                                then
                                    v.self.active = false
                                    v.self.Deactivate()
                                else
                                    v.self.active = true
                                    v.self.Activate()
                                end
                            else
                                v.selected:redraw()
                                coroutine.yield()
                                v.self.Activate()
                            end
                            choice = v:getID()
                            if not bnot_Loop
                            then
                                run = false
                                break
                            end
                        end
                    end
                end
            end
        end
    )
    return choice
    end
end

---comment
---@param mess string
---@param _yesText string|nil
---@param _noText string|nil
---@return boolean
function terminal:prompt(mess,_yesText,_noText)
    expect(true,0,self,"terminal")
    expect(false,1,mess,"string")
    expect(false,2,_yesText,"string","nil")
    expect(false,3,_noText,"string","nil")
    local bool = false
    local message,Yes,no
    do
        local x,y = self:getSize()
        range(0,x,10)
        range(0,y,4)
        message = self:create(1,1,x,y-2,true)
        local buttons_menu = self:create(2,y-3,x-1,3,true)
        x,y = buttons_menu:getSize()
        Yes = buttons_menu:create(1,1,x/2,y,true)
        Yes:make_button()
        Yes.default:setTextColor(colors.white)
        Yes.selected:setTextColor(colors.white)
        Yes.default:setBackgroundColor(colors.black)
        Yes.selected:setBackgroundColor(colors.blue)
        Yes.default:setText(_yesText or "yes")
        Yes.selected:setText(_yesText or "yes")
        no = buttons_menu:create(x/2+1,1,x/2-1,y,true)
        no:make_button()
        no.default:setTextColor(colors.white)
        no.selected:setTextColor(colors.white)
        no.default:setBackgroundColor(colors.black)
        no.selected:setBackgroundColor(colors.blue)
        no.default:setText(_noText or "no")
        no.selected:setText(_noText or "no")
    end
    message:make_textBox()
    self:setBackgroundColor(colors.brown)
    self:redraw()
    do -- writes the message to the screen
        local termSizeX = message:getSize()
        if #mess > termSizeX
        then
            mess = util.string.wrap(termSizeX,mess)
        end
        message:setBackgroundColor(colors.brown)
        message:setTextColor(colors.purple)
        message:write(mess)
        message:redraw()
    end
    parallel.waitForAny(function ()
        while true do
            coroutine.yield()
            if bool
            then
                Yes.selected:redraw()
                no.default:redraw()
            else
                no.selected:redraw()
                Yes.default:redraw()
            end
        end
    end,function ()
        local _bRun = true
        local handle = {
            [keys.right] = function ()
                bool = false
            end,
            [keys.left] = function ()
                bool = true
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
                local tmp
                if bool
                then
                    tmp = Yes
                else
                    tmp = no
                end
                local absoluteX,absolutelY = tmp:getABS()
                local SizeX,SizeY = tmp:getSize()
                if event[2] >= absoluteX and event[2] <= SizeX and event[3] >= absolutelY and event[3] <= SizeY
                then
                    bool = not bool
                    _bRun = false
                    break
                end
            end
        end
    end)
    return bool
end

---comment
---@param self terminal
---@param OTbl table|terminal
---@param TblSettings table|nil
function terminal:run_list(OTbl,TblSettings) 
    expect(true,0,self,"terminal")
    expect(false,1,OTbl,"table")
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    field(2,TblSettings,"DOTC","number","nil")
    field(2,TblSettings,"DOBC","number","nil")
    field(2,TblSettings,"SOTC","number","nil")
    field(2,TblSettings,"SOBC","number","nil")
    field(2,TblSettings,"MBC","number","nil")
    field(2,TblSettings,"MTC","number","nil")
    if TblSettings.help
    then
        local stri = "\n"
        local function Add(mess,Type,meaning)
            stri = stri..("[\"%s\"] = \"%s\",meaning:%s\n"):format(mess,Type,meaning)
        end
        Add("message","string nil","will be displayed on the first row")
        Add("MBC","number nil","message_BackgroundColor")
        Add("MTC","number nil","message_TextColor")
        Add("OTC","number nil","option_textColor")
        Add("OBC","number nil","option_backgeoundColor")
        error(("table of settings %s"):format(stri),0)
    end
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    if #OTbl == 0
    then
        error("table is empty",2)
    end
    self:setVisible(true)
    local x,y = self:getSize()
    range(0,y,2)
    local Pages = {{}}
    local Prompt = self:create(1,1,x,1,true)
    Prompt:make_textBox()
    local canv = self:create(1,2,x,y-2,true)
    canv:setBackgroundColor(self:getBackgroundColor())
    local Page = self:create(1,y,x,1,true)
    Page:make_textBox()
    Page:setBackgroundColor(TblSettings.MBC or colors.white)
    Page:setTextColor(TblSettings.MTC or colors.black)
    do -- sperates the tbl into pages
        local PagesCount = 1
        local Cy = 1
        for i,v in pairs(OTbl) do
            if Cy > y-2
            then
                Cy = 1
                PagesCount = PagesCount + 1
                Pages[PagesCount] = {}
            end
            local temp = canv:create(1,Cy,x,1,true)
            temp:make_button()
            temp.selected:setText(v)
            temp.default:setText(v)
            temp.default:setBackgroundColor(TblSettings.DOBC or temp.default.color.back)
            temp.default:setTextColor(TblSettings.DOTC or temp.default.color.text)
            temp.selected:setBackgroundColor(TblSettings.SOBC or temp.selected.color.back)
            temp.selected:setTextColor(TblSettings.SOTC or temp.selected.color.text)
            temp:setID(i)
            table.insert(Pages[PagesCount],temp)
            Cy = Cy + 1
        end
    end
    local left,right,smallScreen
    local otpLen = #Pages
    local CurrentPage,currentSel = 1,1
    local function setPage(n)
        canv:clear(false)
        for _,v in pairs(Pages[CurrentPage]) do
            v:setVisible(false)
        end
        CurrentPage = CurrentPage + n
        for i,v in pairs(Pages[CurrentPage]) do
            v:setVisible(true)
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
        Prompt.reposition(2,1,x-1,1)
        left = self:create(1,1,1,1,true)
        right = self:create(x,1,1,1,true)
        left:make_button(false)
        right:make_button(false)
        left.selected:setTextColor(TblSettings.SOTC or left.selected.color.text)
        left.default:setTextColor(TblSettings.DOTC or left.default.color.text)
        left.selected:setBackgroundColor(TblSettings.SOBC or left.selected.color.back)
        left.default:setBackgroundColor(TblSettings.DOBC or left.default.color.back)
        left.default:setText("<")
        left.selected:setText("<")
        right.default:setText(">")
        right.selected:setText(">")
        right.selected:setTextColor(TblSettings.SOTC or right.selected.color.text)
        right.selected:setBackgroundColor(TblSettings.SOBC or right.selected.color.back)
        right.default:setTextColor(TblSettings.DOTC or right.default.color.text)
        right.default:setBackgroundColor(TblSettings.DOBC or right.default.color.back)
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
        left:setVisible(true)
        right:setVisible(true)
    end
    do -- builds the prompt textBox
        local message = field(2,TblSettings,"message","string","nil") or "please choose"
        local x2 = select(1,Prompt:getSize())
        if #message < x2
        then
            local x3,y3 = Prompt:getCenter()
            Prompt:setCursorPos(x3-(#message/2)+1,y3)
            Prompt:setBackgroundColor(TblSettings.MBC or colors.white)
            Prompt:setTextColor(TblSettings.MTC or colors.black)
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
            if self:isVisible()
            then
                local event = {os.pullEventRaw()}
                if event[1] == "key"
                then
                    if event[2] == keys.down and currentSel < #Pages[CurrentPage]
                    then
                        Pages[CurrentPage][currentSel].active = false
                        currentSel = currentSel + 1
                        Pages[CurrentPage][currentSel].active = true
                    elseif event[2] == keys.up and currentSel > 1
                    then
                        Pages[CurrentPage][currentSel].active = false
                        currentSel = currentSel - 1
                        Pages[CurrentPage][currentSel].active = true
                    elseif event[2]  == keys.enter
                    then
                        selected = Pages[CurrentPage][currentSel]:getID()
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
                        local Posx,Posy = v.getABS()
                        local sX,sY = v:getSize()
                        sX = (sX + Posx)-1
                        sY = (sY + Posy)-1
                        if event[3] >= Posx and event[3] <= sX and event[4] >= Posy and event[4] <= sY
                        then
                            selected = v:getID()
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
                if v.active then
                    v.selected:redraw()
                else
                    v.default:redraw()
                end
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
---time to build the GUI modules
return GUI
