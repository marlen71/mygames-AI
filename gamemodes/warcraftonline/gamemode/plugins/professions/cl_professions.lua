--[[
    Warcraft Online — интерфейс ремёсел.
    Мини-игра использует вертикальный зелёный сектор и движущийся маркер;
    сервер самостоятельно проверяет удержание, перенос и завершение заказов.
]]

WO.ProfessionsUI = WO.ProfessionsUI or {}

local requestedCharacter = nil

local function LocalCharacter()
    return WO.Character and WO.Character.GetLocal and WO.Character.GetLocal() or nil
end

local function RequestSnapshot()
    local char = LocalCharacter()
    if not char or not isstring(char.id) or char.id == "" then return end

    if requestedCharacter ~= char.id then
        requestedCharacter = char.id
        WO.Net.SendToServer("Profession.SyncRequest")
    end
end

local function SkillFor(data, professionId)
    local skill = data and data.skills and data.skills[professionId]
    if not istable(skill) then return { xp = 0, level = 1, completedShifts = 0 } end
    return skill
end

local function AddHeader(parent)
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(74)
    header:DockMargin(0, 0, 0, 10)
    header:SetPaintBackground(false)
    header.Paint = function(_, w)
        WO.UI.DrawTextFit("Гильдия ремёсел", "WO.Title", 0, 2,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 8, 34)
        WO.UI.DrawTextFit("Выберите работу, выполните три заказа и сдайте смену. Зарплата и опыт выдаются только сервером после сдачи.",
            "WO.Small", 2, 42, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP, w - 10, 26)
    end
end

local function CurrentShift()
    local data = WO.Professions.ClientData
    return data and data.shift or nil
end

local function CurrentTask()
    local shift = CurrentShift()
    return shift and shift.task or nil
end

local function SendInput(shiftId, action, value)
    if not isstring(shiftId) or shiftId == "" then return end
    WO.Net.SendToServer("Profession.WorkInput", shiftId, action, value == true)
end

local function MakeShiftPanel(parent, shift, def)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(TOP)
    panel:SetTall(shift.status == "ready" and 250 or 440)
    panel:DockMargin(0, 0, 0, 12)

    local rank = def.ranks[math.Clamp(tonumber(shift.rank) or 1, 1, 3)]
    panel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radius)
        local title = def.name .. " — " .. (rank and rank.name or "")
        WO.UI.DrawTextFit(title, "WO.Subtitle", 16, 12,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 32, 26)
        local stateText = shift.status == "ready" and
            "Заказы готовы: сдайте смену, чтобы получить зарплату." or
            ("Заказ " .. tostring(math.min((shift.completedOrders or 0) + 1,
                shift.requiredOrders or 3)) .. "/" .. tostring(shift.requiredOrders or 3) ..
                " · базовая ставка " .. tostring((shift.basePay or 0) * (shift.requiredOrders or 3)) ..
                " монет до бонусов и качества.")
        WO.UI.DrawTextFit(stateText, "WO.Small", 16, 42,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 32, 24)
    end

    if shift.status ~= "ready" and istable(shift.task) then
        local game = vgui.Create("DPanel", panel)
        game:Dock(TOP)
        game:DockMargin(14, 74, 14, 8)
        game:SetTall(246)
        game.woShiftId = shift.id
        game.woHolding = false
        game:SetMouseInputEnabled(true)

        game.Paint = function(self, w, h)
            local task = CurrentTask()
            if not task then return end

            WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark,
                WO.UI.Colors.border)
            WO.UI.DrawTextFit(task.title or "Заказ", "WO.Body", 14, 10,
                WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 28, 22)

            if task.mode == "timing" then
                local barX, barY, barW, barH = 28, 43, 48, h - 66
                surface.SetDrawColor(12, 18, 28, 255)
                surface.DrawRect(barX, barY, barW, barH)
                surface.SetDrawColor(WO.UI.Colors.borderLight)
                surface.DrawOutlinedRect(barX, barY, barW, barH, 1)

                local center = math.Clamp(tonumber(task.zoneCenter) or 0.5, 0, 1)
                local zoneWidth = math.Clamp(tonumber(task.zoneWidth) or 0.2, 0.08, 0.5)
                local greenHeight = barH * zoneWidth
                local greenY = barY + barH - (center + zoneWidth * 0.5) * barH
                surface.SetDrawColor(64, 190, 113, 220)
                surface.DrawRect(barX + 2, greenY, barW - 4, greenHeight)

                local now = CurTime()
                local startedAt = tonumber(task.clientStartedAt) or now
                local marker = 0.5 + 0.44 * math.sin(
                    math.max(0, now - startedAt) * (tonumber(task.speed) or 1) +
                    (tonumber(task.phaseOffset) or 0))
                local markerY = barY + barH - marker * barH
                surface.SetDrawColor(245, 248, 252, 255)
                surface.DrawRect(barX - 4, markerY - 3, barW + 8, 6)

                local activeShift = CurrentShift()
                if activeShift and activeShift.professionId == "fisher" then
                    local fishX = barX + barW + 4
                    surface.SetDrawColor(235, 242, 250, 255)
                    surface.DrawPoly({
                        { x = fishX, y = markerY },
                        { x = fishX + 5, y = markerY - 4 },
                        { x = fishX + 11, y = markerY - 3 },
                        { x = fishX + 16, y = markerY },
                        { x = fishX + 11, y = markerY + 3 },
                        { x = fishX + 5, y = markerY + 4 },
                    })
                    surface.DrawPoly({
                        { x = fishX, y = markerY },
                        { x = fishX - 5, y = markerY - 4 },
                        { x = fishX - 5, y = markerY + 4 },
                    })
                    surface.SetDrawColor(18, 22, 30, 255)
                    surface.DrawRect(fishX + 10, markerY - 1, 2, 2)
                end

                local labelColor = self.woHolding and WO.UI.Colors.good or WO.UI.Colors.text
                WO.UI.DrawTextFit("Удерживайте ЛКМ в зелёной зоне", "WO.Small",
                    96, 58, labelColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 22)
                WO.UI.DrawTextFit("Отпустите кнопку, если маркер вышел за пределы.", "WO.Tiny",
                    96, 84, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 30)
                local progress = math.Clamp(tonumber(task.progress) or 0, 0, 1)
                WO.UI.DrawTextFit("Прогресс заказа", "WO.Tiny", 96, 135,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 18)
                WO.UI.DrawBar(96, 158, math.max(90, w - 120), 14, progress,
                    WO.UI.Colors.good, WO.UI.Colors.panelDark, nil)
                WO.UI.DrawTextFit(math.floor(progress * 100) .. "%", "WO.Tiny",
                    96, 181, WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 18)
                WO.UI.DrawTextFit(task.instruction or "", "WO.Tiny", 96, 205,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 30)
            else
                local distance = math.max(0, tonumber(task.carriedDistance) or 0)
                local required = math.max(1, tonumber(task.requiredDistance) or 1)
                local ratio = math.Clamp(distance / required, 0, 1)
                local phase = task.phase or "pickup"
                local message = phase == "pickup" and "Подойдите к грузу и нажмите «Забрать груз»." or
                    ("Несите груз: " .. math.floor(math.min(distance, required)) .. " / " .. required .. " юнитов.")
                WO.UI.DrawTextFit(message, "WO.Small", 96, 58,
                    WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 44)
                WO.UI.DrawTextFit("Прогресс доставки", "WO.Tiny", 96, 123,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 18)
                WO.UI.DrawBar(96, 148, math.max(90, w - 120), 16, ratio,
                    WO.UI.Colors.accent, WO.UI.Colors.panelDark, nil)
                WO.UI.DrawTextFit(task.instruction or "", "WO.Tiny", 96, 180,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 112, 32)
            end
        end

        if shift.task.mode == "timing" then
            game.OnMousePressed = function(self, mouseCode)
                if mouseCode == MOUSE_LEFT and not self.woHolding then
                    self.woHolding = true
                    self:MouseCapture(true)
                    SendInput(self.woShiftId, "hold", true)
                end
            end
            game.OnMouseReleased = function(self, mouseCode)
                if mouseCode == MOUSE_LEFT and self.woHolding then
                    self.woHolding = false
                    self:MouseCapture(false)
                    SendInput(self.woShiftId, "hold", false)
                end
            end
            game.OnRemove = function(self)
                if self.woHolding then
                    self.woHolding = false
                    SendInput(self.woShiftId, "hold", false)
                end
            end
        else
            local pickup = WO.UI.Button(game, "Забрать груз", function()
                SendInput(shift.id, "pickup", false)
            end)
            pickup:SetSize(160, 36)
            pickup:SetPos(96, 184)
            pickup:SetAccent(true)
            pickup:SetFont("WO.Small")
            pickup.Think = function(self)
                local task = CurrentTask()
                self:SetVisible(task ~= nil and task.mode == "delivery" and task.phase == "pickup")
            end
        end
    else
        local ready = WO.UI.Label(panel,
            "Все три заказа выполнены. Нажмите «Завершить смену», чтобы получить расчётную зарплату и опыт.",
            "WO.Body", WO.UI.Colors.text)
        ready:Dock(TOP)
        ready:DockMargin(16, 78, 16, 12)
        ready:SetTall(44)
    end

    local cancel = WO.UI.Button(panel, "Отменить смену без оплаты", function()
        WO.Net.SendToServer("Profession.CancelShift", shift.id)
    end)
    cancel:Dock(BOTTOM)
    cancel:DockMargin(14, 6, 14, 12)
    cancel:SetTall(34)
    cancel:SetFont("WO.Tiny")

    local finish = WO.UI.Button(panel, "Завершить смену и получить зарплату", function()
        WO.Net.SendToServer("Profession.FinishShift", shift.id)
    end)
    finish:Dock(BOTTOM)
    finish:DockMargin(14, 8, 14, 0)
    finish:SetTall(42)
    finish:SetAccent(true)
    finish:SetEnabled(shift.status == "ready")

    return panel
end

local function MakeProfessionCard(parent, def, data, char, hasShift)
    local skill = SkillFor(data, def.id)
    local level = math.Clamp(math.floor(tonumber(skill.level) or
        WO.Professions.GetLevelForXP(def.id, skill.xp)), 1, 3)
    local rank = def.ranks[level]
    local bonus = WO.Professions.GetBonus(char, def.id)
    local basePay = WO.Professions.GetBasePay(def.id, level, 3)
    local projectedPay = math.floor(basePay * (1 + bonus))

    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:SetTall(108)
    card:DockMargin(0, 0, 0, 8)
    card.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radiusSmall)
        WO.UI.DrawTextFit(def.name, "WO.Body", 14, 10,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 170, 22)
        WO.UI.DrawTextFit("Ступень " .. level .. "/3 — " .. rank.name,
            "WO.Small", 14, 36, WO.UI.Colors.text, TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP, w - 170, 20)
        local xpNeeded = level >= 3 and "максимум" or
            tostring(def.ranks[level + 1].requiredXP - (tonumber(skill.xp) or 0)) .. " опыта до повышения"
        WO.UI.DrawTextFit("Опыт: " .. tostring(skill.xp or 0) .. " · " .. xpNeeded ..
            " · бонус расы/класса +" .. math.floor(bonus * 100) .. "%",
            "WO.Tiny", 14, 60, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP, w - 170, 16)
        WO.UI.DrawTextFit("Базовая ставка за три заказа: " .. basePay ..
            " · расчётно с бонусом: около " .. projectedPay .. " монет",
            "WO.Tiny", 14, 81, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP, w - 170, 16)
    end

    local start = WO.UI.Button(card, "Устроиться", function()
        WO.Net.SendToServer("Profession.StartShift", def.id)
    end)
    start:SetSize(132, 40)
    start:SetPos(0, 34)
    start:SetAccent(true)
    start:SetFont("WO.Small")
    start:SetEnabled(not hasShift)
    card.PerformLayout = function(self, w)
        start:SetPos(w - start:GetWide() - 12, 34)
    end

    return card
end

function WO.ProfessionsUI.BuildPanel(parent)
    if not IsValid(parent) then return end

    RequestSnapshot()
    AddHeader(parent)

    local scroll = WO.UI.Scroll(parent)
    scroll:Dock(FILL)

    local char = LocalCharacter()
    local data = WO.Professions.ClientData or { skills = {}, shift = nil }
    local shift = data.shift
    local hasShift = istable(shift) and isstring(shift.id)

    if hasShift then
        local def = WO.Professions.Get(shift.professionId)
        if def then MakeShiftPanel(scroll, shift, def) end
    end

    local jobsHeader = WO.UI.Label(scroll, hasShift and "Другие доступные ремёсла" or
        "Выберите ремесло и начните смену", "WO.Subtitle", WO.UI.Colors.accent)
    jobsHeader:Dock(TOP)
    jobsHeader:DockMargin(0, 0, 0, 10)
    jobsHeader:SetTall(30)

    for _, professionId in ipairs(WO.Professions.GetIDs()) do
        local def = WO.Professions.Get(professionId)
        if def then MakeProfessionCard(scroll, def, data, char, hasShift) end
    end
end

WO.Hook.Add("ProfessionsSynced", "professions_ui_refresh", function(_, revisionChanged)
    if revisionChanged and WO.MenuUI and WO.MenuUI.GetPage and WO.MenuUI.GetPage() == "work" and
        WO.MenuUI.RefreshPage then
        WO.MenuUI.RefreshPage("work")
    end
end)
