
-- this is degined to replace the require API so modules can be reloaded as needed
-- this module minics the require system in that once loaded it simply just calleds the module once more
-- unless the reload boolean is set to true then it will simply reload it 
-- if the module fails to load it will not save it in the loaded Table unlike the actual require

local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local fm = require and require("generalModules.fm") or dofile("generalModules/fm.lua")
local handle = {}
local Paths = util.file.list("rom/modules",false,true,true)
table.insert(Paths,"")
handle.Path = {}
handle.loaded = {}
-- adds a LoadPath to the loadPaths Table
---@overload fun(_sPath:string,bReload:boolean)
function handle.Path.Add(_sPath)
    if not fs.exists(_sPath)
    then
        error(("%s:not found"):format(_sPath),0)
    end
    table.insert(Paths,_sPath)
end
-- removes a loadPath from the loadPaths Table
---@overload fun(_sPath:string,bReload:boolean)
function handle.Path.Remove(_sPath)
    local i = util.table.find(Paths,_sPath)
    if i
    then
        table.remove(Paths,i)
    end
    return true
end

-- return a copy of the loadPaths Table
function handle.Path.list()
    return util.table.copy(Paths)
end
---@overload fun(_sPath:string,bReload:boolean)
function handle.require(_sPath,bReload)
    -- backwards support for require
    -- turns the '.' into "/" then adds
    -- .lua to the end of the string
    _sPath = string.gsub(_sPath,"%.","/")..".lua"
    
    -- checks to see if the modules exists
    -- in the paths written in the Path Table
    local Path
    for _,v in pairs(Paths) do
        local Tem = fs.combine(v,_sPath)
        if fs.exists(Tem)
        then
            Path = Tem
            break
        end
    end
    -- if not found then
    -- returns error code simular format 
    -- to the  old require API
    if not Path
    then
        local err = _sPath.."\n"
        for _,v in pairs(Paths) do
            err = err..fs.combine(v,_sPath)..": not found".."\n"
        end
        error(err,2)
    end
    -- if found then it checks to see if it is already loaded 
    -- is so it simply calleds the module once again and returns the APIS the module returns 
    -- unless he reload boolean is true
    -- which then it will reload and replace the module completelly 
    if not bReload
    then
        for i,v in pairs(handle.loaded) do
            if i == _sPath
            then
                -- i don't bother to put it in a pcall
                -- because it work the first time
                -- for proformace reasons
                return v()
            end
        end
    end
    local SFn = fm.readFile(Path,"R")
    local fn,err = load(SFn,"@"..Path,"bt",setmetatable({["shell"] = shell,["require"] = handle.require,["Mrequire"] = util.table.copy(handle,false)},{__index = _G}))
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