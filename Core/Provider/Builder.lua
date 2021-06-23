-- Builder.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/21/2021, 9:01:53 PM
--
---@type ns
local ns = select(2, ...)

local function compare(a, b)
    if a.key ~= b.key then
        return a.key < b.key
    end
    return a.value < b.value
end

---@class Builder: Object
---@field target any
---@field cache table<string, KeyValue[]>
---@field refs table<any, boolean>
---@field out KeyValue[]
---@field type WowType
---@field thread Thread
local Builder = ns.class()

function Builder:Constructor(target, thread)
    self.thread = thread
    self.target = target
    self.type = ns.GetType(target)
    self.cache = {}
    self.refs = {}
    self.out = {}
end

function Builder:Add(t, kv)
    self.cache[t] = self.cache[t] or {}
    tinsert(self.cache[t], kv)
end

function Builder:AddValue(t, object)
    if not object then
        return
    end
    return self:Add(t, ns.ProviderDisplay:New(ns.Value:New(object)))
end

function Builder:AddKeyValue(key, value, checkStar)
    if self.refs[value] then
        return
    end

    local t = ns.GetType(value)
    if t == 'uiobject' then
        if checkStar and self.type == 'uiobject' then
            local isChild = value.GetParent and value:GetParent() == self.target
            self:Add(ns.GetUIObjectType(value), ns.ProviderKeyValue:New(key, value, not isChild))
        else
            self:Add(ns.GetUIObjectType(value), ns.ProviderKeyValue:New(key, value))
        end
    else
        self:Add(t, ns.ProviderKeyValue:New(key, value))
    end

    if t == 'uiobject' or t == 'table' then
        self.refs[value] = true
    end

    self.thread:YieldPoint()
end

function Builder:AddList(list)
    for _, v in ipairs(list) do
        self:AddKeyValue('', v)
    end
end

function Builder:AddListMothod(method)
    if not self.target[method] then
        return
    end
    return self:AddList({self.target[method](self.target)})
end

function Builder:PackType(t)
    local res = self.cache[t]
    if not res or #res == 0 then
        return
    end

    tinsert(self.out, ns.ProviderHeader:New(t, #res))

    if #res < 2000 then
        sort(res, compare)
    else
        local function yield()
            return self.thread:YieldPoint()
        end
        ns.qsort(res, compare, yield)
    end

    for _, v in ipairs(res) do
        tinsert(self.out, v)
    end
end

function Builder:Process()
    for k, v in pairs(self.target) do
        self:AddKeyValue(k, v, true)
    end

    self:AddValue('Metatable', getmetatable(self.target))

    if ns.GetType(self.target) == 'uiobject' then
        if self.target.GetNumPoints then
            for i = 1, self.target:GetNumPoints() do
                self:Add('Anchor', ns.ProviderDisplay:New(ns.PointValue:New(self.target:GetPoint(i))))
            end
        end

        self:AddListMothod('GetChildren')
        self:AddListMothod('GetRegions')
        self:AddListMothod('GetAnimationGroups')
        self:AddListMothod('GetAnimations')
    end

    self:PackType('Metatable')
    self:PackType('Anchor')
    self:PackType('Frame')
    self:PackType('Region')
    self:PackType('AnimationGroup')
    self:PackType('Animation')
    self:PackType('string')
    self:PackType('number')
    self:PackType('boolean')
    self:PackType('table')
    self:PackType('userdata')
    self:PackType('function')
    self:PackType('thread')

    return self.out
end

ns.Builder = Builder
