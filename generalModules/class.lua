---@diagnostic disable: duplicate-set-field
local util = require("generalModules.utilties")
local expect = require("generalModules.expect2")
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
function Main_Class:create_Object(sName,...)
    expect(false,1,sName,"string")
    local Object = {}

    local function setParent(Tbl_Parent)
        expect(false,1,Tbl_Parent,"table")
        self = Tbl_Parent
    end
    if util.string.split(util.table.getType(self),":")[1] == "class" and self ~= Main_Class and getmetatable(self).Allow_Class_calling
    then
        Object,setParent = self:create_Object(sName,...)
        setParent(self)
        Object:init(...)
    else
        do
            local protected = {}
            local Meta = {}
            ---@diagnostic disable: duplicate-set-field
            Meta.__index = function (_,k)
                return protected[k] ~= nil and protected[k] or self[k]
            end
            Meta.__newindex = function (Tbl,index,value)
                if protected[index]
                then
                    error("value is protected",2)
                end
                if index == "protected"
                then
                    expect(false,3,value,"table")
                    field(3,value,"index","string")
                    index = value.index
                    value = value.value
                    protected[index] = value
                    return true
                end
                rawset(Tbl,index,value)
            end
            setmetatable(Object,Meta)
            ---@diagnostic enable : duplicate-set-field
        end
    end
    util.table.setType(Object,("Object:%s"):format(sName))
    return Object,setParent
end
function Main_Class:init(...)

end

return Main_Class