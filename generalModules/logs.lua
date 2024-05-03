local expect = require("cc.expect").expect
local util = require("generalModules.utilties")
local fm = require("generalModules.fm")
local fs = fs
---@param _sDir string
---@return function
return function (_sDir,limit)
    expect(1,_sDir,"string")
   limit =  expect(2,limit,"number","nil") or 4
    if not fs.isDir(_sDir) and fs.exists(_sDir)
    then
        error(("%s:is not a directory"):format(_sDir))
    end
    local managment = _sDir.."/logsman.settings"
    ---@param _sName string
    ---@param bOverWrite boolean|nil
    ---@return table
    return function (_sName,bOverWrite)
        expect(1,_sName,"string")
        expect(2,bOverWrite,"boolean","nil")
        local Path,note
        local closed = false
        _sName = util.file.withoutExtension(fs.getName(_sName))
        if fs.exists(("%s/%s(1).log"):format(_sDir,_sName)) and not bOverWrite
        then
            local info
            if not fs.exists(managment)
            then
                info = {}
            else
                info = fm.readFile(managment,"S")
            end
            if not info
            then
                note = true
                info = {}
            end
            if info[_sName] and info[_sName].created >= limit
            then
                Path =  ("%s/%s(%s).log"):format(_sDir,_sName,info[_sName].count)
                if info[_sName].count >= info[_sName].created
                then
                    info[_sName].count = 1
                else
                    info[_sName].count = (info[_sName].count or 0) + 1
                end
            else
                if not info[_sName]
                then
                    info[_sName] = {count = 1,created = 2}
                else
                    info[_sName].created = info[_sName].created + 1
                end
                local i = 0
                repeat
                    i = i+1
                until not fs.exists(("%s/%s(%s).log"):format(_sDir,_sName,i))
                Path = ("%s/%s(%s).log"):format(_sDir,_sName,i)
            end
            fm.OverWrite(managment,info)
        else
            Path = ("%s/%s(1).log"):format(_sDir,_sName)
        end
        local file,err = fs.open(Path,"w")
        if not file
        then
            error(err,0)
        end
        local handle = {}
        ---comment
        ---@param info string
        function handle.Info(info)
            expect(1,info,"string")
            file.write(("Info:%s:%s\n"):format(os.date(),info))
        end
        ---comment
        ---@param info string
        function handle.Warn(info)
            expect(1,info,"string")
            file.write(("Warn:%s:%s\n"):format(os.date(),info))
        end
        ---comment
        ---@param err string
        ---@diagnostic disable-next-line: redefined-local
        function handle.Error(err)
            expect(1,err,"string")
            file.write(("Error:%s:%s\n"):format(os.date(),err))
        end
        ---comment
        ---@param info string
        function handle.Fatal(info)
            expect(1,info,"string")
            file.write(("Fatal:%s:%s\n"):format(os.date(),info))
        end
        if note
        then
            handle.error("check logging system , the system will contiune but logging files will not stop at the limit")
        end
        function handle.isClosed()
            return closed
        end
        function handle.close()
            file.close()
            closed = true
        end
        util.table.setType(handle,("log:%s"):format(_sName))
        return handle
    end
end
