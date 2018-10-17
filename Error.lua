-- Error.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 12:42:22 PM

local ns = select(2, ...)
local Error = ns.Frame.Error

function Error:OnLoad()
    self.items = {} do
        for i = 1, 1000 do
            table.insert(self.items, i)
        end
    end
    self.ErrorList.update = function() return self:UpdateErrorList() end

    self:SetScript('OnShow', self.UpdateErrorList)
    self:SetScript('OnSizeChanged', self.OnSizeChanged)

    print(self.Right.EditBoxScroll.EditBox)

    self:OnSizeChanged()
end

function Error:OnSizeChanged()
    HybridScrollFrame_CreateButtons(self.ErrorList, 'tdDevToolsErrorItemTemplate')
    self.ErrorList:GetScrollChild():SetSize(self:GetSize())
    self:UpdateErrorList()
end

function Error:UpdateErrorList()
    local offset = HybridScrollFrame_GetOffset(self.ErrorList)
    local buttons = self.ErrorList.buttons
    local items = self.items

    for i = 1, #buttons do
        local button = buttons[i]

        button:SetText(items[i + offset])
        button:Show()
        button:SetWidth(self.ErrorList:GetWidth() - 16)
    end

    local totalHeight = #items * 24
    HybridScrollFrame_Update(self.ErrorList, totalHeight, self.ErrorList:GetHeight())
end

Error:OnLoad()
