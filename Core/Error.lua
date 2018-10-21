-- Error.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 12:42:22 PM

local ns      = select(2, ...)
local Error   = ns.Frame.Error
local Console = ns.Frame.Console

local FindPath    = ns.Util.FindPath
local ShortPath   = ns.Util.ShortPath
local ColoredPath = ns.Util.ColoredPath

function Error:OnLoad()
    self.index   = 0
    self.EditBox = self.RightSide.EditBoxScroll.EditBox
    self.Tab     = ns.Frame.Tab2
    self.errors = {}

    ns.ListViewSetup(self.ErrorList, {
        itemList         = self.errors,
        buttonTemplate   = 'tdDevToolsErrorItemTemplate',
        OnItemFormatting = function(button, item)
            return self:OnItemFormatting(button, item)
        end
    })

    local old = geterrorhandler()
    seterrorhandler(function(err) old(err) return self:AddError(err) end)

    self:SetScript('OnShow', self.Refresh)
    self:SetScript('OnEvent', self.OnEvent)

    self:RegisterEvent('ADDON_ACTION_BLOCKED')
    self:RegisterEvent('ADDON_ACTION_FORBIDDEN')
    self:RegisterEvent('MACRO_ACTION_BLOCKED')
    self:RegisterEvent('MACRO_ACTION_FORBIDDEN')
end

function Error:ADDON_ACTION_BLOCKED(event, addon, port)
    self:AddError(format('%s blocked from using %s', addon, port))
end

function Error:ADDON_ACTION_FORBIDDEN(event, addon, port)
    self:AddError(format('%s forbidden from using %s (Only usable by Blizzard)', addon, port))
end

function Error:MACRO_ACTION_BLOCKED(event, port)
    self:AddError(format('Macro blocked from using %s', port))
end

function Error:MACRO_ACTION_FORBIDDEN(event, port)
    self:AddError(format('Macro forbidden from using %s (Only usable by Blizzard)', port))
end

function Error:OnEvent(event, ...)
    self[event](self, event, ...)
end

function Error:OnItemClick(button)
    local id   = button:GetID()
    local info = self.errors[id]
    if not info then
        return
    end

    self.selectedErr = info
    self:Refresh()
end

function Error:OnItemDeleteClick(button)
    local id = button:GetID()
    table.remove(self.errors, id)
    self:Refresh()
    self:UpdateCount()
end

function Error:OnItemFormatting(button, info)
    button.Count:SetFormattedText('(%d)', info.count)
    button.Text:SetText(info.full)
    button.Selected:SetShown(self.selectedErr and info.err == self.selectedErr.err)
end

function Error:Refresh()
    self:UpdateList()
    self:UpdateError()
end

function Error:UpdateList()
    self.ErrorList:Refresh()
end

local MESSAGE_FORMAT = [[
|cff00ffffMessage:|r %s
|cff00ffffTime:|r %s
|cff00ffffCount:|r %d
|cff00ffffStack:|r %s
]]

function Error:UpdateError()
    if not tIndexOf(self.errors, self.selectedErr) then
        self.selectedErr = nil
    end

    self.EditBox:SetText(not self.selectedErr and '' or MESSAGE_FORMAT:format(
        self.selectedErr.err,
        date('%Y:%m:%d %H:%M:%S', self.selectedErr.time),
        self.selectedErr.count,
        self.selectedErr.stack
    ))
end

function Error:UpdateCount()
    local count = #self.errors
    self.Tab:SetText(count == 0 and 'Errors' or format('Errors |cffff0000(%d)|r', #self.errors))
end

function Error:AddError(err)
    local info = self:TakeError(err) or self:ParseErr(err)

    info.count = info.count + 1
    info.time  = time()

    table.insert(self.errors, 1, info)
    self:Refresh()
    self:UpdateCount()

    Console:RawLog('ERROR', info.path, format('|Herror:%d|h%s|h ', info.index, info.formatted))
end

function Error:ParseErr(err)
    local formatted
    local stack
    local full

    local path = FindPath(err)
    if not path then
        stack     = debugstack(4)
        path      = FindPath(stack)
        formatted = err
        full      = path .. ': ' .. err
    else
        formatted = ShortPath(err):sub(#path+3)
        stack     = debugstack(5)
        full      = err
    end

    self.index = self.index + 1

    return {
        err       = err,
        formatted = formatted,
        full      = full,
        count     = 0,
        path      = ColoredPath(path),
        stack     = stack,
        index     = self.index
    }
end

function Error:TakeError(err)
    for i, v in ipairs(self.errors) do
        if v.err == err then
            return tremove(self.errors, i)
        end
    end
end

function Error:FindErr(index)
    for _, info in ipairs(self.errors) do
        if info.index == index then
            return info
        end
    end
end

function Error:SelectErr(index)
    local info = self:FindErr(index)
    if not info then
        return
    end
    self.selectedErr = info
    self:Refresh()
end

function Error:Clear()
    wipe(self.errors)
    self:Refresh()
    self:UpdateCount()
end

Error:OnLoad()
