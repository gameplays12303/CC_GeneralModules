local handle = {}
local function listerror(tbl)
    local list = ""
    if #tbl > 1
    then
        for _,v in pairs(tbl) do
            list = list..v..",\t"
        end
        list = string.sub(list,1,#list-2)
        list = list.."\t"
    else
        list = tbl[1].."\t"
    end
    return list
end
local function getType(var)
    if type(var) == "table"
    then
        return (getmetatable(var) or {}).type or "table"
    end
    return type(var)
end
---comment
---@param _bClasses boolean
---@param index number
---@param var any
---@param ... unknown
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
        else
            for _,v in pairs({...}) do
                if v == "table"
                then
                    return true
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
    error(("argument #%s expected %s: got %s"):format(index,listerror({...}),getType(var)),3)
end
handle.blacklist  = function (index,var,...)
    handle.expect(false,1,index,"number")
    if #{...}  == 0
    then
        error("check arguments",2)
    end
    local info
    if type(var) == "table"
    then
        info = (getmetatable(var) or {}).type
    end
    for i,v in pairs({...}) do
        if info and info == v or type(var) == v
        then
            error(("argument #%s can not be %s got %s"):format(index,listerror({...}),getType(var)),0)
        end
    end
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
---@param ... unknown
handle.field = function (loc,tbl,index,...)
    handle.exepct(false,1,loc,"number")
    handle.expect(false,2,tbl,"table")
    handle.expect(false,3,index,"string","number")
    if #{...} == 0
    then
        error("argument #4 expect values got none",2)
    end
    for i,v in pairs({...}) do
        handle.expect(i+4,v,"string")
    end
    local info = tbl[index]
    if not info
    then
        error(("argument #%s :%s not found in table"):format(loc,index),2)
    end 
    local bool = pcall(handle.exepct,true,index,...)
    if not bool
    then
        error(("argument #%s: %s is expected to be %s: got %s"):format(loc,index,listerror({...}),type(info)),3)
    end
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
    max = handle.expect(false,4,max,"number","nil") or -math.huge
    if max < min
    then
        error(("%s: min is greator then max"):format(index),2)
    end
    if num > max or num < min
    then
        error(("expected %s: to be between %s and %s got %s"):format(index,min,max,num),2)
    end
    return num
end
return handle