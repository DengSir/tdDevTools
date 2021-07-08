-- Document.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 7/7/2021, 3:24:04 PM
--
---@type ns
local ns = select(2, ...)

---@class tdDevToolsDocument: Frame, __Document, Object
local Document = ns.class('Frame')

function Document:Constructor()
    self.systemContents = {}
    self.contentFields = {}

    -- ns.Frame.Error:DisableWarn()
    -- APIDocumentation_LoadUI()
    -- ns.Frame.Error:EnableWarn()

    ns.ListView:Bind(self.SystemList, {
        -- itemList = APIDocumentation.systems,
        buttonTemplate = 'tdDevToolsDocumentSystemItemTemplate',
        OnItemFormatting = function(button, item)
            return self:RenderItem(button, item)
        end,
    })

    ns.ListView:Bind(self.ContentList, {
        buttonTemplate = 'tdDevToolsDocumentContentItemTemplate',
        OnItemFormatting = function(button, item)
            return self:RenderItem(button, item)
        end,
    })

    ns.ListView:Bind(self.FieldList, {
        buttonTemplate = 'tdDevToolsDocumentBaseItemTemplate',
        OnItemFormatting = function(button, item)
            return self:RenderItem(button, item)
        end,
    })

    self:SetScript('OnShow', self.OnShow)
end

function Document:OnShow()
    if not APIDocumentation then
        APIDocumentation_LoadUI()
    end

    if APIDocumentation then
        self.SystemList:SetItemList(APIDocumentation.systems)
        self:SetScript('OnShow', nil)
    end
end

function Document:RenderItem(button, item)
    button.Text:SetText(self:RenderContentItem(item))
    button.Selected:SetShown(item == self.selectedSystem or item == self.selectedContent)
end

local function GetApiName(api)
    local namespace = api.System and api.System:GetNamespaceName()
    if namespace ~= '' then
        return format('%s.%s', namespace, api:GetName())
    end
    return api:GetName()
end

local function GetApiFields(api, tblName, default)
    if api[tblName] then
        local values = {}

        for i, v in ipairs(api[tblName]) do
            if v:IsOptional() then
                tinsert(values, format('|cff00ffff%s?|r', v:GetName()))
            else
                tinsert(values, format('|cff00ffff%s|r', v:GetName()))
            end
        end
        return table.concat(values, ', ')
    end
    return default or ''
end

local function GetFunctionArguments(api)
    return GetApiFields(api, 'Arguments')
end

local function GetFunctionReturns(api)
    return GetApiFields(api, 'Returns', 'void')
end

function Document:RenderContentItem(item)
    if type(item) == 'string' then
        return format('|cffffd200%s|r', item)
    end

    local t = item:GetType()
    if t == 'function' then
        return format('%s(%s) -> %s', GetApiName(item), GetFunctionArguments(item), GetFunctionReturns(item))
    elseif t == 'event' then
        return item.LiteralName
    elseif t == 'table' then
        return item:GetFullName()
    elseif t == 'system' then
        return item:GetName()
    elseif t == 'field' then
        local v = item
        if v:IsOptional() then
            return format('|cff00ffff%s?|r: |cff00ff00%s|r', v:GetName(), v.Mixin or v.Type)
        else
            return format('|cff00ffff%s|r: |cff00ff00%s|r', v:GetName(), v.Mixin or v.Type)
        end
    else
        print(t)
    end
    return ''
end

function Document:OnSystemItemClick(button)
    local id = button:GetID()
    local system = APIDocumentation.systems[id]
    if system then
        self.selectedSystem = system
        self.ContentList:SetItemList(self:GetSystemContents(system))
        self.SystemList:Refresh()
    end
end

function Document:OnContentItemClick(button)
    local id = button:GetID()
    local content = self:GetSystemContents(self.selectedSystem)[id]
    if not content then
        return
    end

    local fields = self:GetContentFields(content)
    if fields then
        self.selectedContent = content
        self.FieldList:SetItemList(fields)
        self.ContentList:Refresh()
    end
end

local function Add(name, container, output)
    if container and #container > 0 then
        tinsert(output, name)

        for _, v in ipairs(container) do
            tinsert(output, v)
        end
    end
end

function Document:GetSystemContents(system)
    if not self.systemContents[system] then
        local contents = {}

        Add('Functions', system.Functions, contents)
        Add('Tables', system.Tables, contents)
        Add('Events', system.Events, contents)

        self.systemContents[system] = contents
    end
    return self.systemContents[system]
end

function Document:GetContentFields(content)
    if not self.contentFields[content] then
        local fields = {}

        Add('Arguments', content.Arguments, fields)
        Add('Returns', content.Returns, fields)
        Add('Payloads', content.Payload, fields)
        Add('Fields', content.Fields, fields)

        self.contentFields[content] = fields
    end
    return self.contentFields[content]
end

Document:Bind(ns.Frame.Document)
