-- Tests.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:06:29 AM

for i = 1, 1000 do
    print(i, UIParent, CLASS_ICON_TCOORDS, {i=i}, 1, 1.1, 'string', true, false, nil, UIParent[0])
end

dump(nil, 'string', 123, true, false)

LibStub('AceLocale-3.0'):NewLocale('Test', 'zhCN')
-- LibStub('AceLocale-3.0'):GetLocale('Test', 'zhCN')
LibStub('AceLocale-3.0'):NewLocale('Test', 'enUS', nil, true)

function GG()
    return UseAction(1)
end

function HH()
    GG()
end
