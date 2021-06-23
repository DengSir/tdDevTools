-- KeyValue.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/21/2021, 4:57:54 PM
--
---@type ns
local ns = select(2, ...)

--
--
---@class KeyValue: Object
---@field _Meta KeyValue
---@field Empty KeyValue
---@field object any
---@field display string
---@field type string
---@field empty boolean
local KeyValue = ns.class()

function KeyValue._Meta:__lt(other)
    if self.empty then
        return true
    end
    if other.empty then
        return false
    end
    return self.display < other.display
end

function KeyValue:IsInspectable()
    return self.type == 'uiobject' or self.type == 'table'
end

function KeyValue:IsCopiable()
    return self.type == 'string' or self.type == 'number' or self.type == 'boolean'
end

--
--
---@class Key: KeyValue
local Key = ns.class(KeyValue)

function Key:Constructor(object, display)
    if object and object ~= '' then
        self.object = object
        self.type = ns.GetType(object)
        self.display = display or ns.KeyRender(object)
    else
        self.empty = true
        self.display = '|cff808080n/a|r'
    end
end

Key.Empty = Key:New('')

--
--
---@class Value: KeyValue
local Value = ns.class(KeyValue)

function Value:Constructor(object, display)
    self.object = object
    self.type = ns.GetType(object)
    self.display = display or ns.TypeRender(object)
end

--
--
---@class PointValue: KeyValue
local PointValue = ns.class(KeyValue)

function PointValue:Constructor(p, relative, ...)
    if ns.GetType(relative) == 'uiobject' then
        self.object = relative
        self.type = ns.GetType(relative)
    end
    self.display = ns.Render(p, relative, ...)
end

ns.Key = Key
ns.Value = Value
ns.PointValue = PointValue
