-- Item.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
--
---@type ns
local ns = select(2, ...)

local tinsert = table.insert
local wipe = table.wipe or wipe
local tostring = tostring

---@class tdDevToolsItem: Frame, Object
local Item = ns.class('Frame')

local QUALITY_COLORS = {
    [0] = {0.62, 0.62, 0.62}, -- Poor
    [1] = {1.00, 1.00, 1.00}, -- Common
    [2] = {0.12, 1.00, 0.00}, -- Uncommon
    [3] = {0.00, 0.44, 0.87}, -- Rare
    [4] = {0.64, 0.21, 0.93}, -- Epic
    [5] = {1.00, 0.50, 0.00}, -- Legendary
    [6] = {0.90, 0.80, 0.50}, -- Artifact
    [7] = {0.00, 0.80, 1.00}, -- Heirloom
    [8] = {0.00, 0.80, 1.00}, -- WoW Token
}

-- ---- Filter Popup ----

-- ---- Item Panel ----

function Item:Constructor()
    self.searchText = ''
    self.debounceTimer = nil
    self.sortKey = 'id'
    self.sortDir = 1 -- 1=asc, -1=desc
    self.selectedNode = nil
    self.displayList = ns.ItemSparse
    self.categoryTree = {}

    local catSelf = self
    ns.TreeView:Bind(self.Left.CategoryPanel.CategoryList, {
        itemTree = self.categoryTree,
        depth = 3,
        buttonTemplate = 'tdDevToolsItemCategoryTemplate',
        OnItemFormatting = {
            [1] = function(button, item)
                local catList = button.scrollFrame
                local hasChildren = #item > 0
                local isExpanded = hasChildren and catList:IsItemExpend(item)
                local prefix = hasChildren and (isExpanded and [[|TInterface\AddOns\!!!tdDevTools\Media\ArrowBR.BLP:8:8|t ]] or [[|TInterface\AddOns\!!!tdDevTools\Media\ArrowDown.BLP:8:8|t ]]) or '  '
                button.Label:SetText(prefix .. item.name)
                local selected = item.isAll and not catSelf.selectedNode or catSelf.selectedNode == item
                button.Selected:SetShown(selected or false)
            end,
            [2] = function(button, item)
                local catList = button.scrollFrame
                local hasChildren = #item > 0
                local isExpanded = hasChildren and catList:IsItemExpend(item)
                local prefix = hasChildren and (isExpanded and [[|TInterface\AddOns\!!!tdDevTools\Media\ArrowBR.BLP:8:8|t ]] or [[|TInterface\AddOns\!!!tdDevTools\Media\ArrowDown.BLP:8:8|t ]]) or '  '
                button.Label:SetText('  ' .. prefix .. item.name)
                button.Selected:SetShown(catSelf.selectedNode == item)
            end,
            [3] = function(button, item)
                button.Label:SetText('        ' .. item.name)
                button.Selected:SetShown(catSelf.selectedNode == item)
            end,
        },
    })

    ns.ListView:Bind(self.Left.Content.ItemList, {
        itemList = ns.ItemSparse,
        buttonTemplate = 'tdDevToolsItemRowTemplate',
        OnItemFormatting = function(button, item)
            return self:OnItemFormatting(button, item)
        end,
    })

    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)
end

function Item:OnShow()
    if not self.inited then
        self.inited = true
        self:BuildCategoryTree()
        self.Left.CategoryPanel.CategoryList:Refresh()
        self:ApplySort()
    end
end

function Item:OnHide()
    tdDevToolsItemTip:Hide()
end

function Item:BuildCategoryTree()
    wipe(self.categoryTree)
    self.categoryTree[1] = {name = '全部', isAll = true}

    local tree = self.categoryTree

    -- 仿照 AuctionCategoryMixin 构造可嵌套的分类节点
    local makeNode
    makeNode = function(name, classID, subClassID, invType)
        local node = {name = name}
        if classID ~= nil then
            node.filters = {{classID = classID, subClassID = subClassID, inventoryType = invType}}
        end

        function node:CreateSubCategoryAndFilter(cID, scID, invT)
            local subName
            if invT then
                subName = C_Item.GetItemInventorySlotInfo(invT)
            elseif scID then
                subName = C_Item.GetItemSubClassInfo(cID, scID)
            else
                subName = GetItemClassInfo(cID)
            end
            if not subName or subName == '' then return nil end
            local child = makeNode(subName, cID, scID, invT)
            self[#self + 1] = child
            return child
        end

        function node:AddFilter(cID, scID, invT)
            self.filters = self.filters or {}
            self.filters[#self.filters + 1] = {classID = cID, subClassID = scID, inventoryType = invT}
        end

        function node:AddBulkInventoryTypeCategories(cID, scID, invTypes)
            for _, invT in ipairs(invTypes) do
                self:CreateSubCategoryAndFilter(cID, scID, invT)
            end
        end

        function node:FindSubCategoryByName(n)
            for _, child in ipairs(self) do
                if child.name == n then return child end
            end
        end

        function node:GenerateSubCategoriesAndFiltersFromSubClass(cID)
            for _, scID in ipairs({GetAuctionItemSubClasses(cID)}) do
                self:CreateSubCategoryAndFilter(cID, scID)
            end
        end

        return node
    end

    local function newNode(classID)
        local name = GetItemClassInfo(classID)
        if not name then return nil end
        local node = makeNode(name, classID)
        tree[#tree + 1] = node
        return node
    end

    -- Weapons
    do
        local cat = newNode(Enum.ItemClass.Weapon)
        if cat then
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe2H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Bows)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Guns)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace1H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace2H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Polearm)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword1H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword2H)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Staff)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Unarmed)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Generic)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Dagger)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Thrown)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Crossbow)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Wand)
            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Fishingpole)
        end
    end

    -- Armor
    do
        local MiscArmorInventoryTypes = {
            Enum.InventoryType.IndexHeadType,
            Enum.InventoryType.IndexNeckType,
            Enum.InventoryType.IndexBodyType,
            Enum.InventoryType.IndexFingerType,
            Enum.InventoryType.IndexTrinketType,
            Enum.InventoryType.IndexHoldableType,
        }
        local ClothArmorInventoryTypes = {
            Enum.InventoryType.IndexHeadType,
            Enum.InventoryType.IndexShoulderType,
            Enum.InventoryType.IndexChestType,
            Enum.InventoryType.IndexWaistType,
            Enum.InventoryType.IndexLegsType,
            Enum.InventoryType.IndexFeetType,
            Enum.InventoryType.IndexWristType,
            Enum.InventoryType.IndexHandType,
            Enum.InventoryType.IndexCloakType, -- 布甲独有
        }
        local ArmorInventoryTypes = {
            Enum.InventoryType.IndexHeadType,
            Enum.InventoryType.IndexShoulderType,
            Enum.InventoryType.IndexChestType,
            Enum.InventoryType.IndexWaistType,
            Enum.InventoryType.IndexLegsType,
            Enum.InventoryType.IndexFeetType,
            Enum.InventoryType.IndexWristType,
            Enum.InventoryType.IndexHandType,
        }

        local cat = newNode(Enum.ItemClass.Armor)
        if cat then
            local miscCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic)
            if miscCat then
                miscCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic, MiscArmorInventoryTypes)
            end

            local clothCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth)
            if clothCat then
                clothCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, ClothArmorInventoryTypes)
                local chestCat = clothCat:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, Enum.InventoryType.IndexRobeType)
                end
            end

            local leatherCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather)
            if leatherCat then
                leatherCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather, ArmorInventoryTypes)
                local chestCat = leatherCat:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather, Enum.InventoryType.IndexRobeType)
                end
            end

            local mailCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail)
            if mailCat then
                mailCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail, ArmorInventoryTypes)
                local chestCat = mailCat:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail, Enum.InventoryType.IndexRobeType)
                end
            end

            local plateCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate)
            if plateCat then
                plateCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate, ArmorInventoryTypes)
                local chestCat = plateCat:FindSubCategoryByName(C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate, Enum.InventoryType.IndexRobeType)
                end
            end

            cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield)
            if ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Relic)
            else
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Libram)
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Idol)
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Totem)
            end
        end
    end

    -- Containers
    do
        local cat = newNode(Enum.ItemClass.Container)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Container)
        end
    end

    -- Consumables
    do
        local cat = newNode(Enum.ItemClass.Consumable)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Consumable)
        end
    end

    -- Glyphs (Wrath+)
    if ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
        local cat = newNode(Enum.ItemClass.Glyph)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Glyph)
        end
    end

    -- Trade Goods
    do
        local cat = newNode(Enum.ItemClass.Tradegoods)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Tradegoods)
        end
    end

    -- Projectile (Classic ~ Wrath)
    if not (ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM)) then
        local cat = newNode(Enum.ItemClass.Projectile)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Projectile)
        end
    end

    -- Quiver (Classic ~ Wrath)
    if not (ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM)) then
        local cat = newNode(Enum.ItemClass.Quiver)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Quiver)
        end
    end

    -- Recipes
    do
        local cat = newNode(Enum.ItemClass.Recipe)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Recipe)
        end
    end

    -- Reagent (Classic only)
    if not (ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE)) then
        newNode(Enum.ItemClass.Reagent)
    end

    -- Gems (TBC+)
    if not ClassicExpansionAtLeast or ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
        local cat = newNode(Enum.ItemClass.Gem)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Gem)
        end
    end

    -- Miscellaneous
    do
        local cat = newNode(Enum.ItemClass.Miscellaneous)
        if cat then
            if not ClassicExpansionAtLeast or ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Junk)
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Reagent)
                if not (ClassicExpansionAtLeast and ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA)) then
                    cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.CompanionPet)
                end
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Holiday)
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Other)
                cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous, Enum.ItemMiscellaneousSubclass.Mount)
            end
        end
    end

    -- Quest Items (TBC+)
    if not ClassicExpansionAtLeast or ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE) then
        newNode(Enum.ItemClass.Questitem)
    end

    -- Battle Pets (MoP+)
    if not ClassicExpansionAtLeast or ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
        local cat = newNode(Enum.ItemClass.Battlepet)
        if cat then
            cat:GenerateSubCategoriesAndFiltersFromSubClass(Enum.ItemClass.Battlepet)
        end
    end
end

function Item:OnCategoryClick(button)
    local item = button.item
    local catList = self.Left.CategoryPanel.CategoryList

    if item.isAll then
        self.selectedNode = nil
        wipe(catList.treeStatus.extends)
        catList:Refresh()
    else
        self.selectedNode = item
        if #item > 0 then
            catList:ToggleItem(item)
        else
            catList:Refresh()
        end
    end
    self:Rebuild(self.searchText)
end

function Item:OnSearchTextChanged(text)
    if text == self.searchText then
        return
    end
    self.searchText = text

    if self.debounceTimer then
        self.debounceTimer:Cancel()
    end
    self.debounceTimer = C_Timer.NewTimer(0.3, function()
        self.debounceTimer = nil
        self:Rebuild(text)
    end)
end

function Item:Rebuild(searchText)
    local filters = self.selectedNode and self.selectedNode.filters
    local hasSearch = searchText ~= ''

    local base
    if not hasSearch and not filters then
        base = ns.ItemSparse
    else
        base = {}
        local lower = hasSearch and searchText:lower() or nil
        for _, entry in ipairs(ns.ItemSparse) do
            local pass = true
            if filters then
                local matched = false
                for _, f in ipairs(filters) do
                    if (not f.classID or entry[5] == f.classID)
                        and (not f.subClassID or entry[6] == f.subClassID)
                        and (not f.inventoryType or entry[7] == f.inventoryType) then
                        matched = true
                        break
                    end
                end
                if not matched then pass = false end
            end
            if pass and lower then
                local id, name = entry[1], entry[2]
                if not name:lower():find(lower, 1, true) and not tostring(id):find(lower, 1, true) then
                    pass = false
                end
            end
            if pass then
                tinsert(base, entry)
            end
        end
    end
    self.selectedItem = nil
    self.displayList = base
    self:ApplySort()
end

local SORT_FUNCS = {
    id = function(a, b)
        return a[1] < b[1]
    end,
    ilvl = function(a, b)
        return (a[4] or 0) < (b[4] or 0)
    end,
    quality = function(a, b)
        if a[3] ~= b[3] then
            return a[3] < b[3]
        end
        return (a[4] or 0) < (b[4] or 0)
    end,
}

function Item:ApplySort()
    local list = {}
    for _, v in ipairs(self.displayList) do
        tinsert(list, v)
    end
    local fn = SORT_FUNCS[self.sortKey]
    local dir = self.sortDir
    if dir == 1 then
        table.sort(list, fn)
    else
        table.sort(list, function(a, b)
            return fn(b, a)
        end)
    end
    self.Left.Content.ItemList:SetItemList(list)
    self:UpdateSortLabels()
end

function Item:UpdateSortLabels()
    local arrow = self.sortDir == 1 and [[ |TInterface\AddOns\!!!tdDevTools\Media\ArrowUp.BLP:8:8|t]] or
                      [[ |TInterface\AddOns\!!!tdDevTools\Media\ArrowDown.BLP:8:8|t]]
    local ch = self.Left.Content.ColHeader
    ch.SortID.Label:SetText(self.sortKey == 'id' and ('ID' .. arrow) or 'ID')
    ch.SortIlvl.Label:SetText(self.sortKey == 'ilvl' and ('iLvl' .. arrow) or 'iLvl')
    ch.SortQuality.Label:SetText(self.sortKey == 'quality' and ('Name/Quality' .. arrow) or 'Name/Quality')
end

function Item:OnSortClick(key)
    if self.sortKey == key then
        self.sortDir = -self.sortDir
    else
        self.sortKey = key
        self.sortDir = key == 'id' and 1 or -1
    end
    self:ApplySort()
end

function Item:OnItemFormatting(button, item)
    local id, name, quality, ilvl = item[1], item[2], item[3], item[4]
    button.IdText:SetText(id)
    button.IlvlText:SetText(ilvl or '')
    button.NameText:SetText(name)
    local c = QUALITY_COLORS[quality] or QUALITY_COLORS[1]
    button.NameText:SetTextColor(c[1], c[2], c[3])
    button.Selected:SetShown(self.selectedItem == item)
end

function Item:OnItemClick(button)
    self.selectedItem = button.item
    self.Left.Content.ItemList:Refresh()

    local itemID = button.item[1]
    if IsShiftKeyDown() then
        local link = select(2, GetItemInfo(itemID))
        if link then
            local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
            if editBox then
                ChatEdit_InsertLink(link)
            end
        end
    else
        tdDevToolsItemTip:SetOwner(tdDevToolsItemScrollChild, 'ANCHOR_PRESERVE')
        tdDevToolsItemTip:SetItemByID(itemID)
        tdDevToolsItemTip:Show()
    end
end

Item:Bind(ns.Frame.Item)
