-- API.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:02:38 AM

local ns      = select(2, ...)
local Util    = ns.Util
local Console = ns.Console

setprinthandler(function(...)
    return Console:Print(Util.GetLogPrefix(8) .. table.concat({Console:RenderAll(...)}, ', '))
end)

local orig_DevTools_RunDump = DevTools_RunDump
local function Build_DevTools_RunDump()
    local prefix = Util.GetLogPrefix(4)
    local function Write(_, text)
        return Console:Print(prefix .. 'Dump: ' .. text)
    end
    return function(value, context)
        context.Write = Write
        return orig_DevTools_RunDump(value, context)
    end
end

function dump(...)
    DevTools_RunDump = Build_DevTools_RunDump()
    DevTools_Dump({...}, 'value')
    DevTools_RunDump = orig_DevTools_RunDump
end

function inspect(value)
    UIParentLoadAddOn('Blizzard_DebugTools')
    DisplayTableInspectorWindow(value)
end
