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
    MessageFrame:SetFontObject('tdDevToolsConsoleFont')
    MessageFrame:SetIndentedWordWrap(true)
    MessageFrame:SetJustifyH('LEFT')
    MessageFrame:SetFading(false)
    MessageFrame:SetHyperlinksEnabled(true)
    MessageFrame:SetScript('OnHyperlinkClick', function(_, link)
        TypeRender.ClickValue(link)
    end)
    MessageFrame:SetOnDisplayRefreshedCallback(function(self)
        local maxValue = self:GetMaxScrollRange()
        local atBottom = self:AtBottom()
        self.scrollBar:SetMinMaxValues(0, maxValue)
        if atBottom then
            self.scrollBar:SetValue(maxValue)
        end
    end)

    self.MessageFrame.scrollBar:SetScript('OnValueChanged', function(self, value)
        local minValue, maxValue = self:GetMinMaxValues()
        local value = floor(value + 0.5)
        self:GetParent():SetScrollOffset(maxValue - value)
        HybridScrollFrame_UpdateButtonStates(self:GetParent(), value)
    end)

    self.MessageFrame.scrollUp:SetScript('OnClick', function(_, _, down)
        if down then
            self.MessageFrame:ScrollUp()
            PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
        end
    end)

    self.MessageFrame.scrollDown:SetScript('OnClick', function(_, _, down)
        if down then
            self.MessageFrame:ScrollDown()
            PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
        end
    end)
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

Console:OnLoad()
