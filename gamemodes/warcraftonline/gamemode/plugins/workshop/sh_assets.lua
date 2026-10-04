--[[
    Warcraft Online — обнаружение смонтированных Workshop-ассетов (shared).

    Не создаёт зависимости от сторонних SWEP-классов: из Workshop берутся только
    проверенные пути моделей, а боевые параметры остаются в WO-схемах и на сервере.
]]

WO.Workshop = WO.Workshop or {}
WO.Workshop.Catalog = WO.Workshop.Catalog or {}
WO.Workshop.ResolvedModels = WO.Workshop.ResolvedModels or {}

local function Lower(value)
    return string.lower(tostring(value or ""))
end

local function ContainsAny(text, terms)
    if not istable(terms) or #terms == 0 then return true end

    text = Lower(text)

    for _, term in ipairs(terms) do
        local value = Lower(term)

        if value ~= "" and string.find(text, value, 1, true) then
            return true
        end
    end

    return false
end

local function IsMountedModel(path)
    return isstring(path) and path ~= "" and
        string.EndsWith(Lower(path), ".mdl") and file.Exists(path, "GAME") == true
end

local function AppendModel(out, seen, path)
    if not IsMountedModel(path) or seen[path] then return false end

    seen[path] = true
    out[#out + 1] = path

    return true
end

local function ReadLevel(entry, searchableText)
    if not istable(entry) then return nil end

    for _, key in ipairs({ "Level", "level", "NPCLevel", "npcLevel", "MinLevel", "minLevel" }) do
        local level = tonumber(entry[key])

        if level then return math.floor(level) end
    end

    for _, dataKey in ipairs({ "KeyValues", "keyvalues", "Data", "data" }) do
        local data = entry[dataKey]

        if istable(data) then
            for _, key in ipairs({ "level", "Level", "minlevel", "MinLevel" }) do
                local level = tonumber(data[key])

                if level then return math.floor(level) end
            end
        end
    end

    local text = Lower(searchableText)
    local levelText = string.match(text, "level%s*[:#%-]?%s*(%d+)") or
        string.match(text, "(%d+)%s*%-?%s*level")

    return tonumber(levelText)
end

local function ReadNPCModel(entry)
    if not istable(entry) then return nil end

    local direct = entry.Model or entry.model or entry.ModelPath or entry.modelPath or
        entry.NPCModel or entry.npcModel

    if isstring(direct) then return direct end

    if istable(direct) then
        for _, path in ipairs(direct) do
            if isstring(path) then return path end
        end
    end

    for _, dataKey in ipairs({ "KeyValues", "keyvalues", "Data", "data" }) do
        local data = entry[dataKey]

        if istable(data) then
            local path = data.model or data.Model or data.modelPath

            if isstring(path) then return path end
        end
    end

    local class = entry.Class or entry.class

    if isstring(class) and scripted_ents and isfunction(scripted_ents.GetStored) then
        local stored = scripted_ents.GetStored(class)
        local definition = istable(stored) and (stored.t or stored) or nil
        local path = definition and (definition.Model or definition.model)

        if isstring(path) then return path end
    end

    return nil
end

local function NPCSearchText(key, entry)
    return table.concat({
        tostring(key or ""),
        tostring(entry.Name or entry.name or ""),
        tostring(entry.PrintName or entry.printName or ""),
        tostring(entry.Category or entry.category or ""),
        tostring(entry.Class or entry.class or ""),
        tostring(entry.Type or entry.type or ""),
    }, " ")
end

--- Ищет NPC-аддон в стандартном GMod NPC-реестре; выбирает только существующий .mdl.
function WO.Workshop.NPCModels(assetId)
    local catalog = WO.Workshop.Catalog[assetId]
    local search = catalog and catalog.npcSearch
    local found = {}

    if not istable(search) or not list or not isfunction(list.Get) then
        return found
    end

    local registry = list.Get("NPC") or {}

    for key, entry in pairs(registry) do
        if istable(entry) then
            local text = NPCSearchText(key, entry)
            local categoryMatches = ContainsAny(text, search.categoryTerms)
            local nameMatches = ContainsAny(text, search.nameTerms)
            local level = ReadLevel(entry, text)
            local levelMatches = search.level == nil or level == search.level

            if categoryMatches and nameMatches and levelMatches then
                local model = ReadNPCModel(entry)

                if IsMountedModel(model) then
                    found[#found + 1] = {
                        model = model,
                        name = tostring(entry.Name or entry.name or key),
                        category = tostring(entry.Category or entry.category or ""),
                        level = level,
                    }
                end
            end
        end
    end

    table.sort(found, function(a, b)
        if a.name ~= b.name then
            return string.lower(a.name) < string.lower(b.name)
        end

        return a.model < b.model
    end)

    return found
end

--- Проверяет точный runtime-класс NPC: список NPC или реестр SENT.
function WO.Workshop.HasNPCClass(class)
    if not isstring(class) or class == "" then return false end

    if scripted_ents and isfunction(scripted_ents.GetStored) then
        local ok, stored = pcall(scripted_ents.GetStored, class)
        local definition = istable(stored) and (stored.t or stored) or nil

        if ok and istable(definition) then
            return true
        end
    end

    if list and isfunction(list.Get) then
        local registry = list.Get("NPC") or {}

        if istable(registry[class]) then
            return true
        end

        for _, entry in pairs(registry) do
            if istable(entry) and (entry.Class == class or entry.class == class) then
                return true
            end
        end
    end

    return false
end

local function PlayerManagerModels(search)
    local out, seen = {}, {}

    if not player_manager or not isfunction(player_manager.AllValidModels) then
        return out
    end

    local ok, models = pcall(player_manager.AllValidModels)

    if not ok or not istable(models) then return out end

    local nameTerms = istable(search) and search.nameTerms or search
    local genderTerms = istable(search) and search.genderTerms or nil
    local excludeTerms = istable(search) and search.excludeTerms or nil

    local function matches(identity)
        if not ContainsAny(identity, nameTerms) then return false end

        -- player_manager identifiers commonly concatenate race and gender
        -- (e.g. "humanmale00_00"); frontier-based word matching misses those.
        if istable(genderTerms) and #genderTerms > 0 and
            not ContainsAny(identity, genderTerms) then return false end
        if istable(excludeTerms) and ContainsAny(identity, excludeTerms) then return false end

        return true
    end

    local function add(path)
        if IsMountedModel(path) and not seen[path] then
            seen[path] = true
            out[#out + 1] = path
        end
    end

    for name, path in pairs(models) do
        local identity = tostring(name) .. " " .. tostring(path)

        if isstring(path) and matches(identity) then
            add(path)
        elseif isstring(name) and matches(identity) then
            add(name)
        end
    end

    table.sort(out)

    return out
end

--- Ищет установленные player_manager модели по расе и полу.
function WO.Workshop.PlayerModels(search)
    return PlayerManagerModels(search)
end

local scannedModels = nil
local modelScanTruncated = false

local function BuildMountedModelIndex()
    if not (WO.Config.Workshop and WO.Config.Workshop.DeepModelDiscovery) or not isfunction(file.Find) then
        return scannedModels or {}
    end

    if scannedModels then return scannedModels end

    scannedModels = {}

    local limit = math.max(100, math.floor(tonumber(WO.Config.Workshop.ModelScanDirectoryLimit) or 2500))
    local queue = { "models" }
    local cursor = 1
    local visited = {}
    local count = 0

    while cursor <= #queue and count < limit do
        local directory = queue[cursor]
        cursor = cursor + 1

        if not visited[directory] then
            visited[directory] = true
            count = count + 1

            local ok, files, folders = pcall(file.Find, directory .. "/*", "GAME")

            if ok then
                for _, name in ipairs(files or {}) do
                    if string.EndsWith(Lower(name), ".mdl") then
                        local path = directory .. "/" .. name

                        if IsMountedModel(path) then
                            scannedModels[#scannedModels + 1] = path
                        end
                    end
                end

                table.sort(folders or {})

                for _, folder in ipairs(folders or {}) do
                    queue[#queue + 1] = directory .. "/" .. folder
                end
            end
        end
    end

    modelScanTruncated = cursor <= #queue
    table.sort(scannedModels)

    if modelScanTruncated then
        WO.Warn("Workshop model scan reached the directory limit (" .. limit .. "); " ..
            "set WO.Config.Workshop.ModelScanDirectoryLimit higher or add a verified path override")
    end

    return scannedModels
end

local function FindPathModels(search)
    local out = {}

    if not istable(search) then return out end

    for _, path in ipairs(BuildMountedModelIndex()) do
        local lowerPath = Lower(path)

        if ContainsAny(lowerPath, search.nameTerms) then
            local preferred = ContainsAny(lowerPath, search.preferredPathTerms)

            if preferred or search.requirePreferredPath ~= true then
                out[#out + 1] = {
                    model = path,
                    score = preferred and 1 or 0,
                }
            end
        end
    end

    table.sort(out, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.model < b.model
    end)

    return out
end

local function ConfigOverrides(assetId)
    local overrides = WO.Config.WorkshopModelOverrides or {}
    local value = overrides[assetId]

    if isstring(value) then return { value } end
    if istable(value) then return value end

    return {}
end

--- Возвращает только реально смонтированные модели для указанного ассета.
function WO.Workshop.Models(assetId)
    local catalog = WO.Workshop.Catalog[assetId]
    local out, seen = {}, {}

    if not catalog then return out end

    for _, path in ipairs(catalog.models or {}) do
        AppendModel(out, seen, path)
    end

    for _, path in ipairs(ConfigOverrides(assetId)) do
        AppendModel(out, seen, path)
    end

    local npcModels = WO.Workshop.NPCModels(assetId)

    for _, entry in ipairs(npcModels) do
        AppendModel(out, seen, entry.model)
    end

    if istable(catalog.playerModelSearch) then
        for _, path in ipairs(PlayerManagerModels(catalog.playerModelSearch)) do
            AppendModel(out, seen, path)
        end
    end

    if #out == 0 and istable(catalog.modelSearch) then
        for _, entry in ipairs(FindPathModels(catalog.modelSearch)) do
            AppendModel(out, seen, entry.model)
        end
    end

    WO.Workshop.ResolvedModels[assetId] = out[1]

    return out
end

--- Первая существующая модель ассета или безопасный fallback.
function WO.Workshop.ModelOr(assetId, fallback)
    local models = WO.Workshop.Models(assetId)

    return models[1] or fallback
end

--- Первая установленная модель подходящего NPC из набора по имени/категории.
function WO.Workshop.NPCModelOr(assetId, fallback)
    local models = WO.Workshop.NPCModels(assetId)

    if models[1] then
        WO.Workshop.ResolvedModels[assetId] = models[1].model
        return models[1].model
    end

    return WO.Workshop.ModelOr(assetId, fallback)
end

local function WeaponIdentity(class, weapon)
    return table.concat({
        tostring(class or weapon.ClassName or weapon.Class or weapon.class or ""),
        tostring(weapon.PrintName or weapon.printName or ""),
        tostring(weapon.Category or weapon.category or ""),
        tostring(weapon.Base or weapon.base or ""),
    }, " ")
end

--- Ищет модели только у зарегистрированных SWEP; класс стороннего SWEP не выдаётся игроку.
function WO.Workshop.WeaponModels(assetId)
    local catalog = WO.Workshop.Catalog[assetId]
    local search = catalog and catalog.weaponSearch
    local found = {}

    if not istable(search) or not weapons or not isfunction(weapons.GetList) then
        return found
    end

    local ok, registry = pcall(weapons.GetList)

    if not ok or not istable(registry) then return found end

    for _, weapon in ipairs(registry) do
        if istable(weapon) then
            local class = weapon.ClassName or weapon.Class or weapon.class or ""
            local identity = WeaponIdentity(class, weapon)
            local nameMatches = ContainsAny(identity, search.nameTerms)
            local contextMatches = ContainsAny(identity, search.contextTerms)

            if nameMatches and (search.requireContext ~= true or contextMatches) then
                local worldModel = IsMountedModel(weapon.WorldModel) and weapon.WorldModel or nil
                local viewModel = IsMountedModel(weapon.ViewModel) and weapon.ViewModel or nil

                if worldModel or viewModel then
                    found[#found + 1] = {
                        class = tostring(class),
                        name = tostring(weapon.PrintName or weapon.printName or class),
                        category = tostring(weapon.Category or weapon.category or ""),
                        worldModel = worldModel,
                        viewModel = viewModel,
                    }
                end
            end
        end
    end

    table.sort(found, function(a, b)
        if a.name ~= b.name then
            return string.lower(a.name) < string.lower(b.name)
        end

        return a.class < b.class
    end)

    return found
end

--- Возвращает пару проверенных view/world models или fallback-пути.
function WO.Workshop.WeaponModelPair(assetId, fallbackViewModel, fallbackWorldModel)
    local entries = WO.Workshop.WeaponModels(assetId)

    for _, entry in ipairs(entries) do
        if entry.viewModel or entry.worldModel then
            return entry.viewModel or fallbackViewModel,
                entry.worldModel or fallbackWorldModel,
                entry
        end
    end

    return fallbackViewModel, fallbackWorldModel, nil
end

--- Проверяет точный сторонний SWEP-класс в реестре (классы не угадываются).
function WO.Workshop.HasClass(_, class)
    return isstring(class) and weapons and isfunction(weapons.GetStored) and
        weapons.GetStored(class) ~= nil
end

function WO.Workshop.GetDiagnostics()
    local report = {}

    for assetId, catalog in pairs(WO.Workshop.Catalog) do
        report[#report + 1] = {
            id = assetId,
            title = catalog.title or assetId,
            workshopID = catalog.id,
            models = WO.Workshop.Models(assetId),
            weapons = WO.Workshop.WeaponModels(assetId),
            npcClasses = {},
        }
    end

    local runtime = {
        id = "runtime_requirements",
        title = "Required runtime models, NPCs and SWEPs",
        workshopID = "exact classes",
        models = {},
        weapons = {},
        npcClasses = {},
    }

    local seenModels = {}

    for _, race in pairs(WO.Races and WO.Races.GetAll and WO.Races.GetAll() or {}) do
        for _, gender in ipairs(race.genders or {}) do
            for _, path in ipairs((race.models and race.models[gender]) or {}) do
                if not seenModels[path] and WO.Models.Exists(path) then
                    seenModels[path] = true
                    runtime.models[#runtime.models + 1] = path
                end
            end
        end
    end

    for key, class in pairs(WO.Workshop.RequestedSWEPs or {}) do
        local stored = weapons and isfunction(weapons.GetStored) and weapons.GetStored(class)
        runtime.weapons[#runtime.weapons + 1] = {
            class = class,
            name = istable(stored) and (stored.PrintName or stored.ClassName) or key,
            registered = istable(stored),
            worldModel = istable(stored) and stored.WorldModel or nil,
            viewModel = istable(stored) and stored.ViewModel or nil,
        }
    end

    for key, class in pairs(WO.Workshop.RequestedNPCClasses or {}) do
        runtime.npcClasses[#runtime.npcClasses + 1] = {
            key = key,
            class = class,
            registered = WO.Workshop.HasNPCClass(class),
        }
    end

    table.sort(runtime.models)
    table.sort(runtime.weapons, function(a, b) return a.class < b.class end)
    table.sort(runtime.npcClasses, function(a, b) return a.class < b.class end)
    report[#report + 1] = runtime

    table.sort(report, function(a, b) return a.id < b.id end)

    return report, modelScanTruncated
end

if WO.Models and WO.Models.RefreshRaceLists then
    WO.Models.RefreshRaceLists()

    -- Workshop addons may finish mounting shortly after the player joins. Rebuild
    -- the validated client/server model lists briefly during startup; later UI
    -- opens also trigger an on-demand refresh if a previously missing model appears.
    timer.Create("wo_workshop_race_model_refresh", 2, 15, function()
        WO.Models.RefreshRaceLists()
    end)
end

WO.Log("Workshop asset adapter loaded (" .. table.Count(WO.Workshop.Catalog) .. " catalog entries)")
