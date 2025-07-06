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

---@class Parent: Object, Frame
local Parent = ns.class('Frame')

function Parent:Constructor()
    self.DISPLAY_SIZE_CHANGED = self.RequestUpdateSize
    self.UI_SCALE_CHANGED = self.RequestUpdateSize

    self:RegisterEvent('DISPLAY_SIZE_CHANGED')
    self:RegisterEvent('UI_SCALE_CHANGED')
    self:RegisterEvent('PLAYER_LOGIN')

    self:SetScript('OnEvent', self.OnEvent)

    self:UpdateSize()
    self:CheckDebugTools()
end

function Parent:OnEvent(event, ...)
    self[event](self, ...)
end

function Parent:PLAYER_LOGIN()
    self:SetupDatabase()
    self:SetupMinimap()
end

function Parent:SetupDatabase()
    ns.db = LibStub('AceDB-3.0'):New('TDDB_DEVTOOLS_NEW', ns.PROFILE, true)

    if _G.TDDB_DEVTOOLS then
        if _G.TDDB_DEVTOOLS.errors then
            for _, v in ipairs(_G.TDDB_DEVTOOLS.errors) do
                tinsert(ns.db.global.errors, v)
            end
        end

        _G.TDDB_DEVTOOLS = nil
    end
end

function Parent:SetupMinimap()
    local ADDON = 'tdDevTools'
    local LDB = LibStub('LibDataBroker-1.1')
    local LDBIcon = LibStub('LibDBIcon-1.0')

    local obj = LDB:NewDataObject(ADDON, {
        type = 'data source',
        icon = [[Interface\HelpFrame\helpicon-bug]],
        iconCoords = {0.1, 0.9, 0.1, 0.9},
        OnEnter = function(button)
            GameTooltip:SetOwner(button, 'ANCHOR_LEFT')
            GameTooltip:SetText(ADDON)
        end,
        OnLeave = GameTooltip_Hide,
        OnClick = function(_, clicked)
            if clicked == 'LeftButton' then
                ns.Frame:SetShown(not ns.Frame:IsShown())
            else
            end
        end,
    })

    LDBIcon:Register(ADDON, obj, ns.db.profile.window.minimap)
end

function Parent:RequestUpdateSize()
    self:SetScript('OnUpdate', self.OnUpdate)
end

function Parent:OnUpdate()
    self:SetScript('OnUpdate', nil)
    self:UpdateSize()
end

function Parent:UpdateSize()
    self:SetScale(GetScreenWidth() / GetPhysicalScreenSize() * 2 * GetScreenDPIScale())
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

ns.Parent = Parent:Bind(tdDevToolsParent)
