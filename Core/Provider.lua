-- Object.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/19/2021, 12:57:32 AM
--
---@type ns
local ns = select(2, ...)

local ipairs, pairs, getmetatable, print, tostring = ipairs, pairs, getmetatable, print, tostring
local tinsert, sort = table.insert, table.sort or sort

local C_Widget = C_Widget

---@class Provider: Object
---@field items ProviderItem[]
---@field list ProviderItem[]
local Provider = ns.class()
ns.Provider = Provider

local function compare(a, b)
    print(a, b)
    if a.key ~= b.key then
        return a.key < b.key
    end
    return a.value < b.value
end

function Provider:Constructor(target)
    self.target = target
    self.type = ns.GetType(self.target)
end

function Provider:SetFilter(text)
    text = text:trim():lower()

    self.filter = text ~= '' and text or nil
end

function Provider:Kill()
    if self.processThread then
        self.processThread:Kill()
        self.processThread = nil
    end
end

function Provider:PackType(t, list, map, out)
    local res = list[t] or {}
    if map[t] then
        for _, v in pairs(map[t]) do
            tinsert(res, v)
        end
    end

    if #res == 0 then
        return
    end

    tinsert(out, ns.ProviderHeader:New(t, #res))

    if #res < 2000 then
        sort(res, compare)
    else
        ns.qsort(res, compare, function()
            return self.processThread:YieldPoint()
        end)
    end

    for _, v in ipairs(res) do
        tinsert(out, v)
    end
end

function Provider:ProcessObjects(objects, map)
    for _, obj in ipairs(objects) do
        local t = ns.GetType(obj)
        if t ~= 'uiobject' then
        else
            local st = ns.GetUIObjectType(obj)
            map[st] = map[st] or {}
            map[st][obj] = ns.ProviderKeyValue:New('', obj)
        end
        self.processThread:YieldPoint()
    end
end

function Provider:ProcessData()
    local thread = self.processThread

    local out = {}
    local map = {}
    local more = {}

    -- local mt = getmetatable(self.target)
    -- if mt then
    --     tinsert(out, ProviderHeader:New('metatable'))
    --     tinsert(out, ProviderValue:New(mt))
    -- end

    if self.type == 'uiobject' then
        -- if self.target.GetNumPoints then
        --     local n = self.target:GetNumPoints()
        --     if n and n > 0 then
        --         tinsert(out, ProviderHeader:New('anchor'))

        --         for i = 1, n do
        --             local point, relative, relativePoint, x, y = self.target:GetPoint(i)

        --             tinsert(out, ProviderValue:New(relative, ns.Render(point, relative, relativePoint, x, y)))
        --         end
        --     end
        -- end

        if self.target.GetChildren then
            self:ProcessObjects({self.target:GetChildren()}, map)
        end
        if self.target.GetRegions then
            self:ProcessObjects({self.target:GetRegions()}, map)
        end
        if self.target.GetAnimationGroups then
            self:ProcessObjects({self.target:GetAnimationGroups()}, map)
        end
        if self.target.GetAnimations then
            self:ProcessObjects({self.target:GetAnimations()}, map)
        end
    end

    for k, v in pairs(self.target) do
        local t = ns.GetType(v)
        if t == 'uiobject' then
            local st = ns.GetUIObjectType(v)
            map[st] = map[st] or {}
            if map[st][v] then
                if map[st][v].key == '' then
                    map[st][v]:SetKey(k)
                else
                    more[t] = more[t] or {}
                    tinsert(more[t], ns.ProviderKeyValue:New(k, v))
                end
            else
                local isChild = v.GetParent and v:GetParent() == self.target
                map[st][v] = ns.ProviderKeyValue:New(k, v, not isChild)
            end
        else
            more[t] = more[t] or {}
            tinsert(more[t], ns.ProviderKeyValue:New(k, v))
        end

        thread:YieldPoint()
    end

    self:PackType('Frame', more, map, out)
    self:PackType('Region', more, map, out)
    self:PackType('AnimationGroup', more, map, out)
    self:PackType('Animation', more, map, out)
    self:PackType('Font', more, map, out)
    self:PackType('userdata', more, map, out)
    self:PackType('string', more, map, out)
    self:PackType('number', more, map, out)
    self:PackType('boolean', more, map, out)
    self:PackType('table', more, map, out)
    self:PackType('function', more, map, out)
    self:PackType('thread', more, map, out)

    self.items = out
    self.list = out

    C_Timer.After(0, function()
        self:Fire('OnRefresh')
    end)


    print('done')
end

function Provider:ProcessFilter()
    if not self.items then
        return
    end

    if self.filter then
        local out = {}
        for _, v in ipairs(self.items) do
            if v:Match(self.filter) then
                tinsert(out, v)
            end
        end
        self.list = out
    else
        self.list = self.items
    end

    self:Fire('OnRefresh')
end

function Provider:Refresh()
    if self.processThread then
        return
    end
    self.processThread = ns.Thread:New()
    self.processThread:Start(function()
        self:ProcessData()
        self:ProcessFilter()
        self.processThread = nil
    end)
    return not self.processThread
end

function Provider:GetParent()
    if self.type == 'uiobject' then
        if self.target.GetParent then
            return self.target:GetParent()
        else
            print('no GetParent ' .. self.target:GetObjectType())
        end
    end
end

function Provider:GetTitle()
    if self.type == 'uiobject' then
        if self.target.GetDebugName then
            return self.target:GetDebugName()
        elseif self.target.GetName then
            return self.target:GetName()
        else
            return self.target:GetObjectType() .. ' ' .. tostring(self.target)
        end
    else
        return 'Table'
    end
end

function Provider:IsUIObject()
    return self.type == 'uiobject'
end

function Provider:IsReaderable()
    return C_Widget.IsRenderableWidget(self.target)
end
