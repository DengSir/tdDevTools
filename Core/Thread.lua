-- Thread.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/18/2018, 1:35:37 PM

local ns     = select(2, ...)
local Thread = {}
local mt     = {__index = Thread}

ns.Thread = Thread

function Thread:New(func, frame, extend)
    local obj = setmetatable({}, mt)
    obj.co = coroutine.create(func)
    obj.frame = frame
    obj.extend = extend and frame * 10 or frame
    return obj
end

function Thread:Start(...)
    self.endTime = GetTimePreciseSec() + self.extend
    return coroutine.resume(self.co, ...)
end

function Thread:Resume(...)
    self.endTime = GetTimePreciseSec() + self.frame
    return coroutine.resume(self.co, ...)
end

function Thread:Kill()
    self.killed = true
end

function Thread:YieldPoint()
    if GetTimePreciseSec() > self.endTime then
        self.timer = C_Timer.NewTimer(0, function()
            self.timer = nil
            return self:Resume()
        end)
        return self:Yield()
    end
end

local function packResult(...)
    return {
        args = {...},
        argsCount = select('#', ...)
    }
end

local function unpackResult(pack)
    return unpack(pack.args, 1, pack.argsCount)
end

function Thread:Yield()
    local pack = packResult(coroutine.yield())
    if self.killed then
        if self.timer then
            self.timer:Cancel()
        end
        error('killed')
    end
    return unpackResult(pack)
end
