-- Modified from original GeneralModules, licensed under MIT
-- These modifications were made by wendell Parham for the project
-- For full license information, see LICENSE file in the modules directory.

local handle = {}
local getmetatable = getmetatable
local originType = type
local function type(value,byPass)
    local FoundType = originType(value)
    if FoundType == "table"
    then
        local bool,meta = pcall(getmetatable,value)
        if not bool or not meta or not byPass
        then
            return "table"
        end
        return meta.__type
    end
    return FoundType
end
local function listerror(tbl)
    local list = " "
    if #tbl > 1
    then
        for _,v in pairs(tbl) do
            list = list..v..", "
        end
        list = string.sub(list,1,#list-2)
        list = list.." "
    else
        list = tbl[1]
    end
    return list
end

local function get_name(n)
    local name
    if debug and debug.getinfo then -- if we can get the name of the called function then lets include index else put the file in it's place
        local ok,info = pcall(debug.getinfo,(n or 0)+5,"nS")
        if not ok
        then
            return
        end
        name = info.name and info.name ~= "" and info.what ~= "C" and info.name
    end
    return name
end
local function get_internal_name(n)
    local name
    if debug and debug.getinfo then -- if we can get the name of the called function then lets include index else put the file in it's place
        local ok,info = pcall(debug.getinfo,n or 3,"nS")
        if not ok
        then
            return error(info,n or 3)
        end
        name = info.name and info.name ~= "" and info.what ~= "C" and info.name
    end
    return name
end
---used when a mismatch number of argument or type has been decteded by one of the expect apis done because we can not call the expected api on in it self 
local function checkArguments()
    local name = get_name()
    error(("check arguments %s:"):format(name and name or ""),3)
end


handle.internal_apis = {
    Warning = "these apis have no argument checking because of stock overflow reasons",
    listerror = listerror,
    get_name = get_name,
    get_internal_name = get_internal_name,
    checkArguments = checkArguments
}
---@param _bClasses boolean
---@param index number
---@param var any
---@param ... string
---@return any
function handle.expect(_bClasses,index,var,...)
    if #{...} == 0 or type(_bClasses) ~= "boolean"
    then
        checkArguments()
    end
    local CurrentType = type(var,_bClasses)
    for _,v in pairs({...}) do
        if CurrentType == v
        then
            return var
        end
    end
    local name  = get_name()
    error(("argument #%s%s expected %s: got %s"):format(index,name and (" from %s"):format(name) or "",listerror({...}),type(var,_bClasses)),3)
end 

---@param index number
---@param var any
---@param ... string
---@return any
---@diagnostic disable-next-line: lowercase-global
function handle.blacklist(_bClasses,index,var,...)
    handle.expect(false,1,_bClasses,"boolean")
    handle.expect(false,2,index,"number")
    if #{...}  == 0
    then
        checkArguments()
    end
    local info = type(var,_bClasses)
    local failed = false
    for _,v in pairs({...}) do
        if info == v
        then
            failed = true
        end
    end
    if failed
    then
        local name  = get_name()
        error(("argument #%s%s banned %s: got %s"):format(index,name and (" from %s"):format(name) or "",listerror({...}),type(var,_bClasses)),3)
    end
    return var
end

---@param index number
---@param var any
---@return any
---@diagnostic disable-next-line: lowercase-global
function handle.expectValue(index,var)
    handle.expect(false,1,index,"number")
    if type(var) == "nil"
    then
        local name = get_name()
        error(("argument #%s%s:expected value got nil"):format(index,name and (" from %s"):format(name) or ""),3)
    end
    return var
end

---@param tbl table
---@param index number|string
---@param ... string
---@diagnostic disable-next-line: lowercase-global
function handle.field(loc,tbl,index,...)
    handle.expect(false,1,loc,"number")
    handle.expect(false,2,tbl,"table")
    handle.expect(false,3,index,"string","number")
    if #{...} == 0
    then
        checkArguments()
    end
    for i,v in pairs({...}) do
        handle.expect(false,i+4,v,"string")
    end
    local bool = pcall(handle.expect,true,0,tbl[index],...)
    if not bool
    then
        local name = get_name()
        error(("argument #%s %s: %s is expected to be %s: got %s"):format(loc,index,name and (" from %s"):format(name) or "",listerror({...}),type(tbl[index])),3)
    end
    return tbl[index]
end

---@param index number|string
---@param num number
---@param min number|nil
---@param max number|nil
---@return number
---@diagnostic disable-next-line: lowercase-global
function handle.range(index,num,min,max)
    handle.expect(false,1,index,"number","string")
    handle.expect(false,2,num,"number")
    min = handle.expect(false,3,min,"number","nil") or -math.huge
    max = handle.expect(false,4,max,"number","nil") or math.huge
    if max < min
    then
        error(("min is greator then max got %s/%s"):format(min,max),2)
    elseif num > max or num < min
    then
        local name = get_name()
        error(("expected argument #%s%s: to be between %s and %s got %s"):format(index,name and (" from %s"):format(name) or "",min,max,num),4)
    end
    return num
end
return setmetatable(handle,{__call = expect})