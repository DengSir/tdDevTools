-- Util.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:45 PM

LoadAddOn('Blizzard_DebugTools')

BINDING_HEADER_TDDEVTOOLS = 'tdDevTools'

local ns   = select(2, ...)
local Util = {}

ns.Util = Util

local VALUE_POS = {
    [0] = 'CENTER',
    [1] = 'LEFT',
    [2] = 'RIGHT',

    [4] = 'TOP',
    [5] = 'TOPLEFT',
    [6] = 'TOPRIGHT',

    [8] = 'BOTTOM',
    [9] = 'BOTTOMLEFT',
    [10] = 'BOTTOMRIGHT',
}

function Util.GetCodePath(depth)
    return (
        debugstack(depth, 1, 1)
        :gsub(': in.+$', '')
        :gsub('^[^\\]*%\\AddOns%\\', '')
        :gsub('^(.+):(%d+)$', '|cff00ffff%1|r:|cffff00ff%2|r')
    )
end

function Util.GetMousePosition(frame)
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    x, y = x / scale, y / scale

    local value =   (x <= frame:GetLeft() + 10     and 1 or 0) +    -- left
                    (x >= frame:GetRight() - 10    and 2 or 0) +    -- right
                    (y >= frame:GetTop() - 10      and 4 or 0) +    -- top
                    (y <= frame:GetBottom() + 10   and 8 or 0)      -- bottom

    return VALUE_POS[value], value
end

function Util.GetLogPrefix(depth)
    return format('|cff00ff00%s.%03d|r %s : ', date('%H:%M:%S'), floor(GetTime() * 1000) % 1000, Util.GetCodePath(depth + 1))
end
