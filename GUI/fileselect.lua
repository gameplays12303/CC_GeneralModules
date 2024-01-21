local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect = (require and require("generalModules.expect2") or dofile("generalModules/expect2.lua")).expect
return function (terminal,_sStartDir,message,AccpetFiles,AccpetDirs)
    expect(true,1,terminal,"terminal","nil")
    _sStartDir = expect(false,2,_sStartDir,"string","nil") or ""
    expect(false,3,message,"string","nil")
    expect(false,4,AccpetFiles,"boolean","nil")
    expect(false,5,AccpetDirs,"boolean","nil")
    if not message
    then
        message = "select "
        if AccpetDirs 
        then
            message = message.."Directory"
        end
        if AccpetDirs and AccpetFiles
        then
            message = message.." or File"
        elseif AccpetDirs
        then
            message = message.." File"
        end
    end
    if AccpetDirs ~= nil and not AccpetDirs and AccpetFiles ~= nil and not AccpetFiles
    then
        error("arguments 4 & 5 can't both be false",2)
    end
    if not terminal.run_list
    then
        error("nessary function missing",2)
    end
    if not fs.exists(_sStartDir)
    then
        error(("%s:not found"):format(_sStartDir),2)
    end
    if not fs.isDir(_sStartDir)
    then
        error(("%s:is not a Directory"):format(_sStartDir),0)
    end
    local dir = _sStartDir
    while true do
        local list = util.file.list(dir,AccpetFiles,true)
        if dir ~= _sStartDir
        then
            table.insert(list,"back")
        end
        table.insert(list,"exit()")
        
        local fileselected = list[terminal:run_list(list,{message = ("CurrentDir:%s:%s"):format(dir,message)})]
        if fileselected == "exit()"
        then
            break
        end
        if fileselected ~= "back"
        then
            local Path = fs.combine(dir,fileselected)
            local actions = {}
            if fs.isDir(Path)
            then
                if AccpetDirs
                then
                    table.insert(actions,"select")
                end
                table.insert(actions,"open")
            else
                table.insert(actions,"select")
            end
            table.insert(actions,"back")
            local selected = actions[terminal:run_list(actions,{message = "choose your action"})]
            if selected == "select"
            then
                return Path
            elseif selected == "open"
            then
               dir = Path
            end
        else
            dir = util.file.getDir(dir)
        end
    end
    return nil
end