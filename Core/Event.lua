-- Event.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2018, 2:06:08 PM

local ns    = select(2, ...)
local Event = ns.Frame.Event

function Event:OnLoad()
    self.isRunning = false
    self.events    = {}
    self.ignores   = {}
    self.EventList = self.EventContainer.EventList

    ns.ListViewSetup(self.EventList, {
        itemList         = self.events,
        buttonTemplate   = 'tdDevToolsEventItemTemplate',
        OnItemFormatting = function(button, item)
            return self:OnEventItemFormatting(button, item)
        end
    })

    self.Updater = CreateFrame('Frame')
    self.Updater:Hide()
    self.Updater:SetScript('OnUpdate', function() return self:OnFrame() end)

    self:SetScript('OnShow', self.Refresh)
    self:SetScript('OnEvent', self.OnEvent)
end

function Event:Start()
    self.isRunning     = true
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
        self.EventContainer.ToggleButton:SetText('Start')
        self:Stop()
    else
        self.EventContainer.ToggleButton:SetText('Stop')
        self:Start()
    end
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

function Event:OnEventItemFormatting(button, info)
    local right, left = self:GetEventText(info)
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
end

function Event:OnEventItemIgnoreClick(button)
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

function Event:OnEventItemClick(button)
    local info = self.events[button:GetID()]
    if info.args then
        inspect(info.args)
    end
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
    return self.EventList:Refresh(self.events)
end

Event:OnLoad()
