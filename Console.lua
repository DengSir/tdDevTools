-- Console.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:57 PM

local ns         = select(2, ...)
local Util       = ns.Util
local TypeRender = ns.TypeRender
local Console    = ns.Frame.Console

ns.Console = Console

function Console:OnLoad()
    local MessageFrame = self.MessageFrame
    MessageFrame:SetMaxLines(9000)
    MessageFrame:SetFontObject(ConsoleFontNormal)
    MessageFrame:SetIndentedWordWrap(true)
    MessageFrame:SetJustifyH('LEFT')
    MessageFrame:SetFading(false)
    MessageFrame:SetHyperlinksEnabled(true)
    MessageFrame:SetScript('OnHyperlinkClick', function(_, link)
        TypeRender.ClickValue(link)
    end)
    MessageFrame:SetOnDisplayRefreshedCallback(function()
        local maxValue = self.MessageFrame:GetMaxScrollRange()
        local atBottom = self.MessageFrame:AtBottom()
        self.ScrollBar:SetMinMaxValues(0, maxValue)
        if atBottom then
            self.ScrollBar:SetValue(maxValue)
        end
    end)

    self.ScrollBar:SetScript('OnValueChanged', function(ScrollBar, value)
        local minValue, maxValue = ScrollBar:GetMinMaxValues()
        local value = floor(value + 0.5)
        MessageFrame:SetScrollOffset(maxValue - value)
    end)


    tinsert(UISpecialFrames, self:GetName())

    self:SetScript('OnMouseWheel', self.OnMouseWheel)
    -- self:SetScript('OnMouseDown', self.OnMouseDown)
    -- self:SetScript('OnMouseUp', self.StopMovingOrSizing)

    -- UIParent:HookScript('OnSizeChanged', function()
    --     self:ClearAllPoints()
    --     self:SetPoint('TOPLEFT')
    --     self:SetPoint('TOPRIGHT')
    -- end)
end

function Console:OnMouseWheel(delta)
    if IsControlKeyDown() then

    else
        self.ScrollBar:SetValue(self.ScrollBar:GetValue() - delta)
    end
end

function Console:OnMouseDown()
    local position, value = Util.GetMousePosition(self)
    if value >= 8 then
        self:StartSizing(position)
    end
end

function Console:Print(text, r, g, b)
    self.MessageFrame:AddMessage(text, r or 1, g or 1, b or 1)
end

function Console:RenderAll(...)
    local sb = {}
    for i = 1, select('#', ...) do
        table.insert(sb, TypeRender((select(i, ...))))
    end
    return unpack(sb)
end

function Console:Toggle()
    self:SetShown(not self:IsShown())
end

Console:OnLoad()
