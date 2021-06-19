-- Inspect.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 6/18/2021, 11:41:24 PM
--
---@type ns
local ns = select(2, ...)

local next = next
local random = fastrandom or math.random
local tremove, tinsert, wipe = table.remove, table.insert, table.wipe

local CreateFrame = CreateFrame

---@class Inspect: Object, Frame, tdDevToolsInspectTemplate
---@field current Provider
---@field default Inspect
local Inspect = ns.class('Frame')
ns.Inspect = Inspect

Inspect.pool = {}

function Inspect:Constructor()
    ns.ListView:Bind(self.Fields, {
        buttonTemplate = 'tdDevToolsInspectItemTemplate',
        OnItemFormatting = function(button, item)
            return self:OnFieldItemFormatting(button, item)
        end,
    })

    self.back = {}
    self.forward = {}

    self:SetScript('OnHide', self.OnHide)
end

function Inspect:OnHide()
    self:Hide()
    wipe(self.back)
    wipe(self.forward)
    self.current = nil
    if not self.noRelease then
        self.pool[self] = true
    end
end

function Inspect:OnFieldItemFormatting(button, item)
    button.Key:SetText('')
    button.Value:SetText('')
    button.Header:SetText('')
    button.HeaderBackground:SetShown(item.type == 'header')
    button.Star:SetShown(item.star)

    if item.header then
        button.Header:SetText(item.header:upper())
    end
    if item.value then
        button.Value:SetText(item.value)
    end
    if item.key then
        button.Key:SetText(item.key == '' and '|cff808080n/a|r' or item.key)
        button.Value:SetPoint('LEFT', button.Key, 'RIGHT', 5, 0)
    else
        button.Value:SetPoint('LEFT', button.Key, 'LEFT')
    end
end

function Inspect:SetProvider(obj)
    if self.current then
        tinsert(self.back, self.current)
        wipe(self.forward)
    end
    self.current = obj
    self.Fields:SetItemList(self.current.list)
    self.Fields:SetOffset(0)
    self:Refresh()
end

function Inspect:GoParent()
    local parent = self.current:GetParent()
    if parent then
        self:SetProvider(ns.Provider:New(parent))
    end
end

function Inspect:GoBack()
    if #self.back == 0 then
        return
    end

    tinsert(self.forward, 1, self.current)
    self.current = nil
    self:SetProvider(tremove(self.back, #self.back))
end

function Inspect:GoForward()
    if #self.forward == 0 then
        return
    end

    tinsert(self.back, self.current)
    self.current = nil
    self:SetProvider(tremove(self.forward, 1))
end

function Inspect:Duplicate()
    local ins = Inspect:InspectTable(self.current.target)
    if ins then
        ins:ClearAllPoints()
        ins:SetPoint('BOTTOMLEFT', self:GetLeft() + 30, self:GetBottom() + 30)
        ins:SetSize(self:GetSize())
        ins:Raise()
    end
end

function Inspect:Refresh()
    self.Header.Parent:SetEnabled(self.current:GetParent())
    self.Header.Back:SetEnabled(#self.back > 0)
    self.Header.Forward:SetEnabled(#self.forward > 0)
    self.Header.Title:SetText(self.current:GetTitle())

    local isRenderable = self.current:IsReaderable()
    if isRenderable then
        self.Controls.Visible:Enable()
        self.Controls.Visible:SetChecked(self.current.target:IsShown())

        self.Controls.Highlight:Enable()
        self.Controls.Highlight:SetChecked(self.highlight)
    else
        self.Controls.Visible:Disable()
        self.Controls.Visible:SetChecked(false)

        self.Controls.Highlight:Disable()
        self.Controls.Highlight:SetChecked(false)
    end

    if isRenderable and self.highlight then
        self.FrameHighlight = self.FrameHighlight or self:CreateHighlightFrame()
        self.FrameHighlight:Show()
        self.FrameHighlight:HighlightFrame(self.current.target)
    elseif self.FrameHighlight then
        self.FrameHighlight:Hide()
    end

    if self.dynamicUpdate then
        self:SetScript('OnUpdate', self.OnUpdate)
    else
        self:SetScript('OnUpdate', nil)
    end
end

function Inspect:OnUpdate()
    self.current:Refresh()
    self.Fields:SetItemList(self.current.list)
end

function Inspect:OnItemClick(item)
    if item.type == 'uiobject' or item.type == 'table' then
        if IsControlKeyDown() then
            Inspect:InspectTable(item.object)
        else
            self:SetProvider(ns.Provider:New(item.object))
        end
    end
end

function Inspect:OnHighlightClick()
    self.highlight = self.Controls.Highlight:GetChecked()
    self:Refresh()
end

function Inspect:OnVisibleClick()
    self.current.target:SetShown(self.Controls.Visible:GetChecked())
    self:Refresh()
end

function Inspect:OnDynamicUpdatesClick()
    self.dynamicUpdate = self.Controls.DynamicUpdates:GetChecked()
    self:Refresh()
end

function Inspect:CreateHighlightFrame()
    ns.CheckBlizzardDebugTools()
    return CreateFrame('Frame', nil, self, 'FrameHighlightTemplate')
end

---- static

function Inspect:Create()
    return self:Bind(CreateFrame('Frame', nil, ns.Frame, 'tdDevToolsInspectTemplate'))
end

function Inspect:Acquire()
    local obj = next(self.pool)
    if obj then
        self.pool[obj] = nil
    else
        obj = Inspect:Create()
    end
    return obj
end

function Inspect:Default()
    if not self.default then
        self.default = self:Acquire()
        self.default.noRelease = true
    end
    return self.default
end

function Inspect:InspectTable(obj, default)
    local t = ns.GetType(obj)
    if t ~= 'table' and t ~= 'uiobject' then
        return
    end

    local ins = default and Inspect:Default() or Inspect:Acquire()
    if not ins:IsShown() then
        ins:ClearAllPoints()
        ins:SetPoint('BOTTOMLEFT', 64 + random(64), 64 + random(64))
        ins:SetSize(300, 250)
    end
    ins:Show()
    ins:SetProvider(ns.Provider:New(obj))
    return ins
end
