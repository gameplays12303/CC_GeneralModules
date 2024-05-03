-- dbprotect.lua - Protect your functions from the debug library
-- By JackMacWindows
-- Licensed under CC0, though I'd appreciate it if this notice was left in place.

-- Simply run this file in some fashion, then call `debug.protect` to protect a function.
-- It takes the function as the first argument, as well as a list of functions
-- that are still allowed to access the function's properties.
-- Once protected, access to the function's environment, locals, and upvalues is
-- blocked from all Lua functions. A function *can not* be unprotected without
-- restarting the Lua state.
-- The debug library itself is protected too, so it's not possible to remove the
-- protection layer after being installed.
-- It's also not possible to add functions to the whitelist after protecting, so
-- make sure everything that needs to access the function's properties are added.

local protectedObjects
local n_getfenv, n_setfenv, d_getfenv, getlocal, getupvalue, d_setfenv, setlocal, setupvalue, upvaluejoin =
    getfenv, setfenv, debug.getfenv, debug.getlocal, debug.getupvalue, debug.setfenv, debug.setlocal, debug.setupvalue, debug.upvaluejoin

local error, getinfo, running, select, setmetatable, type, tonumber = error, debug.getinfo, coroutine.running, select, setmetatable, type, tonumber

local superprotected

local function keys(t, v, ...)
    if v then t[v] = true end
    if select("#", ...) > 0 then return keys(t, ...)
    else return t end
end

local function superprotect(v, ...)
    if select("#", ...) > 0 then return superprotected[v or ""] or v, superprotect(...)
    else return superprotected[v or ""] or v end
end

local function checkint32(n)
    n = bit32.band(tonumber(n), 0xFFFFFFFF)
    if bit32.btest(n, 0x80000000) then n = n - 0x100000000 end
    return n
end

function debug.getinfo(thread, func, what)
    if type(thread) ~= "thread" then what, func, thread = func, thread, running() end
    local retval
    if tonumber(func) then retval = getinfo(thread, func+1, what)
    else retval = getinfo(thread, func, what) end
    if retval and retval.func then retval.func = superprotected[retval.func] or retval.func end
    return retval
end

function debug.getlocal(thread, level, loc)
    if loc == nil then loc, level, thread = level, thread, running() end
    local k, v
    if type(level) == "function" then
        local caller = getinfo(2, "f")
        if protectedObjects[level] and not (caller and protectedObjects[level][caller.func]) then return nil end
        k, v = superprotect(getlocal(level, loc))
    elseif tonumber(level) then
        local info = getinfo(thread, level + 1, "f")
        local caller = getinfo(2, "f")
        if info and protectedObjects[info.func] and not (caller and protectedObjects[info.func][caller.func]) then return nil end
        k, v = superprotect(getlocal(thread, level + 1, loc))
    else k, v = superprotect(getlocal(thread, level, loc)) end
    return k, v
end

function debug.getupvalue(func, up)
    if type(func) == "function" then
        local caller = getinfo(2, "f")
        if protectedObjects[func] and not (caller and protectedObjects[func][caller.func]) then return nil end
    end
    local k, v = superprotect(getupvalue(func, up))
    return k, v
end

function debug.setlocal(thread, level, loc, value)
    if loc == nil then loc, level, thread = level, thread, running() end
    if tonumber(level) then
        local info = getinfo(thread, level + 1, "f")
        local caller = getinfo(2, "f")
        if info and protectedObjects[info.func] and not (caller and protectedObjects[info.func][caller.func]) then error("attempt to set local of protected function", 2) end
        setlocal(thread, level + 1, loc, value)
    else setlocal(thread, level, loc, value) end
end

function debug.setupvalue(func, up, value)
    if type(func) == "function" then
        local caller = getinfo(2, "f")
        if protectedObjects[func] and not (caller and protectedObjects[func][caller.func]) then error("attempt to set upvalue of protected function", 2) end
    end
    setupvalue(func, up, value)
end

function _G.getfenv(f)
    local v
    if f == nil then v = n_getfenv(2)
    elseif tonumber(f) and checkint32(f) > 0 then
        local info = getinfo(f + 1, "f")
        local caller = getinfo(2, "f")
        if info and protectedObjects[info.func] and not (caller and protectedObjects[info.func][caller.func]) then return nil end
        v = n_getfenv(f+1)
    elseif type(f) == "function" then
        local caller = getinfo(2, "f")
        if protectedObjects[f] and not (caller and protectedObjects[f][caller.func]) then return nil end
        v = n_getfenv(f)
    else v = n_getfenv(f) end
    return v
end

function _G.setfenv(f, tab)
    if tonumber(f) and checkint32(f) > 0 then
        local info = getinfo(f + 1, "f")
        local caller = getinfo(2, "f")
        if info and protectedObjects[info.func] and not (caller and protectedObjects[info.func][caller.func]) then error("attempt to set environment of protected function", 2) end
        n_setfenv(f+1, tab)
    elseif type(f) == "function" then
        local caller = getinfo(2, "f")
        if protectedObjects[f] and not (caller and protectedObjects[f][caller.func]) then error("attempt to set environment of protected function", 2) end
    end
    n_setfenv(f, tab)
end

if d_getfenv then
    function debug.getfenv(o)
        if type(o) == "function" then
            local caller = getinfo(2, "f")
            if protectedObjects[o] and not (caller and protectedObjects[o][caller.func]) then return nil end
        end
        local v = d_getfenv(o)
        return v
    end

    function debug.setfenv(o, tab)
        if type(o) == "function" then
            local caller = getinfo(2, "f")
            if protectedObjects[o] and not (caller and protectedObjects[o][caller.func]) then error("attempt to set environment of protected function", 2) end
        end
        d_setfenv(o, tab)
    end
end

if upvaluejoin then
    function debug.upvaluejoin(f1, n1, f2, n2)
        if type(f1) == "function" and type(f2) == "function" then
            local caller = getinfo(2, "f")
            if protectedObjects[f1] and not (caller and protectedObjects[f1][caller.func]) then error("attempt to get upvalue of protected function", 2) end
            if protectedObjects[f2] and not (caller and protectedObjects[f2][caller.func]) then error("attempt to set upvalue of protected function", 2) end
        end
        upvaluejoin(f1, n1, f2, n2)
    end
end

function debug.protect(func, ...)
    if type(func) ~= "function" then error("bad argument #1 (expected function, got " .. type(func) .. ")", 2) end
    if protectedObjects[func] then error("attempt to protect a protected function", 2) end
    protectedObjects[func] = keys(setmetatable({}, {__mode = "k"}), ...)
end

superprotected = {
    [n_getfenv] = _G.getfenv,
    [n_setfenv] = _G.setfenv,
    [d_getfenv] = debug.getfenv,
    [d_setfenv] = debug.setfenv,
    [getlocal] = debug.getlocal,
    [setlocal] = debug.setlocal,
    [getupvalue] = debug.getupvalue,
    [setupvalue] = debug.setupvalue,
    [upvaluejoin] = debug.upvaluejoin,
    [getinfo] = debug.getinfo,
    [superprotect] = function() end,
}

protectedObjects = keys(setmetatable({}, {__mode = "k"}),
    getfenv,
    setfenv,
    debug.getfenv,
    debug.setfenv,
    debug.getlocal,
    debug.setlocal,
    debug.getupvalue,
    debug.setupvalue,
    debug.upvaluejoin,
    debug.getinfo,
    superprotect,
    debug.protect
)
for k,v in pairs(protectedObjects) do protectedObjects[k] = {} end