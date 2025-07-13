local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect = (require and require("generalModules.expect2") or dofile("generalModules/expect2.lua")).expect
return function (terminal,_sStartDir,message,AcceptFiles,AccpetDirs,file_type)
    expect(true,1,terminal,"terminal","object","nil")
    _sStartDir = expect(false,2,_sStartDir,"string","nil") or ""
    expect(false,3,message,"string","nil")
    expect(false,4,AcceptFiles,"boolean","nil")
    expect(false,5,AccpetDirs,"boolean","nil")
    if not message
    then
        message = "select "
        if AccpetDirs 
        then
            message = message.."Directory"
        end
        if AccpetDirs and AcceptFiles
        then
            message = message.." or File"
        elseif AccpetDirs
        then
            message = message.." File"
        end
    end
    if AccpetDirs ~= nil and not AccpetDirs and AcceptFiles ~= nil and not AcceptFiles
    then
        error("arguments 4 & 5 can't both be false",2)
    end
    if not terminal.run_list
    then
        error("nessary function missing argument #1",2)
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
        local list = {}
        for _,v in pairs(util.file.list(dir,AcceptFiles,true,true)) do
            local ext = util.file.getExtension(v)
            if (ext == nil and fs.isDir(v)) or file_type == nil
            then
                table.insert(list,fs.getName(v))
            elseif ext == file_type
            then
                table.insert(list,fs.getName(v))
            end
        end
        if dir ~= _sStartDir
        then
            table.insert(list,"back")
        end
        table.insert(list,"exit()")
        terminal:reset()
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
            terminal:reset()
            sleep(.01)
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