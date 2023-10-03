---@diagnostic disable: undefined-field, duplicate-set-field

---@diagnostic disable-next-line: undefined-field
local native = type(term) == "function" and term() or type(term.current) == "function" and term.current() or type(term.native) == "function" and term.native() or type(term.native) == "table" and term.native or term
local util = require and require("generalModules.utilties") or BIOS.dofile("generalModules/utilties.lua")
local expect = (require and require("generalModules.expect2") or BIOS.dofile("generalModules/expect2.lua"))
local range = expect.range
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
---@diagnostic disable-next-line: param-type-mismatch
native = util.table.copy(native)
local GUI = {}
local focus = GUI
local function isColor(color)
    if not util.color.isColor(color)
    then
        error(("%s: invalid color"):format(color),3)
    end
end
---@class terminal

local function restorePallet(Tbl)
    for i,v in pairs(Tbl.color.palette) do
        if util.color.isColor(i)
        then
            native.setPaletteColor(i,table.unpack(v))
        end
    end
end

-- this is a custom terminal and will return a window
---@class terminal
local terminal = setmetatable({},{__disableMeta = true})
setmetatable(native,{__index = GUI})
GUI = setmetatable({
    window = {
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
function GUI.reposition()
    return true
end
function GUI.getABS()
    return 1,1
end
function GUI.isVisble()
    return true  
end
function GUI.redrawAll()
    return true
end
util.table.setType(GUI,"blueprint")
function terminal:clear()
    self.pixels = {}
    self:redraw()
end
function terminal:getSize()
    return self.window.width,self.window.height 
end
function terminal:redraw()
    local nativeColor = native.getBackgroundColor()
    if self:isVisble()
    then
        local aX,aY = self:getABS()
        local x,y = self:getSize()
        local CBG = self:getBackgroundColor()
        restorePallet(self)
        for i = 1,y do
            for C = 1,x do
                native.setCursorPos(aX+(C-1),aY+(i-1))
                if self.pixels[i] and self.pixels[i][C]
                then
                    native.setBackgroundColor(self.pixels[i][C])
                else
                    native.setBackgroundColor(CBG)
                end
                native.write("\t")
            end
        end
        for _,v in pairs(self.children) do
        v:redraw()
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
---comment
---@param color number
---@param x number
---@param y number
function terminal:setPixel(color,x,y)
    expect(true,0,self,"terminal")
    expect(false,1,color,"number")
    expect(false,2,x,"number")
    expect(false,3,y,"number")
    do
        local Rx,Ry = self:getSize()
        range(2,x,0,Rx)
        range(3,y,0,Ry)
    end
    self.pixels[y] = self.pixels[y] or {}
    self.pixels[y][x] = color
end
function terminal:isFocus()
    return self == focus
end
function terminal:setFocus()
    focus = self
    return true
end
---comment
---@param bTrue boolean
---@return boolean
function terminal:setVisible(bTrue)
    expect(false,1,bTrue,"boolean")
    self.visible = bTrue
    return true
end

-- this creates a new instance of the Parent window and then stores the new window as a child in the Parent
-- the child table is a weak table meaning when you close the window the garbage will clean it out
---comment
---@param nX number
---@param nY number
---@param nWidth number
---@param nHeight number
---@param Visible boolean|nil
function terminal:Term(nX,nY,nWidth,nHeight,Visible)
    expect(true,0,self,"terminal","blueprint")
    expect(false,1,nX,"number")
    expect(false,2,nY,"number")
    expect(false,3,nWidth,"number")
    expect(false,4,nHeight,"number")
    expect(false,5,Visible,"boolean","nil")
    local instance
    do
        local x,y = self:getSize()
        range(1,nX,0,x)
        range(2,nY,0,y)
        range(3,nWidth,0,x)
        range(4,nHeight,0,y)
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
    function instance.reposition(new_x,new_y,new_width,new_height)
        expect(false,1,new_x,"number")
        expect(false,2,new_y,"number")
        expect(false,3,new_width,"number")
        expect(false,4,new_height,"number")
        do
            local x,y = self:getSize()
            print(tostring(self),x,y)
            range(1,new_x,1,x)
            range(2,new_y,1,y)
            range(3,new_width,1,x)
            range(4,new_height,1,y)
        end
        instance.window.x = new_x
        instance.window.y = new_y
        instance.window.width = new_width
        instance.window.height = new_height
        if self ~= GUI
        then
            self:redraw()
        end
        return true
    end
    function instance.getABS()
        local x,y = instance:getPosition()
        local Px,Py = self:getABS()
        return Px+(x-1),Py+(y-1)
    end
    function instance.isVisble()
        if self:isVisble()
        then
            return instance.visible
        end
        return false
    end
    function instance.redrawParent()
        return self:redraw()
    end
    return instance
end
-- just prepares the blueprint for use
do
    for _,v in pairs(colors) do
        if type(v) == "number" and util.color.isColor(v)
        then
            GUI:setPaletteColor(v,native.getPaletteColor(v))
        end
    end
end
-- 
---@class window
---@diagnostic disable-next-line: assign-type-mismatch
local window = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function window:clear()
    expect(true,0,self,"window")
    self.lines = {}
end
function window:clearLine()
    expect(true,0,self,"window")
    local y = select(self:getCursorPos())
    self.lines[y] = nil
end
function window:getCursorBlink()
    expect(true,0,self,"window")
    return self.Cursor.blink
end
function window:getCursorPos()
    expect(true,0,self,"window")
    return self.Cursor.pos.x,self.Cursor.pos.y
end

---comment
---@return table
function window:getLine()
    expect(true,0,self,"window")
    local y = select(2,self:getCursorPos())
    return self.lines[y]
end
---comment
---@return number
function window:getTextColor()
    expect(true,0,self,"window")
    return self.color.text
end
function window:getOffset()
    return self.window.Offset.x,self.window.Offset.y
end
---@diagnostic disable-next-line: duplicate-set-field
function window:redraw()
    expect(true,0,self,"window")
    if self:isVisble()
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
                native.write("\t")
            end
            CX = CX + 1
        end
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
    end

end
function window:redrawLine()
    expect(true,0,self,"window")
    if self:isVisble()
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
                native.write("\t")
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
function window:restoreCursor()
    expect(true,0,self,"window")
    if self:isVisble()
    then
        restorePallet(self)
        native.setBackgroundColor(self:getBackgroundColor())
        native.setTextColor(self:getTextColor())
        do
            local Ax,Ay = self:getABS()
            local x,y = self:getCursorPos()
            native.setCursorPos(Ax+(x-1),Ay+(y-1))
        end
    end
    return true
end
---comment
---@param _n number
---@param _bFlip boolean|nil
function window:setOFFX(_n,_bFlip)
    expect(false,1,_n,"number")
    expect(false,2,_bFlip,"boolean","nil")
    local offX = self:getOffset()
    local Y = select(2,self:getCursorPos())
    local w = self:getSize()
    local result
    if _bFlip
    then
        result = offX-_n
    else
        result = offX+_n
    end
    if result < 0
    then
        result = 0
    elseif result > #self.lines[Y]-w
    then
        result = #self.lines[Y]-w
    end
    self.window.Offset.x = result
end
---comment
---@param _n number
---@param _bFlip boolean|nil
function window:setOFFY(_n,_bFlip)
    expect(false,1,_n,"number")
    expect(false,2,_bFlip,"boolean","nil")
    local offY = select(2,self:getOffset())
    local h = select(2,self:getSize())
    local result
    if _bFlip
    then
        result = offY-_n
    else
        result = offY+_n
    end
    if result < 0
    then
        result = 0
    elseif result > #self.lines-h
    then
        result = #self.lines-h
    end
    self.window.Offset.y = result
end
---comment
---@param bTrue boolean
function window:setCursorBlink(bTrue)
    expect(true,0,self,"window")
    expect(false,1,bTrue,"boolean")
    self.Cursor.Blink = bTrue
end
---comment
---@param nX number
---@param nY number
function window:setCursorPos(nX,nY)
    expect(true,0,self,"window")
    expect(false,1,nX,"number")
    expect(false,2,nY,"number")
    do
        local x,y = self:getSize()
        range(1,nX,0,x)
        range(2,nY,0,y)
    end
    self.Cursor.pos.x = nX
    self.Cursor.pos.y = nY
end
---comment
---@param color number
function window:setTextColor(color)
    expect(true,0,self,"window")
    isColor(color)
    self.color.text = color
end
---comment
---@param sText string
---@param bOverWrite boolean
function window:write(sText,bOverWrite)
    expect(true,0,self,"window")
    expect(false,1,sText,"string")
    expect(false,2,bOverWrite,"boolean","nil")
    local result = {}
    local flagLines = false
    local X,Y = self:getCursorPos()
    for letter in sText:gmatch(".") do table.insert(result, letter) end
    do
        self.lines[Y] = self.lines[Y] or {}
        local offX,offY = self:getOffset()
        local CB,CT = self:getBackgroundColor(),self:getTextColor()
        for x=1,#sText do
            if result[x] == "\b"
            then
                table.remove(self.lines[Y+offY],(X+(x-1))+offX)
            elseif result[x] == "\n"
            then
                Y = Y + 1
                X = 1
                flagLines = true
            elseif not bOverWrite
            then
                table.insert(self.lines[Y+offY],(X+(x-1))+offX,{
                    Char = result[x],
                    color = {back = CB,text = CT}
                })
            else
                self.lines[Y+offY][(X+(x-1))+offX] = {
                    Char = result[x],
                    color = {back = CB,text = CT}
                }
            end
        end
    end
    if self:isVisble()
    then
        if not flagLines
        then
            self:redrawLine()
        else
            self:redraw()
        end
    end
end
---comment
---@param self terminal
function terminal:make_Window()
    expect(true,0,self,"terminal")
    do
        local meta = getmetatable(self) or {}
        meta.__index = window
        setmetatable(self,meta)
    end
    util.table.setType(self,"window")
    self.window.Offset = {}
    self.window.Offset.x = 0
    self.window.Offset.y = 0
    self.lines = {}
    self.Cursor = {pos = {x = 1,y = 1},blink = false}
    self.color.text = colors.black
    self.pixels = nil
    self.children = nil
end

-- button
---@class button
---@diagnostic disable-next-line: assign-type-mismatch
local button = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
---comment
---@param color number
function button:setTextColor(color)
    expect(false,1,color,"number")
    self.color.text = color
end
---comment
---@param sText string
function button:setText(sText)
    expect(false,1,sText,"string")
    self.text = sText
end
function button:redraw()
    if self.Parent:isVisble()
    then
        local SX,SY = self.Parent:getSize()
        local APX,APH = self.Parent:getABS()
        local CTC = native.getTextColor()
        local CBC = native.getBackgroundColor()
        restorePallet(self.Parent)
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
            native.setCursorPos(math.floor(APX+(SX-1)/2 - self.text:len() / 2 + .5),math.floor(APH+(SY-1)/ 2 + .5))
            native.write(self.text)
        end
        native.setTextColor(CTC)
        native.setBackgroundColor(CBC)
    end
end
---comment
---@param fn function
function button:setActivate(fn)
    expect(false,1,fn,"function")
    self.Parent.Activate = fn
end
---comment
---@param fn function
function button:setDeactivate(fn)
    expect(false,1,fn,"function")
    self.Parent.Deactivate = fn
end
if native.isColor()
then
    function GUI.buttonRun(bLoop,...)
    expect(false,1,bLoop,"boolean")
    local buttons = {}
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
                    table.insert(buttons,v)
                end
            end
            if #buttons == 0
            then
                error("button APIs not found",2)
            end
        else
            for _,v in pairs(argus) do
                if util.table.getType(v) == "button"
                then
                    table.insert(buttons,v)
                end
            end
        end
    end
    for _,v in pairs(buttons) do
        v.Parent:setVisible(true)
    end
    parallel.waitForAny(
        function ()
            while true do
                for i,v in pairs(buttons) do
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
                local event = table.pack(os.pullEvent("mouse_click"))
                for i,v in pairs(buttons) do
                    local Px,Py = v.Parent:getABS()
                    local Sx,SY = v.Parent:getSize()
                    local x,y = event[3],event[4]
                    if x >= Px and x <= Sx+Px and y >= Py and y <= SY+Py
                    then
                        if v.Parent.toggle
                        then
                            if v.Parent.active
                            then
                                v.Parent.active = false
                                v.Parent.Deactivate()
                            else
                                v.Parent.active = true
                                v.Parent.Activate()
                            end
                        else
                            v.selected:redraw()
                            coroutine.yield()
                            v.Parent.Activate()
                        end
                    end
                end
            end
        end
    )
    end
end
---comment
---@param self terminal
function terminal:make_button(bToggle)
    expect(true,0,self,"terminal")
    self.Parent = self
    self.selected = setmetatable({
        Parent = self,
        text = "button",
        color = {
            text = colors.red,
            back = colors.yellow,
        },
    },{__index = button})
    self.default = setmetatable({
        Parent = self,
        text = "button",
        color = {
            text = colors.blue,
            back = colors.green,
        },
    },{__index = button})
    if bToggle
    then
        self.toggle = bToggle
        self.active = false
    end
    self.Activate = function ()
        return nil
    end
    self.pixels = nil
    self.text = "term"
    self.children = nil
    setmetatable(self,{__index = button})
    util.table.setType(self,"button")
end


---comment
---@param self terminal
---@param OTbl table|terminal
---@param TblSettings table|nil
function terminal:run_list(OTbl,TblSettings)
    expect(true,0,self,"terminal")
    expect(false,1,OTbl,"table")
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    field(2,TblSettings,"OTC","number","nil")
    field(2,TblSettings,"OBC","number","nil")

    if TblSettings.help
    then
        local stri = "\n"
        local function Add(mess,Type,meaning)
            stri = stri..("[\"%s\"] = \"%s\",meaning:%s\n"):format(mess,Type,meaning)
        end
        Add("message","string nil","will be displayed on the first row")
        Add("MBC","number nil","message_BackgroundColor")
        Add("MTC","number nil","message_TextColor")
        error(("table of settings %s"):format(stri),0)
    end
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    if #OTbl == 0
    then
        error("table is empty",2)
    end
    local x,y = self:getSize()
    range(0,y,2)
    local buttons = {{}}
    local textWindow = self:Term(1,1,x,1)
    self:setVisible(true)
    textWindow:make_Window()
    textWindow:setVisible(true)
    local canv = self:Term(1,2,x,y-1)
    canv:setVisible(true)
    canv:setBackgroundColor(self:getBackgroundColor())
    do
        local Page = 1
        local Cy = 1
        for i,v in pairs(OTbl) do
            if Cy > y
            then
                Cy = 1
                Page = Page + 1
                buttons[Page] = {}
            end
            local temp = canv:Term(1,Cy,x,Cy,true)
            temp:make_button()
            print(temp:getSize(),Cy) os.pullEvent("key")
            temp:setText(v)
            table.insert(buttons[Page],temp)
            Cy = Cy + 1
        end
    end
    local left,right
    if #buttons > 1 and GUI.buttonRun
    then
        textWindow.reposition(2,1,x-1,1)
        left = GUI:Term(1,1,1,1)
        right = GUI:Term(x,1,x,1)
        left:make_button(false)
        right:make_button(false)
        left.default:setText("<")
        left.selected:setText("<")
        right.default:setText(">")
        right.selected:setText(">")
        left:setVisible(true)
        right:setVisible(true)
    end
    do
        local message = field(2,TblSettings,"message","string","nil") or "please choose"
        local x2,y2 = textWindow:getSize()
        if #message < x2
        then
            textWindow:setCursorPos(math.floor(x2/2 - message:len() / 2 + .5),math.floor(y2/ 2 + .5))
            textWindow:setBackgroundColor(field(2,TblSettings,"MBC","number","nil") or textWindow:getBackgroundColor())
            textWindow:setTextColor(field(2,TblSettings,"MTC","number","nil") or textWindow:getTextColor())
            textWindow:write(message)
        else
            textWindow = nil
        end
    end
    self:redraw()
    local function input()
    end
    local function redraw()
    end
end
--progress Bar
local bar = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function bar:redraw()
end
function bar:nextcheck(n)
end
function bar:setnumCheckpoints()
end
function terminal:progressBar()
    expect(true,0,self,"terminal")
end
---time to build the GUI modules
return GUI
