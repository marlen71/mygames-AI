--[[
    Warcraft Online — core bootstrap.
    Создаёт namespace'ы, логирование, глобальные утилиты.
]]

WO.Core = WO.Core or {}
WO.Util = WO.Util or {}
WO.Hook = WO.Hook or {}
WO.Registry = WO.Registry or {}
WO.Lang = WO.Lang or {}
WO.Config = WO.Config or {}
WO.Net = WO.Net or {}
WO.Database = WO.Database or {}
WO.SaveQueue = WO.SaveQueue or {}
WO.Character = WO.Character or {}
WO.Plugins = WO.Plugins or {}

-- Namespace'ы игровых систем (создаются здесь, наполняются плагинами).
WO.Races = WO.Races or {}
WO.Classes = WO.Classes or {}
WO.Customization = WO.Customization or {}
WO.Items = WO.Items or {}
WO.Inventory = WO.Inventory or {}
WO.Equipment = WO.Equipment or {}
WO.Stats = WO.Stats or {}
WO.Leveling = WO.Leveling or {}
WO.Currency = WO.Currency or {}
WO.Combat = WO.Combat or {}
WO.Interaction = WO.Interaction or {}
WO.Requirements = WO.Requirements or {}
WO.Notify = WO.Notify or {}
WO.Admin = WO.Admin or {}
WO.Sound = WO.Sound or {}
WO.Target = WO.Target or {}
WO.UI = WO.UI or {}
WO.Visual = WO.Visual or {}

---------------------------------------------------------------------------
-- Логирование
---------------------------------------------------------------------------

local PREFIX = "[WO] "

local function FormatArgs(...)
    local args = {...}
    local out = {}

    for i = 1, #args do
        out[i] = tostring(args[i])
    end

    return table.concat(out, " ")
end

--- Информационное сообщение.
function WO.Log(...)
    MsgC(Color(120, 200, 255), PREFIX, color_white, FormatArgs(...) .. "\n")
end

--- Предупреждение.
function WO.Warn(...)
    MsgC(Color(255, 200, 60), PREFIX .. "WARNING: ", color_white, FormatArgs(...) .. "\n")
end

--- Ошибка (не роняет сервер, но должна быть заметна).
function WO.Error(...)
    MsgC(Color(255, 90, 90), PREFIX .. "ERROR: ", color_white, FormatArgs(...) .. "\n")

    if WO.Config and WO.Config.Debug and WO.Config.DebugTracebackOnError then
        debug.traceback()
    end
end

--- Отладочное сообщение (только при WO.Config.Debug).
function WO.Debug(...)
    if not (WO.Config and WO.Config.Debug) then return end

    MsgC(Color(170, 170, 170), PREFIX .. "DEBUG: ", color_white, FormatArgs(...) .. "\n")
end

---------------------------------------------------------------------------
-- Глобальные обёртки (в духе проекта: WO.Log / WO.Warn / WO.Error / WO.Debug)
---------------------------------------------------------------------------

_G.WOLog = WO.Log
_G.WOWarn = WO.Warn
_G.WOError = WO.Error
_G.WODebug = WO.Debug

---------------------------------------------------------------------------
-- Lifecycle загрузки
---------------------------------------------------------------------------

WO.Core.LoadedAt = SysTime()

--- Вызывается в конце shared.lua: сообщает, что все модули загружены.
function WO.Core.FinishLoading()
    WO.Core.IsLoaded = true

    local count = 0

    for _ in pairs(WO.Plugins.Registry or {}) do
        count = count + 1
    end

    WO.Log("Warcraft Online v" .. WO.Version .. " loaded (" .. count .. " plugins, " ..
        (SERVER and "server" or "client") .. ", " .. string.format("%.2f", SysTime() - WO.Core.LoadedAt) .. "s)")
end

---------------------------------------------------------------------------
-- Общие GMod-хуки ядра
---------------------------------------------------------------------------

hook.Add("Initialize", "wo_core_initialize", function()
    WO.Log("Initializing Warcraft Online...")

    if SERVER then
        WO.Database.Initialize()
    end

    WO.Hook.Run("WO_Initialize")
end)
