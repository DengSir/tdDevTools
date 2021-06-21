-- ProviderItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/21/2021, 5:09:28 PM
--
---@type ns
local ns = select(2, ...)

--
--
---@class ProviderItem: Object
---@field key KeyValue
---@field value KeyValue
---@field star boolean
---@field type string
local ProviderItem = ns.class()

function ProviderItem:Match(text)
    return not self.match or self.match:find(text, nil, true)
end

--
--
---@class ProviderHeader: ProviderItem
local ProviderHeader = ns.class(ProviderItem)

function ProviderHeader:Constructor(header, count)
    self.type = 'header'
    if count then
        self.header = format('%s (%d)', header, count)
    else
        self.header = header
    end
end

--
--
---@class ProviderValue: ProviderItem
local ProviderValue = ns.class(ProviderItem)

function ProviderValue:Constructor(object, display)
    self.type = ns.GetType(object)
    self.object = object
    self.value = display or ns.TypeRender(object)
    self.match = ns.GenMatch(object)
end

--
--
---@class ProviderKeyValue: ProviderItem
local ProviderKeyValue = ns.class(ProviderItem)

function ProviderKeyValue:Constructor(key, value, star)
    self.star = star
    self.value = ns.Value:New(value)
    self:SetKey(key)
end

function ProviderKeyValue:SetKey(key)
    self.key = ns.Key:New(key)
end


ns.ProviderHeader = ProviderHeader
ns.ProviderKeyValue = ProviderKeyValue
