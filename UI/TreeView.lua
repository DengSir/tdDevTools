-- TreeView.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/20/2018, 4:28:53 PM
--
---@type ns
local ns = select(2, ...)

local ipairs, type, setmetatable = ipairs, type, setmetatable
local coroutine = coroutine
local ceil, min, max = ceil, min, max

local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update

---@class TreeStatus: Object
local TreeStatus = ns.class()

function TreeStatus:Constructor(itemTree, depth)
    self.itemTree = itemTree
    self.depth = depth
    self.extends = setmetatable({}, {__mode = 'k'})
end

function TreeStatus:Iterate(start)
    local index = 0

    local function Iterate(tree, depth)
        if depth > self.depth then
            return
        end
        for _, child in ipairs(tree) do
            index = index + 1
            if not start or index >= start then
                coroutine.yield(depth, child)
            end
            if type(child) == 'table' and self.extends[child] then
                Iterate(child, depth + 1)
            end
        end
    end

    return coroutine.wrap(function()
        return Iterate(self.itemTree, 1)
    end)
end

function TreeStatus:GetCount()
    local function GetCount(tree, depth)
        if self.depth == depth then
            return #tree
        end

        local count = 0
        for i, child in ipairs(tree) do
            count = count + 1
            if type(child) == 'table' and self.extends[child] then
                count = count + GetCount(child, depth + 1)
            end
        end
        return count
    end
    return GetCount(self.itemTree, 1)
end

---@class TreeView: ScrollFrame
local TreeView = ns.class(ns.ScrollFrame)
ns.TreeView = TreeView

function TreeView:Constructor(_, opts)
    self.treeStatus = TreeStatus:New(opts.itemTree, opts.depth)
    self.OnItemFormatting = opts.OnItemFormatting
end

function TreeView:update()
    local offset = HybridScrollFrame_GetOffset(self)
    local buttons = self.buttons
    local treeStatus = self.treeStatus
    local containerHeight = self:GetHeight()
    local buttonHeight = self.buttonHeight or buttons[1]:GetHeight()
    local itemCount = treeStatus:GetCount()
    local maxCount = ceil(containerHeight / buttonHeight)
    local buttonCount = min(maxCount, itemCount)

    local iter = treeStatus:Iterate(offset + 1)

    for i = 1, buttonCount do
        local index = i + offset
        local button = buttons[i]
        if index > itemCount then
            button:Hide()
        else
            local depth, item = iter()

            button.depth = depth
            button.item = item
            button.scrollFrame = self
            button:SetID(index)
            button:Show()
            self.OnItemFormatting[depth](button, item)
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end
    HybridScrollFrame_Update(self, max(1, itemCount * buttonHeight), containerHeight)
end

function TreeView:ToggleItem(item)
    self.treeStatus.extends[item] = not self.treeStatus.extends[item] or nil
    self:Refresh()
end

function TreeView:IsItemExpend(item)
    return self.treeStatus.extends[item]
end
