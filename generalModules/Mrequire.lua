
local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local fm = require and require("generalModules.fm") or dofile("generalModules/fm.lua")
local handle = {}
local Paths = util.file.list("rom/modules",false,true,true)
table.insert(Paths,"")
table.insert(Paths,"generalModules")
handle.Path = {}
handle.loaded = {}
---@overload fun(_sPath:string,bReload:boolean)
function handle.Path.Add(_sPath)
    if not fs.exists(_sPath)
    then
        error(("%s:not found"):format(_sPath),0)
    end
    table.insert(Paths,_sPath)
end
---@overload fun(_sPath:string,bReload:boolean)
function handle.Path.Remove(_sPath)
    local i = util.table.find(Paths,_sPath)
    if i
    then
        table.remove(Paths,i)
    end
    return true
end
function handle.Path.list()
    return util.table.copy(Paths)
end
---@overload fun(_sPath:string,bReload:boolean)
function handle.require(_sPath,bReload)
    _sPath = string.gsub(_sPath,"%.","/")
    local Path
    for _,v in pairs(Paths) do
        local Tem = fs.combine(v,_sPath..".lua")
        if fs.exists(Tem)
        then
            Path = Tem
            break
        end
    end
    if not Path
    then
        local err = _sPath.."\n"
        for _,v in pairs(Paths) do
            err = err..fs.combine(v,_sPath)..": not found".."\n"
        end
        error(err,2)
    end
    if not bReload
    then
        for i,v in pairs(handle.loaded) do
            if i == _sPath
            then
                return v()
            end
        end
    end
    local SFn = fm.readFile(Path,"R")
    local fn,err = load(SFn,"@"..Path,"bt",setmetatable({["shell"] = shell,["require"] = handle.require},{__index = _G}))
    if not fn
    then
        error(err,0)
    end
    local ok = table.pack(pcall(fn))
    if not ok[1]
    then
        error(ok[2],0)
    end
    handle.loaded[_sPath] = fn
    return table.unpack(ok,2)
end
return handle