-- Api.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/19/2021, 8:15:03 PM
--
---@class ns
---@field db PROFILE
---@field Frame _tdDevToolsFrame
---@field Builder Builder
---@field Thread Thread
---@field TypeRender TypeRender
---@field Key KeyValue
---@field Value Value
---@field Point Value
---@field ScrollFrame _ScrollFrame
---@field ListView ListView
---@field TreeView ListView
---@field ProviderKeyValue ProviderKeyValue
---@field ProviderDisplay ProviderDisplay
---@field ProviderHeader ProviderHeader
---@field PointValue PointValue
local ns = select(2, ...)

local LibClass = LibStub('LibClass-2.0')

local type, select, error, rawget = type, select, error, rawget
local date, debugstack = date, debugstack
local format = string.format
local floor = math.floor
local tinsert, tconcat = table.insert, table.concat

local GetTime = GetTime
local UIParentLoadAddOn = UIParentLoadAddOn

function ns.stringify(value)
    local t = ns.GetType(value)
    local name
    if t == 'uiobject' then
        if value.GetDebugName then
            name = value:GetDebugName()
        elseif value.GetName then
            name = value:GetName()
        end
    elseif t == 'table' then
        name = tostring(value)
    end
    return name or tostring(value) or ''
end

---@return Object
function ns.class(...)
    return LibClass:New(...)
end

local function partition(list, low, high, comp, yield)
    local current = list[low];
    while low < high do
        while low < high and comp(current, list[high]) do
            high = high - 1
        end
        list[low], list[high] = list[high], list[low]

        while low < high and not comp(current, list[low]) do
            low = low + 1
        end
        list[low], list[high] = list[high], list[low]

        if yield then
            yield()
        end
    end
    return low
end

local function qsort(list, low, high, comp, yield)
    if low < high then
        local pivot = partition(list, low, high, comp, yield)
        qsort(list, low, pivot - 1, comp, yield)
        qsort(list, pivot + 1, high, comp, yield)
    end
end

function ns.qsort(list, comp, yield)
    return qsort(list, 1, #list, comp, yield)
end

---@alias WowType type
---| '"uiobject"'

---@alias WowUIType
---| '"Frame"'
---| '"Region"'
---| '"AnimationGroup"'
---| '"Animation"'
---| '"Font"'

---@return WowType
function ns.GetType(obj)
    local t = type(obj)
    if t == 'table' and type(rawget(obj, 0)) == 'userdata' and obj.GetObjectType then
        if not obj.IsForbidden or not obj:IsForbidden() then
            return 'uiobject'
        end
    end
    return t
end

---@return WowUIType
function ns.GetUIObjectType(obj)
    if obj:IsObjectType('Frame') then
        return 'Frame'
    elseif obj:IsObjectType('Region') then
        return 'Region'
    elseif obj:IsObjectType('AnimationGroup') then
        return 'AnimationGroup'
    elseif obj:IsObjectType('Animation') then
        return 'Animation'
    elseif obj:IsObjectType('Font') then
        return 'Font'
    else
        error('unknown type: ' .. obj:GetObjectType())
    end
end

function ns.Render(...)
    local sb = {}
    for i = 1, select('#', ...) do
        tinsert(sb, ns.TypeRender((select(i, ...))))
    end
    return tconcat(sb, ', ')
end

function ns.KeyRender(k)
    if type(k) == 'string' then
        return k
    end
    return ns.TypeRender(k)
end

function ns.CheckBlizzardDebugTools()
    return UIParentLoadAddOn('Blizzard_DebugTools')
end

function ns.ShortPath(path)
    return (path:gsub('^[^\\]*%\\AddOns%\\', ''):gsub('^.+[\r\n]', ''))
end

function ns.FindPath(text)
    local path = text:match('([^:]+:%d+): ')
    return path and ns.ShortPath(path)
end

function ns.ColoredPath(path)
    return path and path:gsub('^(.+):(%d+)$', '|cff00ffff%1|r|cffffffff:|r|cffff00ff%2|r') or ''
end

function ns.GetCallColoredPath(depth)
    return ns.ColoredPath(ns.FindPath(debugstack(depth)))
end

function ns.GetColoredTime()
    return format('|cff00ff00%s.%03d|r', date('%H:%M:%S'), floor(GetTime() * 1000) % 1000)
end

local searchables = {uioject = true, string = true, boolean = true, number = true}
function ns.GenMatch(...)
    local sb = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        if v and v.object then
            local t = ns.GetType(v.object)
            if searchables[t] then
                local s = ns.stringify(v.object)
                if not s:find('\0') then
                    tinsert(sb, s:lower())
                end
            end
        end
    end
    return table.concat(sb, '\001')
end

-- @debug@
function ns.checkGlobal()
    setfenv(2, setmetatable({}, {
        __index = function(t, k)
            C_Timer.After(0, function()
                print(k)
            end)
            t[k] = _G[k]
            return _G[k]
        end,
    }))
end
-- @end-debug@

---@class PROFILE
ns.PROFILE = { --
    global = { --
        errors = {},
    },
    profile = { --
        window = { --
            minimap = {},
            frame = {height = 60},
        },
    },
}
