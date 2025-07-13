-- general purpose code 
-- this code dose not have a decated purpose
-- it is just simple code that i would use multipul times 
local expect = (require and require("generalModules.expect2") or dofile("generalModules/expect2.lua"))
local blacklist = expect.blacklist
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local fs,string,table = fs,string,table
local setmetatable = setmetatable
local getmetatable = getmetatable
local utilties = {}
utilties.string = {}
utilties.table = {}
utilties.file = {}
utilties.color = {}
-- strings addons 

---splits a string input no sep value nor _bkeepdelimiters to get a list of chars
---@param inputstr string
---@param sep string|nil
---@param _bkeepdelimiters boolean|nil
---@return table
---@return integer|nil
function utilties.string.split(inputstr, sep,_bkeepdelimiters)
      expect(false,1,inputstr,"string")
      expect(false,2,sep,"string","nil")
      expect(false,3,_bkeepdelimiters,"boolean","nil")
      local t={}
      if not sep
      then
            for char in string.gmatch(inputstr,".") do
                  table.insert(t, char) 
            end
            return t
      end
      if not _bkeepdelimiters
      then
            local total_segments = 0
            for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
            end
            return t,total_segments
      end
      for str in string.gmatch(inputstr,"[^"..sep.."]*"..sep.."?") do
            table.insert(t, str)
      end
      return t
end
---preps a string for the window
---@param terminal_size number
---@param _sMessage string
---@param CursorPosX number|nil
function utilties.string.wrap(terminal_size,_sMessage,CursorPosX)
      expect(false,1,terminal_size,"number")
      expect(false,2,_sMessage,"string")
      CursorPosX = expect(false,3,CursorPosX,"number","nil") or 0
      local words = utilties.string.split(_sMessage," ",true)
      local result,size = "",0
      while #words > 0 do
            local CurrentWord = table.remove(words,1)
            for char in string.gmatch(CurrentWord,".") do
                  if char == "\n"
                  then
                        CursorPosX = 1
                        size = size + 1
                        result = result.."\n"
                  else
                        CursorPosX = CursorPosX + 1
                        if CursorPosX > terminal_size
                        then
                              CursorPosX = 1
                              size = size + 1
                              result = result.."\n"
                        end
                        result = result..char
                  end
            end
      end
      return result,size
end
---custom built Serializer design to handle selfReferencing tables and functions (using string.dump)
---@param _data any
---@param dump_fn boolean|nil
---@param _Index number|nil
---@return string|unknown
function utilties.string.Serialize(_data,dump_fn,_Index)
      expect(false,2,dump_fn,"boolean","nil")
      _Index =  expect(false,3,_Index,"number","nil") or 0
      local actions = {
            ["boolean"] = function (value)
                  return tostring(value)
            end,
            ["string"] = function (value)
                  return "\""..value.."\""
            end,
      }
      actions["function"] = function (value)
            if dump_fn
            then
                  local bool,ret = pcall(string.dump,value)
                  if bool
                  then
                        return ret
                  end
            end
            return actions["string"](tostring(value))
      end
      actions["number"] = actions["boolean"]
      actions["thread"] = actions["boolean"]
      actions["userData"] = actions["boolean"]
      actions["table"] = function ()
            local result = "{\n"
            local seen = {}
            local Current = {depth = 1,value = _data,key = nil,Parent = nil}
            while Current do
                  local k,v = next(Current.value,Current.key)
                  Current.key = k
                  seen[Current.value] = true
                  if k == nil and v == nil
                  then
                        Current = Current.Parent
                        if not Current
                        then
                              result = result.."}"
                              break
                        end
                        result = result..("\t"):rep(Current.depth).."},\n"
                  end
                  local equalPattern
                  if type(k) == "string" and string.find(k,"%p")
                  then
                        equalPattern = ("[\"%s\"] = "):format(tostring(k))
                  elseif type(k) == "string" and not string.match(k,"^%s*$")
                  then
                        equalPattern = ("%s = "):format(tostring(k))
                  else
                        equalPattern = ""
                  end
                  if type(v) == "table"
                  then
                        if not seen[v]
                        then
                              result = result..("\t"):rep(Current.depth)..equalPattern.."{\n"
                              local newCurrent = {depth = Current.depth+1,value = v,key = nil,Parent = Current}
                              Current = newCurrent
                        else
                              if equalPattern == " = " == nil
                              then
                                    equalPattern = ""
                              end
                              result = result..("\t"):rep(Current.depth)..equalPattern..("%s,\n"):format(actions["string"](tostring(v)))
                        end
                  elseif v ~= nil
                  then
                        result = result..("\t"):rep(Current.depth)..equalPattern..(actions[type(v)] and actions[type(v)](v) or ("[unhandled type]:%s"):format(type(_data)))..",\n"
                  end
            end
            return result
      end
      local action = actions[type(_data)]
      return action and action() or ("unhandled type %s"):format(type(_data))
end
---custom text loader 
---@param _sData string
---@return unknown
function utilties.string.UnSerialize(_sData)
      expect(false,1, _sData, "string")
      local func,err = load("return " .. _sData, "unserialize","t",{})
      if func then
            local ok, result = pcall(func)
            if ok then
                  return result
            end
      end
      return error(err,2)
end
-- fs addons

---gets the created date
---@param sPath string
---@return number
function utilties.file.created(sPath)
      expect(false,1,sPath,"string")
      return fs.attributes(sPath).created
end

---gets the modified date
---@param sPath string
---@return number
function utilties.file.modified(sPath)
      expect(false,1,sPath,"string")
      return fs.attributes(sPath).modified
end
---gets the extension type (.lua)
---@param _sfile string
---@return string
function utilties.file.getExtension(_sfile)
      expect(false,1,_sfile,"string")
      local Table = utilties.string.split(_sfile,"%.",true)
      return Table[2]
end
---gets the root (eg. C:/, Root)
---@param _sPath string
---@return string
function utilties.file.getRoot(_sPath)
      expect(false,1,_sPath,"string")
      return utilties.string.split(_sPath,"/")[1]
end
---gets the name but leaves out the extension
---@param _sfile string
---@return string
function utilties.file.withoutExtension(_sfile)
      expect(false,1,_sfile,"string")
      local Table = utilties.string.split(_sfile,"%.")
      return Table[1]
end

---list everything that's inside a folder and their folders 
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@param showRootDir boolean|nil
---@param showRom boolean|nil
---@return table
function utilties.file.listsubs(sPath,showFiles,showDirs,showRootDir,showRom)
      expect(false,1,sPath,"string")
      expect(false,2,showFiles,"boolean","nil")
      expect(false,3,showDirs,"boolean","nil")
      expect(false,5,showRootDir,"boolean","nil")
      expect(false,6,showRom,"boolean","nil")
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

---list everything inside a folder
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@return table
function utilties.file.list(sPath,showFiles,showDirs,showPath)
      expect(false,1,sPath,"string")
      expect(false,2,showFiles,"boolean","nil")
      expect(false,3,showDirs,"boolean","nil")
      expect(false,4,showPath,"boolean","nil")
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
---wrapps the directory so ".." equals ""
---@param path string
---@return string
function utilties.file.getDir(path)
      expect(false,1,path,"string")
      if fs.getDir(path) == ".."
      then
            return ""
      else
            return fs.getDir(path)
      end
end

---test if a number is a color
---@param color number
---@return boolean
function utilties.color.isColor(color)
      expect(false,1,color,"number")
      for i,v in pairs(colors) do
            if v == color
            then
                  return i
            end
      end
      return false
end
-- table addons

---looks in the table for a values (dose not check subtables nor the index table)
---@param base table
---@param ID any
---@param strict boolean|nil
---@return string|number|boolean
function utilties.table.find(base,ID,strict)
      expect(false,1,base,"table")
      for i,v in pairs(base) do
            if type(v) == "string" and type(ID) == "string" and not strict and string.find(ID,i)
            then
                  return i
            end
            if v == ID
            then
                  return i
            end
      end
      return false
end
---checks to see if a table is selfReferencing
---@param base table
---@return boolean
function utilties.table.selfReferencing(base,Topions)
      expect(false, 1, base, "table")
      Topions = expect(false,2,Topions,"table","nil") or {}
      Topions.bmetaData = field(1,Topions,"bmetaData","boolean","nil") or true
      Topions.bIndex = field(1,Topions,"bIndex","boolean","nil") or true
      Topions.bnewIndex = field(1,Topions,"bnewIndex","boolean","nil") or true
      local stack = {{base, select(2, pcall(getmetatable, base))}}
      local seen = {}
      local firstLoop = true
      while true do
      local current = table.remove(stack)
      if not current then
            break
      end
      local tbl, mt = current[1], current[2]
      if tbl == base and not firstLoop then
            return true
      end
      seen[tbl] = true
      -- Iterate through the current table's values
      for _, v in pairs(tbl) do
            if v == base then
                  return true
            end
            if type(v) == "table" and not seen[v] then
                  table.insert(stack, {v, select(2, pcall(getmetatable, v))})
            end
      end
      -- Check the metatable's __index field if it's a table
      if type(mt) == "table" then
            local meta_index = mt.__index
            if type(meta_index) == "table" and not seen[meta_index] and Topions.bIndex  then
                  table.insert(stack, {meta_index, select(2, pcall(getmetatable, meta_index))})
            end
            local meta_newindex = mt.__newindex
            if type(meta_newindex) == "table" and not seen[meta_newindex] and Topions.bnewIndex then
                  table.insert(stack,{meta_newindex, select(2, pcall(getmetatable, meta_newindex))})
            end
      end
      firstLoop = false
      end
      return false
end
---creates a true copy (with the option to include the meta table)
---@param Copy_Tbl table
---@param copymetatable boolean|nil
---@return table
function utilties.table.copy(Copy_Tbl,copymetatable)
      expect(false,1,Copy_Tbl,"table")
      expect(false,2,copymetatable,"boolean","nil")
      local proxy = {}
      for index,v in pairs(Copy_Tbl) do
            if type(v) == "table" and utilties.table.selfReferencing(v)
            then
                  proxy[index] = utilties.table.copy(v,copymetatable)
            else
                  proxy[index] = v
            end
      end
      local bool,reuslt = pcall(getmetatable,Copy_Tbl)
      if bool and copymetatable
      then
            setmetatable(proxy,reuslt)
      end
      return proxy
end

---transfers a number of items indexes into a new table
---@param base table
---@param _nTransfer number
---@return table
function utilties.table.transfer(base,_nTransfer)
      expect(false,1,base,"table")
      expect(false,2,_nTransfer,"number")
      local CIndex = 1
      local result = {}
      while CIndex <= _nTransfer do
            result[CIndex] = base[CIndex]
            CIndex = CIndex + 1
      end
      return result
end

---replaces the table type with the class type
---@param self table
---@return string
function utilties.table.tostring(self)
      local name = utilties.table.getName(self)
      if name
      then
            return ("%s:%s:(%s)"):format(utilties.table.getType(self),name,utilties.table.get_hash(self))
      else
            return ("%s:(%s)"):format(utilties.table.getType(self),utilties.table.get_hash(self))
      end
end

---sets the table class type
---@param Tbl table
---@param Type string
---@param keepHash boolean|nil
---@return table
function utilties.table.setUp(Tbl,Type,keepHash,newname)
      expect(false,1,Tbl,"table")
      expect(false,2,Type,"string")
      expect(false,3,newname,"string","nil")
      local bool,meta = pcall(getmetatable,Tbl)
      if not bool or not meta
      then
            meta = {}
      end
      meta.__type = Type
      meta.__name = newname
      if keepHash or keepHash == nil
      then
            meta.hash = utilties.table.get_hash(Tbl)
      end
      meta.__tostring = utilties.table.tostring
      return setmetatable(Tbl,meta)
end

---returns the object name 
---@param Tbl table
---@return string
function utilties.table.getName(Tbl)
      expect(false,1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.__name
end

---returns the object type
---@param Tbl table
---@return string
function utilties.table.getType(Tbl)
      expect(false,1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.__type or "table"
end

---returns the hash
---@param Tbl table
---@return string
function utilties.table.get_hash(Tbl)
      expect(false,1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      if meta.__tostring == utilties.table.tostring and not meta.hash
      then
            meta.__tostring = nil
      end
      return meta.hash or tostring(Tbl):match("table: (%x+)") or ""
end
return utilties