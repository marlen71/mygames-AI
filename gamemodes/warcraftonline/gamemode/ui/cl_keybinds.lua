--[[
    Warcraft Online — клиентские клавиши (client).
    WO.UI.BindKey(KEY_X, function() ... end) — вызов по нажатию клавиши.
    Не срабатывает при вводе текста и открытых меню GMod.
]]

WO.UI.Binds = WO.UI.Binds or {}

--[[
    Привязывает клавишу к функции (edge-triggered: один вызов на нажатие).

    @param keyCode number KEY_*
    @param fn function
    @param id string|nil уникальный id (для удаления)
]]
function WO.UI.BindKey(keyCode, fn, id)
    WO.UI.Binds[#WO.UI.Binds + 1] = {
        key = keyCode,
        fn = fn,
        id = id or ("bind_" .. #WO.UI.Binds),
    }
end

--- Убирает привязку по id.
function WO.UI.UnbindKey(id)
    for i = #WO.UI.Binds, 1, -1 do
        if WO.UI.Binds[i].id == id then
            table.remove(WO.UI.Binds, i)
        end
    end
end

local wasDown = {}

local function TypingInField()
    local focus = vgui.GetKeyboardFocus()

    if IsValid(focus) then
        local className = focus:GetClassName()

        if className == "DTextEntry" or className == "DComboBox" or className == "WANG" then
            return true
        end
    end

    return false
end

hook.Add("Think", "wo_keybinds", function()
    if gui.IsGameUIVisible() or gui.IsConsoleVisible() then return end

    local typing = TypingInField()

    for _, bind in ipairs(WO.UI.Binds) do
        local down = input.IsKeyDown(bind.key)

        if down and not wasDown[bind.key] and not typing then
            local ok, err = pcall(bind.fn)

            if not ok then
                WO.Error("Keybind '" .. bind.id .. "' failed: " .. tostring(err))
            end
        end

        wasDown[bind.key] = down
    end
end)
