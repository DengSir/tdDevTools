-- TypeRender.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 4:39:54 PM
--
---@type ns
local ns = select(2, ...)

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

local function colorFactory(r, g, b, formatter)
    local formatter = formatter or tostring
    local template = format('|cff%02x%02x%02x', r * 255, g * 255, b * 255) .. '%s|r'
    return function(value)
        return format(template, formatter(value))
    end
end

TypeRender['nil'] = colorFactory(0.5, 0.5, 0.5)
TypeRender['function'] = colorFactory(0, 1, 1)

TypeRender.other = colorFactory(1, 1, 1)
TypeRender.string = colorFactory(1, 1, 0, function(value)
    return format('%q', value)
end)
TypeRender.number = colorFactory(0, 1, 0.5)
TypeRender.boolean = colorFactory(1, 0, 0)
TypeRender.userdata = colorFactory(1, 1, 0.5)

TypeRender.table = function(tbl)
    local name = tostring(tbl)
    if not name then
        error('no name')
    end
    tables[name] = tbl
    return format('|Htable:%s|h|cff00ffff[%s]|r|h', name, name)
end

TypeRender.uiobject = function(obj)
    local name
    if obj.GetDebugName then
        name = obj:GetDebugName()
    elseif obj.GetName then
        name = obj:GetName()
    else
        name = tostring(obj)
    end
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
