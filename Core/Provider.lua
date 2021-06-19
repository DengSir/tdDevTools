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

ns.checkGlobal()

---@class Provider: Object
local Provider = ns.class()
ns.Provider = Provider

local function compare(a, b)
    if a.key ~= b.key then
        return a.key < b.key
    end
    return a.value < b.value
end

local function ProcessObjects(objects, map)
    for _, obj in ipairs(objects) do
        local t = ns.GetType(obj)
        if t ~= 'uiobject' then
        else
            local st = ns.GetUIObjectType(obj)
            map[st] = map[st] or {}
            map[st][obj] = {type = t, key = '', value = ns.TypeRender(obj), object = obj}
        end
    end
end

local function GenType(t, list, map, out)
    local res = list[t] or {}
    if map[t] then
        for _, v in pairs(map[t]) do
            tinsert(res, v)
        end
    end

    if #res == 0 then
        return
    end

    tinsert(out, {type = 'header', header = t})

    sort(res, compare)

    for _, v in ipairs(res) do
        tinsert(out, v)
    end
end

function Provider:Constructor(target)
    self.target = target
    self:Refresh()
end

function Provider:Refresh()
    self.list = {}
    self.touched = {}
    self.type = ns.GetType(self.target)

    local map = {}
    local list = {}

    local mt = getmetatable(self.target)
    if mt then
        tinsert(self.list, {type = 'header', header = 'metatable'})
        tinsert(self.list, {type = 'table', value = ns.TypeRender(mt), object = mt})
    end

    if self.type == 'uiobject' then
        if self.target.GetNumPoints then
            local n = self.target:GetNumPoints()
            if n and n > 0 then
                tinsert(self.list, {type = 'header', header = 'anchor'})

                for i = 1, n do
                    local point, relative, relativePoint, x, y = self.target:GetPoint(i)
                    local t = ns.GetType(relative)
                    tinsert(self.list,
                            {type = t, value = ns.Render(point, relative, relativePoint, x, y), object = relative})
                end
            end
        end

        if self.target.GetChildren then
            ProcessObjects({self.target:GetChildren()}, map)
        end
        if self.target.GetRegions then
            ProcessObjects({self.target:GetRegions()}, map)
        end
        if self.target.GetAnimationGroups then
            ProcessObjects({self.target:GetAnimationGroups()}, map)
        end
        if self.target.GetAnimations then
            ProcessObjects({self.target:GetAnimations()}, map)
        end
    end

    for k, v in pairs(self.target) do
        local t = ns.GetType(v)
        if t == 'uiobject' then
            local st = ns.GetUIObjectType(v)
            map[st] = map[st] or {}
            if map[st][v] then
                if map[st][v].key == '' then
                    map[st][v].key = ns.KeyRender(k)
                else
                    list[t] = list[t] or {}
                    tinsert(list[t], {type = t, key = ns.KeyRender(k), value = ns.TypeRender(v), object = v})
                end
            else
                local isChild = v.GetParent and v:GetParent() == self.target
                map[st][v] = {type = t, star = not isChild, key = ns.KeyRender(k), value = ns.TypeRender(v), object = v}
            end
        else
            list[t] = list[t] or {}
            tinsert(list[t], {type = t, key = ns.KeyRender(k), value = ns.TypeRender(v), object = v})
        end
    end

    GenType('Frame', list, map, self.list)
    GenType('Region', list, map, self.list)
    GenType('AnimationGroup', list, map, self.list)
    GenType('Animation', list, map, self.list)
    GenType('Font', list, map, self.list)

    GenType('userdata', list, map, self.list)
    GenType('string', list, map, self.list)
    GenType('number', list, map, self.list)
    GenType('boolean', list, map, self.list)
    GenType('table', list, map, self.list)
    GenType('function', list, map, self.list)
    GenType('thread', list, map, self.list)
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
