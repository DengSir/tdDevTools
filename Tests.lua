-- Tests.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:06:29 AM

if true then
    return
end

for i = 1, 1000 do
    print(i, UIParent, CLASS_ICON_TCOORDS, {i=i}, 1, 1.1, 'string', true, false, nil, UIParent[0])
end

dump(CLASS_ICON_TCOORDS)

inspect({a=1,b=2,c=3})
