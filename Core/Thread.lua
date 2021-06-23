-- Thread.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/18/2018, 1:35:37 PM
--
---@type ns
local ns = select(2, ...)

local coroutine = coroutine
local profilestart, profilestop
do
    local tick = 0
    function profilestart()
        tick = debugprofilestop()
    end

    function profilestop()
        local t = debugprofilestop()
        return t - tick
    end
end

---@class Thread: Object
---@field co thread
local Thread = ns.class()
ns.Thread = Thread

local KILLED = newproxy()

local updater = CreateFrame('Frame')
updater:Hide()
updater:SetScript('OnUpdate', function(self)
    local thread = tremove(self, 1)
    if thread then
        thread:Resume()
    end
end)

function Thread:Start(func, ...)
    self.co = coroutine.create(func)
    profilestart()
    local ok, err = coroutine.resume(self.co, ...)
    if not ok then
        print(err)
    end
end

function Thread:Kill()
    local co = self.co
    self.co = nil
    coroutine.resume(co, KILLED)
end

function Thread:Pending()
    tinsert(updater, self)
    updater:Show()
end

function Thread:YieldPoint()
    if not self.co or self.co ~= coroutine.running() then
        error(KILLED)
    end

    if profilestop() > 16 then
        profilestart()

        self:Pending()

        local killed = coroutine.yield()
        if killed == KILLED then
            error(KILLED)
        end
    end
end

function Thread:Resume()
    if not self.co then
        return
    end
    local ok, err = coroutine.resume(self.co)
    if not ok then
        print(err)
    end
end

function Thread:IsFinished()
    return self.co and coroutine.status(self.co) == 'dead'
end

function Thread:IsDead()
    return not self.co
end
