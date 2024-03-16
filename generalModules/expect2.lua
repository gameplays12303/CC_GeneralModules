local handle = {}
local function listerror(tbl)
    local list = "{"
    if #tbl > 1
    then
        for _,v in pairs(tbl) do
            list = list..v..",\t"
        end
        list = string.sub(list,1,#list-2)
        list = list.."}"
    else
        list = tbl[1]
    end
    return list
end
local function getType(var,btrue)
    if type(var) == "table" and btrue
    then
        return (getmetatable(var) or {}).type or "table"
    elseif type(var) == "table"
    then
        return "table"
    end
    return type(var)
end
---comment
---@param _bClasses boolean
---@param index number
---@param var any
---@param ... string
---@return any
handle.expect = function (_bClasses,index,var,...)
    if #{...} == 0 or type(_bClasses) ~= "boolean"
    then
        error("check arguments",2)
    end
    if type(var) == "table" and _bClasses
    then
        local info = (getmetatable(var) or {}).type
        if info
        then
            for _,v in pairs({...}) do
                if v == info
                then
                    return var
                end
            end
        end
    else
        for _,v in pairs({...}) do
            if type(var) == v
            then
                return var
            end
        end
    end
    if debug then -- if we can get the name of the called function then lets include it
    else
        error(("argument #%s expected %s: got %s"):format(index,listerror({...}),getType(var,_bClasses)),3)
    end
end
---comment
---@param index number
---@param var any
---@param ... string
---@return any
handle.blacklist  = function (_bClasses,index,var,...)
    handle.expect(false,1,_bClasses,"boolean")
    handle.expect(false,2,index,"number")
    if #{...}  == 0
    then
        error("check arguments",2)
    end
    local info
    if type(var) == "table"
    then
        info = (getmetatable(var) or {}).type
    end
    local faild = false
    for _,v in pairs({...}) do
        if info
        then
            for _,b in pairs({...}) do
                if b == info
                then
                    faild = true
                end
            end
        elseif type(var) == v
        then
            faild = true
        end
    end
    if faild
    then
        error(("argument #%s banned %s: got %s"):format(index,listerror({...}),getType(var,_bClasses)),3)
    end
    return var
end
---comment
---@param index number
---@param var any
---@return any
handle.expectValue = function (index,var)
    handle.expect(false,1,index,"number")
    if type(var) == "nil"
    then
        error(("argument #%s:expected value got nil"):format(index),2)
    end
    return var
end
setmetatable(handle,{call = handle.expect})
---comment
---@param tbl table
---@param index number|string
---@param ... string
handle.field = function (loc,tbl,index,...)
    handle.expect(false,1,loc,"number")
    handle.expect(false,2,tbl,"table")
    handle.expect(false,3,index,"string","number")
    if #{...} == 0
    then
        error("argument #4 expect values got none",2)
    end
    for i,v in pairs({...}) do
        handle.expect(false,i+4,v,"string")
    end
    local bool = pcall(handle.expect,true,0,tbl[index],...)
    if not bool
    then
        error(("argument #%s: %s is expected to be %s: got %s"):format(loc,index,listerror({...}),type(tbl[index])),3)
    end
    return tbl[index]
end
---comment
---@param index number|string
---@param num number
---@param min number|nil
---@param max number|nil
---@return number
handle.range = function (index,num,min,max)
    handle.expect(false,1,index,"number","string")
    handle.expect(false,2,num,"number")
    min = handle.expect(false,3,min,"number","nil") or -math.huge
    max = handle.expect(false,4,max,"number","nil") or math.huge
    if max < min
    then
        error((" %s min is greator then max %s"):format(min,max),3)
    end
    if num > max or num < min
    then
        error(("expected argument #%s: to be between %s and %s got %s"):format(index,min,max,num),3)
    end
    return num
end
setmetatable(handle,{__call = handle.expect})
return handle