-- LibLog-1.0.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/18/2018, 9:12:24 PM

local MAJOR,MINOR = "LibLog-1.0", 1
local Log, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not Log then return end

function Log:Debug(...)
end

function Log:Info(...)
end

function Log:Warn(...)
end

function Log:Error(...)
end
