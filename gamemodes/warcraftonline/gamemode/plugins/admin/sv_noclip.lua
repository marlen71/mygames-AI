-- Absolute noclip prohibition for every player, including administrators.
-- Leaving noclip is allowed so a previously enabled state can always be exited.
hook.Add("PlayerNoClip", "wo_noclip_forbidden", function(_, desiredState)
    if desiredState == false then return true end

    return false
end)
