-- API.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:02:38 AM

local ns      = select(2, ...)
local Util    = ns.Util
local Console = ns.Frame.Console

setprinthandler(function(...)
    return Console:Print(Util.GetLogPrefix(8) .. table.concat({Console:RenderAll(...)}, ', '))
end)

local function BuildRunDumpContext(orig)
    local prefix = Util.GetLogPrefix(4)
    local function Write(_, text)
        return Console:Print(prefix .. 'Dump: ' .. text, 1, 1, 1)
    end
    return function(value, context)
        context.Write = Write
        return orig(value, context)
    end
end

function dump(...)
    if UIParentLoadAddOn('Blizzard_DebugTools') then
        local orig = DevTools_RunDump
        DevTools_RunDump = BuildRunDumpContext(orig)
        DevTools_Dump({...}, 'value')
        DevTools_RunDump = orig
    end
end

function inspect(value)
    if UIParentLoadAddOn('Blizzard_DebugTools') then
        DisplayTableInspectorWindow(value)
    end
end
