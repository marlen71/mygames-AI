--[[
    Warcraft Online — уведомления (shared).
    WO.Notify(ply, type, text) — сервер определяет факт события,
    клиент только отображает уведомление.

    WO.Notify — callable-таблица (поддерживает и WO.Notify.Show).
]]

WO.Notify = WO.Notify or {}

-- WO.Notify(ply, "info", "текст") работает как функция (сервер → net, клиент → показ)
setmetatable(WO.Notify, {
    __call = function(_, target, notifyType, text, sound)
        if not isstring(text) then
            text = tostring(text)
        end

        if SERVER then
            if istable(target) then
                for _, ply in ipairs(target) do
                    if IsValid(ply) then
                        WO.Net.Send("Notify.Show", ply, notifyType, text, sound or "")
                    end
                end
            elseif IsValid(target) then
                WO.Net.Send("Notify.Show", target, notifyType, text, sound or "")
            end
        else
            WO.Notify.Show(notifyType, text, sound)
        end
    end,
})

---------------------------------------------------------------------------
-- Net-сообщение
---------------------------------------------------------------------------

WO.Net.Register("Notify.Show", {
    direction = "toclient",
    write = function(notifyType, text, sound)
        net.WriteString(tostring(notifyType))
        net.WriteString(tostring(text))
        net.WriteString(tostring(sound))
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadString()
    end,
    handler = function(_, notifyType, text, sound)
        if CLIENT then
            WO.Notify.Show(notifyType, text, sound)
        end
    end,
})
