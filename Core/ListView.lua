-- ListView.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 8:19:47 PM

local ns = select(2, ...)

local function update(self)
    local offset          = HybridScrollFrame_GetOffset(self)
    local buttons         = self.buttons
    local itemList        = self.itemList or {}
    local containerHeight = self:GetHeight()
    local buttonHeight    = self.buttonHeight or buttons[1]:GetHeight()
    local itemCount       = itemList.count or #itemList
    local maxCount        = ceil(containerHeight / buttonHeight)
    local buttonCount     = min(maxCount, itemCount)

    for i = 1, buttonCount do
        local index  = i + offset
        local button = buttons[i]
        if index > itemCount then
            button:Hide()
        else
            local item   = itemList[index]
            button.item = item
            button.scrollFrame = self
            button:SetID(index)
            button:Show()
            self.OnItemFormatting(button, item)
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end
    HybridScrollFrame_Update(self, itemCount * buttonHeight, containerHeight)
end

local function SetItemList(self, itemList)
    self.itemList = itemList
    self:Refresh()
end

local function JumpToItem(self, item)
    local index = tIndexOf(self.itemList, item)
    if index then
        local buttonHeight = self.buttonHeight or self.buttons[1]:GetHeight()
        local maxCount     = ceil(self:GetHeight() / buttonHeight)
        local height       = math.max(0, math.floor(buttonHeight * (index - maxCount/2)))
        HybridScrollFrame_SetOffset(self, height)
        self.scrollBar:SetValue(height)
    end
end

function ns.ListViewSetup(scrollFrame, opts)
    scrollFrame.update      = update
    scrollFrame.SetItemList = SetItemList
    scrollFrame.JumpToItem  = JumpToItem

    scrollFrame.itemList         = opts.itemList
    scrollFrame.OnItemFormatting = opts.OnItemFormatting
    return ns.ScrollFrameSetup(scrollFrame, opts)
end
