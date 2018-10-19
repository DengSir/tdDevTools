-- ListView.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 8:19:47 PM

local ns = select(2, ...)

local function OnUpdate(self)
    self:SetScript('OnUpdate', nil)
    self:update()
end

local function OnSizeChanged(self, width, height)
    self:GetScrollChild():SetSize(width - 16, height)
    self:Refresh()
end

local function update(self)
    local offset          = HybridScrollFrame_GetOffset(self)
    local buttons         = self.buttons
    local itemList        = self.itemList
    local containerHeight = self:GetHeight()
    local buttonHeight    = self.buttonHeight
    local itemCount       = #itemList
    local maxCount        = ceil(containerHeight / buttonHeight)
    local buttonCount     = min(maxCount, itemCount)

    for i = 1, buttonCount do
        local index  = i + offset
        local button = buttons[i]
        local item   = itemList[index]

        if item then
            button.scrollFrame = self
            button:SetID(index)
            button:Show()
            self.itemFormatting(button, item)
        else
            button:Hide()
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end
    HybridScrollFrame_Update(self, itemCount * buttonHeight, containerHeight)
end

local function Refresh(self, itemList)
    if itemList then
        self.itemList = itemList
    end
    return self:SetScript('OnUpdate', OnUpdate)
end

function ns.ListViewSetup(scrollFrame, opts)
    local buttonTemplate = opts.buttonTemplate

    scrollFrame.buttons = setmetatable({}, {__index = function(t, i)
        local button = CreateFrame('Button', nil, scrollFrame:GetScrollChild(), buttonTemplate)
        t[i] = button
        if i == 1 then
            button:SetPoint('TOPLEFT')
            button:SetPoint('TOPRIGHT')
        else
            button:SetPoint('TOPLEFT', t[i - 1], 'BOTTOMLEFT')
            button:SetPoint('TOPRIGHT', t[i - 1], 'BOTTOMRIGHT')
        end
        return button
    end})

    scrollFrame.itemList       = opts.itemList
    scrollFrame.itemFormatting = opts.OnItemFormatting
    scrollFrame.buttonHeight   = scrollFrame.buttons[1]:GetHeight()
    scrollFrame:SetScript('OnSizeChanged', OnSizeChanged)

    scrollFrame.update      = update
    scrollFrame.Refresh     = Refresh
end
