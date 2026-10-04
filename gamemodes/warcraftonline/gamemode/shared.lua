--[[
    Warcraft Online — shared bootstrap (server + client).

    Этот файл — оркестратор: он объявляет WO-примитивы загрузки файлов и
    подключает все подсистемы в правильном порядке.

    ВАЖНО ПРО include():
    GMod разрешает пути include()/AddCSLuaFile() относительно ТЕКУЩЕГО файла.
    Поэтому динамическая загрузка (плагины, схемы, сущности, оружие) обязана
    вызываться через WO.Include, тело которого написано ЗДЕСЬ (корень gamemode/),
    чтобы относительные пути вида "plugins/inventory/sv_inventory.lua"
    гарантированно резолвились в gamemode/plugins/inventory/sv_inventory.lua.
]]

GM.Name = "Warcraft Online"
GM.Author = "Warcraft Online Team"
GM.Version = "2.5.0"

WO = WO or {}
WO.Name = "Warcraft Online"
WO.Version = "2.5.0"

---------------------------------------------------------------------------
-- Определение корневой папки гейммода (для file.Find)
---------------------------------------------------------------------------

local function ResolveGamemodeFolder()
    local gm = GAMEMODE or GM
    local candidates = {}

    -- GM.Folder может быть как "gamemodes/<name>", так и "gamemodes/<name>/gamemode" —
    -- проверяем кандидатов наличием shared.lua, чтобы file.Find гарантированно
    -- нашёл config/, ui/, plugins/, schemas/ и т.д.
    if gm and isstring(gm.Folder) and gm.Folder ~= "" then
        candidates[#candidates + 1] = gm.Folder
        candidates[#candidates + 1] = gm.Folder .. "/gamemode"
    end

    if gm and isstring(gm.FolderName) and gm.FolderName ~= "" then
        if string.find(gm.FolderName, "/", 1, true) then
            candidates[#candidates + 1] = gm.FolderName
            candidates[#candidates + 1] = gm.FolderName .. "/gamemode"
        else
            candidates[#candidates + 1] = "gamemodes/" .. gm.FolderName
            candidates[#candidates + 1] = "gamemodes/" .. gm.FolderName .. "/gamemode"
        end
    end

    candidates[#candidates + 1] = "gamemodes/warcraftonline/gamemode"

    for _, path in ipairs(candidates) do
        if file.Exists(path .. "/shared.lua", "GAME") then
            return path
        end
    end

    return "gamemodes/warcraftonline/gamemode"
end

WO.GamemodeFolder = ResolveGamemodeFolder()

-- include/AddCSLuaFile принимают абсолютный путь относительно lua/, но для
-- gamemode он должен начинаться с <FolderName>/gamemode/, НЕ gamemodes/.
local function ResolveGamemodeIncludeFolder()
    local gm = GAMEMODE or GM
    local folderName = gm and gm.FolderName

    if not isstring(folderName) or folderName == "" then
        local folder = gm and gm.Folder

        if isstring(folder) then
            folderName = string.match(string.gsub(folder, "\\", "/"), "^gamemodes/([^/]+)")
        end
    end

    if (not isstring(folderName) or folderName == "") and engine and isfunction(engine.ActiveGamemode) then
        folderName = engine.ActiveGamemode()
    end

    if not isstring(folderName) or folderName == "" then
        folderName = "warcraftonline"
    end

    folderName = string.gsub(folderName, "\\", "/")
    folderName = string.gsub(folderName, "^gamemodes/", "")
    folderName = string.gsub(folderName, "/gamemode/?$", "")
    folderName = string.gsub(folderName, "/+$", "")

    return folderName .. "/gamemode"
end

WO.GamemodeIncludeFolder = ResolveGamemodeIncludeFolder()

---------------------------------------------------------------------------
-- Загрузка файлов
---------------------------------------------------------------------------

-- Определяет realm файла по префиксу имени: sv_ → server, cl_ → client, иначе shared.
local function GuessRealm(path)
    local filename = string.GetFileFromFilename(path)
    local prefix = string.lower(string.sub(filename, 1, 3))

    if prefix == "sv_" then
        return "server"
    elseif prefix == "cl_" then
        return "client"
    end

    return "shared"
end

-- Пути include/AddCSLuaFile должны быть абсолютными относительно lua/.
-- В GMod для gamemode это "<FolderName>/gamemode/..."; относительный путь
-- из загруженного core/plugins-файла разрешался бы относительно вложенной папки.
local function ResolveIncludePath(path)
    if not isstring(path) or path == "" then
        error("WO.Include expects a non-empty path", 2)
    end

    path = string.gsub(path, "\\", "/")

    local diskRoot = string.gsub(WO.GamemodeFolder, "\\", "/")
    diskRoot = string.gsub(diskRoot, "^gamemodes/", "")
    local includeRoot = WO.GamemodeIncludeFolder

    if string.sub(path, 1, 10) == "gamemodes/" then
        path = string.sub(path, 11)
    end

    if path == includeRoot or string.sub(path, 1, #includeRoot + 1) == includeRoot .. "/" then
        return path
    end

    if path == diskRoot then
        return includeRoot
    end

    if string.sub(path, 1, #diskRoot + 1) == diskRoot .. "/" then
        path = string.sub(path, #diskRoot + 2)
    end

    return includeRoot .. "/" .. path
end

--[[
    WO.Include(path, realm)
    Загружает файл гейммода. Путь указывается относительно папки gamemode/.
    realm: "shared" | "server" | "client" (по умолчанию определяется по префиксу файла).
    Результаты include() возвращаются вызывающему коду.
]]
function WO.Include(path, realm)
    realm = realm or GuessRealm(path)
    local resolvedPath = ResolveIncludePath(path)

    if realm == "server" then
        if SERVER then
            return include(resolvedPath)
        end

        return
    elseif realm == "client" then
        if SERVER then
            AddCSLuaFile(resolvedPath)

            return
        end

        return include(resolvedPath)
    end

    if SERVER then
        AddCSLuaFile(resolvedPath)
    end

    return include(resolvedPath)
end

--[[
    WO.IncludeDir(dir, recursive)
    Загружает все .lua-файлы из папки (относительно gamemode/).
    Порядок: сортировка по имени файла. Рекурсия — при recursive = true.
]]
function WO.IncludeDir(dir, recursive)
    local base = WO.GamemodeFolder .. "/" .. dir
    local files, folders = file.Find(base .. "/*", "GAME")

    table.sort(files, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for _, fileName in ipairs(files) do
        if string.EndsWith(fileName, ".lua") then
            WO.Include(dir .. "/" .. fileName)
        end
    end

    if recursive then
        table.sort(folders, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        for _, folderName in ipairs(folders) do
            WO.IncludeDir(dir .. "/" .. folderName, true)
        end
    end
end

---------------------------------------------------------------------------
-- Порядок загрузки
---------------------------------------------------------------------------

-- Ядро
WO.Include("core/sh_core.lua")
WO.Log("Gamemode Lua include root: " .. WO.GamemodeIncludeFolder ..
    " (file search root: " .. WO.GamemodeFolder .. ")")
WO.Include("core/sh_enums.lua")
WO.Include("core/sh_util.lua")
WO.Include("core/sh_hooks.lua")
WO.Include("core/sh_registry.lua")
WO.Include("core/sh_lang.lua")

-- Локализация (регистрирует словари до загрузки конфигов и плагинов)
WO.IncludeDir("localization")

-- Конфигурация
WO.Include("core/sh_config.lua")
WO.IncludeDir("config")

-- Сеть и персонаж
WO.Include("core/sh_network.lua")
WO.Include("core/sh_character.lua")
WO.Include("core/sh_players.lua")
WO.Include("core/sh_character_net.lua")

-- Серверная персистентность
WO.Include("core/sv_database.lua")
WO.Include("core/sv_savequeue.lua")
WO.Include("core/sv_players.lua")
WO.Include("core/sv_characters.lua")

-- Клиентское состояние персонажа
WO.Include("core/cl_character.lua")

-- UI-фреймворк (клиент)
WO.IncludeDir("ui", true)

-- Плагины (метаданные, зависимости, приоритеты)
WO.Include("core/sh_plugins.lua")

-- Контент (data-driven): схемы, оружие, сущности
WO.IncludeDir("schemas", true)
WO.Hook.Run("SchemasLoaded")
WO.IncludeDir("weapons", true)
WO.IncludeDir("entities", true)

-- Финализация загрузки ядра (хук Initialize может быть уже вызван)
WO.Core.FinishLoading()
