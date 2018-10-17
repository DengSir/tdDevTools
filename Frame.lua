-- Frame.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 4:36:17 PM

local ns    = select(2, ...)
local Frame = tdDevToolsFrame

ns.Frame = Frame

function Frame:OnLoad()
    -- self.tabs = {
    --     self.Console,
    --     self.Error,
    -- }
end

function Frame:OnTabClick(id)
    for i, frame in ipairs(self.tabFrames) do
        frame:SetShown(i == id)
    end
end

Frame:OnLoad()
