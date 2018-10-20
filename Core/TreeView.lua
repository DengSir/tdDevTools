-- TreeView.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/20/2018, 4:28:53 PM

local ns = select(2, ...) or {}

local TreeStatus = {}

function TreeStatus:New(itemTree, depth)
    local obj = {}
    obj.itemTree = itemTree
    obj.depth = depth
    obj.extends = setmetatable({}, {__mode = 'k'})
    return setmetatable(obj, {__index = TreeStatus})
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

local function update(self)
    local offset          = HybridScrollFrame_GetOffset(self)
    local buttons         = self.buttons
    local treeStatus      = self.treeStatus
    local containerHeight = self:GetHeight()
    local buttonHeight    = self.buttonHeight or buttons[1]:GetHeight()
    local itemCount       = treeStatus:GetCount()
    local maxCount        = ceil(containerHeight / buttonHeight)
    local buttonCount     = min(maxCount, itemCount)

    local iter = treeStatus:Iterate(offset + 1)

    for i = 1, buttonCount do
        local index  = i + offset
        local button = buttons[i]
        if index > itemCount then
            button:Hide()
        else
            local depth, item = iter()

            button.depth       = depth
            button.item        = item
            button.scrollFrame = self
            button:SetID(index)
            button:Show()
            self.OnItemFormatting[depth](button, item)
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end
    HybridScrollFrame_Update(self, itemCount * buttonHeight, containerHeight)
end

local function ToggleItem(self, item)
    self.treeStatus.extends[item] = not self.treeStatus.extends[item] or nil
    self:Refresh()
end

local function IsItemExpend(self, item)
    return self.treeStatus.extends[item]
end

function ns.TreeViewSetup(scrollFrame, opts)
    scrollFrame.treeStatus       = TreeStatus:New(opts.itemTree, opts.depth)
    scrollFrame.update           = update
    scrollFrame.SetItemTree      = SetItemTree
    scrollFrame.ToggleItem       = ToggleItem
    scrollFrame.IsItemExpend     = IsItemExpend
    scrollFrame.OnItemFormatting = opts.OnItemFormatting

    return ns.ScrollFrameSetup(scrollFrame, opts)
end

local itemTree = {
    {
        {
            {
                1, 2, 3, 4
            }
        }
    },
    {
    }
}

s = TreeStatus:New(itemTree, 5)
s.extends[itemTree[1]] = true
s.extends[itemTree[1][1]] = true
s.extends[itemTree[1][1][1]] = true

print(s:GetCount())

for d, i in s:Iterate(2) do
    print(d, i)
end
