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

local PREVIEWABLE_INVTYPES = {
    [1] = true, -- Head
    [3] = true, -- Shoulder
    [4] = true, -- Body/Shirt
    [5] = true, -- Chest
    [6] = true, -- Waist
    [7] = true, -- Legs
    [8] = true, -- Feet
    [9] = true, -- Wrist
    [10] = true, -- Hands
    [13] = true, -- One-hand
    [14] = true, -- Shield
    [15] = true, -- Ranged
    [16] = true, -- Cloak
    [17] = true, -- Two-hand
    [19] = true, -- Tabard
    [20] = true, -- Robe
    [21] = true, -- Main hand
    [22] = true, -- Off hand
    [26] = true, -- Wand/Ranged right
}

function Item:Constructor()
    self.searchText = ''
    self.debounceTimer = nil
    self.sortKey = 'id'
    self.sortDir = 1 -- 1=asc, -1=desc
    self.selectedNode = nil
    self.qualityFilter = nil
    self.displayList = ns.ItemSparse
    self.categoryTree = {}
    self.colWidths = {id = 45, ilvl = 36}

    Model_SetDefaultRotation(self.PreviewPanel.Model, 6)

    self.Tip = tdDevToolsItemTip
    self.Tip.UpdateTooltip = function()
        if self.selectedItem then
            self.Tip:SetItemByID(self.selectedItem)
        end
    end

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

                button.ExpandIcon:SetPoint('LEFT', 4, 0)
                button.ExpandIcon:SetTexture(isExpanded and [[Interface\AddOns\!!!tdDevTools\Media\ArrowBR.BLP]] or
                                                 [[Interface\AddOns\!!!tdDevTools\Media\ArrowDown.BLP]])
                button.ExpandIcon:SetShown(hasChildren)

                button.Label:SetText(item.name)
                local selected = item.isAll and not catSelf.selectedNode or catSelf.selectedNode == item
                button.Selected:SetShown(selected or false)
            end,
            [2] = function(button, item)
                local catList = button.scrollFrame
                local hasChildren = #item > 0
                local isExpanded = hasChildren and catList:IsItemExpend(item)

                button.ExpandIcon:SetPoint('LEFT', 16, 0)
                button.ExpandIcon:SetTexture(isExpanded and [[Interface\AddOns\!!!tdDevTools\Media\ArrowBR.BLP]] or
                                                 [[Interface\AddOns\!!!tdDevTools\Media\ArrowDown.BLP]])
                button.ExpandIcon:SetShown(hasChildren)

                button.Label:SetText(item.name)
                button.Selected:SetShown(catSelf.selectedNode == item)
            end,
            [3] = function(button, item)
                button.ExpandIcon:SetPoint('LEFT', 24, 0)
                button.ExpandIcon:Hide()
                button.Label:SetText(item.name)
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
    local w = self.Left.Content.ColHeader:GetWidth()
    if w > 0 then
        self:UpdateColumnWidths(w)
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
            if not subName or subName == '' then
                return nil
            end
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
                if child.name == n then
                    return child
                end
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
        if not name then
            return nil
        end
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
            Enum.InventoryType.IndexHeadType, Enum.InventoryType.IndexNeckType, Enum.InventoryType.IndexBodyType,
            Enum.InventoryType.IndexFingerType, Enum.InventoryType.IndexTrinketType,
            Enum.InventoryType.IndexHoldableType,
        }
        local ClothArmorInventoryTypes = {
            Enum.InventoryType.IndexHeadType, Enum.InventoryType.IndexShoulderType, Enum.InventoryType.IndexChestType,
            Enum.InventoryType.IndexWaistType, Enum.InventoryType.IndexLegsType, Enum.InventoryType.IndexFeetType,
            Enum.InventoryType.IndexWristType, Enum.InventoryType.IndexHandType, Enum.InventoryType.IndexCloakType, -- 布甲独有
        }
        local ArmorInventoryTypes = {
            Enum.InventoryType.IndexHeadType, Enum.InventoryType.IndexShoulderType, Enum.InventoryType.IndexChestType,
            Enum.InventoryType.IndexWaistType, Enum.InventoryType.IndexLegsType, Enum.InventoryType.IndexFeetType,
            Enum.InventoryType.IndexWristType, Enum.InventoryType.IndexHandType,
        }

        local cat = newNode(Enum.ItemClass.Armor)
        if cat then
            local miscCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic)
            if miscCat then
                miscCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic,
                                                       MiscArmorInventoryTypes)
            end

            local clothCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth)
            if clothCat then
                clothCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth,
                                                        ClothArmorInventoryTypes)
                local chestCat = clothCat:FindSubCategoryByName(
                                     C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth,
                                       Enum.InventoryType.IndexRobeType)
                end
            end

            local leatherCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather)
            if leatherCat then
                leatherCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather,
                                                          ArmorInventoryTypes)
                local chestCat = leatherCat:FindSubCategoryByName(
                                     C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather,
                                       Enum.InventoryType.IndexRobeType)
                end
            end

            local mailCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail)
            if mailCat then
                mailCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail,
                                                       ArmorInventoryTypes)
                local chestCat = mailCat:FindSubCategoryByName(
                                     C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail,
                                       Enum.InventoryType.IndexRobeType)
                end
            end

            local plateCat = cat:CreateSubCategoryAndFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate)
            if plateCat then
                plateCat:AddBulkInventoryTypeCategories(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate,
                                                        ArmorInventoryTypes)
                local chestCat = plateCat:FindSubCategoryByName(
                                     C_Item.GetItemInventorySlotInfo(Enum.InventoryType.IndexChestType))
                if chestCat then
                    chestCat:AddFilter(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate,
                                       Enum.InventoryType.IndexRobeType)
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
                    cat:CreateSubCategoryAndFilter(Enum.ItemClass.Miscellaneous,
                                                   Enum.ItemMiscellaneousSubclass.CompanionPet)
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

function Item:FilterItem(entry)
    if self.qualityFilter and entry.quality ~= self.qualityFilter then
        return false
    end
    if self.searchText and self.searchText ~= '' then
        local lower = self.searchText:lower()
        local id = entry.id
        if not entry.name:lower():find(lower, 1, true) and not tostring(id):find(lower, 1, true) then
            return false
        end
    end
    local filters = self.selectedNode and self.selectedNode.filters
    if filters then
        local matched = false
        for _, f in ipairs(filters) do
            if (not f.classID or entry.classID == f.classID) and (not f.subClassID or entry.subclassID == f.subClassID) and
                (not f.inventoryType or entry.invType == f.inventoryType) then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end
    return true
end

function Item:Rebuild(searchText)
    local filters = self.selectedNode and self.selectedNode.filters
    local hasSearch = searchText ~= ''
    local hasQuality = self.qualityFilter

    local base
    if not hasSearch and not filters and not hasQuality then
        base = ns.ItemSparse
    else
        base = {}
        for _, entry in ipairs(ns.ItemSparse) do
            if self:FilterItem(entry) then
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
        return a.id < b.id
    end,
    ilvl = function(a, b)
        return (a.ilvl or 0) < (b.ilvl or 0)
    end,
    quality = function(a, b)
        if a.quality ~= b.quality then
            return a.quality < b.quality
        end
        if a.ilvl ~= b.ilvl then
            return (a.ilvl or 0) < (b.ilvl or 0)
        end
        return a.id < b.id
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

function Item:UpdateColumnWidths(w)
    if w <= 0 then
        return
    end
    local idW = math.max(45, math.floor(w * 0.13))
    local ilvlW = math.max(32, math.floor(w * 0.09))
    self.colWidths = {id = idW, ilvl = ilvlW}
    local ch = self.Left.Content.ColHeader
    ch.SortID:SetWidth(idW)
    ch.SortIlvl:SetWidth(ilvlW)
    if self.inited then
        self.Left.Content.ItemList:Refresh()
    end
end

function Item:ShowPreview(itemID, invType)
    if not PREVIEWABLE_INVTYPES[invType] then
        self:HidePreview()
        return
    end
    local panel = self.PreviewPanel
    local model = panel.Model
    if not panel:IsShown() then
        model:SetUnit('player')
        panel:Show()
    end
    local link = select(2, GetItemInfo(itemID))
    if link then
        model:TryOn(link)
    else
        C_Timer.After(0.2, function()
            if self.selectedItem and self.selectedItem.id == itemID then
                local l = select(2, GetItemInfo(itemID))
                if l then
                    model:TryOn(l)
                end
            end
        end)
    end
end

function Item:HidePreview()
    local panel = self.PreviewPanel
    if panel:IsShown() then
        panel.Model:Undress()
        panel:Hide()
    end
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

function Item:UpdateQualityBtns()
    for q = 0, 7 do
        local btn = self.Header['Q' .. q]
        if btn then
            btn.Sel:SetShown(self.qualityFilter == q)
        end
    end
end

function Item:OnQualityFilterClick(q)
    if self.qualityFilter == q then
        self.qualityFilter = nil
    else
        self.qualityFilter = q
    end
    self:UpdateQualityBtns()
    self:Rebuild(self.searchText)
end

function Item:OnItemFormatting(button, item)
    local id, name, quality, ilvl = item.id, item.name, item.quality, item.ilvl
    local icon = item.icon ~= 0 and item.icon or C_Item.GetItemIconByID(id)
    button.IdText:SetWidth(self.colWidths.id - 5)
    button.IlvlText:SetWidth(self.colWidths.ilvl)
    button.IdText:SetText(id)
    button.IlvlText:SetText(ilvl or '')
    button.NameText:SetText(name)
    if icon then
        button.Icon:SetTexture(icon)
        button.Icon:Show()
    else
        button.Icon:Hide()
    end
    local c = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
    button.NameText:SetTextColor(c.r, c.g, c.b)
    button.Selected:SetShown(self.selectedItem == item)
end

function Item:OnItemClick(button)
    self.selectedItem = button.item
    self.Left.Content.ItemList:Refresh()

    local item = button.item
    local itemID = item.id
    if IsShiftKeyDown() then
        local link = select(2, GetItemInfo(itemID))
        if link then
            local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
            if editBox then
                ChatEdit_InsertLink(link)
            end
        end
    else
        self.Tip:SetOwner(tdDevToolsItemScrollChild, 'ANCHOR_PRESERVE')
        self.Tip:SetItemByID(itemID)
        self.Tip:Show()
        self:ShowPreview(itemID, item.invType)
    end
end

Item:Bind(ns.Frame.Item)
