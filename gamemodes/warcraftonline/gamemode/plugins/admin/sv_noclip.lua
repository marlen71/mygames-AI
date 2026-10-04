-- Noclip is disabled for regular players and granted only through the admin
-- permission catalog (SAM permission: wo_noclip).
hook.Add("PlayerNoClip", "wo_admin_noclip_permission", function(ply, desiredState)
    -- Always allow leaving noclip, including after an administrator loses access.
    if desiredState == false then return true end
    if desiredState ~= true then return false end

    return WO.Admin and WO.Admin.Can and
        WO.Admin.Can(ply, "movement.noclip") == true
end)
