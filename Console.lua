-- Console.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/16/2018, 3:59:57 PM

local ns         = select(2, ...)
local Util       = ns.Util
local TypeRender = ns.TypeRender

local Console = {}

function Console:OnLoad()
    local bg = self:CreateTexture(nil, 'BACKGROUND') do
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.8)
    end

    local Border = self:CreateTexture(nil, 'BORDER') do
        Border:SetColorTexture(1, 1, 1, 0.5)
        Border:SetHeight(1)
        Border:SetPoint('BOTTOMLEFT')
        Border:SetPoint('BOTTOMRIGHT')
    end

    local Header = CreateFrame('Frame', nil, self) do
        Header:SetHeight(20)
        Header:SetPoint('TOPLEFT')
        Header:SetPoint('TOPRIGHT')

        local Border = Header:CreateTexture(nil, 'BORDER') do
            Border:SetColorTexture(1, 1, 1, 0.5)
            Border:SetHeight(1)
            Border:SetPoint('BOTTOMLEFT')
            Border:SetPoint('BOTTOMRIGHT')
        end
    end

    local MessageFrame = CreateFrame('ScrollingMessageFrame', nil, self) do
        MessageFrame:SetMaxLines(9000)
        MessageFrame:SetFontObject(ConsoleFontSmall)
        MessageFrame:SetIndentedWordWrap(true)
        MessageFrame:SetJustifyH('LEFT')
        MessageFrame:SetFading(false)
        MessageFrame:SetPoint('TOPLEFT', Header, 'BOTTOMLEFT', 3, -1)
        MessageFrame:SetPoint('BOTTOMRIGHT', -20, 2)
        MessageFrame:SetHyperlinksEnabled(true)
        MessageFrame:SetScript('OnHyperlinkClick', function(_, link)
            TypeRender.ClickValue(link)
        end)
        MessageFrame:SetOnDisplayRefreshedCallback(function()
            local maxValue = self.MessageFrame:GetMaxScrollRange()
            local atBottom = self.MessageFrame:AtBottom()
            self.ScrollBar:SetMinMaxValues(0, maxValue)
            if atBottom then
                self.ScrollBar:SetValue(maxValue)
            end
        end)
    end

    local ScrollBar = CreateFrame('Slider', nil, self, 'UIPanelScrollBarTemplate') do
        ScrollBar.scrollStep = 3
        ScrollBar:SetPoint('TOPRIGHT', Header, 'BOTTOMRIGHT', 0, -16)
        ScrollBar:SetPoint('BOTTOMRIGHT', 0, 17)
        ScrollBar:SetScript('OnValueChanged', function(ScrollBar, value)
            local minValue, maxValue = ScrollBar:GetMinMaxValues()
            local value = floor(value + 0.5)
            MessageFrame:SetScrollOffset(maxValue - value)

            ScrollBar.ScrollUpButton:Enable()
            ScrollBar.ScrollDownButton:Enable()
            if value == minValue then
                ScrollBar.ScrollUpButton:Disable()
            end
            if value == maxValue then
                ScrollBar.ScrollDownButton:Disable()
            end
        end)
    end

    setprinthandler(function(...)
        return self:Print(format('%s %s : %s',
            date('|cff00ff00%H:%M:%S|r'),
            Util.GetCodePath(8),
            table.concat({self:RenderAll(...)}, ', ')
        ), 0.5, 0.5, 0.5)
    end)

    self.ScrollBar    = ScrollBar
    self.MessageFrame = MessageFrame

    -- self:SetFlattensRenderLayers(true)
    self:SetPoint('TOPLEFT')
    self:SetPoint('TOPRIGHT')
    self:SetHeight(300)
    self:SetResizable(true)
    self:EnableMouse(true)
    self:EnableMouseWheel(true)
    self:SetFrameStrata('FULLSCREEN_DIALOG')
    self:SetMinResize(40, 40)

    self:SetScript('OnMouseWheel', self.OnMouseWheel)
    self:SetScript('OnMouseDown', self.OnMouseDown)
    self:SetScript('OnMouseUp', self.StopMovingOrSizing)

    UIParent:HookScript('OnSizeChanged', function()
        self:ClearAllPoints()
        self:SetPoint('TOPLEFT')
        self:SetPoint('TOPRIGHT')
    end)
end

function Console:FormatCodePath(depth)
    -- body...
end

function Console:OnMouseWheel(delta)
    if IsControlKeyDown() then

    else
        self.ScrollBar:SetValue(self.ScrollBar:GetValue() - delta)
    end
end

function Console:OnMouseDown()
    local position, value = Util.GetMousePosition(self)
    if value >= 8 then
        self:StartSizing(position)
    end
end

function Console:Print(text, r, g, b)
    self.MessageFrame:AddMessage(text, r or 1, g or 1, b or 1)
end

function Console:RenderAll(...)
    local sb = {}
    for i = 1, select('#', ...) do
        table.insert(sb, TypeRender((select(i, ...))))
    end
    return unpack(sb)
end

Console = Mixin(CreateFrame('Frame'), Console)
Console:OnLoad()

for i = 1, 1000 do
    print(i, 1, 2, 3, UIParent, UIParent[0], true, false, nil, 'Hello world', CLASS_ICON_TCOORDS)
end

setfenv(DevTools_Dump, setmetatable({
    DevTools_RunDump = function(value, context)
        local prefix = format('%s %s |cff808080:|r %s',
            date('|cff00ff00%H:%M:%S|r'),
            Util.GetCodePath(4),
            'Dump: '
        )

        Console:Print(prefix)
        context.Write = function(_, text)
            return Console:Print(prefix .. text)
        end
        return DevTools_RunDump(value, context)
    end
}, {__index = _G}))

function dump(...)
    DevTools_Dump({...}, 'value')
end

dump(1,2,3)
