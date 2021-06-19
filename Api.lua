-- Api.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/19/2021, 8:15:03 PM
--
---@class ns
local ns = select(2, ...)

local LibClass = LibStub('LibClass-2.0')

local type, select, error, rawget = type, select, error, rawget
local tinsert, tconcat = table.insert, table.concat

function ns.class(...)
    return LibClass:New(...)
end

function ns.GetType(obj)
    local t = type(obj)
    if t == 'table' and type(rawget(obj, 0)) == 'userdata' and obj.GetObjectType then
        if not obj.IsForbidden or not obj:IsForbidden() then
            return 'uiobject'
        end
    end
    return t
end

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
