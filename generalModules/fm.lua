-- this is just a module to lower the ammount of code to be written
-- if you need specific handling or are going to be writing to the file
-- multipule times this is not the handle you want to use

local expect = (require and require("cc.expect") or dofile("rom/modules/main/cc/expect.lua")).expect
local insert = table.insert
local open = fs.open
local exists = fs.exists
local fm = {}
---@overload fun(sPath:string,data:any,mode:string)
function fm.OverWrite(sPath,data,mode)
    expect(1,sPath,"string")
    expect(3,mode,"string","nil")
    mode = mode or "S"
    if mode ~= "S" and mode ~= "R"
    then
        error("Invalid mode",2)
    end
    local file,mess = open(sPath,"w")
    if file == nil then
        return error(mess,0)
    end
    if mode == "R"
    then
        file.write(data)
    else
        file.write(textutils.serialise(data))
    end
    file.close()
    return true
end
---@overload fun(sPath:string,mode:string)
function fm.readFile(sPath,mode)
    expect(1,sPath,"string")
    expect(3,mode,"string")
    mode = mode or "S"
    if mode ~= "S" and mode ~= "R"
    then
        error("Invalid mode",2)
    end
    if not exists(sPath) then
        error("Invalid path "..sPath.." dose not exist",0)
    end
    local file,mess = open(sPath,"r")
    if file == nil then
        return error(mess,0)
    end
    local data
    if mode == "R"
    then
        data = file.readAll()
    else
        data = textutils.unserialise(file.readAll())
    end
    file.close()
    return data
end
return fm
