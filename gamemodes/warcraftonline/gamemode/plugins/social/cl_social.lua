--[[ Warcraft Online — меню знакомства по F2. ]]

local introductionFrame

function WO.Social.OpenIntroductionMenu()
    if IsValid(introductionFrame) then
        introductionFrame:Close()
        introductionFrame = nil
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:HasCharacter() or not WO.Character.GetLocal() then
        WO.Notify(ply, "info", "Сначала выберите персонажа.")
        return
    end

    introductionFrame = WO.UI.Window("Знакомство", 470, 330)

    local description = WO.UI.Label(introductionFrame,
        "Познакомиться с персонажами поблизости. Знакомство взаимное: вы узнаете их личности, а они — вашу.",
        "WO.Body", WO.UI.Colors.textDim)
    description:SetPos(22, 54)
    description:SetSize(426, 54)

    local modes = { "whisper", "talk", "shout" }
    local top = 122

    for _, mode in ipairs(modes) do
        local modeDef = WO.Social.IntroductionModes[mode]
        local button = WO.UI.Button(introductionFrame,
            modeDef.label .. " — радиус " .. modeDef.range,
            function()
                WO.Net.SendToServer("Social.Introduce", mode)
                if IsValid(introductionFrame) then introductionFrame:Close() end
                introductionFrame = nil
            end)
        button:SetPos(22, top)
        button:SetSize(426, 42)
        top = top + 52
    end

    local hint = WO.UI.Label(introductionFrame,
        "F2 · шёпот / разговор / крик", "WO.Tiny", WO.UI.Colors.textDim)
    hint:SetPos(22, 286)
    hint:SetSize(426, 20)

    introductionFrame.OnRemove = function() introductionFrame = nil end
end

WO.UI.BindKey(KEY_F2, WO.Social.OpenIntroductionMenu, "social_introduction")

WO.Hook.Add("CharacterMenuOpening", "social_close_introduction", function()
    if IsValid(introductionFrame) then introductionFrame:Remove() end
    introductionFrame = nil
    WO.Social.SetKnown({})
end)

WO.Hook.Add("SocialKnownUpdated", "social_identity_refresh", function()
    -- Nameplates read the client book each frame; this hook also gives open UI
    -- pages a clean point to refresh identity-dependent summaries if needed.
end)
