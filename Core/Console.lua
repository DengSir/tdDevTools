-- Console.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:57 PM
--
---@type ns
local ns = select(2, ...)

local assert, ipairs = assert, ipairs
local format = string.format
local floor = math.floor
local tinsert, unpack, wipe = table.insert, table.unpack or unpack, table.wipe or wipe

local PlaySound = PlaySound

local Console = ns.Frame.Console
local Thread = ns.Thread

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
    MessageFrame:SetOnDisplayRefreshedCallback(function(self)
        local maxValue = self:GetMaxScrollRange()
        local atBottom = self:AtBottom()
        self.scrollBar:SetMinMaxValues(0, maxValue)
        if atBottom then
            self.scrollBar:SetValue(maxValue)
        end
    end)
    MessageFrame:RegisterEvent('ADDON_LOADED')
    MessageFrame:SetScript('OnEvent', function(_, ev, addon)
        if ev ~= 'ADDON_LOADED' or addon ~= 'Blizzard_APIDocumentation' then
            return
        end

        function APIDocumentation.WriteLine(obj, msg)
            local info = ChatTypeInfo['SYSTEM']
            self:AddMessage(msg, info.r, info.g, info.b)
        end
        MessageFrame:UnregisterEvent('ADDON_LOADED')
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
            PlaySound(1115) -- SOUNDKIT.U_CHAT_SCROLL_BUTTON
        end
    end)

    self.MessageFrame.scrollDown:SetScript('OnClick', function(_, _, down)
        if down then
            self.MessageFrame:ScrollDown()
            PlaySound(1115) -- SOUNDKIT.U_CHAT_SCROLL_BUTTON
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

    for i, v in ipairs(self.waitingMessages) do
        self.MessageFrame:AddMessage(v.text, v.r, v.g, v.b)
    end
    wipe(self.waitingMessages)

    ProgressBar.FadeAnim:Play(true)
    self.filteringThread = nil
end

function Console:AddMessage(text, r, g, b)
    local message = {
        text = text,
        match = text:lower():gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''),
        r = r,
        g = g,
        b = b,
    }
    tinsert(self.savedMessages, message)

    if self:MatchLog(message.match) then
        if self.filteringThread then
            tinsert(self.waitingMessages, message)
        else
            self.MessageFrame:AddMessage(text, r, g, b)
        end
    end
end

local levelColors = {DEBUG = {1, 1, 1}, INFO = {1, 1, 1}, WARN = {1, .5, 0}, ERROR = {1, 0, 0}}

function Console:RawLog(level, path, text)
    return self:AddMessage(format('%s %s %s|cffffffff:|r %s', level, ns.GetColoredTime(), path, text),
                           unpack(assert(levelColors[level])))
end

function Console:Log(level, depth, ...)
    return self:RawLog(level, ns.GetCallColoredPath(depth + 1), ns.Render(...))
end

function Console:MatchLog(text)
    if self.filterText == '' then
        return true
    end
    return text:lower():find(self.filterText, nil, true)
end

function Console:Clear()
    if self.filteringThread then
        self.filteringThread:Kill()
    end
    self.MessageFrame:Clear()
    wipe(self.savedMessages)
    wipe(self.waitingMessages)
end

Console:OnLoad()
