
-- this is degined to replace the require API so modules can be reloaded as needed
-- this module minics the require system in that once loaded it simply just calleds the module once more
-- unless the reload boolean is set to true then it will simply reload it 
-- if the module fails to load it will not save it in the loaded Table unlike the actual require

local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect = (require and require("cc.expect") or dofile("rom/modules/main/cc/expect.lua")).expect
local handle = {path = {}}
handle.Path = {Paths = util.file.list("rom/modules",false,true,true)}
table.insert(handle.Path.Paths,"")
handle.loaded = {}
-- adds a LoadPath to the loadPaths Table
---comment
---@param _sPath string
---@param priority number|nil
function handle.Path.Add(_sPath,priority)
    expect(1,_sPath,"string")
    expect(2,priority,"number","nil")
    _sPath = string.gsub(_sPath,"%.","/")
    if not fs.exists(_sPath)
    then
        error(("%s:not found"):format(_sPath),0)
    end
    if priority
    then
        table.insert(handle.Path.Paths,priority,_sPath)
    else
        table.insert(handle.Path.Paths,_sPath)
    end
    
end
-- removes a loadPath from the loadPaths Table
---comment
---@param _sPath string
---@return boolean
function handle.Path.Remove(_sPath)
    expect(1,_sPath,"string")
    local i = util.table.find(handle.Path.Paths,_sPath)
    if i
    then
        table.remove(handle.Path.Paths,i)
    end
    return true
end
local function protect(Tbl)
    for _,v in pairs(Tbl) do
        if type(v) == "table" and not util.table.selfReferencing(v)
        then
            protect(v)
        elseif type(v) == "function"
        then
            pcall(debug.protect,v)
        end
    end
end

---loads up the api
--- unlike normal require it can take a environment table and reload a api
---@param _sPath string
---@param _Env table|nil
---@param bforce_Reload boolean|nil
---@return table|unknown
function handle.require(_sPath,_Env,bforce_Reload)
    expect(1,_sPath,"string")
    expect(2,_Env,"table","nil")
    expect(3,bforce_Reload,"boolean","nil")
    -- backwards support for require
    -- turns the '.' into "/" then adds
    -- .lua to the end of the string
    if util.file.getExtension(_sPath) ~= "lua"
    then
        _sPath = string.gsub(_sPath,"%.","/")..".lua"
    end
    
    -- checks to see if the modules exists
    -- in the Paths written in the Path Table
    local Path
    for _,v in pairs(handle.Path.Paths) do
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
        for _,v in pairs(handle.Path.Paths) do
            err = err..fs.combine(v,_sPath)..": not found".."\n"
        end
        error(err,2)
    end
    -- if found then it checks to see if it is already loaded 
    -- is so it simply calleds the module once again and returns the APIS the module returns 
    -- unless he reload boolean is true
    -- which then it will reload and replace the module completelly 
    if not bforce_Reload
    then
        for i,v in pairs(handle.loaded) do
            if i == _sPath
            then
                -- i don't bother to put it in a pcall
                -- because it work the first time
                -- for proformace reasons
                if table.setReadOnly
                then
                    local meta = getmetatable(v).__index
                    return table.unpack(meta)
                    
                end
                return v()
            end
        end
    end
    _Env = _Env or {}
    _Env["require"] = handle.require
    _Env["mReq"] = handle
    do
        local meta = getmetatable(_Env) or {}
        meta.__index = _G
        setmetatable(_Env,meta)
    end
    local fn,err = loadfile(Path,"bt",_Env)
    if not fn
    then
        error(err,0)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    local ok = table.pack(pcall(fn))
    if not ok[1]
    then
        error(ok[2],0)
    end
    if table.setReadOnly
    then
        if debug and debug.protect
        then
            protect(ok)
        end
        handle.loaded[_sPath] = table.setReadOnly({table.unpack(ok,2)},handle)
        local meta = getmetatable(handle.loaded[_sPath])
        meta._env = _Env
    else
        handle.loaded[_sPath] = fn
    end
    return table.unpack(ok,2)
end
--- reloads the all the apis
function handle.reLoadAll()
    if table.isReadOnly
    then
        for path,value in pairs(handle.loaded) do
            local env = (getmetatable(value) or {})._env
            handle.require(path,env,true)
        end
    else
        for i, v in pairs(handle.loaded) do
            
            local _Env = getfenv(v)
            handle.require(i,_Env,true)
        end
    end
end
return handle
