-- TypeRender.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 4:39:54 PM
--
---@type ns
local ns = select(2, ...)

local tostring = tostring
local format = string.format

local TypeRender = setmetatable({}, {
    __index = function(t)
        return t.other
    end,
    __call = function(self, value)
        local t = ns.GetType(value)
        return self[t](value)
    end,
})

local widgets = setmetatable({}, {__mode = 'v'})
local tables = setmetatable({}, {__mode = 'v'})

ns.TypeRender = TypeRender

function ns.stringify(value)
    local t = ns.GetType(value)
    local name
    if t == 'uiobject' then
        if value.GetDebugName then
            name = value:GetDebugName()
        elseif value.GetName then
            name = value:GetName()
        end
    elseif t == 'table' then
        name = tostring(value)
    end
    return name or tostring(value) or ''
end

local function colorFactory(r, g, b, formatter)
    local formatter = formatter or ns.stringify
    local template = format('|cff%02x%02x%02x', r * 255, g * 255, b * 255) .. '%s|r'
    return function(value)
        return format(template, formatter(value))
    end
end

TypeRender['nil'] = colorFactory(0.5, 0.5, 0.5)
TypeRender['function'] = colorFactory(0, 0.5, 1)

TypeRender.other = colorFactory(1, 1, 1)
TypeRender.string = colorFactory(1, 1, 0, function(value)
    return format('%q', value)
end)
TypeRender.number = colorFactory(0, 1, 0.5)
TypeRender.boolean = colorFactory(1, 0, 0)
TypeRender.userdata = colorFactory(1, 1, 0.5)
TypeRender.thread = colorFactory(1, 0.5, 1)

TypeRender.table = function(tbl)
    local name = tostring(tbl)
    tables[name] = tbl
    return format('|Htable:%s|h|cff00ffff[%s]|r|h', name, name)
end

TypeRender.uiobject = function(obj)
    local name = ns.stringify(obj)
    widgets[name] = obj
    return format('|Huiobject:%s|h|cff00ff00[%s]|r|h', name, name)
end

TypeRender.ClickValue = function(link)
    if not link then
        return
    end
    local linkType, linkContent = link:match('^([^:]+):(.+)$')
    if not linkType then
        return
    end

    if linkType == 'uiobject' then
        local widget = widgets[linkContent]
        if widget then
            inspect(widget)
        end
    elseif linkType == 'table' then
        local tbl = tables[linkContent]
        if tbl then
            inspect(tbl)
        end
    elseif linkType == 'error' then
        if ns.Frame.Error:SelectErr(linkContent) then
            ns.Frame:SetTab(2)
        end
    else
        return
    end
    return true
end

local orig_ItemRefTooltip_SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link)
    if TypeRender.ClickValue(link) then
        return
    end
    return orig_ItemRefTooltip_SetHyperlink(self, link)
end
