--[[
    Warcraft Online — звуковой менеджер (client).
    Все звуки UI/игры берутся из WO.Config.Sounds — не хардкодить в плагинах.

        WO.Sound.PlayLocal("ui_click")
        WO.Sound.PlayLocal("item_pickup", 75, 100)
]]

WO.Sound = WO.Sound or {}

--[[
    Проигрывает звук локально по id из конфига (или напрямую путь).

    @param id string ключ WO.Config.Sounds или путь к звуку
    @param level number громкость 0-100
    @param pitch number тон 0-255
]]
function WO.Sound.PlayLocal(id, level, pitch)
    local soundPath = (WO.Config.Sounds and WO.Config.Sounds[id]) or id

    if not isstring(soundPath) or soundPath == "" then return end

    surface.PlaySound(soundPath)

    -- Примечание: surface.PlaySound не поддерживает level/pitch;
    -- для точного контроля используйте WO.Sound.PlayEntity.
end

--[[
    Проигрывает звук с позиционированием (3D).

    @param pos Vector
    @param id string
    @param level number
    @param pitch number
]]
function WO.Sound.PlayEntity(pos, id, level, pitch)
    local soundPath = (WO.Config.Sounds and WO.Config.Sounds[id]) or id

    if not isstring(soundPath) or soundPath == "" then return end

    sound.Play(soundPath, pos, level or 75, pitch or 100)
end
