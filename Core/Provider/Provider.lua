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

function Provider:ProcessData()
    self.items = ns.Builder:New(self.target, self.processThread):Process()
    self.list = self.items
    self:Fire('OnRefresh')
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
