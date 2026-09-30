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
GM.Version = "1.0.0"

WO = WO or {}
WO.Name = "Warcraft Online"
WO.Version = "1.0.0"

---------------------------------------------------------------------------
-- Определение корневой папки гейммода (для file.Find)
---------------------------------------------------------------------------

local function ResolveGamemodeFolder()
    local gm = GAMEMODE or GM

    if gm and isstring(gm.Folder) and gm.Folder ~= "" then
        return gm.Folder
    end

    if gm and isstring(gm.FolderName) and gm.FolderName ~= "" then
        if string.find(gm.FolderName, "/", 1, true) then
            return gm.FolderName .. "/gamemode"
        end

        return "gamemodes/" .. gm.FolderName .. "/gamemode"
    end

    return "gamemodes/warcraftonline/gamemode"
end

WO.GamemodeFolder = ResolveGamemodeFolder()

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

--[[
    WO.Include(path, realm)
    Загружает файл гейммода. Путь указывается относительно папки gamemode/.
    realm: "shared" | "server" | "client" (по умолчанию определяется по префиксу файла).
]]
function WO.Include(path, realm)
    realm = realm or GuessRealm(path)

    if realm == "server" then
        if SERVER then
            include(path)
        end
    elseif realm == "client" then
        if SERVER then
            AddCSLuaFile(path)
        else
            include(path)
        end
    else
        if SERVER then
            AddCSLuaFile(path)
        end

        include(path)
    end
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
WO.IncludeDir("weapons", true)
WO.IncludeDir("entities", true)

-- Финализация загрузки ядра (хук Initialize может быть уже вызван)
WO.Core.FinishLoading()
