-- Frame.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 4:36:17 PM
--
---@type ns
local ns = select(2, ...)
local Frame = tdDevToolsFrame

ns.Frame = Frame

function Frame:OnLoad()
    self.numTabs = #self.tabs
    self:SetTab(1)
    self:SetScript('OnKeyDown', self.OnKeyDown)
    self:SetScript('OnShow', function(self)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 100)
    end)
end

function Frame:OnKeyDown(key)
    if key == GetBindingKey('TOGGLEGAMEMENU') and self:IsShown() and not GetCurrentKeyBoardFocus() then
        self:Hide()
        self:SetPropagateKeyboardInput(false)
        return
    end
    self:SetPropagateKeyboardInput(true)
end

function Frame:SetTab(id)
    self.selectedTab = id

    for i = 1, self.numTabs do
        self.tabFrames[i]:SetShown(i == id)
        self.tabs[i]:SetEnabled(i ~= id)
        self.tabs[i]:SetHeight(i == id and 22 or 19)
    end
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

Frame:OnLoad()
