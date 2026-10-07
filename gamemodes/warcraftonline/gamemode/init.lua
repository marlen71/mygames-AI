--[[
    Warcraft Online — server entry point.
    Loads the shared bootstrap (which loads core, config, plugins, schemas).
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
