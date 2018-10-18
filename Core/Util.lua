-- Util.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:45 PM

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

function Util.ShortPath(path)
    return (path:gsub('^[^\\]*%\\AddOns%\\', ''):gsub('^.+[\r\n]', ''))
end

function Util.FindPath(text)
    local path = text:match('([^:]+:%d+): ')
    return path and Util.ShortPath(path)
end

function Util.FormatPath(path)
    return path and path:gsub('^(.+):(%d+)$', '|cff00ffff%1|r|cffffffff:|r|cffff00ff%2|r') or ''
end

function Util.FormatLogPrefix(path)
    return format('|cff00ff00%s.%03d|r %s|cffffffff:|r ', date('%H:%M:%S'), floor(GetTime() * 1000) % 1000, Util.FormatPath(path))
end

function Util.GetLogPrefix(depth)
    return Util.FormatLogPrefix(Util.FindPath(debugstack(depth, 1, 1)))
end
