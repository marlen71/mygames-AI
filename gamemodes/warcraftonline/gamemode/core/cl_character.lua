--[[
    Warcraft Online — клиентское состояние персонажа (client).
    Кэш активного персонажа и списка персонажей.
    UI-экраны живут в plugins/character и подписываются на WO.Hook-события.
]]

WO.Character.Local = WO.Character.Local or nil
WO.Character.List = WO.Character.List or {}
WO.Character.StateReceived = WO.Character.StateReceived or false

---------------------------------------------------------------------------
-- Хендшейк готовности клиента
-- Сервер не знает, когда клиент закончил загружать Lua, поэтому клиент
-- сам сообщает о готовности и при необходимости повторяет запрос.
---------------------------------------------------------------------------

local function SendReady()
    WO.Net.SendToServer("Client.Ready")
end

hook.Add("InitPostEntity", "wo_client_ready", function()
    timer.Simple(0.5, SendReady)
end)

-- Ретраи: если ответ (Character.List) не пришёл
timer.Simple(3, function()
    if not WO.Character.StateReceived then
        SendReady()
    end
end)

timer.Simple(8, function()
    if not WO.Character.StateReceived then
        SendReady()
    end
end)

---------------------------------------------------------------------------
-- События (вызываются net-обработчиками из core/sh_character_net.lua)
---------------------------------------------------------------------------

-- Открытие меню создания/выбора обрабатывается плагином character:
--   WO.Hook.Add("OpenCharacterCreate", "character_ui", ...)
--   WO.Hook.Add("OpenCharacterSelect", "character_ui", ...)

-- Уведомления об ошибках создания/выбора
local function ShowNotify(kind, text)
    if WO.Notify and WO.Notify.Show then
        WO.Notify.Show(kind, text)
    end
end

WO.Hook.Add("CharacterCreateResult", "core_cl_character", function(success, reason)
    if not success then
        ShowNotify("error", WO.Lang:Get("character.create_failed") .. ": " .. tostring(reason))
    end
end)

WO.Hook.Add("CharacterSelectResult", "core_cl_character", function(success, reason)
    if not success then
        ShowNotify("error", WO.Lang:Get("character.select_failed") .. ": " .. tostring(reason))
    end
end)

WO.Hook.Add("CharacterDeleteResult", "core_cl_character", function(success, reason)
    if success then
        ShowNotify("success", WO.Lang:Get("character.deleted"))
    else
        ShowNotify("error", WO.Lang:Get("character.delete_failed") .. ": " .. tostring(reason))
    end
end)

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- Активный персонаж (клиентский кэш).
function WO.Character.GetLocal()
    return WO.Character.Local
end

--- Список персонажей для экрана выбора.
function WO.Character.GetList()
    return WO.Character.List or {}
end

--- Отправляет запрос создания персонажа.
function WO.Character.RequestCreate(data)
    WO.Net.SendToServer("Character.Create", data)
end

--- Отправляет запрос выбора персонажа.
function WO.Character.RequestSelect(charId)
    WO.Net.SendToServer("Character.Select", charId)
end

--- Отправляет запрос удаления персонажа.
function WO.Character.RequestDelete(charId)
    WO.Net.SendToServer("Character.Delete", charId)
end

--- Выход из персонажа в меню выбора.
function WO.Character.RequestLogout()
    WO.Net.SendToServer("Character.Logout")
end
