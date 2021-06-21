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
---@field object any
---@field display any
local KeyValue = ns.class()

function KeyValue._Meta:__lt(other)
    print(self.display, other.display)
    return self.display < other.display
end

function KeyValue._Meta:__eq(other)
    print(self.display, other.display)
    return self.display == other.display
end

--
--
---@class Key: KeyValue
local Key = ns.class(KeyValue)

function Key:Constructor(object, display)
    if object and object ~= '' then
        self.object = object
        self.display = display or ns.KeyRender(object)
    else
        self.object = ''
        self.display = '|cff808080n/a|r'
    end
end

--
--
---@class Value: KeyValue
local Value = ns.class(KeyValue)

function Value:Constructor(object, display)
    self.object = object
    self.display = display or ns.TypeRender(object)
end

--
--
---@class PointValue: KeyValue
local PointValue = ns.class(KeyValue)

function PointValue:Constructor(p, relative, ...)
    if ns.GetType(relative) == 'uiobject' then
        self.object = relative
    end
    self.display = ns.Render(p, relative, ...)
end

ns.Key = Key
ns.Value = Value
ns.PointValue = PointValue
