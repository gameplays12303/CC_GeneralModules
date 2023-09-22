
local expect = require("generalModules.expect2")
local util = require("generalModules.utilties")
local blacklist = expect.blacklist
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local meta = {}
local class = setmetatable({},{__index = meta})
util.table.setType(class,"class")
function meta:publicmethod(index,fn)
    expect(false,1,index,"string")
    expect(false,1,fn,"function")
    self[index] = fn
end
function meta:publicVar(index,var)
    expect(false,1,index,"string")
    blacklist(2,var,"function")
    self[index] = var
end
function meta:init()
    expect(true,0,self,"class")
    local initmethod = {}
    local instance = util.table.copy(self)
    do
        local info = {}
        info.__index = meta
        setmetatable(instance,info)
    end
    util.table.setType(instance,"class")
    function instance:AddStaticmethod(index,fn,arguments)
        expect(false,1,index,"string")
        expect(false,2,fn,"function")
        expect(false,3,arguments,"table")
        for i,v in pairs(arguments) do
            field(i+3,v,"type","string")
            field(i+3,v,"value",v.type)
        end
        arguments.n = #arguments
        initmethod[index] = {string.dump(fn),getfenv(fn),arguments}
    end
    function instance.getArguements(index)
        expect(false,1,index,"string")
        if initmethod[index]
        then
            return true,table.unpack(initmethod[index] and initmethod[index][3] or {})
        else
            return false,"not a method"
        end
    end
    for i,v in pairs(initmethod) do
        local fun
        do
            local fn,err =  load(v[1],"@initmethod","bt",v[2])
            if not fn
            then
                error(err,0)
            end
            fun = fn
        end
        instance[i] = function (...)
            do
                local argu = table.pack(self.getArguements(i))
                local stop
                for b,c in pairs(...) do
                    local bool = pcall(expect(b,c,argu[b]))
                    if not bool and not stop
                    then
                        stop = b
                    end
                end
                if stop
                then
                    local argus = {...}
                    error(("argument #%s: expected %s got %s"):format(stop,argus[stop],argu[stop]),2)
                end

            end
            local bool = table.pack(pcall(fun,...))
            if not bool[1]
            then
                error(bool[2],0)
            end
            return table.unpack(bool,2)
        end
    end
    return instance
end
return class