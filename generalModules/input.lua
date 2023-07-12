---@diagnostic disable: need-check-nil
local input = {}
local expect = require("cc.expect")
local completion = require("cc.completion")
local util = require("utilties")
local insert = table.insert
local pack = table.pack
local term = term
---@overload fun(message:string,replace:string|nil,history:table|nil,list:table|nil)
function input.prompt(message,replace,history,list)
    expect(1,message,"string","nil")
    expect(2,replace,"string","nil")
    expect(3,history,"table","nil")
    expect(4,list,"table","nil")
    local x,_ = term.getCursorPos()
    print(message)
    local _,y  = term.getCursorPos()
    term.setCursorPos(x,y)
    return tostring(read(replace,history,function(text) if list ~= nil then return completion.choice(text,list) end end))
end
---@overload fun(Table:table,mess:string,optionsColor:number|nil,TextColor:number|nil,BackgroundColor:number|nil)
function input.BasicMenu(Table,mess,optionsColor,TextColor,BackgroundColor)
    expect(1,Table,"table")
    expect(2,mess,"string")
    expect(3,optionsColor,"number","nil")
    expect(4,TextColor,"number","nil")
    expect(5,BackgroundColor,"number","nil")
    optionsColor = optionsColor or colors.white
    TextColor = TextColor or colors.white
    BackgroundColor = BackgroundColor or colors.green
    local Sx = term.getSize()
    local originalBack = term.getBackgroundColor()
    local originalText = term.getTextColor()
    local run = true
    local sel = 1
    while run do
        term.setBackgroundColor(BackgroundColor)
        term.clear()
        term.setCursorPos(math.ceil(( Sx / 2) - (mess:len() / 2)),1)
        print(mess)
        for _=0,Sx do
            term.write("=")
        end
        local _,Current = term.getCursorPos()
            term.setCursorPos(0,Current+1)
        for i,v in pairs(Table) do
            local _,y2 = term.getCursorPos()
            if sel == i
            then
                local stri = ("[%s]:%s"):format(i,v)
                term.setCursorPos(math.ceil((Sx / 2) - (stri:len() / 2)),y2)
                term.setTextColor(optionsColor)
                print(stri)
                term.setTextColor(TextColor)
            else
                local stri = ("%s:%s"):format(i,v)
                term.setCursorPos(math.ceil((Sx / 2) - (stri:len() / 2)),y2)
                term.setTextColor(optionsColor)
                print(stri)
                term.setTextColor(TextColor)
            end
        end
        local _,key = os.pullEvent("key")
        if key == keys.up and  sel>1
        then
            sel = sel-1
        elseif key == keys.down and sel<#Table
        then
            sel = sel+1
        elseif key == keys.enter
        then
            term.setBackgroundColor(originalBack)
            term.setTextColor(originalText)
            term.clear()
            term.setCursorPos(1,1)
            return sel
        end
    end
end
input.ADVmenu = {}
-- W.I.P
---@diagnostic disable-next-line: undefined-doc-name
---@overload fun(x:number,y:number,width:number,height:number,ID:number|string,Parent:term,func:function,...)
input.ADVmenu.button = function(x,y,width,height,ID,Parent,func,...)
    expect(1,x,"number")
    expect(2,y,"number")
    expect(3,width,"number")
    expect(4,height,"number")
    expect(5,ID,"number","string")
    Parent = expect(6,Parent,"table","nil") or term.current()
    expect(7,func,"function","nil")
    local handle
    local info = {x = x,y = y,width = width+x-1,hight = y+height-1,ID = ID or math.random(),window = window.create(Parent,x,y,width,height),content = {},defualt = {},highlight = {}}
    handle = {info = info}
    function handle.update()
        local Parent = term.current()
---@diagnostic disable-next-line: redundant-parameter
        term.redirect(info.window)
        local x1,y1 = term.getSize()
        local CX,CY = 0,0
        while true do
            term.write("")
            CX = CX +1
            if CX == x1 and CY ~= y1
            then
                CX = 0
                CY = CY +1
            else
                break
            end
        end
        if info.content.Text
        then
            term.setCursorPos(info.content.x,info.content.y)
            term.write(info.content.Text or "")
        end
---@diagnostic disable-next-line: redundant-parameter
        term.redirect(Parent)
        Parent.redraw()
    end
    handle.defualts = {}
    function handle.defualts.setTextColor(color)
        expect(1,color,"number")
        if not util.color.isColor(color)
        then
            error(("%s:is not a valid color"):format(color),2)
        end
        info.defualt.TextColor = color
        handle.defualts.UnHighlight()
        return true
    end
    function handle.defualts.setBackgroundColor(color)
        expect(1,color,"number")
        if not util.color.isColor(color)
        then
            error(("%s:is not a valid color"):format(color),2)
        end
        info.defualt.BackgroundColor = color
        handle.defualts.UnHighlight()
    end
    function handle.defualts.UnHighlight()
        info.window.setBackgroundColor(info.defualt.BackgroundColor or colors.yellow)
        info.window.setTextColor(info.defualt.TextColor or colors.blue)
        handle.update()
    end
    handle.highlights = {}
    function handle.highlights.setTextColor(color)
        expect(1,color,"number")
        if not util.color.isColor(color)
        then
            error(("%s:is not a valid color"):format(color),2)
        end
        info.highlight.TextColor = color
        handle.highlights.Highlight()
        return true
    end
    function handle.highlights.setBackgroundColor(color)
        expect(1,color,"number")
        if not util.color.isColor(color)
        then
            error(("%s:is not a valid color"):format(color),2)
        end
        info.highlight.BackgroundColor = color
        handle.highlights.Highlight()
    end
    function handle.highlights.highlight()
        info.window.setBackgroundColor(info.highlight.BackgroundColor or colors.blue)
        info.window.setTextColor(info.highlight.TextColor or colors.white)
        handle.update()
    end
    function handle.write(_sText,X1,Y1)
        local X2,Y2 = info.window.getSize()
        local Table = {}
        do
            local X3 = 0
            local Y3 = 0
            local stri = _sText
            local T2
            local T3
            while true do
                if Y3 == Y2
                then
                    break
                elseif X3 == X2
                then
                    Y3  = Y3+1
                end
                T2 = string.sub(stri,1,X3)
                T3 = string.sub(stri,X3,#T3)
                insert(Table,T2)
                stri = T3
                if T3 == ""
                then
                    break
                end
                X3 = X3+1
            end
        end
        _sText = table.concat(_sText,"\n")
        info.content.Text = _sText
        info.content.x = X1
        info.content.y = Y1
        handle.update()
    end
    function handle.setVisible(bTrue)
        expect(1,bTrue,"boolean")
        info.window.setVisible(bTrue)
        handle.update()
        return true
    end
    function handle.setPos(Term,x1,y1,width1,height1)
        info.window.reposition(Term,x1,y1,width1,height1)
        info.x = x1
        info.y = y1
        info.width = width1+x1-1
        info.height = height+y1-1
        handle.update()
        return true
    end
    function handle.run()
        handle.highlights.highlight()
        if not info.func
        then
            return info.ID
        end
        local results = pack(info.func(unpack(info.argu)))
        handle.defualts.UnHighlight()
        return unpack(results)
    end
    return handle
end
input.ADVmenu.Text = function (x,y,width,hight,ID,Parent)
    expect(1,x,"number")
    expect(2,y,"number")
    expect(3,width,"number")
    expect(4,hight,"number")
    expect(5,ID,"number","string")
    Parent = expect(6,Parent,"table","nil") or term.current()
end
return input