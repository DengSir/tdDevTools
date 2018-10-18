-- Console.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:57 PM

local ns         = select(2, ...)
local Util       = ns.Util
local TypeRender = ns.TypeRender
local Console    = ns.Frame.Console
local Thread     = ns.Thread

function Console:OnLoad()
    self.filterText = ''
    self.savedMessages = {}
    self.waitingMessages = {}

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

function Console:OnFilterBoxTextChanged(text)
    if self.filterText == text then
        return
    end
    self.filterText = text:lower()
    self.MessageFrame:Clear()

    if self.filteringThread then
        self.filteringThread:Kill()
    end

    self.filteringThread = Thread:New(function()
        return self:FilteringProcess()
    end, 0.0015, true)
    self.filteringThread:Start()
end

function Console:FilteringProcess()
    local numMessages = #self.savedMessages
    local ProgressBar = self.Header.Filter.ProgressBar

    wipe(self.waitingMessages)
    ProgressBar:SetMinMaxSmoothedValue(0, numMessages)
    ProgressBar:ResetSmoothedValue(0)

    if ProgressBar:GetAlpha() == 0 and not ProgressBar.FadeAnim:IsPlaying() then
        ProgressBar.FadeAnim:Play()
    end

    for i = 1, numMessages do
        local v = self.savedMessages[i]
        self.filteringThread:YieldPoint()

        if self:MatchLog(v.match) then
            self.MessageFrame:AddMessage(v.text, v.r, v.g, v.b)
        end
        ProgressBar:SetSmoothedValue(numMessages - i + 1)
    end

    ProgressBar.FadeAnim:Play(true)

    for i, v in ipairs(self.waitingMessages) do
        self.MessageFrame:AddMessage(v.text, v.r, v.g, v.b)
    end
    wipe(self.waitingMessages)
end

function Console:Print(text, r, g, b)
    local message = {
        text = text,
        match = text:lower():gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''),
        r = r, g = g, b = b
    }
    table.insert(self.savedMessages, message)

    if self:MatchLog(message.match) then
        if self.filteringThread then
            table.insert(self.waitingMessages, message)
        else
            self.MessageFrame:AddMessage(text, r, g, b)
        end
    end
end

function Console:MatchLog(text)
    if self.filterText == '' then
        return true
    end
    return text:find(self.filterText, nil, true)
end

function Console:RenderAll(...)
    local sb = {}
    for i = 1, select('#', ...) do
        table.insert(sb, TypeRender((select(i, ...))))
    end
    return unpack(sb)
end

Console:OnLoad()
