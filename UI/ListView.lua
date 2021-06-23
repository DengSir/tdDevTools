-- ListView.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 8:19:47 PM
--
---@type ns
local ns = select(2, ...)

---@class ListView: _ScrollFrame
---@field itemList any[]
local ListView = ns.class(ns.ScrollFrame)
ns.ListView = ListView

function ListView:Constructor(_, opts)
    self.itemList = opts.itemList

    local OnItemFormatting = opts.OnItemFormatting
    if OnItemFormatting then
        self:SetCallback('OnItemFormatting', function(_, ...)
            return OnItemFormatting(...)
        end)
    end
end

function ListView:update()
    if not self.itemList then
        return
    end

    local offset = HybridScrollFrame_GetOffset(self)
    local buttons = self.buttons
    local itemList = self.itemList
    local containerHeight = self:GetHeight()
    local buttonHeight = self.buttonHeight or buttons[1]:GetHeight()
    local itemCount = itemList.count or #itemList
    local maxCount = ceil(containerHeight / buttonHeight)
    local buttonCount = min(maxCount, itemCount)

    for i = 1, buttonCount do
        local index = i + offset
        local button = buttons[i]
        button:Hide()
        if index > itemCount then
        else
            local item = itemList[index]
            button.item = item
            button.scrollFrame = self
            button:SetID(index)
            button:Show()
            self:Fire('OnItemFormatting', button, item)
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end
    HybridScrollFrame_Update(self, itemCount * buttonHeight, containerHeight)
end

function ListView:SetItemList(itemList)
    self.itemList = itemList
    self:Refresh()
end

function ListView:JumpToItem(item)
    local index = tIndexOf(self.itemList, item)
    if index then
        local buttonHeight = self.buttonHeight or self.buttons[1]:GetHeight()
        local maxCount = ceil(self:GetHeight() / buttonHeight)
        local height = math.max(0, math.floor(buttonHeight * (index - maxCount / 2)))

        self:SetOffset(height)
    end
end
