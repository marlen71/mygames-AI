--[[
    Warcraft Online — призываемые маунты (server-authoritative).
    Предмет камня уникален и bound; внешний horse NPC создаётся только после
    проверки точного wow_npc_8883 в runtime registry.
]]

local config = WO.Config.Mounts or {}
local horseClass = config.horseClass or "wow_npc_8883"
local stoneClass = config.stoneItem or "mount_stone"
local maximumLevel = math.max(1, math.floor(tonumber(config.maximumLevel) or 5))
local maximumHunger = math.max(1, math.floor(tonumber(config.maximumHunger) or 100))
local activeByCharacter = WO.Mounts.ActiveByCharacter

local function GetCharacter(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:HasCharacter() then return nil end

    return ply:GetCharacter()
end

local function FindStone(char, uid)
    local container = char and WO.Inventory and WO.Inventory.GetContainer(char)

    if not container then return nil end

    for itemUID, instance in pairs(container:GetItems() or {}) do
        if instance.class == stoneClass and (not uid or itemUID == uid) then
            return instance
        end
    end

    return nil
end

local function HasHorseClass()
    return WO.Workshop and WO.Workshop.HasNPCClass and WO.Workshop.HasNPCClass(horseClass) == true
end

local function GetMountDefinition(instance)
    local data = istable(instance and instance.data) and instance.data or {}
    local class = data.mountClass or instance and instance.mountClass or horseClass

    return config.definitions and config.definitions[class], class
end

local function MountLevel(instance)
    local data = instance and instance.data or {}
    local definition = GetMountDefinition(instance)
    local cap = math.max(1, math.floor(tonumber(definition and definition.maximumLevel) or maximumLevel))

    return math.Clamp(math.floor(tonumber(data.level) or 1), 1, cap)
end

local function Hunger(instance)
    local data = instance and instance.data or {}
    local definition = GetMountDefinition(instance)
    local cap = math.max(1, math.floor(tonumber(definition and definition.maximumHunger) or maximumHunger))

    return math.Clamp(math.floor(tonumber(data.hunger) or cap), 0, cap)
end

local function MaximumHealth(instance)
    local definition = GetMountDefinition(instance) or {}

    return math.max(1, math.floor((tonumber(definition.baseHealth) or 120) +
        (MountLevel(instance) - 1) * (tonumber(definition.healthPerLevel) or 35)))
end

local function ArmorLevel(instance)
    local data = instance and instance.data or {}
    local definition = GetMountDefinition(instance)
    local cap = math.max(0, math.floor(tonumber(definition and definition.maximumArmorLevel) or 0))

    return math.Clamp(math.floor(tonumber(data.armorLevel) or 0), 0, cap)
end

local function ApplyMountStats(ent, instance)
    if not IsValid(ent) then return end

    local definition = GetMountDefinition(instance) or {}
    local level = MountLevel(instance)
    local maxHealth = MaximumHealth(instance)
    local data = istable(instance.data) and instance.data or {}
    local currentHealth = math.Clamp(math.floor(tonumber(data.health) or maxHealth), 1, maxHealth)
    local armorLevel = ArmorLevel(instance)

    instance.data = data
    data.health = currentHealth
    data.maxHealth = maxHealth
    data.armorLevel = armorLevel

    if isfunction(ent.SetMaxHealth) then ent:SetMaxHealth(maxHealth) end
    if isfunction(ent.SetHealth) then ent:SetHealth(currentHealth) end
    if isfunction(ent.SetNW2Int) then
        ent:SetNW2Int("wo_level", level)
        ent:SetNW2Int("wo_mount_health", currentHealth)
        ent:SetNW2Int("wo_mount_max_health", maxHealth)
        ent:SetNW2Int("wo_mount_hunger", Hunger(instance))
        ent:SetNW2Int("wo_mount_armor", armorLevel)
    end
    if isfunction(ent.SetNW2Float) then
        ent:SetNW2Float("wo_mount_armor_reduction",
            math.Clamp(armorLevel * (tonumber(definition.armorReductionPerLevel) or 0), 0, 0.75))
    end
    if isfunction(ent.SetNW2String) then
        ent:SetNW2String("wo_name", (definition.name or "Лошадь") .. " · ур. " .. level)
        ent:SetNW2String("wo_role", "mount")
    end
end

local function FindOwnedActive(char, ply)
    local keep = IsValid(activeByCharacter[char.id]) and activeByCharacter[char.id] or nil

    -- Reconcile runtime state instead of trusting a single Lua reference: this
    -- also removes duplicates left by a reload or a previously interrupted cleanup.
    for _, ent in ipairs(ents.FindByClass(horseClass) or {}) do
        if IsValid(ent) and ent.WO_MountOwnerCharID == char.id then
            if not keep then
                keep = ent
            elseif ent ~= keep then
                ent.WO_MountDismissing = true
                ent:Remove()
            end
        end
    end

    if IsValid(keep) then
        keep.WO_MountOwner = ply
        activeByCharacter[char.id] = keep
        return keep
    end

    activeByCharacter[char.id] = nil
    return nil
end

local function MarkStoneChanged(ply, char, instance)
    if WO.Inventory and WO.Inventory.SendDelta then
        WO.Inventory.SendDelta(ply, "update", instance)
    end

    if WO.SaveQueue then
        WO.SaveQueue.MarkDirty(char)
    end
end

local function StoreMountHealth(ent, ply, char)
    if not IsValid(ent) or not IsValid(ply) or not char then return false end

    local stone = FindStone(char, ent.WO_MountStoneUID)

    if not stone then return false end

    stone.data = istable(stone.data) and stone.data or {}
    local health = math.Clamp(math.floor(tonumber(ent:Health()) or 0), 0, MaximumHealth(stone))

    if tonumber(stone.data.health) == health then return false end

    stone.data.health = health
    stone.data.maxHealth = MaximumHealth(stone)
    MarkStoneChanged(ply, char, stone)

    return true
end

local function ValidateMountItem(ply, instance, expectedKey)
    if not istable(instance) or not isstring(instance.uid) or not isstring(instance.class) then
        return nil, nil, "invalid_item"
    end

    local char = GetCharacter(ply)
    local container = char and WO.Inventory and WO.Inventory.GetContainer(char)
    local owned = container and container:GetItem(instance.uid)

    if owned ~= instance then return nil, nil, "item_not_owned" end

    local stone = FindStone(char)
    local definition = GetMountDefinition(stone)

    if not stone or not definition then return nil, nil, "no_mount" end
    if definition[expectedKey] ~= instance.class then return nil, nil, "wrong_mount_item" end

    return char, stone, nil, definition
end

function WO.Mounts.HasMount(ply)
    local char = GetCharacter(ply)

    return char ~= nil and FindStone(char) ~= nil
end

function WO.Mounts.Purchase(ply, itemClass, price)
    local char = GetCharacter(ply)

    if not char then return false, "no_character" end
    if itemClass ~= stoneClass then return false, "invalid_mount_item" end
    if not HasHorseClass() then return false, "horse_class_missing" end
    if FindStone(char) then return false, "already_owned" end

    price = math.max(0, math.floor(tonumber(price) or 0))

    if not WO.Currency.CanAfford(ply, price) then
        return false, "not_enough_money"
    end

    local paid, payReason = WO.Currency.Take(ply, price)

    if not paid then return false, payReason or "not_enough_money" end

    local mountDefinition = config.definitions and config.definitions[horseClass]

    if not mountDefinition then
        WO.Currency.Add(ply, price, "mount_purchase_rollback")
        return false, "mount_definition_missing"
    end

    local customData = {
        mountClass = horseClass,
        level = 1,
        experience = 0,
        hunger = tonumber(mountDefinition.maximumHunger) or maximumHunger,
        health = tonumber(mountDefinition.baseHealth) or 120,
        maxHealth = tonumber(mountDefinition.baseHealth) or 120,
        armorLevel = 0,
    }
    local given, giveReason = WO.Inventory.GiveItem(ply, stoneClass, 1, customData)

    if not given then
        WO.Currency.Add(ply, price, "mount_purchase_rollback")
        return false, giveReason or "inventory_full"
    end

    WO.Notify(ply, "success", "Камень призыва лошади добавлен в инвентарь.")
    return true
end

function WO.Mounts.Toggle(ply, instance)
    local char = GetCharacter(ply)

    if not char then return false, "no_character" end
    if not istable(instance) or instance.class ~= stoneClass then return false, "invalid_stone" end

    local stone = FindStone(char, instance.uid)

    if stone ~= instance then return false, "stone_not_owned" end

    local current = FindOwnedActive(char, ply)

    if current then
        StoreMountHealth(current, ply, char)
        activeByCharacter[char.id] = nil
        current.WO_MountDismissing = true

        if IsValid(current) then current:Remove() end

        WO.Notify(ply, "info", "Лошадь возвращена в камень.")
        return true
    end

    if not HasHorseClass() then
        WO.Notify(ply, "error", "Класс лошади wow_npc_8883 не зарегистрирован на сервере.")
        return false, "horse_class_missing"
    end

    local hunger = Hunger(stone)

    if hunger <= 0 then
        WO.Notify(ply, "error", "Лошадь проголодалась. Сначала используйте овёс.")
        return false, "mount_hungry"
    end

    if tonumber(stone.data and stone.data.health) and tonumber(stone.data.health) <= 0 then
        WO.Notify(ply, "error", "Лошадь ранена. Используйте лечебный бальзам.")
        return false, "mount_needs_healing"
    end

    if activeByCharacter[char.id] and IsValid(activeByCharacter[char.id]) then
        return false, "already_summoned"
    end

    local mount = ents.Create(horseClass)

    if not IsValid(mount) then
        WO.Warn("Cannot create exact mount class '" .. horseClass .. "'")
        return false, "spawn_failed"
    end

    local forward = isfunction(ply.GetForward) and ply:GetForward() or Vector(0, 1, 0)
    local right = isfunction(ply.GetRight) and ply:GetRight() or Vector(1, 0, 0)
    local spawnPos = ply:GetPos() - forward * 96 + right * 40

    mount:SetPos(spawnPos)
    mount:SetAngles(Angle(0, (ply:EyeAngles() and ply:EyeAngles().y) or 0, 0))
    if isfunction(mount.SetOwner) then mount:SetOwner(ply) end
    mount:Spawn()
    mount:Activate()

    if not IsValid(mount) then return false, "spawn_failed" end

    mount.WO_MountOwnerCharID = char.id
    mount.WO_MountOwnerSteamID64 = isfunction(ply.SteamID64) and ply:SteamID64() or ""
    mount.WO_MountOwner = ply
    mount.WO_MountClass = select(2, GetMountDefinition(stone)) or horseClass
    mount.WO_MountStoneUID = stone.uid
    mount.WO_MountDismissing = false
    mount:SetNW2String("wo_mount_owner", char.id or "")
    mount:SetNW2Int("wo_mount_hunger", hunger)

    if isfunction(mount.SetUseType) then mount:SetUseType(SIMPLE_USE) end
    if isfunction(mount.AddEntityRelationship) and D_LI then
        mount:AddEntityRelationship(ply, D_LI, 99)
    end
    if isfunction(mount.DropToFloor) then mount:DropToFloor() end

    ApplyMountStats(mount, stone)
    activeByCharacter[char.id] = mount

    WO.Notify(ply, "success", "Лошадь призвана. Используйте камень ещё раз, чтобы отозвать её.")
    return true
end

function WO.Mounts.Feed(ply, instance)
    local char, stone, reason, definition = ValidateMountItem(ply, instance, "feedItem")

    if not char then
        if reason == "no_mount" then WO.Notify(ply, "error", "У вас нет камня призыва маунта.") end
        return false, reason or "no_character"
    end

    local cap = math.max(1, math.floor(tonumber(definition.maximumHunger) or maximumHunger))
    local hunger = Hunger(stone)

    if hunger >= cap then
        WO.Notify(ply, "info", "Маунт уже сыт.")
        return false, "mount_full"
    end

    stone.data = stone.data or {}
    stone.data.hunger = math.min(cap, hunger +
        math.max(1, math.floor(tonumber(definition.hungerPerFeed) or 35)))
    local mount = FindOwnedActive(char, ply)

    if IsValid(mount) then
        mount:SetNW2Int("wo_mount_hunger", stone.data.hunger)
    end

    MarkStoneChanged(ply, char, stone)
    WO.Notify(ply, "success", "Маунт накормлен: сытость " .. stone.data.hunger .. "/" .. cap .. ".")
    return true
end

function WO.Mounts.Upgrade(ply, instance)
    local char, stone, reason, definition = ValidateMountItem(ply, instance, "trainingItem")

    if not char then
        if reason == "no_mount" then WO.Notify(ply, "error", "Сначала приобретите камень призыва маунта.") end
        return false, reason or "no_character"
    end

    local oldLevel = MountLevel(stone)
    local cap = math.max(1, math.floor(tonumber(definition.maximumLevel) or maximumLevel))

    if oldLevel >= cap then
        WO.Notify(ply, "info", "Маунт уже достиг максимального уровня.")
        return false, "mount_max_level"
    end

    if (tonumber(char.level) or 1) <= oldLevel then
        WO.Notify(ply, "error", "Уровень персонажа должен быть выше уровня маунта.")
        return false, "character_level_too_low"
    end

    stone.data = stone.data or {}
    local oldMaxHealth = MaximumHealth(stone)
    local oldHealth = tonumber(stone.data.health) or oldMaxHealth
    stone.data.level = oldLevel + 1
    stone.data.experience = (tonumber(stone.data.experience) or 0) + 100
    local newMaxHealth = MaximumHealth(stone)
    stone.data.health = math.min(newMaxHealth, math.max(1, oldHealth) +
        math.max(0, math.floor(tonumber(definition.healthPerLevel) or 0)))
    stone.data.maxHealth = newMaxHealth

    local mount = FindOwnedActive(char, ply)

    if IsValid(mount) then ApplyMountStats(mount, stone) end

    MarkStoneChanged(ply, char, stone)
    WO.Notify(ply, "success", "Уровень маунта повышен до " .. stone.data.level .. ".")
    return true
end

function WO.Mounts.Heal(ply, instance)
    local char, stone, reason, definition = ValidateMountItem(ply, instance, "healingItem")

    if not char then
        if reason == "no_mount" then WO.Notify(ply, "error", "У вас нет маунта для лечения.") end
        return false, reason or "no_character"
    end

    stone.data = stone.data or {}
    local maximum = MaximumHealth(stone)
    local current = math.Clamp(math.floor(tonumber(stone.data.health) or maximum), 0, maximum)

    if current >= maximum then
        WO.Notify(ply, "info", "Здоровье маунта уже полностью восстановлено.")
        return false, "mount_full_health"
    end

    stone.data.health = math.min(maximum, current +
        math.max(1, math.floor(tonumber(definition.healAmount) or 60)))
    stone.data.maxHealth = maximum

    local mount = FindOwnedActive(char, ply)

    if IsValid(mount) then
        mount:SetHealth(stone.data.health)
        mount:SetNW2Int("wo_mount_health", stone.data.health)
        mount:SetNW2Int("wo_mount_max_health", maximum)
    end

    MarkStoneChanged(ply, char, stone)
    WO.Notify(ply, "success", "Маунт восстановил " .. stone.data.health .. "/" .. maximum .. " HP.")
    return true
end

function WO.Mounts.UpgradeArmor(ply, instance)
    local char, stone, reason, definition = ValidateMountItem(ply, instance, "armorItem")

    if not char then
        if reason == "no_mount" then WO.Notify(ply, "error", "У вас нет маунта для улучшения.") end
        return false, reason or "no_character"
    end

    local current = ArmorLevel(stone)
    local cap = math.max(0, math.floor(tonumber(definition.maximumArmorLevel) or 0))

    if current >= cap then
        WO.Notify(ply, "info", "Броня маунта уже улучшена до максимума.")
        return false, "mount_armor_max"
    end

    if (tonumber(char.level) or 1) < math.max(1, tonumber(definition.minimumArmorLevel) or 1) then
        WO.Notify(ply, "error", "Уровень персонажа недостаточен для этого улучшения.")
        return false, "character_level_too_low"
    end

    stone.data = stone.data or {}
    stone.data.armorLevel = current + 1

    local mount = FindOwnedActive(char, ply)

    if IsValid(mount) then ApplyMountStats(mount, stone) end

    MarkStoneChanged(ply, char, stone)
    WO.Notify(ply, "success", "Броня маунта улучшена: " .. stone.data.armorLevel .. "/" .. cap .. ".")
    return true
end

local function DismissCharacterMount(charId, notify)
    local mount = activeByCharacter[charId]

    if not IsValid(mount) then
        activeByCharacter[charId] = nil
        return false
    end

    local owner = mount.WO_MountOwner
    local char = GetCharacter(owner)

    if char and char.id == charId then StoreMountHealth(mount, owner, char) end

    activeByCharacter[charId] = nil
    mount.WO_MountDismissing = true
    mount:Remove()

    if notify and IsValid(owner) then
        WO.Notify(owner, "info", notify)
    end

    return true
end

local function MountArmorReduction(ent)
    if not IsValid(ent) then return 0 end

    local definition = config.definitions and config.definitions[ent.WO_MountClass or horseClass]
    local level = math.max(0, tonumber(ent:GetNW2Int("wo_mount_armor", 0)) or 0)

    return math.Clamp(level * (tonumber(definition and definition.armorReductionPerLevel) or 0), 0, 0.75)
end

-- Both combat pipelines can hit the external NPC mount class.
WO.Hook.Add("CombatCalculate", "mount_armor", function(info)
    local target = info and info.target

    if IsValid(target) and target.WO_MountOwnerCharID then
        info.amount = math.max(0, tonumber(info.amount) or 0) * (1 - MountArmorReduction(target))
    end
end)

WO.Hook.Add("CombatPostDamage", "mount_health", function(info)
    local target = info and info.target
    local owner = IsValid(target) and target.WO_MountOwner or nil
    local char = GetCharacter(owner)

    if char then StoreMountHealth(target, owner, char) end
end)

hook.Add("EntityTakeDamage", "wo_mount_armor", function(target, damageInfo)
    if not IsValid(target) or not target.WO_MountOwnerCharID or not damageInfo or
        not isfunction(damageInfo.ScaleDamage) then return end

    local multiplier = 1 - MountArmorReduction(target)
    if multiplier < 1 then damageInfo:ScaleDamage(multiplier) end
end)

hook.Add("PostEntityTakeDamage", "wo_mount_health_engine", function(target, _, wasDamageTaken)
    if wasDamageTaken ~= true or not IsValid(target) or not target.WO_MountOwnerCharID then return end

    local owner = target.WO_MountOwner
    local char = GetCharacter(owner)

    if char then StoreMountHealth(target, owner, char) end
end)

-- One central maintenance timer: hunger only decreases while the mount is out.
timer.Create("wo_mount_hunger", 60, 0, function()
    for charId, mount in pairs(activeByCharacter) do
        if not IsValid(mount) then
            activeByCharacter[charId] = nil
        else
            local ply = mount.WO_MountOwner
            local char = GetCharacter(ply)
            local stone = char and FindStone(char, mount.WO_MountStoneUID)

            if not char or char.id ~= charId or not stone or not ply:Alive() then
                DismissCharacterMount(charId)
            else
                StoreMountHealth(mount, ply, char)
                stone.data = stone.data or {}
                local definition = GetMountDefinition(stone) or {}
                local hungerRate = math.max(1, math.floor(tonumber(definition.hungerPerMinute) or
                    tonumber(config.hungerPerMinute) or 1))
                stone.data.hunger = math.max(0, Hunger(stone) - hungerRate)
                mount:SetNW2Int("wo_mount_hunger", stone.data.hunger)
                MarkStoneChanged(ply, char, stone)

                if stone.data.hunger <= 0 then
                    DismissCharacterMount(charId, "Лошадь проголодалась и вернулась в камень.")
                end
            end
        end
    end
end)

hook.Add("EntityRemoved", "wo_mount_entity_removed", function(ent)
    local charId = ent and ent.WO_MountOwnerCharID

    if charId and activeByCharacter[charId] == ent then
        activeByCharacter[charId] = nil
    end
end)

hook.Add("PlayerDeath", "wo_mount_player_death", function(ply)
    local char = IsValid(ply) and ply:GetCharacter()

    if char then DismissCharacterMount(char.id) end
end)

hook.Add("PlayerDisconnected", "wo_mount_disconnect", function(ply)
    local char = IsValid(ply) and ply:GetCharacter()

    if char then DismissCharacterMount(char.id) end
end)

WO.Hook.Add("CharacterUnloaded", "mounts_unload", function(char, ply)
    if char and char.id then DismissCharacterMount(char.id) end
end)

WO.Hook.Add("CharacterLoaded", "mounts_unique_guard", function(char, ply)
    local container = WO.Inventory.GetContainer(char)
    local found = false

    for uid, instance in pairs(container and container:GetItems() or {}) do
        if instance.class == stoneClass then
            if not found then
                found = true
                instance.data = istable(instance.data) and instance.data or {}
                instance.data.mountClass = horseClass
                instance.data.level = MountLevel(instance)
                instance.data.hunger = Hunger(instance)
            else
                -- Repairs old/malformed saves containing duplicate bound mount stones.
                WO.Inventory.RemoveItem(ply, uid, instance.amount or 1)
                WO.Warn("Removed duplicate mount stone from character " .. tostring(char.id))
            end
        end
    end
end)
