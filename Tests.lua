-- Tests.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:06:29 AM

-- local orig = C_ChatInfo.SendAddonMessage

-- C_ChatInfo.SendAddonMessage = function(...)
--     print(...)
--     return orig(...)
-- end

-- local Frame = CreateFrame('Frame')
-- Frame:RegisterEvent('CHAT_MSG_ADDON')
-- Frame:SetScript('OnEvent', function(_, ...)
--     print(...)
-- end)

function printsecure(tbl)
    for k, v in pairs(tbl) do
        print(k, v, issecurevariable(tbl, k))
    end
end
