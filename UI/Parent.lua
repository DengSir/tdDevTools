-- Parent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/18/2021, 8:28:49 PM
--
---@type ns
local ns = select(2, ...)

local IsAddOnLoaded = IsAddOnLoaded
local GetScreenWidth = GetScreenWidth
local GetPhysicalScreenSize = GetPhysicalScreenSize

local Parent = tdDevToolsParent
ns.Parent = Parent

function Parent:OnLoad()
    self.DISPLAY_SIZE_CHANGED = self.UpdateSize
    self.UI_SCALE_CHANGED = self.UpdateSize

    self:RegisterEvent('DISPLAY_SIZE_CHANGED')
    self:RegisterEvent('UI_SCALE_CHANGED')

    self:SetScript('OnEvent', self.OnEvent)

    self:UpdateSize()
    self:CheckDebugTools()
end

function Parent:OnEvent(event, ...)
    self[event](self, ...)
end

function Parent:UpdateSize()
    self:SetScale(GetScreenWidth() / GetPhysicalScreenSize() * 2)
end

function Parent:OnBlizzardDebugToolsLoaded()
    function FrameStackTooltip_InspectTable(o)
        return ns.Inspect:InspectTable(o.highlightFrame, true)
    end

    function DisplayTableInspectorWindow(obj)
        return ns.Inspect:InspectTable(obj)
    end
end

function Parent:CheckDebugTools()
    if IsAddOnLoaded('Blizzard_DebugTools') then
        self:OnBlizzardDebugToolsLoaded()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end

function Parent:ADDON_LOADED(addon)
    if addon == 'Blizzard_DebugTools' then
        self:OnBlizzardDebugToolsLoaded()
        self:UnregisterEvent('ADDON_LOADED')
    end
end

Parent:OnLoad()
