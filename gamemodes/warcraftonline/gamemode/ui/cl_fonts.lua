--[[
    Warcraft Online — шрифты (client).
    Все шрифты создаются здесь; плагины не создают свои шрифты.
]]

local function CreateFonts()
    surface.CreateFont("WO.Title", {
        font = "Roboto",
        size = 22,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("WO.Subtitle", {
        font = "Roboto",
        size = 18,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.MenuButton", {
        font = "Roboto",
        size = 21,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.Body", {
        font = "Roboto",
        size = 15,
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("WO.Small", {
        font = "Roboto",
        size = 13,
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("WO.Tiny", {
        font = "Roboto",
        size = 11,
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("WO.Number", {
        font = "Roboto",
        size = 16,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("WO.HUD", {
        font = "Roboto",
        size = 17,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("WO.HUDName", {
        font = "Roboto",
        size = 19,
        weight = 700,
        antialias = true,
    })
end

CreateFonts()

-- Пересоздание шрифтов при смене разрешения (safe)
hook.Add("OnScreenSizeChanged", "wo_fonts_resize", function()
    CreateFonts()
end)
