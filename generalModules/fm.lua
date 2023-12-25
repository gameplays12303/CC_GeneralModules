-- this is just a module to lower the ammount of code to be written
-- if you need specific handling or are going to be writing to the file
-- multipule times this is not the handle you want to use

local expect = (require and require("generalModules.expect2") or dofile("generalModules/expect2.lua"))
local blacklist = expect.blacklist
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local open = fs.open
local exists = fs.exists
local fm = {}
---@overload fun(sPath:string,data:any,mode:string)
function fm.OverWrite(sPath,data,mode)
    expect(false,1,sPath,"string")
    blacklist(false,2,data,"thread","userdata")
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
    expect(false,1,sPath,"string")
    expect(false,3,mode,"string")
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
