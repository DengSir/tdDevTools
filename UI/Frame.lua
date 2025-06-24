-- Frame.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 4:36:17 PM
--
---@type ns
local ns = select(2, ...)

local GetBindingKey = GetBindingKey
local GetCurrentKeyBoardFocus = GetCurrentKeyBoardFocus

---@class _tdDevToolsFrame: Object, tdDevToolsFrame
---@field tabs Button[]
---@field tabFrames Frame[]
---@field numTabs number
---@field selectedTab number
---@field Console tdDevToolsConsole
---@field Event __Event
---@field Document tdDevToolsDocument
---@field Error tdDevToolsError
local Frame = ns.class('Frame')

function Frame:Constructor()
    self.numTabs = #self.tabs
    self:SetTab(1)
    -- self:SetScript('OnKeyDown', self.OnKeyDown)
    self:SetScript('OnShow', function(self)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 100)
        self:RestorePosition()
    end)
    self:GetParent():HookScript('OnSizeChanged', function()
        self:SetPoint('TOPLEFT')
        self:SetPoint('TOPRIGHT')
        self:RestorePosition()
    end)

    tinsert(UISpecialFrames, self:GetName())
end

-- function Frame:OnKeyDown(key)
--     if key == GetBindingKey('TOGGLEGAMEMENU') and self:IsShown() and not GetCurrentKeyBoardFocus() then
--         self:Hide()
--         self:SetPropagateKeyboardInput(false)
--         return
--     end
--     self:SetPropagateKeyboardInput(true)
-- end

function Frame:SetTab(id)
    self.selectedTab = id

    local prev
    for i = 1, self.numTabs do
        local tab = self.tabs[i]
        local tabFrame = self.tabFrames[i]

        tabFrame:SetShown(i == id)
        tab:SetEnabled(i ~= id)
        tab:SetHeight(i == id and 22 or 19)

        if tab:IsShown() then
            tab:ClearAllPoints()
            if not prev then
                tab:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 10, 1)
            else
                tab:SetPoint('TOPLEFT', prev, 'TOPRIGHT', 5, 0)
            end
            prev = tab
        end
    end
end

function Frame:AddTab(text, frame)
    local id = self.numTabs + 1

    local tab = CreateFrame('Button', nil, self, 'tdDevToolsTabButtonTemplate', id)
    tab:SetText(text)

    self.tabs[id] = tab
    self.tabFrames[id] = frame
    self.numTabs = id

    self:SetTab(self.selectedTab or 1)

    return tab
end

function Frame:Toggle(tab)
    if tab and self.selectedTab ~= tab then
        self:SetTab(tab)
    else
        self:SetShown(not self:IsShown())
    end
end

function Frame:OnTargetClick(showHidden)
    ns.CheckBlizzardDebugTools()
    FrameStackTooltip_Toggle(showHidden, true, true)
end

function Frame:SavePosition()
    self:SetUserPlaced(false)
    ns.db.profile.window.height = self:GetHeight() / self:GetParent():GetHeight()
end

function Frame:RestorePosition()
    self:SetHeight(ns.db.profile.window.height * self:GetParent():GetHeight())
end

ns.Frame = Frame:Bind(tdDevToolsFrame)
