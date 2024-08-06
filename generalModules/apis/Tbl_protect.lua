local util = dofile("generalModules/utilties.lua")
local expect = dofile("generalModules/expect2.lua")
local expectValue = expect.expectValue

---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
-- time to add some new features
---@diagnostic disable:redundant-parameter,duplicate-set-field
local Tbl = util.table.copy(table)
local metaTable = {getmetatable = getmetatable,setmetatable = setmetatable}
local nativeRawSet = rawset
local function find(meta,index)
    index = (index or 0) >= 4 and index or 4
    local info = debug.getinfo(index)
    local found = false
    for _,v in pairs(meta) do
        if type(v) == "table" and not util.table.selfReferencing(v)
        then
            found = find(v,index+1)
        elseif type(v) == "function" and info.func == v
        then
            return true
        end
    end
    return found
end
local function hasAccess(meta)
    if meta.access ~= nil and debug then
        if find(meta)
        then
            return true
        end
    elseif not debug or not meta.access
    then
        return true
    end
    return false
end
_G.getmetatable = function (Table)
    expect(false,1,Table,"table")
    local meta = metaTable.getmetatable(Table) or {}
    if (meta.__disabledGetMeta or meta._isReadOnly) and not hasAccess(meta)
    then
        error("access denied",2)
    end
    return metaTable.getmetatable(Table)
end
_G.setmetatable = function (Table,_metaTable)
    expect(false,1,Table,"table")
    expect(false,2,_metaTable,"table","nil")
    local meta = metaTable.getmetatable(Table) or {}
    if meta.__disabledSetMeta and not hasAccess(meta)
    then
        error("permission denied",2)
    end
    return metaTable.setmetatable(Table,_metaTable)
end
_G.DisabledSetMeta = function (Table,...)
    expect(false,1,Table,"table")
    local tmp = table.pack(...)
    for i,v in pairs(tmp) do
        expect(false,i+1,v,"function")
    end
    local meta = metaTable.getmetatable(Table) or {}
    meta.__disabledSetMeta = true
    meta.access = tmp
    metaTable.setmetatable(Table,meta)
end
_G.DisabledGetMeta = function (Table,...)
    expect(false,1,Table,"table")
    local tmp = {...}
    for i,v in pairs(tmp) do
        expect(false,i+1,v,"function")
    end
    local meta = metaTable.getmetatable(Table) or {}
    meta.__disabledGetMeta = true
    meta.access = tmp
    return metaTable.setmetatable(Table,meta)
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
    Tbl.remove(_tlist,_nindex)
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

---comment
---@param _tlist table
---@return table
table.setReadOnly = function (_tlist,accesslist)
    expect(false,1,_tlist,"table")
    expect(false,2,accesslist,"table","nil")
    local meta = metaTable.getmetatable(_tlist) or {}
    if meta._isReadOnly
    then
        error("table is ReadOnly",2)
    end
    meta.__index = _tlist
    meta.__newindex = function (t, k, v)
        error("table is ReadOnly",2)
    end
    meta._isReadOnly = true
    meta.access = accesslist
    meta.__pairs = function ()
        local k = nil
        return function ()
            local v
            repeat k,v=next(_tlist,k) until v~= nil or k == nil
            return k,v
        end
    end
    meta.__ipairs = function ()
        local count = 0
        return function ()
            count = count+1
            return _tlist[count]
        end
    end
    local proxy = metaTable.setmetatable({},meta)
    if util.table.getType(_tlist) ~= "table"
    then
        util.table.setType(proxy,util.table.getType(_tlist))
    end
    return  proxy
end

table.isReadOnly = function (_tlist)
    expect(false,1,_tlist,"table")
    return (metaTable.getmetatable(_tlist) or {})._isReadOnly or false
end

if debug and debug.protect
then
    debug.protect(getmetatable)
    debug.protect(setmetatable)
    debug.protect(DisabledGetMeta)
    debug.protect(DisabledSetMeta)
    debug.protect(rawset)
    for _,v in pairs(table) do
        if type(v) == "function"
        then
            debug.protect(v)
        end
    end
end
if tonumber(string.sub(_VERSION,1,3)) <= 5.1
then
    local raw_pairs = pairs
    pairs = function(t)
        local metatable = metaTable.getmetatable(t)
        if metatable and metatable.__pairs then
            return metatable.__pairs(t)
        end
        return raw_pairs(t)
    end

    local raw_ipairs = ipairs
    ipairs = function(t)
        local metatable = metaTable.getmetatable(t)
        if metatable and metatable.__ipairs then
            return metatable.__ipairs(t)
        end
        return raw_ipairs(t)
    end
end