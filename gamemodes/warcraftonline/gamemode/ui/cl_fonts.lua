--[[
    Warcraft Online — единая типографика (client).
    Все плагины используют эти имена: глобальная правка здесь улучшает весь UI.
]]

local function CreateFonts()
    surface.CreateFont("WO.Title", {
        font = "Roboto",
        size = 27,
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("WO.Subtitle", {
        font = "Roboto",
        size = 21,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("WO.MenuButton", {
        font = "Roboto",
        size = 22,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("WO.Body", {
        font = "Roboto",
        size = 17,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.Small", {
        font = "Roboto",
        size = 15,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.Tiny", {
        font = "Roboto",
        size = 13,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.Number", {
        font = "Roboto",
        size = 18,
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("WO.HUD", {
        font = "Roboto",
        size = 18,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("WO.HUDName", {
        font = "Roboto",
        size = 21,
        weight = 800,
        antialias = true,
    })
end

CreateFonts()

-- Пересоздание шрифтов после смены разрешения (без перерегистрации плагинов).
hook.Add("OnScreenSizeChanged", "wo_fonts_resize", function()
    CreateFonts()
end)
