-- basic input system to prompt Usrs


---@diagnostic disable: need-check-nil
local input = {}
local expect = require("cc.expect")
local completion = require("cc.completion")
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
    BackgroundColor = BackgroundColor or colors.black
    local Sx = term.getSize()
    local originalBack = term.getBackgroundColor()
    local originalText = term.getTextColor()
    local sel = 1
    while true do
        term.setBackgroundColor(BackgroundColor)
        term.clear()
        term.setCursorPos(math.ceil(( Sx / 2) - (mess:len() / 2)),1)
        print(mess)
        for _=0,Sx do
            term.write("=")
        end
        do
            local Current = select(2,term.getCursorPos())
            term.setCursorPos(1,Current+1)
        end
        for i,v in pairs(Table) do
            local y2 = select(2,term.getCursorPos())
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
        local key = select(2,os.pullEvent("key"))
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

return input