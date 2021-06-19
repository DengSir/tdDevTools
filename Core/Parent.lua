-- Parent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/18/2021, 8:28:49 PM
--
---@type ns
local ns = select(2, ...)

local Parent = tdDevToolsParent
ns.Parent = Parent

local function UpdateSize()
    Parent:SetScale(GetScreenWidth() / GetPhysicalScreenSize() * 2)
end

ns.event('DISPLAY_SIZE_CHANGED', UpdateSize)
ns.event('UI_SCALE_CHANGED', UpdateSize)
ns.addon('Blizzard_DebugTools', function()
    function FrameStackTooltip_InspectTable(o)
        return ns.Inspect:InspectTable(o.highlightFrame, true)
    end

    function DisplayTableInspectorWindow(obj)
        return ns.Inspect:InspectTable(obj)
    end
end)
