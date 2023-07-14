-- desgin to be used to select a file when a program ask
-- to do : add start directory
local expect = require("cc.expect")
local  util = require("generalModules.utilties")
local input = require("generalModules.input")
---@overload fun(Text:string,bShowDir:boolean,bShowFiles:boolean,BC:number,TC:number)
return function (Text,BC,TC)
    expect(1,Text,"string")
    expect(2,BC,"number","nil")
    expect(3,TC,"number","nil")
    if BC and not util.color.isColor(BC)
    then
        error("2 argument is not a color",2)
    end
    if TC and not util.color.isColor(TC)
    then
        error("3 argument is not a color",2)
    end
    local dir = ""
    while true do
        local list = util.file.list(dir,true,true)
        print(dir)
        for _,v in pairs(list) do
            v = fs.getName(v)
        end
        table.insert(list,"back")
        local choice = input.BasicMenu(list,("%s: :Current dir: %s "):format(Text,dir ~= "" and dir or "Root"),TC,TC,BC)
        if list[choice] == "back"
        then
            dir = util.file.getDir(dir)
        else
            local Path = fs.combine(dir,list[choice])
            local actions
            if not fs.isDir(Path)
            then
                actions = {"select","back"}
            else
               actions = {"open","select","back"}
            end
            local choice2 = input.BasicMenu(actions,("choose what to do with this : %s"):format(list[choice]),TC,TC,BC)
            local act = actions[choice2]
            if act == "select"
            then
                return Path
            elseif act == "open"
            then
                dir = Path
            end
        end
    end
end
