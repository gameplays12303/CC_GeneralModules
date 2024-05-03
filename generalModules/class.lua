---@diagnostic disable: duplicate-set-field
local util = require("generalModules.utilties")
local expect = require("generalModules.expect2")
assert(debug,"requires the debug API")
assert(debug.getinfo,"requires the getinfo")

local field = expect.field
---@diagnostic disable-next-line:cast-local-type
expect = expect.expect
---@class Main_Class
local Main_Class = {}

---comment
---@param sName string
---@param Class_calling boolean|nil
function Main_Class:SubClass(sName,Class_calling)
    expect(false,1,sName,"string")
    local new_class = setmetatable({},{__index = self,Allow_Class_calling = Class_calling})
    util.table.setType(new_class,("class:%s"):format(sName),false)
    return new_class
end
---comment
---@param sName string
---@param ... any|nil
---@return table|unknown
---@return function
---@return function
function Main_Class:create_Object(sName,...)
    expect(false,1,sName,"string")
    local arguments = table.pack(...)
    for i,v in pairs(arguments) do
        if type(i) == "number"
        then
            expect(false,1+i,v,"table")
        end
    end
    local Object = {}

    local function setParent(Tbl_Parent)
        expect(false,1,Tbl_Parent,"table")
        self = Tbl_Parent
    end
    local accessTbl = setmetatable({self},{mode = ""})
    local function giveAccess(class)
        local stri = util.string.split(util.table.getType(class),":")
        if stri[1] == "class"
        then
            table.insert(accessTbl,class)
        end
    end
    if util.string.split(util.table.getType(self),":")[1] == "class" and self ~= Main_Class and getmetatable(self).Allow_Class_calling
    then
        Object,setParent,giveAccess = self:create_Object(sName,table.unpack(arguments,2))
        setParent(self)
        giveAccess(self)
    else
        do
            local private = {}
            local protected = {}
            local Meta = {}
            ---@diagnostic disable: duplicate-set-field
            Meta.__index = function (_,k)
                if debug and debug.protect 
                then
                    local tmp = private[k]
                    tmp = type(tmp) == "table" and util.table.copy(tmp) or tmp
                    if debug and debug.getinfo and tmp ~= nil
                    then
                        local info = debug.getinfo(1)
                        for _,v in pairs(accessTbl) do
                            if util.table.find(v,info.func)
                            then
                                return tmp
                            end
                        end
                        error("var denied (private var)",2)
                    elseif tmp
                    then
                        return tmp
                    end
                end
                return protected[k] and type(protected[k]) == "table" and util.table.copy(protected[k]) or self[k]
            end
            Meta.__newindex = function (Tbl,index,value)
                if index == "protected"
                then
                    expect(false,3,value,"table")
                    field(3,value,"index","string")
                    index = value.index
                    if index == "protected" or index == "private"
                    then
                        error("reserved word",2)
                    end
                    value = value.value
                    if protected[index] ~= nil
                    then
                        error("value is static",2)
                    end
                    protected[index] = value
                    return true
                elseif index == "private" 
                then
                    expect(false,3,value,"table")
                    field(3,value,"index","string")
                    index = value.index
                    if index == "protected" or index == "private"
                    then
                        error("reserved word",2)
                    end
                    value = value.value
                    if debug
                    then
                        
                    end
                end
                rawset(Tbl,index,value)
            end
            setmetatable(Object,Meta)
            if DisabledGetMeta
            then
                DisabledGetMeta(Object,{util.table.setType,util.table.getType,util.table.get_hash,util.table.tostring})
            end
            ---@diagnostic enable : duplicate-set-field
        end
    end
    util.table.setType(Object,("Object:%s"):format(sName))
    Object:init(table.unpack(arguments[1]))
    return Object,setParent,giveAccess
end
function Main_Class:init(...)

end

return Main_Class