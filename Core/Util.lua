-- Util.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:45 PM

BINDING_HEADER_TDDEVTOOLS = 'tdDevTools'

local ns         = select(2, ...)
local TypeRender = ns.TypeRender
local Util       = {}

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

local function ShortPath(path)
    return (path:gsub('^[^\\]*%\\AddOns%\\', ''):gsub('^.+[\r\n]', ''))
end

local function FindPath(text)
    local path = text:match('([^:]+:%d+): ')
    return path and ShortPath(path)
end

local function ColoredPath(path)
    return path and path:gsub('^(.+):(%d+)$', '|cff00ffff%1|r|cffffffff:|r|cffff00ff%2|r') or ''
end

local function GetCallColoredPath(depth)
    return ColoredPath(FindPath(debugstack(depth)))
end

local function Render(...)
    local sb = {}
    for i = 1, select('#', ...) do
        table.insert(sb, TypeRender((select(i, ...))))
    end
    return table.concat(sb, ', ')
end

local function GetColoredTime()
    return format('|cff00ff00%s.%03d|r', date('%H:%M:%S'), floor(GetTime() * 1000) % 1000)
end

Util.ShortPath          = ShortPath
Util.FindPath           = FindPath
Util.ColoredPath        = ColoredPath
Util.GetCallColoredPath = GetCallColoredPath
Util.Render             = Render
Util.GetColoredTime     = GetColoredTime


function Util.NoRender(...)
    return ...
end
