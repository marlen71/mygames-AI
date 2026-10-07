--[[
    Warcraft Online — in-world interface for profession shifts.
    Work starts and is handed in at the matching profession NPC. Mini-games
    are drawn over the live world HUD; no profession page or popup menu is used.
]]

WO.ProfessionsUI = WO.ProfessionsUI or {}

local requestedCharacter = nil
local nextSnapshotRequestAt = 0
local nextNoShiftProbeAt = 0
local inputContext = nil
local previousKeys = {}
local sentStates = {}
local sentShiftId = nil

local function LocalCharacter()
    return WO.Character and WO.Character.GetLocal and WO.Character.GetLocal() or nil
end

local function ClientData()
    local char = LocalCharacter()
    local data = WO.Professions.ClientData
    if not char or not data or data.characterId ~= char.id then return nil end
    return data
end

local function CurrentShift()
    local data = ClientData()
    return data and data.shift or nil
end

local function CurrentTask()
    local shift = CurrentShift()
    return shift and shift.task or nil
end

function WO.ProfessionsUI.GetCurrentShift()
    return CurrentShift()
end

local function RequestSnapshot(force)
    local char = LocalCharacter()
    if not char or not isstring(char.id) or char.id == "" then return end

    local data = WO.Professions.ClientData
    if not force and istable(data) and data.characterId == char.id then
        requestedCharacter = char.id
        return
    end

    if requestedCharacter ~= char.id then
        requestedCharacter = char.id
        nextSnapshotRequestAt = 0
    end

    local now = CurTime()
    if now < nextSnapshotRequestAt then return end

    -- Retry while the client has no snapshot for this character. A single
    -- request can be lost during character selection/reconnect; the server's
    -- rate limit is three requests per five seconds.
    nextSnapshotRequestAt = now + 2.5
    WO.Net.SendToServer("Profession.SyncRequest")
end

local function SendInput(shiftId, action, value)
    if not isstring(shiftId) or shiftId == "" then return end
    WO.Net.SendToServer("Profession.WorkInput", shiftId, action, value == true)
end

local function SetInputState(shift, action, isDown)
    isDown = isDown == true
    if sentStates[action] == isDown then return end
    if sentStates[action] == nil and not isDown then
        sentStates[action] = false
        return
    end
    sentStates[action] = isDown
    sentShiftId = shift.id
    SendInput(shift.id, action, isDown)
end

local function KeyDown(key)
    return key ~= nil and input and input.IsKeyDown and input.IsKeyDown(key) == true
end

local function KeyPressed(name, key)
    local down = KeyDown(key)
    local wasDown = previousKeys[name] == true
    previousKeys[name] = down
    return down and not wasDown, down
end

local function ResetInputState()
    if sentShiftId then
        for action, isDown in pairs(sentStates) do
            if isDown then SendInput(sentShiftId, action, false) end
        end
    end

    previousKeys = {}
    sentStates = {}
    sentShiftId = nil
    inputContext = nil
end

local function ResetProfessionSyncState()
    requestedCharacter = nil
    nextSnapshotRequestAt = 0
    nextNoShiftProbeAt = 0
    WO.Professions.ClientData = nil
    ResetInputState()
end

WO.Hook.Add("CharacterSynced", "professions_client_sync", ResetProfessionSyncState)

local function GetInputContext(shift, task)
    return table.concat({ tostring(shift and shift.id or ""), tostring(shift and shift.status or ""),
        tostring(task and task.orderIndex or ""), tostring(task and task.mode or "") }, ":")
end

local function PollDirectionalStates(shift, axis)
    local leftDown = KeyDown(KEY_A)
    local rightDown = KeyDown(KEY_D)
    local upDown = KeyDown(KEY_W)
    local downDown = KeyDown(KEY_S)

    if axis == "vertical" then
        SetInputState(shift, "up", upDown)
        SetInputState(shift, "down", downDown)
    else
        SetInputState(shift, "left", leftDown)
        SetInputState(shift, "right", rightDown)
    end
end

local function PollMiniGameInput(shift, task)
    local gameMode = WO.Professions.GetMiniGame(task.mode)
    local engine = gameMode and gameMode.engine
    if not engine then return end

    if engine == "delivery" then
        local pickupPressed = KeyPressed("pickup", KEY_E)
        if pickupPressed and task.phase == "pickup" then SendInput(shift.id, "pickup", true) end
        return
    elseif engine == "lumber" then
        local usePressed = KeyPressed("lumber_use", KEY_E)

        if usePressed and task.phase == "pickup" then
            SendInput(shift.id, "pickup", true)
        elseif usePressed and task.phase == "carry" then
            SendInput(shift.id, "drop", true)
        elseif task.phase == "work" then
            local directions = {
                { action = "up", key = KEY_W },
                { action = "left", key = KEY_A },
                { action = "down", key = KEY_S },
                { action = "right", key = KEY_D },
            }

            for _, direction in ipairs(directions) do
                local pressed = KeyPressed("lumber_" .. direction.action, direction.key)
                if pressed then SendInput(shift.id, direction.action, true) end
            end
        end

        return
    end

    if engine == "hold" then
        local _, spaceDown = KeyPressed("space", KEY_SPACE)
        SetInputState(shift, "hold", spaceDown)
    elseif engine == "strike" or engine == "rhythm" or engine == "stack" then
        local pressed = KeyPressed("space", KEY_SPACE)
        if pressed then SendInput(shift.id, "strike", true) end
    elseif engine == "tap" then
        local pressed = KeyPressed("space", KEY_SPACE)
        if pressed then SendInput(shift.id, "tap", true) end
    elseif engine == "sequence" or engine == "identify" or engine == "choice" then
        local maxChoice = math.Clamp(#(task.choiceOptions or {}), 1, 4)
        if engine == "sequence" then maxChoice = 4 end
        for choice = 1, maxChoice do
            local key = KEY_1 + choice - 1
            local pressed = KeyPressed("choice" .. choice, key)
            if pressed then SendInput(shift.id, "choice" .. choice, true) end
        end
    elseif engine == "alternate" then
        local leftPressed = KeyPressed("left", KEY_A)
        local rightPressed = KeyPressed("right", KEY_D)
        if leftPressed then SendInput(shift.id, "left", true) end
        if rightPressed then SendInput(shift.id, "right", true) end
    elseif engine == "steer" or engine == "adjust" or engine == "balance" or engine == "sweep" or
        engine == "dodge" then
        PollDirectionalStates(shift, gameMode.axis or "horizontal")
        if engine == "dodge" then
            SetInputState(shift, "up", KeyDown(KEY_W))
            SetInputState(shift, "down", KeyDown(KEY_S))
        end
    elseif engine == "precision" then
        local leftPressed = KeyPressed("left", KEY_A)
        local rightPressed = KeyPressed("right", KEY_D)
        local confirmPressed = KeyPressed("confirm", KEY_SPACE)
        if leftPressed then SendInput(shift.id, "left", true) end
        if rightPressed then SendInput(shift.id, "right", true) end
        if confirmPressed then SendInput(shift.id, "confirm", true) end
    end
end

local function DrawText(text, font, x, y, color, alignX, alignY)
    draw.SimpleTextOutlined(tostring(text or ""), font or "WO.Small", x, y,
        color or WO.UI.Colors.text, alignX or TEXT_ALIGN_LEFT, alignY or TEXT_ALIGN_TOP,
        1, Color(0, 0, 0, 220))
end

local function DrawProgress(x, y, w, h, value, color)
    draw.RoundedBox(4, x, y, w, h, Color(12, 18, 28, 240))
    draw.RoundedBox(4, x, y, math.max(0, math.floor(w * math.Clamp(value or 0, 0, 1))), h,
        color or WO.UI.Colors.good)
    surface.SetDrawColor(175, 190, 210, 160)
    surface.DrawOutlinedRect(x, y, w, h, 1)
end

local function CursorPosition(task)
    local elapsed = math.max(0, CurTime() - (tonumber(task.clientStartedAt) or CurTime()))
    return 0.5 + 0.44 * math.sin(elapsed * (tonumber(task.speed) or 1) +
        (tonumber(task.phaseOffset) or 0))
end

local function DrawFishIcon(x, y)
    surface.SetDrawColor(236, 243, 250, 255)
    surface.DrawPoly({
        { x = x, y = y }, { x = x + 9, y = y - 6 }, { x = x + 20, y = y - 4 },
        { x = x + 26, y = y }, { x = x + 20, y = y + 4 }, { x = x + 9, y = y + 6 },
    })
    surface.DrawPoly({ { x = x, y = y }, { x = x - 7, y = y - 6 }, { x = x - 7, y = y + 6 } })
    surface.SetDrawColor(18, 22, 30, 255)
    surface.DrawRect(x + 18, y - 2, 2, 2)
end

local function DrawFishing(task, x, y, w)
    local bx, by, bw, bh = x + 24, y + 74, 44, 116
    local center = math.Clamp(tonumber(task.zoneCenter) or 0.5, 0, 1)
    local zoneWidth = math.Clamp(tonumber(task.zoneWidth) or 0.2, 0.08, 0.5)
    local marker = CursorPosition(task)
    local markerY = by + bh - marker * bh
    local greenY = by + bh - (center + zoneWidth * 0.5) * bh

    draw.RoundedBox(4, bx, by, bw, bh, Color(9, 18, 30, 255))
    surface.SetDrawColor(64, 190, 113, 235)
    surface.DrawRect(bx + 3, greenY, bw - 6, bh * zoneWidth)
    surface.SetDrawColor(245, 248, 252, 255)
    surface.DrawRect(bx - 5, markerY - 3, bw + 10, 6)
    DrawFishIcon(bx + bw + 10, markerY)
    DrawText("РЫБА", "WO.Tiny", x + 86, by + 7, WO.UI.Colors.accent)
    DrawText("Следите за клёвом", "WO.Small", x + 86, by + 31)
    DrawText("Удерживайте ПРОБЕЛ", "WO.Tiny", x + 86, by + 56, WO.UI.Colors.textDim)
    DrawProgress(x + 86, by + 81, math.max(120, w - 120), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawStrike(task, x, y, w, mode)
    local engine = mode.engine
    local label = engine == "stack" and "КАМЕННАЯ КЛАДКА" or
        engine == "rhythm" and "РАБОЧИЙ РИТМ" or "РАБОЧАЯ ЗОНА"
    DrawText(label, "WO.Tiny", x + 26, y + 82, WO.UI.Colors.accent)

    local iconX, iconY = x + w - 66, y + 97
    surface.SetDrawColor(176, 141, 85, 245)
    if task.mode == "chopping" then
        surface.DrawLine(iconX - 18, iconY + 6, iconX + 18, iconY - 6)
        surface.DrawLine(iconX - 12, iconY + 12, iconX - 8, iconY - 12)
        surface.DrawLine(iconX - 8, iconY - 12, iconX + 2, iconY - 19)
    elseif task.mode == "smithing" then
        draw.RoundedBox(2, iconX - 18, iconY + 5, 36, 8, Color(135, 144, 157, 255))
        draw.RoundedBox(2, iconX - 12, iconY - 1, 24, 8, Color(171, 182, 196, 255))
        surface.SetDrawColor(248, 138, 75, 240)
        surface.DrawRect(iconX - 7, iconY - 7, 14, 5)
    elseif task.mode == "masonry" then
        draw.RoundedBox(2, iconX - 20, iconY - 12, 40, 10, Color(166, 145, 120, 255))
        draw.RoundedBox(2, iconX - 16, iconY, 32, 10, Color(137, 117, 97, 255))
        surface.SetDrawColor(54, 43, 34, 255)
        surface.DrawLine(iconX, iconY - 11, iconX, iconY - 3)
        surface.DrawLine(iconX - 8, iconY + 1, iconX - 8, iconY + 8)
    elseif task.mode == "ropemaking" then
        surface.SetDrawColor(205, 179, 124, 245)
        surface.DrawLine(iconX - 18, iconY - 12, iconX + 15, iconY + 12)
        surface.DrawLine(iconX - 18, iconY + 12, iconX + 15, iconY - 12)
        surface.DrawLine(iconX - 10, iconY - 15, iconX + 18, iconY + 8)
    end
    local bx, by, bw, bh = x + 26, y + 112, math.max(180, w - 52), 22
    local center = math.Clamp(tonumber(task.zoneCenter) or 0.5, 0, 1)
    local zoneWidth = math.Clamp(tonumber(task.zoneWidth) or 0.2, 0.08, 0.5)
    local marker = CursorPosition(task)
    draw.RoundedBox(4, bx, by, bw, bh, Color(10, 16, 25, 255))
    surface.SetDrawColor(64, 190, 113, 225)
    surface.DrawRect(bx + (center - zoneWidth * 0.5) * bw, by + 2, bw * zoneWidth, bh - 4)
    surface.SetDrawColor(245, 248, 252, 255)
    surface.DrawRect(bx + marker * bw - 3, by - 5, 6, bh + 10)
    DrawText(engine == "stack" and "Совместите камень со швом" or
        "Нажмите ПРОБЕЛ в нужный момент", "WO.Small", x + 26, y + 149)
    DrawProgress(x + 26, y + 181, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawTap(task, x, y, w)
    local cx, cy = x + 108, y + 136
    draw.RoundedBox(24, cx - 44, cy - 38, 88, 76, Color(69, 78, 91, 255))
    surface.SetDrawColor(185, 195, 207, 255)
    surface.DrawLine(cx - 22, cy - 13, cx + 5, cy + 3)
    surface.DrawLine(cx + 5, cy + 3, cx - 6, cy + 23)
    surface.DrawLine(cx + 8, cy - 24, cx + 5, cy + 3)
    DrawText("Удары", "WO.Small", x + 174, y + 100, WO.UI.Colors.accent)
    DrawText("ПРОБЕЛ", "WO.Body", x + 174, y + 128)
    DrawProgress(x + 174, y + 164, math.max(140, w - 204), 16, task.progress,
        WO.UI.Colors.accent)
end

local function DrawSequence(task, x, y, w, mode)
    local sequence = task.sequence or {}
    local count = math.max(1, #sequence)
    local gap, boxW = 8, math.min(64, math.floor((w - 70 - gap * (count - 1)) / count))
    local startX, by = x + 26, y + 115

    for index, value in ipairs(sequence) do
        local bx = startX + (index - 1) * (boxW + gap)
        local active = index == (task.sequenceIndex or 1)
        local complete = index < (task.sequenceIndex or 1)
        local color = complete and WO.UI.Colors.good or
            active and WO.UI.Colors.accent or WO.UI.Colors.panelDark
        draw.RoundedBox(5, bx, by, boxW, 42, color)
        DrawText(string.match(value, "([1-4])") or "?", "WO.Body",
            bx + boxW * 0.5, by + 20, WO.UI.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    DrawText(mode.controls or "Повторите последовательность клавишами 1–4.",
        "WO.Small", x + 26, y + 82, WO.UI.Colors.textDim)
    DrawProgress(x + 26, y + 176, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawAlternate(task, x, y, w, mode)
    local expected = task.expectedInput == "right" and "D  ▶" or "◀  A"
    if task.mode == "baking" then
        draw.RoundedBox(20, x + w - 94, y + 95, 58, 42, Color(205, 176, 122, 255))
        surface.SetDrawColor(239, 218, 174, 255)
        surface.DrawLine(x + w - 76, y + 108, x + w - 52, y + 124)
    elseif task.mode == "sawing" then
        draw.RoundedBox(3, x + w - 101, y + 103, 64, 24, Color(145, 102, 60, 255))
        surface.SetDrawColor(210, 217, 225, 255)
        for tooth = 0, 5 do
            surface.DrawLine(x + w - 84 + tooth * 7, y + 94,
                x + w - 79 + tooth * 7, y + 104)
        end
    elseif task.mode == "loading" then
        draw.RoundedBox(3, x + w - 96, y + 97, 28, 28, Color(161, 117, 61, 255))
        draw.RoundedBox(3, x + w - 67, y + 110, 28, 28, Color(187, 141, 74, 255))
        surface.SetDrawColor(91, 62, 34, 255)
        surface.DrawLine(x + w - 82, y + 97, x + w - 82, y + 125)
        surface.DrawLine(x + w - 53, y + 110, x + w - 53, y + 138)
    end

    DrawText(mode.label or "Чередуйте движения", "WO.Tiny", x + 26, y + 88,
        WO.UI.Colors.accent)
    DrawText(expected, "WO.Title", x + 26, y + 113, WO.UI.Colors.text)
    DrawText("Следующее движение: " .. expected, "WO.Small", x + 180, y + 124,
        WO.UI.Colors.textDim)
    DrawProgress(x + 26, y + 176, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawChoice(task, x, y, w)
    local options = task.choiceOptions or { "1", "2", "3" }
    local count = math.max(1, #options)
    local gap = 8
    local boxW = math.floor((w - 52 - gap * (count - 1)) / count)
    DrawText(task.choiceTarget or "Выберите верный вариант", "WO.Small",
        x + 26, y + 79, WO.UI.Colors.textDim)

    for index, label in ipairs(options) do
        local bx = x + 26 + (index - 1) * (boxW + gap)
        draw.RoundedBox(6, bx, y + 111, boxW, 48, Color(44, 57, 76, 240))
        DrawText(index .. "  " .. label, count > 3 and "WO.Tiny" or "WO.Small",
            bx + boxW * 0.5, y + 135, WO.UI.Colors.text,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    DrawProgress(x + 26, y + 176, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawSteering(task, x, y, w, engine, mode)
    DrawText(mode.label or "Управление", "WO.Tiny", x + 26, y + 82, WO.UI.Colors.accent)
    local position = math.Clamp(tonumber(task.cursorPosition) or 0.5, 0, 1)
    local center = math.Clamp(tonumber(task.targetCenter) or 0.5, 0, 1)
    local width = math.Clamp(tonumber(task.targetWidth or task.zoneWidth) or 0.22, 0.08, 0.5)
    local axisText = mode.axis == "vertical" and "W / S" or "A / D"

    if engine == "adjust" then
        local bx, by, bw, bh = x + 48, y + 104, 28, 66
        draw.RoundedBox(7, bx, by, bw, bh, Color(10, 16, 25, 255))
        surface.SetDrawColor(238, 112, 68, 230)
        surface.DrawRect(bx + 5, by + bh - (center + width * 0.5) * bh, bw - 10, width * bh)
        surface.SetDrawColor(245, 248, 252, 255)
        surface.DrawRect(bx - 5, by + bh - position * bh - 3, bw + 10, 6)
        DrawText("ЖАР", "WO.Tiny", bx + 44, by + 10, WO.UI.Colors.accent)
        DrawText("КОТЁЛ", "WO.Small", bx + 44, by + 31)
        DrawText("W / S регулируют температуру", "WO.Tiny", bx + 44, by + 51,
            WO.UI.Colors.textDim)
    else
        local bx, by, bw, bh = x + 26, y + 119, math.max(180, w - 52), 24
        draw.RoundedBox(5, bx, by, bw, bh, Color(10, 16, 25, 255))
        surface.SetDrawColor(64, 190, 113, 225)
        surface.DrawRect(bx + (center - width * 0.5) * bw, by + 2, width * bw, bh - 4)
        surface.SetDrawColor(245, 248, 252, 255)
        surface.DrawRect(bx + position * bw - 4, by - 5, 8, bh + 10)

        if engine == "steer" then
            surface.SetDrawColor(196, 155, 75, 255)
            surface.DrawRect(bx + 8, by - 9, 4, bh + 18)
            surface.DrawRect(bx + bw - 12, by - 9, 4, bh + 18)
            DrawText("ВОРОТА", "WO.Tiny", bx + bw - 56, by - 22, WO.UI.Colors.accent)
        elseif engine == "balance" then
            surface.SetDrawColor(205, 175, 115, 255)
            surface.DrawLine(bx + 30, by - 11, bx + bw - 30, by - 11)
            draw.RoundedBox(3, bx + 27, by - 19, 14, 9, Color(81, 148, 204, 255))
            draw.RoundedBox(3, bx + bw - 41, by - 19, 14, 9, Color(81, 148, 204, 255))
        elseif engine == "sweep" then
            surface.SetDrawColor(176, 153, 116, 235)
            for dust = 1, 5 do
                surface.DrawRect(bx + dust * bw / 6, by + 7 + (dust % 2) * 4, 4, 4)
            end
        end
    end

    if engine ~= "adjust" then
        DrawText(axisText .. " удерживают цель в отмеченной зоне", "WO.Small", x + 26, y + 152,
            WO.UI.Colors.textDim)
    end
    DrawProgress(x + 26, y + 181, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawPrecision(task, x, y, w)
    local bx, by, bw, bh = x + 26, y + 116, math.max(180, w - 52), 24
    local center = math.Clamp(tonumber(task.targetCenter) or 0.5, 0, 1)
    local cursor = math.Clamp(tonumber(task.cursorPosition) or 0.5, 0, 1)
    local zone = math.Clamp(tonumber(task.zoneWidth) or 0.18, 0.08, 0.5)
    DrawText("ОГРАНКА · НАВЕДИТЕ РЕЗЕЦ", "WO.Tiny", x + 26, y + 82, WO.UI.Colors.accent)
    draw.RoundedBox(5, bx, by, bw, bh, Color(10, 16, 25, 255))
    surface.SetDrawColor(89, 167, 220, 230)
    surface.DrawRect(bx + (center - zone * 0.5) * bw, by + 2, zone * bw, bh - 4)
    surface.SetDrawColor(250, 220, 120, 255)
    surface.DrawRect(bx + cursor * bw - 4, by - 6, 8, bh + 12)
    DrawText("A / D — навести · ПРОБЕЛ — резать", "WO.Small", x + 26, y + 151)
    DrawProgress(x + 26, y + 181, math.max(180, w - 52), 14, task.progress,
        WO.UI.Colors.good)
end

local function DrawDodge(task, x, y)
    local bx, by, size = x + 26, y + 78, 126
    draw.RoundedBox(5, bx, by, size, size, Color(15, 25, 27, 245))
    surface.SetDrawColor(70, 104, 75, 170)
    for line = 1, 3 do
        surface.DrawLine(bx, by + line * size * 0.25, bx + size, by + line * size * 0.25)
        surface.DrawLine(bx + line * size * 0.25, by, bx + line * size * 0.25, by + size)
    end

    local targetX = bx + (task.targetX or 0.7) * size
    local targetY = by + (task.targetY or 0.7) * size
    local hazardX = bx + (task.hazardX or 0.8) * size
    local hazardY = by + (task.hazardY or 0.25) * size
    local playerX = bx + (task.playerX or 0.2) * size
    local playerY = by + (task.playerY or 0.5) * size
    draw.RoundedBox(4, targetX - 6, targetY - 6, 12, 12, WO.UI.Colors.good)
    draw.RoundedBox(5, hazardX - 6, hazardY - 6, 12, 12, WO.UI.Colors.danger)
    draw.RoundedBox(5, playerX - 6, playerY - 6, 12, 12, WO.UI.Colors.accent)
    DrawText("Соты", "WO.Tiny", x + 174, y + 95, WO.UI.Colors.good)
    DrawText("Пчела", "WO.Tiny", x + 174, y + 120, WO.UI.Colors.danger)
    DrawText("W / A / S / D", "WO.Small", x + 174, y + 154)
    DrawProgress(x + 174, y + 184, 220, 14, task.progress, WO.UI.Colors.good)
end

local function DrawDelivery(task, shift, x, y, w)
    if task.phase == "pickup" then
        DrawText("ГРУЗ ОЖИДАЕТ У ТОЧКИ", "WO.Tiny", x + 26, y + 88, WO.UI.Colors.accent)
        DrawText("Подойдите к грузу и нажмите E.", "WO.Body", x + 26, y + 119)
        DrawText(task.instruction or "", "WO.Small", x + 26, y + 158, WO.UI.Colors.textDim)
    else
        local distance = math.max(0, tonumber(task.carriedDistance) or 0)
        local required = math.max(1, tonumber(task.requiredDistance) or 1)
        DrawText("НЕСИТЕ ГРУЗ ЧЕРЕЗ МИР", "WO.Tiny", x + 26, y + 84, WO.UI.Colors.accent)
        DrawText(math.floor(math.min(distance, required)) .. " / " .. required .. " units",
            "WO.Body", x + 26, y + 111)
        DrawProgress(x + 26, y + 150, math.max(180, w - 52), 18,
            distance / required, WO.UI.Colors.accent)
        DrawText(task.instruction or "", "WO.Small", x + 26, y + 180, WO.UI.Colors.textDim)
    end
end

local function PlayerDistanceFrom(position)
    local ply = LocalPlayer()
    if not isvector(position) or not IsValid(ply) then return nil end
    return ply:GetPos():Distance(position)
end

local function IsNearLumberPickup()
    local site = WO.Config and WO.Config.ProfessionWorksites and
        WO.Config.ProfessionWorksites.lumberjack
    local ply = LocalPlayer()

    if not istable(site) or not isvector(site.pickupPos) or
        not game or not isfunction(game.GetMap) or game.GetMap() ~= site.map or
        not IsValid(ply) then
        return false
    end

    local radius = math.max(1, tonumber(site.interactionRadius) or 160)
    return ply:GetPos():Distance(site.pickupPos) <= radius
end

local function DrawLumberSequence(task, shift, def, rank)
    local keyLabels = { up = "W", left = "A", down = "S", right = "D" }
    local length = math.max(1, math.floor(tonumber(task.sequenceLength) or 6))
    local completed = math.Clamp(math.floor(tonumber(task.sequenceCount) or
        ((tonumber(task.sequenceIndex) or 1) - 1)), 0, length)
    local prompt = keyLabels[task.sequencePrompt] or "?"
    local screenWidth, screenHeight = ScrW(), ScrH()
    local panelWidth = math.min(500, screenWidth - 32)
    local panelHeight = 286
    local panelX = (screenWidth - panelWidth) * 0.5
    local panelY = math.max(16, screenHeight * 0.62 - panelHeight * 0.5)
    local centerX = panelX + panelWidth * 0.5
    local keyY = panelY + 103
    local feedback = "Нажмите показанную клавишу."
    local feedbackColor = WO.UI.Colors.textDim

    if task.sequenceLastInputCorrect == true then
        feedback = "Верно! Следующая подсказка уже готова."
        feedbackColor = WO.UI.Colors.good
    elseif task.sequenceLastInputCorrect == false then
        feedback = "Не та клавиша — попробуйте ещё раз."
        feedbackColor = WO.UI.Colors.bad
    end

    draw.RoundedBox(12, panelX, panelY, panelWidth, panelHeight, Color(9, 14, 23, 244))
    surface.SetDrawColor(196, 155, 75, 245)
    surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight, 2)
    DrawText((def and def.name or "Лесоруб") .. " · " .. (rank and rank.name or "Дровосек"),
        "WO.Subtitle", panelX + 22, panelY + 15, WO.UI.Colors.accent)
    DrawText("ДОСТАВЛЕНО: " .. tostring(math.max(0, tonumber(shift.completedOrders) or 0)),
        "WO.Tiny", panelX + panelWidth - 22, panelY + 20, WO.UI.Colors.textDim,
        TEXT_ALIGN_RIGHT)
    DrawText("ЗАГОТОВКА БРЁВЕН", "WO.Subtitle", centerX, panelY + 48,
        WO.UI.Colors.accent, TEXT_ALIGN_CENTER)
    DrawText("Нажмите показанную клавишу", "WO.Small", centerX, panelY + 77,
        WO.UI.Colors.text, TEXT_ALIGN_CENTER)

    draw.RoundedBox(10, centerX - 42, keyY, 84, 72, Color(37, 47, 64, 255))
    surface.SetDrawColor(212, 175, 55, 255)
    surface.DrawOutlinedRect(centerX - 42, keyY, 84, 72, 3)
    DrawText(prompt, "WO.Title", centerX, keyY + 36, WO.UI.Colors.text,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    DrawText("Допустимые клавиши: W · A · S · D", "WO.Tiny", centerX, panelY + 181,
        WO.UI.Colors.textDim, TEXT_ALIGN_CENTER)
    DrawText("Правильные нажатия: " .. tostring(completed) .. " / " .. tostring(length),
        "WO.Body", centerX, panelY + 202, WO.UI.Colors.text, TEXT_ALIGN_CENTER)
    DrawProgress(panelX + 42, panelY + 229, panelWidth - 84, 14,
        tonumber(task.progress) or completed / length, WO.UI.Colors.good)
    DrawText(feedback, "WO.Tiny", centerX, panelY + 255, feedbackColor,
        TEXT_ALIGN_CENTER)
end

local function DrawLumberDelivery(task, x, y, w)
    local radius = math.max(1, tonumber(task.interactionRadius) or 160)

    if task.phase == "pickup" then
        local distance = PlayerDistanceFrom(task.pickupPos)
        local atPickup = distance and distance <= radius
        local failed = task.sequenceLastInputCorrect == false
        local headline = failed and "МИНИ-ИГРА ПРОВАЛЕНА" or "ЛЕСНАЯ ЗАГОТОВКА"
        local prompt
        if atPickup then
            prompt = failed and "У штабеля — нажмите E, чтобы начать заново." or
                "У штабеля — нажмите E, чтобы начать."
        elseif failed then
            prompt = "Вернитесь к штабелю · E для повтора: " ..
                tostring(math.floor(distance or 0)) .. " ед."
        else
            prompt = "Вернитесь к брёвнам: " .. tostring(math.floor(distance or 0)) .. " ед."
        end
        DrawText(headline, "WO.Tiny", x + 26, y + 87,
            failed and WO.UI.Colors.bad or WO.UI.Colors.accent)
        DrawText(prompt, "WO.Body", x + 26, y + 116,
            failed and WO.UI.Colors.bad or WO.UI.Colors.text)
        DrawText(task.instruction or "", "WO.Small", x + 26, y + 157, WO.UI.Colors.textDim)
    elseif task.phase == "carry" then
        local distance = PlayerDistanceFrom(task.deliveryPos)
        local routeDistance = math.max(1, tonumber(task.routeDistance) or
            tonumber(task.requiredDistance) or 1)
        local remaining = distance or routeDistance
        local progress = 1 - math.Clamp(remaining / routeDistance, 0, 1)

        DrawText("СКЛАД БРЁВЕН", "WO.Tiny", x + 26, y + 83, WO.UI.Colors.accent)
        DrawText(distance and distance <= radius and "У склада — нажмите E, чтобы сдать." or
            ("До склада: " .. tostring(math.floor(remaining)) .. " ед."),
            "WO.Body", x + 26, y + 110)
        DrawProgress(x + 26, y + 148, math.max(180, w - 52), 16, progress,
            WO.UI.Colors.accent)
        DrawText("При переносе бег, прыжок и смена оружия заблокированы.",
            "WO.Tiny", x + 26, y + 177, WO.UI.Colors.textDim)
    end
end

local function DrawLumberWorldMarker(task, shift)
    if not shift or shift.status ~= "working" then return end

    local carrying = task.phase == "carry"
    local position = carrying and task.deliveryPos or task.pickupPos
    if not isvector(position) then return end

    local screen = position:ToScreen()
    if not screen then return end

    local x, y = tonumber(screen.x), tonumber(screen.y)
    if screen.visible ~= true or not x or not y then
        local ply = LocalPlayer()
        if not IsValid(ply) or not isfunction(ply.EyePos) or not isfunction(ply.EyeAngles) then return end

        local directionAngles = (position - ply:EyePos()):Angle()
        local relativeYaw = ((directionAngles.y - ply:EyeAngles().y + 180) % 360) - 180
        local radians = math.rad(relativeYaw)
        local directionX, directionY = math.sin(radians), -math.cos(radians)
        local halfWidth, halfHeight = ScrW() * 0.5, ScrH() * 0.5
        local edgeX, edgeY = math.max(1, halfWidth - 48), math.max(1, halfHeight - 64)
        local scale = math.min(edgeX / math.max(math.abs(directionX), 0.001),
            edgeY / math.max(math.abs(directionY), 0.001))
        x = halfWidth + directionX * scale
        y = halfHeight + directionY * scale
    end

    local label = carrying and "СКЛАД БРЁВЕН" or "ШТАБЕЛЬ БРЁВЕН"
    draw.RoundedBox(12, x - 12, y - 12, 24, 24, Color(8, 12, 18, 245))
    surface.SetDrawColor(212, 175, 55, 255)
    surface.DrawOutlinedRect(x - 12, y - 12, 24, 24, 2)
    draw.RoundedBox(6, x - 76, y + 17, 152, 24, Color(8, 12, 18, 238))
    DrawText(label, "WO.Tiny", x, y + 29, WO.UI.Colors.accent,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawWorldShift()
    local shift = CurrentShift()
    if not shift then return end

    local def = WO.Professions.Get(shift.professionId)
    if not def then return end

    local task = shift.task
    local mode = task and WO.Professions.GetMiniGame(task.mode) or nil
    local rank = def.ranks[math.Clamp(tonumber(shift.rank) or 1, 1, 3)]

    local w, h = math.min(470, ScrW() - 32), 246
    local x, y = 24, math.max(24, ScrH() - h - 150)

    draw.RoundedBox(10, x, y, w, h, Color(12, 17, 25, 232))
    surface.SetDrawColor(196, 155, 75, 235)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    DrawText(def.name .. " · " .. (rank and rank.name or ""), "WO.Subtitle",
        x + 18, y + 12, WO.UI.Colors.accent)

    local progressText
    if shift.professionId == "lumberjack" then
        progressText = "Доставлено связок: " .. tostring(math.max(0,
            tonumber(shift.completedOrders) or 0)) .. " · расчёт — у работодателя"
    else
        progressText = "Заказ " .. tostring(math.min((shift.completedOrders or 0) + 1,
            shift.requiredOrders or 3)) .. "/" .. tostring(shift.requiredOrders or 3)
    end
    DrawText(progressText, "WO.Tiny", x + 18, y + 43, WO.UI.Colors.textDim)

    if shift.status == "ready" then
        DrawText("Заказы готовы. Вернитесь к «" .. tostring(shift.npcName or "работодателю") .. "».",
            "WO.Body", x + 22, y + 100, WO.UI.Colors.good)
        DrawText("Нажмите E и выберите «Сдать смену».", "WO.Small", x + 22, y + 135,
            WO.UI.Colors.text)
        DrawText("X — отменить смену без выплаты", "WO.Tiny", x + 22, y + 178,
            WO.UI.Colors.textDim)
        return
    end

    local stopText = shift.professionId == "lumberjack" and
        "Смена сдаётся работодателю" or "X — отменить"
    DrawText(stopText, "WO.Tiny", x + w - 18, y + 17,
        WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    if not task then return end
    mode = mode or WO.Professions.GetMiniGame(task.mode) or {}
    DrawText((mode.label or task.mode) .. " · " .. (task.title or "Заказ"),
        "WO.Small", x + 18, y + 66, WO.UI.Colors.text)

    if mode.engine == "hold" then
        DrawFishing(task, x, y, w)
    elseif mode.engine == "strike" or mode.engine == "rhythm" or mode.engine == "stack" then
        DrawStrike(task, x, y, w, mode)
    elseif mode.engine == "tap" then
        DrawTap(task, x, y, w)
    elseif mode.engine == "sequence" then
        DrawSequence(task, x, y, w, mode)
    elseif mode.engine == "alternate" then
        DrawAlternate(task, x, y, w, mode)
    elseif mode.engine == "choice" or mode.engine == "identify" then
        DrawChoice(task, x, y, w)
    elseif mode.engine == "steer" or mode.engine == "adjust" or mode.engine == "balance" or
        mode.engine == "sweep" then
        DrawSteering(task, x, y, w, mode.engine, mode)
    elseif mode.engine == "precision" then
        DrawPrecision(task, x, y, w)
    elseif mode.engine == "dodge" then
        DrawDodge(task, x, y)
    elseif mode.engine == "delivery" then
        DrawDelivery(task, shift, x, y, w)
    elseif mode.engine == "lumber" then
        DrawLumberDelivery(task, x, y, w)
        DrawLumberWorldMarker(task, shift)
    end

    if mode.controls and mode.controls ~= "" and mode.engine ~= "delivery" then
        DrawText(mode.controls, "WO.Tiny", x + 18, y + h - 24,
            WO.UI.Colors.textDim)
    end
end

local function DrawLumberMinigameHUD()
    local shift = CurrentShift()
    if not shift or shift.status ~= "working" then return end

    local task = shift.task
    local mode = task and WO.Professions.GetMiniGame(task.mode) or nil
    if not task or task.phase ~= "work" or not mode or mode.engine ~= "lumber" then return end

    local def = WO.Professions.Get(shift.professionId)
    local rank = def and def.ranks[math.Clamp(tonumber(shift.rank) or 1, 1, 3)] or nil
    DrawLumberSequence(task, shift, def, rank)
end

function WO.ProfessionsUI.DrawWorldShift()
    DrawWorldShift()
end

function WO.ProfessionsUI.DrawLumberMinigame()
    DrawLumberMinigameHUD()
end

function WO.ProfessionsUI.DrawHUD()
    DrawWorldShift()
    DrawLumberMinigameHUD()
end

hook.Add("Think", "wo_professions_world_input", function()
    RequestSnapshot()
    local shift = CurrentShift()

    if not shift then
        local now = CurTime()
        if KeyDown(KEY_E) and now >= nextNoShiftProbeAt and IsNearLumberPickup() then
            nextNoShiftProbeAt = now + 2.5
            RequestSnapshot(true)
        end

        ResetInputState()
        return
    end

    local task = shift.task
    local context = GetInputContext(shift, task)

    if context ~= inputContext then
        ResetInputState()
        inputContext = context
    end

    local cancelPressed = KeyPressed("cancel", KEY_X)
    if cancelPressed and shift.professionId ~= "lumberjack" then
        WO.Net.SendToServer("Profession.CancelShift", shift.id)
        return
    end

    if shift.status == "working" and task then
        PollMiniGameInput(shift, task)
    end
end)

hook.Add("PlayerBindPress", "wo_professions_world_bind", function(ply, bind)
    if ply ~= LocalPlayer() then return end
    local shift = CurrentShift()
    if not shift or shift.status ~= "working" then return end

    local task = shift.task
    local mode = task and WO.Professions.GetMiniGame(task.mode) or nil
    local engine = mode and mode.engine
    local lowerBind = string.lower(bind or "")

    if engine == "lumber" then
        if string.find(lowerBind, "+use", 1, true) then return true end

        if task.phase == "work" and (string.find(lowerBind, "+forward", 1, true) or
            string.find(lowerBind, "+back", 1, true) or
            string.find(lowerBind, "+moveleft", 1, true) or
            string.find(lowerBind, "+moveright", 1, true)) then
            return true
        end

        if task.phase == "carry" then
            if string.find(lowerBind, "+speed", 1, true) or
                string.find(lowerBind, "+jump", 1, true) or
                string.match(lowerBind, "^slot%d+$") or lowerBind == "lastinv" or
                lowerBind == "invnext" or lowerBind == "invprev" or
                lowerBind == "weapnext" or lowerBind == "weapprev" then
                return true
            end
        end
    end

    if (engine == "hold" or engine == "strike" or engine == "rhythm" or engine == "stack" or
        engine == "tap" or engine == "precision") and string.find(lowerBind, "+jump", 1, true) then
        return true
    end

    if engine == "delivery" and task.phase == "pickup" and
        string.find(lowerBind, "+use", 1, true) then
        return true
    end

    if string.find(lowerBind, "+drop", 1, true) then return true end

    if engine == "steer" or engine == "adjust" or engine == "balance" or engine == "sweep" or
        engine == "dodge" or engine == "alternate" or engine == "precision" then
        if string.find(lowerBind, "+forward", 1, true) or string.find(lowerBind, "+back", 1, true) or
            string.find(lowerBind, "+moveleft", 1, true) or string.find(lowerBind, "+moveright", 1, true) then
            return true
        end
    end

    if engine == "sequence" or engine == "identify" or engine == "choice" then
        if string.find(lowerBind, "slot1", 1, true) or string.find(lowerBind, "slot2", 1, true) or
            string.find(lowerBind, "slot3", 1, true) or string.find(lowerBind, "slot4", 1, true) then
            return true
        end
    end
end)

hook.Add("CharacterMenuOpening", "professions_reset_world_controls", ResetProfessionSyncState)

WO.Hook.Add("ProfessionsSynced", "professions_world_ui", function()
    local shift = CurrentShift()
    if not shift then ResetInputState() end
end)
