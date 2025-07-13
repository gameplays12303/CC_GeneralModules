local util = require and require("generalModules.utilties") or dofile("generalModules/utilties.lua")
local expect_table = require and require("generalModules.expect2") or dofile("generalModules/expect2.lua")
local expectValue = expect_table.expectValue
local expect = expect_table.expect
-- time to add some new features
---@diagnostic disable:redundant-parameter,duplicate-set-field
local Tbl = util.table.copy(table)
local metaTable = {getmetatable = getmetatable,setmetatable = setmetatable}
local nativeRawSet = rawset
local function hasAccess(metaData)
    local search
    do -- gets the debug info
        local count = 3
        while search == nil do
            local info = debug.getinfo(count)
            if info.short_src == "[C]"
            then
                count = count + 1
            else
                search = info
            end
        end
    end
    if string.sub(search.short_src,2,3) == "rom" or string.sub(search.short_src,2,4) == "/rom" or search == "bios"
    then
        return true
    end
    if type(metaData.access) == "function"
    then
        return search.func == metaData.access
    end
    local stack = {metaData.access,util,expect_table}
    local seen = {metaData.access,util,expect_table}
    while #stack > 0 do
        local Current = Tbl.remove(stack)
        for _,v in pairs(Current) do
            if type(v) == "table"
            then
                if not seen[v]
                then
                    Tbl.insert(stack,v)
                    seen[v] = true
                end
            elseif type(v) == "function" and search.func == v
            then
                return true
            end
        end
    end
    return false
end
_G.getmetatable = function (Table)
    expect(false,1,Table,"table")
    local meta = metaTable.getmetatable(Table) or {}
    if (meta.__ProtectMeta) and not hasAccess(meta)
    then
        error("access_denied",2)
    end
    return metaTable.getmetatable(Table)
end
_G.setmetatable = function (Table,_metaTable)
    expect(false,1,Table,"table")
    expect(false,2,_metaTable,"table","nil")
    local meta = metaTable.getmetatable(Table) or {}
    if meta.__ProtectMeta and not hasAccess(meta)
    then
        error("permission denied",2)
    end
    return metaTable.setmetatable(Table,_metaTable)
end
_G.ProtectMeta = function (Table,...)
    expect(false,1,Table,"table")
    local tmp = {...}
    for i,v in pairs(tmp) do
        if i ~= "n"
        then
            expect(false,i+1,v,"function","table")
        end
    end
    local meta = metaTable.getmetatable(Table) or {}
    meta.__ProtectMeta = true
    meta.access = tmp
    return metaTable.setmetatable(Table,meta)
end
do -- load
    local debugGet,debugSetMeta = debug.getmetatable,debug.setmetatable
    debug.setmetatable = function (Table)
        expect(false,1,Table,"table")
        local meta = metaTable.getmetatable(Table) or {}
        if (meta.__ProtectMeta) and not hasAccess(meta)
        then
            error("access_denied",2)
        end
        return debugGet(Table)
    end
    debug.getmetatable = function (Table,_metaTable)
        expect(false,1,Table,"table")
        expect(false,2,_metaTable,"table","nil")
        local meta = metaTable.getmetatable(Table) or {}
        if meta.__ProtectMeta and not hasAccess(meta)
        then
            error("permission denied",2)
        end
        return debugSetMeta(Table,_metaTable)
    end
end
---comment
---@param Table table
---@param index number|string
---@param value any
---@return table|nil
_G.rawset = function (Table,index,value)
    expect(false,1,Table,"table")
    expect(false,2,index,"number","string")
    local meta = metaTable.getmetatable(Table)
    if meta._isReadOnly
    then
        error("table is ReadOnly",2)
    end
    return nativeRawSet(Table,index,value)
end

table.insert = function (_tlist,_nindex ,value)
    expect(false,1,_tlist,"table")
    local meta = metaTable.getmetatable(_tlist) or {}
    if meta._isReadOnly
    then
        error("table isReadOnly",2)
    end
    if value ~= nil
    then
        expect(false,2,_nindex,"number")
        Tbl.insert(_tlist,_nindex,value)
    else
        expectValue(2,_nindex)
        Tbl.insert(_tlist,_nindex)
    end
end

table.remove = function (_tlist,_nindex)
    expect(false,1,_tlist,"table")
    expect(false,2,_nindex,"number","nil")
    local meta = metaTable.getmetatable(_tlist) or {}
    if meta._isReadOnly
    then
        error("table isReadOnly",2)
    end
    return Tbl.remove(_tlist,_nindex)
end

table.move = function (_tList1,_nIndex,_nCount,_n2Index,_tList2)
    expect(false,1,_tList1,"table")
    expect(false,2,_nIndex,"number")
    expect(false,3,_nCount,"number")
    expect(false,4,_n2Index,"number")
    expect(false,5,_tList2,"table")
    do
        local mainMeta = metaTable.getmetatable(_tList1) or {}
        local CopyMeta = metaTable.getmetatable(_tList2)  or {}
        if mainMeta._isReadOnly
        then
            error("argument #1 is ReadOnly",2)
        end
        if CopyMeta._isReadOnly
        then
            error("argument #2 is ReadOnly",2)
        end
    end
    return Tbl.move(_tList1,_nIndex,_nCount,_n2Index,_tList2)
end
function table.sort(_tlist,_fnComp)
    expect(false,1,_tlist,"table")
    expect(false,2,_fnComp,"function","nil")
    local meta = metaTable.getmetatable(_tlist) or {}
    if meta._isReadOnly
    then
        error("table is ReadOnly",2)
    end
    return Tbl.sort(_tlist,_fnComp)
end

local function __pairs(self)
    local tlist = (metaTable.getmetatable(self) or {}).__index
    local k = nil
    return function ()
        local v
        repeat k,v=next(tlist,k) until v~= nil or k == nil
        return k,v
    end
end
local function __ipairs(self)
    local tlist = (metaTable.getmetatable(self) or {}).__index
    local count = 0
    return function ()
        count = count+1
        return tlist[count]
    end
end
local function isReadOnly()
    error("table is ReadOnly",2)
end
---comment
---@param _tlist table
---@return table
table.setReadOnly = function (_tlist,...)
    expect(false,1,_tlist,"table")
    local meta = metaTable.getmetatable(_tlist) or {}
    if meta.isProxy
    then
        error("table is a proxy",2)
    end
    meta.__index = _tlist
    meta.isProxy = true
    meta.__newindex = isReadOnly
    meta._isReadOnly = true
    for i,v in pairs({...}) do
        expect(false,i+1,v,"function","table")
    end
    meta.__pairs = __pairs
    meta.__ipairs = __ipairs
    local proxy = metaTable.setmetatable({},meta)
    do
        local Type = util.table.getType(_tlist)
        if Type ~= "table"
        then
            util.table.setUp(proxy,Type)
        end
    end
    ProtectMeta(proxy,...)
    return  proxy
end

table.isReadOnly = function (_tlist)
    expect(false,1,_tlist,"table")
    return (metaTable.getmetatable(_tlist) or {})._isReadOnly or false
end

local function check_name(name)
    if name 
    then
        if string.sub(name,1,4) == "/rom" or string.sub(name,1,3) == "rom"
        then
            local info = debug.getinfo(3)
            if not info or not info.short_src
            then
                return false,"couldn't fetch debug info"
            end
            if string.sub(info.short_src,1,4) ~= "/rom" and string.sub(info.short_src,1,3) ~= "rom" and info.short_src ~= "bios"
            then
                return false,("load_request_denied %s;%s"):format(info.source,name)
            end
        end
        if string.gmatch(string.sub(name,1,1),"%p") and string.sub(name,2) == "bios"
        then
            return false,("load_request_denied can't name process %s"):format(name)
        end
    end
    return true
end


local nativeLoad = load
load = function (x, name, mode, env)
    expect(false,1, x, "function", "string")
    expect(false,2, name, "string", "nil")
    expect(false,3, mode, "string", "nil")
    expect(false,4, env, "table", "nil")
    local value,err = check_name(name)
    if not value
    then
        return false,err
    end
    ---@diagnostic disable-next-line: need-check-nil
    return nativeLoad(x, name, mode, env)
end
if loadstring
then
    local nativeloadstring = loadstring
    loadstring = function (chunk,chunk_name)
        expect(false,1,chunk,"string")
        if type(chunk_name) == "string"
        then
            local value,err = check_name(chunk_name)
            if not value
            then
                return false,err
            end
        end
        return nativeloadstring(chunk,chunk_name)
    end
end

if tonumber(string.sub(_VERSION,4)) <= 5.1
then
    _G.loadstring = loadstring
else
    _G.load = load
end

if debug and debug.protect
then
    debug.protect(getmetatable)
    debug.protect(setmetatable)
    debug.protect(ProtectMeta)
    debug.protect(rawset)
    debug.protect(debug.setmetatable)
    debug.protect(debug.setmetatable)
    for _,v in pairs(table) do
        if type(v) == "function"
        then
            debug.protect(v)
        end
    end
end
if tonumber(string.sub(_VERSION,4)) <= 5.1
then
    local raw_pairs = pairs
    _G.pairs = function(t)
        local metatable = metaTable.getmetatable(t)
        if metatable and metatable.__pairs then
            return metatable.__pairs(t)
        end
        return raw_pairs(t)
    end

    local raw_ipairs = ipairs
    _G.ipairs = function(t)
        local metatable = metaTable.getmetatable(t)
        if metatable and metatable.__ipairs then
            return metatable.__ipairs(t)
        end
        return raw_ipairs(t)
    end
end
_G.debug = table.setReadOnly(debug)
_G.table = table.setReadOnly(table)