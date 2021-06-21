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
    local match = self.match
    return not match or match:find(text, nil, true)
end

--
--
---@class ProviderHeader: ProviderItem
local ProviderHeader = ns.class(ProviderItem)

function ProviderHeader:Constructor(header, count)
    self.type = 'header'

    if count then
        self.header = format('%s (%d)', header:upper(), count)
    else
        self.header = header
    end
end

--
--
---@class ProviderDisplay: ProviderItem
local ProviderDisplay = ns.class(ProviderItem)

function ProviderDisplay:Constructor(value)
    self.value = value
    self.match = ns.GenMatch(value)
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
    if key == '' then
        self.key = ns.Key.Empty
        self.match = ns.GenMatch(self.value)
    else
        self.key = ns.Key:New(key)
        self.match = ns.GenMatch(self.key, self.value)
    end
end

ns.ProviderHeader = ProviderHeader
ns.ProviderKeyValue = ProviderKeyValue
ns.ProviderDisplay = ProviderDisplay
