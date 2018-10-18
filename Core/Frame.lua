-- Frame.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 4:36:17 PM

local ns    = select(2, ...)
local Frame = tdDevToolsFrame

ns.Frame = Frame

function Frame:OnLoad()
    self.numTabs = #self.tabs
    self:SetTab(1)
    self:SetUserPlaced(false)
    self:SetScript('OnEvent', self.OnEvent)
    self:RegisterEvent('DISPLAY_SIZE_CHANGED')
    tinsert(UISpecialFrames, self:GetName())
end

function Frame:OnEvent(event, ...)
    self[event](self, ...)
end

function Frame:DISPLAY_SIZE_CHANGED()
    self:SetPoint('TOPLEFT')
    self:SetPoint('TOPRIGHT')
end

function Frame:SetTab(id)
    for i = 1, self.numTabs do
        self.tabFrames[i]:SetShown(i == id)
        self.tabs[i]:SetEnabled(i ~= id)
        self.tabs[i]:SetHeight(i == id and 25 or 22)
    end
end

Frame:OnLoad()
