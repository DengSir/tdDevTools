-- Event.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 2:06:08 PM

local ns    = select(2, ...)
local Event = ns.Frame.Event

function Event:OnLoad()
    self.EventList = self.EventContainer.EventList
    self.EventList.buttonHeight = 24
    self.EventList.buttons = setmetatable({}, {__index = function(t, i)
        print(i)
        local button = CreateFrame('Button', nil, self.EventList:GetScrollChild(), 'tdDevToolsEventItemTemplate')
        if i == 1 then
            button:SetPoint('TOPLEFT')
        else
            button:SetPoint('TOPLEFT', t[i-1], 'BOTTOMLEFT')
        end
        t[i] = button
        return button
    end})

    self.isRunning = false
    self.events = {}
    self.ignores = {}

    self.EventList.update = function() return self:Refresh() end

    self.Updater = CreateFrame('Frame')
    self.Updater:Hide()
    self.Updater:SetScript('OnUpdate', function() return self:OnFrame() end)

    self:OnSizeChanged()
    self:SetScript('OnShow', self.Refresh)
    self:SetScript('OnEvent', self.OnEvent)
    self:SetScript('OnSizeChanged', self.OnSizeChanged)
end

function Event:Start()
    self.isRunning = true
    self.ignores       = {}
    self.lastEventTime = nil
    self.lastFrames    = 0
    self:RegisterAllEvents()
    self.Updater:Show()
end

function Event:Stop()
    self.isRunning = false
    self:UnregisterAllEvents()
    self.Updater:Hide()
end

function Event:Clear()
    wipe(self.events)
    self:Refresh()
end

function Event:Toggle()
    if self.isRunning then
        self.EventContainer.Header.ToggleButton:SetText('Start')
        self:Stop()
    else
        self.EventContainer.Header.ToggleButton:SetText('Stop')
        self:Start()
    end
end

function Event:OnSizeChanged()
    self.EventList:GetScrollChild():SetSize(self:GetSize())
    -- HybridScrollFrame_CreateButtons(self.EventList, 'tdDevToolsEventItemTemplate')
    self:Refresh()
end

function Event:OnFrame()
    self.lastFrames = self.lastFrames + 1
end

function Event:OnEvent(event, ...)
    if self.ignores[event] then
        return
    end

    local currentTime = GetTime()
    local events = self.events

    if self.lastEventTime and currentTime ~= self.lastEventTime then
        events[#events+1] = {
            event  = 'ELAPSED',
            frames = self.lastFrames,
            long   = currentTime - self.lastEventTime,
        }
    end

    events[#events+1] = {
        event     = event,
        time      = currentTime,
        args      = {...},
        argsCount = select('#', ...)
    }

    self.lastEventTime = currentTime
    self.lastFrames = 0
    self:Refresh()
end

function Event:OnItemIgnoreClick(button)
    local info = self.events[button:GetID()]
    if not info then
        return
    end

    local event  = info.event
    local events = {}
    local lastElapsed

    for i, info in ipairs(self.events) do
        if info.event == 'ELAPSED' then
            if lastElapsed then
                lastElapsed.frames = lastElapsed.frames + info.frames
                lastElapsed.long   = lastElapsed.long + info.long
            else
                lastElapsed = info
            end
        else
            if info.event ~= event then
                if lastElapsed then
                    events[#events+1] = lastElapsed
                    lastElapsed = nil
                end

                events[#events+1] = info
            end
        end
    end

    if lastElapsed then
        events[#events+1] = lastElapsed
    end

    self.ignores[event] = true
    self.events = events
    self:Refresh()
end

function Event:OnItemClick(button)
    local info = self.events[button:GetID()]
    inspect(info.args)
end

function Event:FormatTime(time)
    local mseconds = time * 1000 % 1000
    local seconds  = floor(time % 60)
    local minutes  = floor(time / 60 % 60)
    local hours    = floor(time / 3600)
    return format('%d:%02d:%02d.%03d', hours, minutes, seconds, mseconds)
end

function Event:GetEventText(info)
    if info.event == 'ELAPSED' then
        return format('%.03f sec - %d frame(s)', info.long, info.frames), 'ELAPSED'
    else
        return info.event, self:FormatTime(info.time)
    end
end

function Event:Refresh()
    self:SetScript('OnUpdate', self.OnUpdate)
end

function Event:OnUpdate()
    self:SetScript('OnUpdate', nil)
    self:UpdateList()
end

function Event:UpdateList()
    local offset = HybridScrollFrame_GetOffset(self.EventList)
    local buttons = self.EventList.buttons
    local events = self.events
    local containerHeight = self.EventList:GetHeight()
    local buttonHeight = self.EventList.buttonHeight
    local itemCount = #self.events
    local maxCount = ceil(containerHeight / buttonHeight)
    local buttonCount = min(maxCount, itemCount)

    print(containerHeight, buttonHeight, itemCount, maxCount, buttonCount)

    -- if buttonCount <= 0 then
    --     return
    -- end

    for i = 1, buttonCount do
        local button = buttons[i]
        local id     = i + offset
        local info   = events[id]

        if info then
            local right, left = self:GetEventText(info)
            button.owner = self
            button:SetID(id)
            button.Time:SetText(info.time)
            button.Text:SetText(info.text)
            button.Time:SetText(left)
            button.Text:SetText(right)

            if info.event == 'ELAPSED' then
                button.IgnoreButton:Hide()
                button.Time:SetTextColor(GRAY_FONT_COLOR:GetRGB())
                button.Text:SetTextColor(GRAY_FONT_COLOR:GetRGB())
            else
                button.IgnoreButton:Show()
                button.Time:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
                button.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
            end

            button:Show()
            button:SetWidth(self.EventList:GetWidth() - 16)
        else
            button:Hide()
        end
    end

    for i = buttonCount + 1, #buttons do
        buttons[i]:Hide()
    end

    HybridScrollFrame_Update(self.EventList, itemCount * buttonHeight, containerHeight)
end

Event:OnLoad()
