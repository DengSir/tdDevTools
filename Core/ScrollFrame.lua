-- ScrollFrame.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/20/2018, 7:46:03 PM
--
---@type ns
local ns = select(2, ...)

---@class ScrollFrame: Frame, Object
---@field scrollBar Slider
local ScrollFrame = ns.class('ScrollFrame')
ns.ScrollFrame = ScrollFrame

function ScrollFrame:Constructor(_, opts)
    local buttonTemplate = opts.buttonTemplate

    self.buttons = setmetatable({}, {
        __index = function(t, i)
            if type(i) ~= 'number' then
                return
            end
            local button = CreateFrame('Button', nil, self:GetScrollChild(), buttonTemplate)
            t[i] = button
            if i == 1 then
                button:SetPoint('TOPLEFT')
                button:SetPoint('TOPRIGHT')
            else
                button:SetPoint('TOPLEFT', t[i - 1], 'BOTTOMLEFT')
                button:SetPoint('TOPRIGHT', t[i - 1], 'BOTTOMRIGHT')
            end
            return button
        end,
    })

    self.buttonHeight = self.buttons[1]:GetHeight()
    self:SetScript('OnSizeChanged', self.OnSizeChanged)

    self.update = opts.update or self.update

    if self.scrollBar and not opts.pinBottom then
        self.scrollBar:SetMinMaxValues(0, 1)
        self.scrollBar:SetValue(0)
    end

    self:OnSizeChanged(self:GetSize())
end

function ScrollFrame:OnUpdate()
    self:SetScript('OnUpdate', nil)
    self:update()
end

function ScrollFrame:OnSizeChanged(width, height)
    self:GetScrollChild():SetSize(width - 14, height)
    self:Refresh()
end

function ScrollFrame:Refresh()
    return self:SetScript('OnUpdate', self.OnUpdate)
end

function ScrollFrame:SetOffset(height)
    HybridScrollFrame_SetOffset(self, height)
    self.scrollBar:SetValue(height)
end
