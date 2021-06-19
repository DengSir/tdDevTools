-- API.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:02:38 AM
--
---@type ns
local ns = select(2, ...)
local Console = ns.Frame.Console

local GetCallColoredPath = ns.Util.GetCallColoredPath

setprinthandler(function(...)
    return Console:Log('DEBUG', 8, ...)
end)

local function BuildRunDumpContext(orig)
    local path = GetCallColoredPath(4)
    local function Write(_, text)
        return Console:RawLog('DEBUG', path, 'Dump: ' .. text)
    end

    return function(value, context)
        context.Write = Write
        return orig(value, context)
    end
end

local function dump(...)
    local orig = DevTools_RunDump
    DevTools_RunDump = BuildRunDumpContext(orig)
    DevTools_Dump({...}, 'value')
    DevTools_RunDump = orig
end

function _G.dump(...)
    if ns.CheckBlizzardDebugTools() then
        _G.dump = dump
        return dump(...)
    end
end

function _G.inspect(value)
    return ns.Inspect:InspectTable(value)
end
