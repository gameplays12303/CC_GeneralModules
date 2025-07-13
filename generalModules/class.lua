local expect = require("generalModules.expect2")
local util = require("generalModules.utilties")
local field = expect.field

---@diagnostic disable-next-line: cast-local-type
expect = expect.expect

local Main_class = {}

local function hasAccess(userData)
    -- Get the function at the 3th level in the call stack
    local search = debug.getinfo(3,"f")
    if not search then
        return false -- If no function info, return false
    end
    local Current
    do
        local meta = getmetatable(userData)
        Current = {value = meta.static,Parent = meta.Parent}
    end
    while true do
        for _,v in pairs(Current.value) do
            if v == search.func
            then
                return true
            end
        end
        if Current.Parent
        then
            local meta = getmetatable(Current.Parent)
            Current = {value = meta.static,Parent = meta.Parent}
        else
            break
        end
    end
    return false
end

local function index(userData,key)
    local data = userData
    local visited = {}
    while data do
        visited[data] = true
        local metaData = getmetatable(data) or {}
        if metaData.private and metaData.private[key] ~= nil
        then
            local Found = hasAccess(userData)
            if not Found
            then
               error(("[KEY \'%s\' IS PRIVATE: ACCESS DENIED]"):format(key),2)
            end
            return metaData.private[key]
        end
        if metaData.static and metaData.static[key]
        then
            return metaData.static[key]
        end
        if metaData.indexTable and metaData.indexTable[key] ~= nil
        then
            return metaData.indexTable[key]
        end
        if metaData.Parent
        then
            local value = rawget(metaData.Parent,key)
            if value ~= nil
            then
                return value
            end
        end
        if metaData.Parent and visited[metaData.Parent] == nil
        then
            data = metaData.Parent
        elseif not metaData.Parent
        then
            break
        end
    end
    return nil
end

local function newIndex(userData,key,value)
    local data = getmetatable(userData)
    if hasAccess(userData) or not data.Secure
    then
        if key == "static"
        then 
            expect(false,3,value,"table")
            field(3,value,1,"string")
            field(3,value,2)
            if data.static[value[1]] == nil and data.private[value[1]] == nil and type(value[2]) ~= "function" and type(value[2]) ~= "table"
            then
                data.static[value[1]] = value[2]
                return
            end
        elseif type(value) ~= "function" and data.static[key] == nil and data.private
        then
            data.private[key] = value
            return
        end
    end
    if key == "public"
    then
        expect(false,3,value,"table")
        field(3,value,1,"string")
        if data.static[value[1]] == nil and data.private[value[1]] == nil and type(value[2]) ~= "function"
        then
            rawset(userData,value[1],value[2])
            return
        end
    end
    error(("PERMISSION DENIED"),2)
end

local function __pairs(self)
    -- Initialize the iterator state
    local Current = {}
    do
        local meta = getmetatable(self)
        Current = {mode = 0, static = meta.static, self = self, Parent = meta.Parent,indexTable = meta.indexTable, key = nil}
    end
    -- Iterator function
    return function()
        local key, value
        --- index the static table
        if Current.mode == 0 then
            -- Iterate over the static table
            key, value = next(Current.static, Current.key)
            if key then
                Current.key = key
                return key, value
            end
            -- Switch to extra fields after static is exhausted
            Current.mode = 1
            Current.key = nil
        end
        --- index the extra fields
        if Current.mode == 1 and Current.indexTable
        then
            -- Iterate over the extra table
            key, value = next(Current.indexTable, Current.key)
            if key then
                Current.key = key
                return key, value
            end
            -- Switch to public fields after extra table is exhausted
            Current.mode = 2
            Current.key = nil
        end
        -- Iterate over public fields (instance-level)
        key, value = next(Current.self, Current.key)
        if key ~= nil then
            Current.key = key
            return key, value
        end
        -- Move to the parent once public fields are exhausted
        if Current.Parent then
            local meta
            while key == nil and Current.Parent do
                meta = getmetatable(Current.Parent)
                Current = {mode = 0, static = meta.static, self = Current.Parent, Parent = meta.Parent,indexTable = meta.indexTable,key = nil}
                key,value = next(Current.static)
                Current.key = key
            end
            return key,value
        else
            -- No more parents to traverse
            return nil
        end
    end
end

--- this constructs the class as the class is readonly once constructed
--- this is how we get around it without the chicken and egg problem
local function build(self)
    local meta = getmetatable(self)
    ---@class class
    local newClass = {}
    local metaData = {hash = util.table.get_hash(newClass),__index = index,__newindex = newIndex,static = meta.static,Parent = meta.Parent,type = "class",__name = meta.name,__tostring = util.table.tostring,__pairs = __pairs}
    setmetatable(newClass,metaData)
    if ProtectMeta
    then
        ProtectMeta(newClass,index,newIndex,Main_class,util,hasAccess,__pairs)
    end
    return newClass
end

--- this is used to put info into the constructor table 
local function initialize_handler(self,k,v)
    local meta = getmetatable(self)
    if meta.static[k]
    then
        error(("%s: key is taken"):format(k))
    end
    meta.static[k] = v
end

local methods = {}
--- create a class constructor 
--- call the class constructor table like [table]() for the class when finished
---@param name string
---@return table
function methods:SubClass(name)
    self:isClass(true)
    expect(false,1,name,"string")
    local methodContainer = setmetatable({},{
        __call = build,
        name  = name,
        Parent = self,
        __newindex = initialize_handler,
        static = {},
    })
    return methodContainer
end

---create a object but dose not initialize it
---can take a bluePrint table as the table 
---@param name string
---@return table
function methods:Create_object(name,bluePrint,references)
    expect(false,1,name,"string")
    bluePrint = expect(false,2,bluePrint,"table","nil") or {}
    expect(false,3,references,"table","nil")
    local static
    if bluePrint.static and field(2,bluePrint,"static","table")
    then
        static = bluePrint.static
        bluePrint.static = nil
    end
    local newObject = {}
    local metaData = {indexTable = references,__tostring = util.table.tostring,hash = util.table.get_hash(newObject),__index = index,__newindex = newIndex,Parent = self,private = bluePrint,static = static or {},type = "object",__name = name,__pairs = __pairs}
    metaData._tostring = util.table.tostring
    setmetatable(newObject,metaData)
    if ProtectMeta and false
    then
        ProtectMeta(newObject,index,newIndex,Main_class,util,hasAccess,__pairs)
    end
    return newObject
end


---comment
---@param _bEnfore boolean|nil
---@return boolean
function methods:isObject(_bEnfore)
    local metaData = getmetatable(self)
    local isObject = metaData.type == "object"
    if not _bEnfore
    then
        return isObject
    end
    if not isObject
    then
        error("expected object",3)
    end
end

---comment
---@param _bEnfore boolean|nil
---@return boolean
function methods:isClass(_bEnfore)
    local metaData = getmetatable(self)
    local isClass = metaData.type == "class"
    if not _bEnfore
    then
        return isClass
    end
    if not isClass
    then
        error("expected class",3)
    end
end

--passes a object ownership down
---@param new_parent class
function  methods:setParent(new_parent)
    expect(false,1,new_parent,"table")
    self:isObject(true)
    if not hasAccess(self)
    then
        error("can %s not pass ownership of object",2)
    end
    local data = getmetatable(self)
    data.Parent = new_parent
    return true
end

---comment
---@param name  string
---@param btrue boolean
---@return boolean
function  methods:isNamed(name,btrue)
    expect(false,1,name,"string")
    expect(false,2,btrue,"boolean","nil")
    local metaData = getmetatable(self)
    local boolean = metaData.__name == name
    if btrue and not boolean
    then
        error(("expected table named %s, got %s"):format(name,metaData.__name or "not named"),3)
    end
    return boolean
end

function  methods:getName()
    return getmetatable(self).__name
end
---comment
---@param name string
function  methods:setName(name)
    expect(false,1,name,"string")
    local metaData = getmetatable(self)
    metaData.__name = name
end

do -- prepairs the framework
    local meta = {__index = methods,__newindex = newIndex,private = {},static = methods,type = "class",__name = "Class_framework",__pairs = __pairs}
    meta.hash = util.table.get_hash(Main_class)
    meta.__tostring = util.table.tostring
    setmetatable(Main_class,meta)
    if ProtectMeta
    then
        ProtectMeta(Main_class,Main_class,hasAccess,index,newIndex,__pairs,util)
    end
end
return Main_class