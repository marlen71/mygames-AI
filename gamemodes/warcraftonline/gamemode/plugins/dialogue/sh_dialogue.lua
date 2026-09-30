--[[
    Warcraft Online — диалоги (shared): реестр и API.

    Схема диалога (schemas/dialogues/<id>.lua):
        WO.Dialogue.Register({
            id = "marshal_intro",
            nodes = {
                start = {
                    text = "Привет, странник...",
                    options = {
                        { text = "Расскажи о задании", action = "quest:wolves_of_elwynn" },
                        { text = "Показать товары",   action = "vendor" },
                        { text = "Прощай",            action = "close" },
                    },
                },
            },
        })

    Действия (action):
        "close"            — закрыть диалог
        "next:<nodeId>"    — перейти к узлу
        "quest:<questId>"  — предложить квест (или показать состояние)
        "vendor"           — открыть торговлю этого NPC
]]

WO.Dialogue = WO.Dialogue or {}

WO.Dialogue.List = WO.Dialogue.List or {}

--- Регистрирует диалог (duplicate id → ошибка).
function WO.Dialogue.Register(def)
    if not istable(def) or not isstring(def.id) or def.id == "" then
        WO.Error("WO.Dialogue.Register: invalid definition")
        return false
    end

    if WO.Dialogue.List[def.id] then
        WO.Error("WO.Dialogue.Register: duplicate dialogue id '" .. def.id .. "'")
        return false
    end

    if not istable(def.nodes) or not def.nodes.start then
        WO.Error("WO.Dialogue.Register: dialogue '" .. def.id .. "' must have nodes.start")
        return false
    end

    WO.Dialogue.List[def.id] = def

    WO.Debug("Dialogue registered: " .. def.id)

    return true
end

--- Получить диалог по id.
function WO.Dialogue.Get(id)
    return WO.Dialogue.List[id]
end

--- Все диалоги.
function WO.Dialogue.GetAll()
    return WO.Dialogue.List
end

--- Узел диалога.
function WO.Dialogue.GetNode(dialogueId, nodeId)
    local def = WO.Dialogue.List[dialogueId]

    return def and def.nodes[nodeId or "start"] or nil
end

---------------------------------------------------------------------------
-- Net (регистрация ОБЯЗАТЕЛЬНО в shared-файле: клиент должен знать приёмники)
---------------------------------------------------------------------------

WO.Net.Register("Dialogue.Open", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("DialogueOpened", data)
    end,
})

WO.Net.Register("Dialogue.Finish", {
    direction = "toclient",
    handler = function()
        WO.Hook.Run("DialogueClosed")
    end,
})

WO.Net.Register("Dialogue.Choose", {
    direction = "toserver",
    rate = { max = 8, window = 5 },
    write = function(dialogueId, nodeId, optionIndex)
        net.WriteString(dialogueId or "")
        net.WriteString(nodeId or "")
        net.WriteUInt(optionIndex or 1, 8)
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadUInt(8)
    end,
    validate = function(ply, dialogueId, nodeId, optionIndex)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(dialogueId) or not isstring(nodeId) then return false, "invalid_data" end
        if not isnumber(optionIndex) then return false, "invalid_option" end

        return true
    end,
    handler = function(ply, dialogueId, nodeId, optionIndex)
        if SERVER then
            WO.Dialogue.OnChoose(ply, dialogueId, nodeId, optionIndex)
        end
    end,
})

WO.Net.Register("Dialogue.Close", {
    direction = "toserver",
    rate = { max = 5, window = 5 },
    handler = function(ply)
        if SERVER then
            WO.Dialogue.OnClose(ply)
        end
    end,
})
