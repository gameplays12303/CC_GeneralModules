local expect = require("cc.expect").expect
local util = require("generalModules.utilties")
local fs = fs
---@overload fun(_sDir:string)
return function (_sDir)
    expect(1,_sDir,"string")
    if not fs.isDir(_sDir) and fs.exists(_sDir)
    then
        error(("%s:is not a directory"):format(_sDir))
    end
    ---@overload fun(name:string,bOverWrite:boolean|nil)
    return function (name,bOverWrite)
        expect(1,name,"string")
        expect(2,bOverWrite,"boolean","nil")
        local Path
        local closed = false
        name = util.file.withoutExtension(fs.getName(name))
        if fs.exists(("%s/%s.log"):format(_sDir,name)) and not bOverWrite
        then
            local i = 0
            repeat
                i = i+1
            until not fs.exists(("%s/%s(%s).log"):format(_sDir,name,i))
            Path = ("%s/%s(%s).log"):format(_sDir,name,i)
        else
            Path = ("%s/%s.log"):format(_sDir,name)
        end
        local file = fs.open(Path,"w")
        local handle = {}
        ---@overload fun(info:string)
        function handle.info(info)
            expect(1,info,"string")
            file.write(("info:%s:%s \n"):format(os.date(),info))
        end
        ---@overload fun(err:string)
        function handle.error(err)
            expect(1,err,"string")
            file.write(("error:%s:%s \n"):format(os.date(),err))
        end
        function handle.isClosed()
            return closed
        end
        function handle.close()
            file.close()
            closed = true
        end
        return handle
    end
end