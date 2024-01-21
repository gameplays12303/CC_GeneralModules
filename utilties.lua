-- general purpose code 
-- this code dose not have a decated purpose
-- it is just simple code that i would use multipul times 

local expect = (require and require("cc.expect") or dofile("rom/modules/main/cc/expect.lua")).expect
local fs,string,table = fs,string,table
local setmetatable = setmetatable
local getmetatable = getmetatable
local utilties = {}
utilties.string = {}
utilties.table = {}
utilties.file = {}
-- strings addons 
---comment
---@param inputstr string
---@param sep string|nil
---@param _bkeepdelimiters boolean|nil
---@return table
function utilties.string.split(inputstr, sep,_bkeepdelimiters)
      expect(1,inputstr,"string")
      expect(2,sep,"string","nil")
      expect(3,_bkeepdelimiters,"boolean","nil")
      local t={}
      if not sep
      then
            for letter in inputstr:gmatch(".") do table.insert(t, letter) end
            return t
      end
      if not _bkeepdelimiters
      then
            for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
            end
            return t
      end
      for str in string.gmatch(inputstr,"[^"..sep.."]*"..sep.."?") do
            table.insert(t, str)
      end
      t[#t] = nil
      return t
end
---comment
---@param _nTSX number
---@param _sMessage string
function utilties.string.wrap(_nTSX,_sMessage,_nCPX)
      expect(1,_nTSX,"number")
      expect(2,_sMessage,"string")
      _nCPX = expect(3,_nCPX,"number","nil") or 1
      local list = utilties.string.split(_sMessage,nil,true)
      do
            local result = {}
            for i,v in pairs(list) do
                  result[i] = {}
                  for letter in string.gmatch(v,".") do table.insert(result[i], letter) end
            end
            list = result
      end
      local results = ""
      local Sy = 1
      local CXP = 0
      local index = 1
      local function next()
            index = index + 1
      end
      local function AddAndReset()
            CXP = 0
            Sy = Sy + 1
            results = results.."\n"
      end
      while index <= #list do
            local v = list[index]
            if #v > _nTSX
            then
                  for _,s in pairs(v) do
                        CXP = CXP + 1
                        if CXP > _nTSX
                        then
                              AddAndReset()
                        end
                        results = results..s
                  end
                  next()
            elseif #v+CXP > _nTSX
            then
                  AddAndReset()
            else
                  results = results..table.concat(v,"")
                  CXP = CXP + #v
                  next()
            end
      end
      return results,Sy
end
-- fs addons
---comment
---@param sPath string
---@return number
function utilties.file.created(sPath)
      expect(1,sPath,"string")
      return fs.attributes(sPath).created
end
---comment
---@param sPath string
---@return number
function utilties.file.modified(sPath)
      expect(1,sPath,"string")
      return fs.attributes(sPath).modified
end
---comment
---@param _sfile string
---@return string
function utilties.file.getExtension(_sfile)
      expect(1,_sfile,"string")
      local Table = utilties.string.split(_sfile,"%.")
      return Table[2]
end
---comment
---@param _sPath string
---@return string
function utilties.file.getRoot(_sPath)
      expect(1,_sPath,"string")
      return utilties.string.split(_sPath,"/")[1]
end
---comment
---@param _sfile string
---@return string
function utilties.file.withoutExtension(_sfile)
      expect(1,_sfile,"string")
      local Table = utilties.string.split(_sfile,"%.")
      return Table[1]
end
---comment
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@param showRootDir boolean|nil
---@param showRom boolean|nil
---@return table
function utilties.file.listsubs(sPath,showFiles,showDirs,showRootDir,showRom)
      expect(1,sPath,"string")
      expect(2,showFiles,"boolean","nil")
      expect(3,showDirs,"boolean","nil")
      expect(5,showRootDir,"boolean","nil")
      expect(6,showRom,"boolean","nil")
      showDirs = showDirs or showRootDir
      if not fs.exists(sPath) then
            error("Could not find"..fs.getName(sPath),2)
      end
      if not fs.isDir(sPath) then
            error(fs.getName(sPath).."is not a directory",2)
      end
      local Table = fs.find(sPath.."/*")
      if not showRom
      then
            local ID = utilties.table.find(Table,"rom")
            if ID
            then
                  table.remove(Table,ID)
            end
      end
      local list = {}
      if showRootDir
      then
            table.insert(list,sPath)
      end
      for _,v in pairs(Table) do
            if fs.isDir(v)
            then
                  if showDirs
                  then
                        table.insert(list,v)
                  end
                  local list2 = fs.find(fs.combine(v,"*"))
                  for _,i in pairs(list2) do
                        if fs.isDir(i)
                        then
                              table.insert(Table,i)
                        elseif showFiles
                        then
                              table.insert(list,i)
                        end
                  end
            elseif showFiles
            then
                  table.insert(list,v)
            end
      end
      return list
end
---comment
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@return table
function utilties.file.list(sPath,showFiles,showDirs,showPath)
      expect(1,sPath,"string")
      expect(2,showFiles,"boolean","nil")
      expect(3,showDirs,"boolean","nil")
      expect(4,showPath,"boolean","nil")
      if not fs.exists(sPath)
      then
            error(("%s : not found"):format(sPath),3)
      end
      if not fs.isDir(sPath)
      then
            error(("%s: is file expected directory"):format(sPath),3)
      end
      local list = fs.find(fs.combine(sPath,"*"))
      local list2 = {}
      for _,v in pairs(list) do
            if fs.isDir(v) and showDirs
            then
                  table.insert(list2,v)
            elseif not fs.isDir(v) and showFiles
            then
                  table.insert(list2,v)
            end
      end
      if not showPath
      then
            for i,v in pairs(list2) do
                  list2[i] = fs.getName(v)
            end
      end
      return list2
end
---comment
---@param path string
---@return string
function utilties.file.getDir(path)
      expect(1,path,"string")
      if fs.getDir(path) == ".."
      then
            return ""
      else
            return fs.getDir(path)
      end
end
utilties.color = {}
---comment
---@param color number
---@return boolean
function utilties.color.isColor(color)
      expect(1,color,"number")
      for i,v in pairs(colors) do
            if v == color
            then
                  return i
            end
      end
      return false
end
-- table addons
---comment
---@param base table
---@param ID any
---@return unknown
function utilties.table.find(base,ID)
      expect(1,base,"table")
      for i,v in pairs(base) do
            if type(v) == "string" and type(ID) == "string"
            then
                  if string.find(v,ID)
                  then
                        return i
                  end
            elseif v == ID
            then
                  return i
            end
      end
      return false
end
function utilties.table.selfReferencing(base,search)
expect(1,base,"table")
search =  expect(1,search,"table","nil") or base
local info  = (getmetatable(base) or {}).__index
if type(info) == "function"
then
      info = info(base)
end
if type(info) == "table"
then
      local bool,err = pcall(utilties.table.selfReferencing,info,base)
      if not bool
      then
            return true,err
      end
      if err
      then
            return true
      end
end
return utilties.table.find(base,base) and true or false
end
---comment
---@param Table table
---@param copymetatable boolean|nil
---@param proxy table|nil
---@param copyAll boolean|nil
---@return table
function utilties.table.copy(Table,copymetatable,proxy,copyAll)
expect(1,Table,"table")
expect(2,copymetatable,"boolean","nil")
expect(3,proxy,"table","nil")
proxy = proxy or {}
local metatable = getmetatable(Table)
for k,v in pairs(Table) do
      if type(v) == "table" and not utilties.table.selfReferencing(v)
      then
            proxy[k] = utilties.table.copy(v)
      elseif type(v) ~= "table"
      then
            proxy[k] = v
      end
end
if not table.disabledMetaTable and copymetatable
then
      return setmetatable(proxy,metatable)
elseif table.disabledMetaTable and not table.disabledMetaTable(proxy) and copymetatable
then
      return setmetatable(proxy,metatable)
end
      return proxy
end

---comment
---@param base table
---@param _nTransfer number
---@return table
function utilties.table.transfer(base,_nTransfer)
      expect(1,base,"table")
      expect(2,_nTransfer,"number")
      local CIndex = _nTransfer
      local result = {}
      while CIndex <= _nTransfer do
            result[CIndex] = base[CIndex]
            CIndex = CIndex + 1
      end
      return result
end

local function temp(self)
      local meta = getmetatable(self)
      return ("%s: (%s)"):format(meta.type,meta.hash)
end
---comment
---@param Tbl table
---@param Type string
---@return table
function utilties.table.setType(Tbl,Type)
      expect(1,Tbl,"table")
      expect(2,Type,"string")
      local meta = getmetatable(Tbl) or {}
      meta.type = Type
      meta.hash = utilties.table.get_hash(Tbl)
      meta.__tostring = temp
      return setmetatable(Tbl,meta)
end
---comment
---@param Tbl table
---@return string
function utilties.table.getType(Tbl)
      expect(1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.type or "table"
end
---comment
---@param Tbl table
---@return string
function utilties.table.get_hash(Tbl)
      expect(1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.hash or tostring(Tbl):match("table: (%x+)")
end
return utilties