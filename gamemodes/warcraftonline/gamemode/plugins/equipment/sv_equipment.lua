--[[
    Warcraft Online — экипировка (server).
    Экипировка/снятие — транзакции с проверками и откатами.
    Inventory только сообщает "item equipped"; визуал применяет Visual Manager.
]]

---------------------------------------------------------------------------
-- Объект экипировки персонажа
---------------------------------------------------------------------------

function WO.Equipment.Get(char)
    if not WO.Character.IsCharacter(char) then return nil end

    if not WO.Equipment.IsEquipment(char.equipment) then
        char.equipment = WO.Equipment.New()
    end

    return char.equipment
end

---------------------------------------------------------------------------
-- Синхронизация
---------------------------------------------------------------------------

local function SerializeSlot(instance)
    return {
        uid = instance.uid,
        class = instance.class,
        amount = instance.amount or 1,
        durability = instance.durability,
        data = instance.data or {},
    }
end

function WO.Equipment.Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    local equipment = WO.Equipment.Get(char)

    if not equipment then return end

    local slots = {}

    for slotId, instance in pairs(equipment.slots) do
        slots[slotId] = SerializeSlot(instance)
    end

    WO.Net.Send("Equipment.Sync", ply, slots)
end

local function Refresh(char, ply)
    WO.Stats.Recalculate(char)
    WO.Stats.ApplyVitals(ply)
    WO.Equipment.Sync(ply)
    WO.SaveQueue.MarkDirty(char)
    WO.Hook.Run("EquipmentChanged", char)
end

---------------------------------------------------------------------------
-- Оружие в руках (SWEP)
---------------------------------------------------------------------------

--[[
    Применяет оружие из экипировки: выдаёт SWEP для main_hand/off_hand.
    Вызывается при загрузке персонажа и смене экипировки.
]]
function WO.Equipment.ApplyWeapons(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    local equipment = WO.Equipment.Get(char)

    if not equipment then return end

    -- Убираем все wo-оружие
    for _, wep in ipairs(ply:GetWeapons()) do
        if wep.WOItemUID then
            ply:StripWeapon(wep:GetClass())
        end
    end

    -- Выдаём оружие из слотов
    local mainHandClass = nil

    for _, slotId in ipairs({ "main_hand", "off_hand" }) do
        local instance = equipment:Get(slotId)

        if instance then
            local def = WO.Items.Get(instance.class)

            if def and WO.Items.IsInventoryAllowed(def) and def.weapon and
                isstring(def.weapon.class) and WO.Workshop and
                WO.Workshop.HasClass(nil, def.weapon.class) then
                ply:Give(def.weapon.class)

                local wep = ply:GetWeapon(def.weapon.class)

                if IsValid(wep) then
                    wep.WOItemUID = instance.uid
                    wep.WODamage = def.weapon.damage
                    wep.WOItemClass = instance.class

                    if instance.durability ~= nil then
                        wep.WODurability = instance.durability
                    end

                    if slotId == "main_hand" then
                        mainHandClass = def.weapon.class
                    end
                end
            end
        end
    end

    local loadoutPrimary = nil

    if WO.Loadout and isfunction(WO.Loadout.Apply) then
        loadoutPrimary = WO.Loadout.Apply(ply, char)
    end

    local selectedClass = mainHandClass or loadoutPrimary

    if selectedClass and isfunction(ply.SelectWeapon) and ply:HasWeapon(selectedClass) then
        ply:SelectWeapon(selectedClass)
    end
end

---------------------------------------------------------------------------
-- Visual Equipment Manager (bonemerge / аттачи)
---------------------------------------------------------------------------

WO.Visual = WO.Visual or {}

--[[
    Очищает визуальные аттачи персонажа.
]]
function WO.Visual.Clear(ply)
    if not IsValid(ply) then return end

    for _, ent in ipairs(ply._woVisuals or {}) do
        if IsValid(ent) then
            ent:Remove()
        end
    end

    ply._woVisuals = {}
end

--[[
    Применяет визуальную экипировку (модели-аттачи к костям).
    Использует def.equipment.visual = {
        model = "models/...",
        bone = "ValveBiped.Bip01_Head1",
        scale = 1,
        offset = { pos = Vector, ang = Angle },
    }
    Оружие в руках отображается SWEP-ом (worldmodel) — отдельно.
]]
function WO.Visual.Apply(ply)
    if not IsValid(ply) then return end

    WO.Visual.Clear(ply)

    local char = ply:GetCharacter()
    local equipment = char and WO.Equipment.Get(char)

    if not equipment then return end

    for slotId, instance in pairs(equipment.slots) do
        local def = WO.Items.Get(instance.class)
        local visual = def and def.equipment and def.equipment.visual

        if visual and isstring(visual.model) then
            local att = ents.Create("prop_dynamic")

            if IsValid(att) then
                att:SetModel(visual.model)
                att:SetPos(ply:GetPos())
                att:Spawn()
                att:SetNotSolid(true)
                att:SetMoveType(MOVETYPE_NONE)
                att:SetParent(ply)

                local boneId = ply:LookupBone(visual.bone or "ValveBiped.Bip01_Head1")

                if boneId then
                    att:FollowBone(ply, boneId)
                end

                if visual.scale then
                    att:SetModelScale(visual.scale)
                end

                if visual.offset then
                    att:SetLocalPos(visual.offset.pos or vector_origin)
                    att:SetLocalAngles(visual.offset.ang or angle_zero)
                end

                att.WOVisual = true

                ply._woVisuals = ply._woVisuals or {}
                ply._woVisuals[#ply._woVisuals + 1] = att
            end
        end
    end
end

---------------------------------------------------------------------------
-- Экипировка предмета
---------------------------------------------------------------------------

--[[
    Экипирует предмет из инвентаря.

    Транзакция:
        1. lock item; 2. проверки (слот, требования, класс);
        3. снять старый предмет (если занят слот);
        4. поместить в слот; 5. при неудаче — откат.

    @param ply Player
    @param uid string
    @return boolean success, string|nil reason
]]
function WO.Equipment.Equip(ply, uid)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local equipment = WO.Equipment.Get(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    local def = WO.Items.Get(instance.class)

    if not def or not WO.Items.IsInventoryAllowed(def) or not def.equipment then
        return false, "not_equippable"
    end

    -- Слот
    local slotId = def.equipment.slot

    if slotId == "ring" then
        -- Кольцо: первый свободный слот
        slotId = not equipment:Get("ring_1") and "ring_1" or "ring_2"

        if equipment:Get("ring_1") and equipment:Get("ring_2") then
            slotId = "ring_1" -- заменяем первое
        end
    end

    if not equipment:HasSlot(slotId) then
        return false, "invalid_slot"
    end

    -- Прочность
    if instance.durability ~= nil and instance.durability <= 0 then
        return false, "broken"
    end

    -- Требования (уровень, класс, раса, статы)
    local canUse, reason = WO.Requirements.Check(ply, def.requirements)

    if not canUse then
        return false, "requirement:" .. tostring(reason)
    end

    -- Допуск класса
    local category = WO.Equipment.ItemCategory(def)

    if def.type == "weapon" or slotId == "main_hand" or slotId == "off_hand" then
        if not WO.Classes.IsWeaponAllowed(char.class, category) then
            return false, "class_weapon"
        end
    else
        if not WO.Classes.IsArmorAllowed(char.class, category) then
            return false, "class_armor"
        end
    end

    instance.locked = true

    -- Снимаем старый предмет из слота (если есть)
    local oldInstance = equipment:Get(slotId)

    if oldInstance then
        local unequipOk, unequipReason = WO.Equipment.Unequip(ply, slotId)

        if not unequipOk then
            instance.locked = nil
            return false, unequipReason or "unequip_failed"
        end
    end

    -- Перемещаем из инвентаря в слот
    container:RemoveItem(uid)

    instance.x = nil
    instance.y = nil

    WO.Items.SetState(instance, WO.Items.State.EQUIPPED)

    equipment:Set(slotId, instance)

    instance.locked = nil

    -- Визуал и оружие
    WO.Equipment.ApplyWeapons(ply)
    WO.Visual.Apply(ply)

    Refresh(char, ply)

    WO.Notify(ply, "success", WO.Lang:Get("inventory.equip") .. ": " .. (def.name or instance.class))

    WO.Hook.Run("ItemEquipped", char, instance, slotId)

    return true
end

---------------------------------------------------------------------------
-- Снятие предмета
---------------------------------------------------------------------------

--[[
    Снимает предмет из слота в инвентарь.

    @param ply Player
    @param slotId string
    @return boolean success, string|nil reason
]]
function WO.Equipment.Unequip(ply, slotId)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local equipment = WO.Equipment.Get(char)
    local instance = equipment and equipment:Get(slotId)

    if not instance then return false, "empty_slot" end
    if not WO.Items.IsInventoryAllowed(instance.class) then
        return false, "not_inventory_item"
    end

    if instance.locked then return false, "locked" end

    instance.locked = true

    -- Проверяем место в инвентаре
    local canPlace = container:HasSpace(instance)

    if not canPlace then
        instance.locked = nil
        return false, "no_space"
    end

    equipment:Set(slotId, nil)

    WO.Items.SetState(instance, WO.Items.State.INVENTORY)

    local ok, reason = container:AddItem(instance)

    if not ok then
        -- Откат: возвращаем в слот
        WO.Items.SetState(instance, WO.Items.State.EQUIPPED)
        equipment:Set(slotId, instance)
        instance.locked = nil

        return false, reason or "no_space"
    end

    instance.locked = nil

    -- Визуал и оружие
    WO.Equipment.ApplyWeapons(ply)
    WO.Visual.Apply(ply)

    Refresh(char, ply)

    local def = WO.Items.Get(instance.class)

    WO.Notify(ply, "info", WO.Lang:Get("inventory.unequip") .. ": " .. ((def and def.name) or instance.class))

    WO.Hook.Run("ItemUnequipped", char, instance, slotId)

    return true
end

---------------------------------------------------------------------------
-- Прочность
---------------------------------------------------------------------------

--[[
    Уменьшает прочность экипированного предмета (при использовании).
    При 0 — предмет "сломан" (нельзя использовать).

    @param ply Player
    @param slotId string
    @param amount number
    @return number новая прочность
]]
function WO.Equipment.ReduceDurability(ply, slotId, amount)
    local char = ply:GetCharacter()
    local equipment = char and WO.Equipment.Get(char)
    local instance = equipment and equipment:Get(slotId)

    if not instance or instance.durability == nil then return 0 end

    local def = WO.Items.Get(instance.class)

    if not def or not def.durability then return 0 end

    instance.durability = math.max(0, instance.durability - (tonumber(amount) or 1))

    WO.SaveQueue.MarkDirty(char)
    WO.Equipment.Sync(ply)

    if instance.durability <= 0 then
        WO.Notify(ply, "error", WO.Lang:Get("item.broken") .. ": " .. ((def and def.name) or instance.class))
    end

    return instance.durability
end

---------------------------------------------------------------------------
-- Автоэкипировка стартового оружия (настройка находится в class schema)
---------------------------------------------------------------------------

local function EquipStartingEquipment(char, ply)
    if not WO.Character.IsCharacter(char) or not IsValid(ply) or ply:GetCharacter() ~= char then
        return
    end

    local equipment = WO.Equipment.Get(char)

    if not equipment or equipment.startingEquipmentApplied then return end

    local classDef = WO.Classes and WO.Classes.Get and WO.Classes.Get(char.class)
    local startingEquipment = classDef and classDef.startingEquipment or {}
    local container = WO.Inventory and WO.Inventory.GetContainer and WO.Inventory.GetContainer(char)

    for slotId, itemClass in pairs(startingEquipment) do
        if isstring(slotId) and isstring(itemClass) and equipment:HasSlot(slotId) and
            not equipment:Get(slotId) and container then
            local targetDefinition = WO.Items.Get(itemClass)

            if targetDefinition and targetDefinition.equipment and
                targetDefinition.equipment.slot == slotId then
                for _, instance in pairs(container:GetItems()) do
                    if instance.class == itemClass then
                        local equipped, reason = WO.Equipment.Equip(ply, instance.uid)

                        if equipped then
                            WO.Debug("Starting equipment equipped: " .. itemClass .. " -> " .. slotId ..
                                " for " .. char:GetFullName())
                        else
                            WO.Debug("Starting equipment skipped: " .. itemClass .. " (" ..
                                tostring(reason) .. ")")
                        end

                        break
                    end
                end
            end
        end
    end

    equipment.startingEquipmentApplied = true
    WO.SaveQueue.SaveNow(char)
end

WO.Hook.Add("CharacterSelected", "equipment_starting", EquipStartingEquipment)

---------------------------------------------------------------------------
-- Сохранение / загрузка
---------------------------------------------------------------------------

WO.Hook.Add("CharacterCreate", "equipment", function(char)
    WO.Equipment.Get(char)
end)

WO.Hook.Add("CharacterLoad", "equipment", function(char)
    local rows = WO.Database:Fetch("SELECT * FROM wo_equipment WHERE owner_id = ?", char.id)

    if rows and rows[1] then
        local data = util.JSONToTable(rows[1].slots or "")

        char.equipment = WO.Equipment.Deserialize(data)
    else
        char.equipment = WO.Equipment.New()
    end
end)

WO.Hook.Add("CharacterSave", "equipment", function(char)
    local equipment = WO.Equipment.Get(char)

    if not equipment then return end

    local json = util.TableToJSON(equipment:Serialize())

    WO.Database:Delete("wo_equipment", "owner_id = ?", char.id)

    WO.Database:Insert("wo_equipment", {
        owner_id = char.id,
        slots = json,
    })
end)

WO.Hook.Add("CharacterSync", "equipment", function(char, ply)
    WO.Equipment.Sync(ply)
end)

WO.Hook.Add("CharacterSpawned", "equipment", function(char, ply)
    timer.Simple(0.2, function()
        if IsValid(ply) then
            WO.Equipment.ApplyWeapons(ply)
            WO.Visual.Apply(ply)
        end
    end)
end)

-- Очистка визуалов при выходе
WO.Hook.Add("CharacterUnloaded", "equipment", function(char, ply)
    if IsValid(ply) then
        WO.Visual.Clear(ply)
    end
end)
