-- TypeRender.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 4:39:54 PM
local ns = select(2, ...)
local TypeRender = setmetatable({}, {
    __index = function(t)
        return t.other
    end,
    __call = function(self, value)
        local t = type(value)
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

TypeRender['nil'] = colorFactory(.5, .5, .5)

TypeRender.other = colorFactory(1, 1, 1)
TypeRender.string = colorFactory(0, 1, .5, function(value)
    return format('%q', value)
end)
TypeRender.number = colorFactory(1, 1, 0)
TypeRender.boolean = colorFactory(1, 0, 0)

TypeRender.widget = function(widget)
    local name = widget:GetDebugName()
    if not name then
        error('not found debug name')
    elseif name == '' then
        name = tostring(widget)
    end
    widgets[name] = widget
    return format('|Hwidget:%s|h|cff00ff00[%s]|r|h', name, name)
end

TypeRender.tbl = function(tbl)
    local name = tostring(tbl)
    if not name then
        error('no name')
    end
    tables[name] = tbl
    return format('|Htable:%s|h|cff00ffff[%s]|r|h', name, name)
end

TypeRender.table = function(value)
    if type(rawget(value, 0)) == 'userdata' and value.GetObjectType then
        return TypeRender.widget(value)
    else
        return TypeRender.tbl(value)
    end
end

TypeRender.ClickValue = function(link)
    if not link then
        return
    end
    local linkType, linkContent = link:match('^([^:]+):(.+)$')
    if not linkType then
        return
    end

    if linkType == 'widget' then
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
    end
end
