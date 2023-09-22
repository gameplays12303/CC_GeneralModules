---@diagnostic disable: param-type-mismatch

-- desgin to be used to select a file from within  a program

local expect = require("cc.expect").expect
local  util =  require("generalModules.utilties")
local input = require("generalModules.input")
---@param _sDir string|nil
---@param Text string
---@param CFile boolean|nil
---@param CDir boolean|nil
---@param BC number
---@param TC number
return function (_sDir,Text,CFile,CDir,BC,TC)
    expect(1,_sDir,"string")
    expect(2,Text,"string")
    expect(3,CFile,"boolean","nil")
    expect(4,CDir,"boolean","nil")
    expect(5,BC,"number","nil")
    expect(6,TC,"number","nil")
    if BC and not util.color.isColor(BC)
    then
        error("2 argument is not a color",2)
    end
    if TC and not util.color.isColor(TC)
    then
        error("3 argument is not a color",2)
    end
    if not fs.exists(_sDir)
    then
        error(("%s:dose not exists"):format(_sDir),2)
    elseif not fs.isDir(_sDir)
    then
        error(("%s:is not directory"):format(_sDir),2)
    end
    local dir = _sDir or ""
    while true do
        local list = util.file.list(dir,true,true)
        print(dir)
        for _,v in pairs(list) do
            v = fs.getName(v)
        end
        if dir ~= _sDir
        then
            table.insert(list,"back")
        end
        table.insert(list,"exit")
        local choice = input.BasicMenu(list,("%s: :Current dir: %s "):format(Text,dir ~= "" and dir or "Root"),TC,TC,BC)
        if list[choice] == "back"
        then
            dir = util.file.getDir(dir)
        elseif list[choice] == "exit"
        then
            return ""
        else
            local Path = fs.combine(dir,list[choice])
            local actions
            if not fs.isDir(Path)
            then
                if CFile ~= false
                then
                    actions = {"select","back"}
                else
                    actions = {"back"}
                end
            else
                if CDir ~= false
                then
                    actions = {"open","select","back"}
                else
                    actions = {"open","back"}
                end
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
