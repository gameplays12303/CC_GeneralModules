if debug and not  debug.protect
then
    dofile("generalModules/apis/db_Protect.lua")
end
local expect = require("generalModules.expect2").expect
local util = require("generalModules.utilties")
local class = require("generalModules.class")
local fm = require("generalModules.fm")
local fs = fs
local open_Dirs = setmetatable({},{__mode = "v"})
local log
log = class:SubClass("log",{
    Directory = function (self,_sDir,limit)
        self:isClass(true)
        expect(false,1,_sDir,"string")
        if open_Dirs[_sDir]
        then
            return open_Dirs[_sDir]
        end
        limit =  expect(false,2,limit,"number","boolean") or 4
        if not fs.isDir(_sDir) and fs.exists(_sDir)
        then
            error(("%s:is not a directory"):format(_sDir))
        end
        local managment = _sDir.."/logsman.settings"
        ---@class logDir
        local Dir = log:Create_object("logDir")
        Dir.managment = fs.exists(managment) and fm.readFile(managment) or {}
        Dir.managment_dir= _sDir.."/logsman.settings"
        Dir.directory = _sDir
        Dir.limit = limit or false
        --- store it so we don't have fighting dirs
        open_Dirs[_sDir] = Dir
        return Dir
    end,
    Open_log = function (self,_sName)
        self:isObject(false)
        self:isNamed("logDir",true)
        expect(false,1,_sName,"string")
        local path
        local limit = self.limit
        if limit
        then
            local Info = self.managment and self.managment[_sName]
            if not Info
            then
                self.managment[_sName] = {
                    created = 0,
                    count = 0,
                }
                Info = self.managment[_sName]
            end
            Info.count = Info.count + 1
            if Info.created == self.limit
            then
                if Info.count == Info.created
                then
                    Info.count = 0
                else
                    Info.count = Info.count + 1
                end
                if Info.count > 0
                then
                    path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..("(%s).log"):format(Info.count))
                else
                    path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..".log")
                end
            else
                Info.created = Info.created + 1
                if Info.created > 1
                then
                    path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..("(%s).log"):format(Info.created))
                else
                    path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..".log")
                end
            end
            fm.OverWrite(self.managment_dir,self.managment,"S")
        else
            local count = 0
            path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..".log")
            repeat
                count = count + 1
                path = fs.combine(self.directory,util.file.withoutExtension(fs.getName(_sName))..("(%s).log"):format(count))
            until not fs.exists(path)
        end
        local file,err = fs.open(path,"w")
        if not file
        then
            error(err,0)
        end
        ---@class logFile
        local logFile = log:Create_object("logFile")
        logFile.file = file
        logFile.closed = false
        return logFile 
    end,
    Info = function (self,Info)
        self:isObject(true)
        self:isNamed("logFile",true)
        expect(false,1,Info,"string")
        if self:isClosed()
        then
            error("log_file is closed",2)
        end
        self.file.write(("Info:%s:%s\n"):format(os.date(),Info))
    end,
    Warn = function (self,Info)
        self:isObject(true)
        self:isNamed("logFile",true)
        expect(false,1,Info,"string")
        if self:isClosed()
        then
            error("log_file is closed",2)
        end
        self.file.write(("Warn:%s:%s\n"):format(os.date(),Info))
    end,
    Error = function (self,Err)
        self:isObject(true)
        self:isNamed("logFile",true)
        expect(false,1,Err,"string")
        if self:isClosed()
        then
            error("log_file is closed",2)
        end
        self.file.write(("Error:%s:%s\n"):format(os.date(),Err))
    end,
    Fatal = function (self,Fatal)
        self:isObject(true)
        self:isNamed("logFile",true)
        expect(false,1,Fatal,"string")
        if self:isClosed()
        then
            error("log_file is closed",2)
        end
        self.file.write(("Fatal:%s:%s\n"):format(os.date(),Fatal))
    end,
    isClosed = function (self)
        self:isObject(true)
        self:isNamed("logFile",true)
        return self.closed
    end,
    close = function (self)
        self:isObject(true)
        self:isNamed("logFile",true)
        self.file.close()
        self.closed = true
    end
})
return log


