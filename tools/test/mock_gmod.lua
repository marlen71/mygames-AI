--[[
    mock_gmod.lua — моки GMod API для smoke-тестов Warcraft Online (Lua 5.1/LuaJIT).
    Окружение НЕ идеально повторяет движок, но покрывает API, используемое гейммодом,
    и ловит реальные ошибки загрузки/логики. Запускается из tools/smoke_test.py.

    Предоставляется из Python (таблица py):
      py.file_find(pattern)      -> "f1\0f2\0..." и "d1\0d2\0..." (2 значения)
      py.file_exists(path)       -> boolean
      py.file_read(path)         -> string|nil
      py.sql_query(text)         -> json {ok, rows|nil, err}
      py.now()                   -> number (секунды)
]]

MOCK = {}

---------------------------------------------------------------------------
-- Совместимость Lua 5.1 (GMod/LuaJIT) для разных рантаймов lupa
---------------------------------------------------------------------------

loadstring = loadstring or load
unpack = unpack or table.unpack
setfenv = setfenv or function(fn, env) return fn end

---------------------------------------------------------------------------
-- Базовые глобалы
---------------------------------------------------------------------------

SERVER = MOCK.realm == "server"
CLIENT = MOCK.realm == "client"

-- realm выставляется до include mock (через MOCK_REALM)
MOCK.realm = rawget(_G, "MOCK_REALM") or "server"
SERVER = MOCK.realm == "server"
CLIENT = MOCK.realm == "client"

function istable(v) return type(v) == "table" end
function isstring(v) return type(v) == "string" end
function isnumber(v) return type(v) == "number" end
function isfunction(v) return type(v) == "function" end
function isbool(v) return type(v) == "boolean" end
function isentity(v) return type(v) == "table" and v.__entity == true end

local clock = 0
local timeOffset = 0

function SysTime() return py.now() + timeOffset end
function RealTime() return py.now() + timeOffset end
function CurTime() return clock end
function MOCK.AdvanceTime(n)
    n = tonumber(n) or 0
    clock = clock + n
    timeOffset = timeOffset + n
end

function MsgN(...) print(...) end
function Msg(...) print(...) end

function MsgC(...)
    local out = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) ~= "table" then
            out[#out + 1] = tostring(v)
        end
    end
    io.write(table.concat(out, ""))
    io.write("\n")
end

function ErrorNoHalt(...) MsgC(...) end
function ErrorNoHaltWithStack(...) MsgC(...) end

function PrintTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t or {}) do
        print(string.rep(" ", indent) .. tostring(k) .. " = " .. tostring(v))
    end
end

function Color(r, g, b, a)
    return { r = r or 255, g = g or 255, b = b or 255, a = a or 255, IsColor = true }
end

color_white = Color(255, 255, 255, 255)

-- Клавиши/константы движка (используются в UI/физике)
KEY_J = 74
KEY_ESCAPE = 70
KEY_C = 67
KEY_F1 = 98
KEY_E = 69
HITGROUP_GENERIC = 0
SIMPLE_USE = 3
MOVETYPE_NONE = 0
MOVETYPE_WALK = 2
MOVETYPE_NOCLIP = 8
MOVETYPE_STEP = 3
MOVETYPE_VPHYSICS = 6
SOLID_NONE = 0
SOLID_BBOX = 2
SOLID_VPHYSICS = 6
HULL_HUMAN = 1
COLLISION_GROUP_PLAYER = 5
COLLISION_GROUP_WEAPON = 21
COLLISION_GROUP_NPC = 9
CAP_MOVE_GROUND = 1
CAP_OPEN_DOORS = 2
NPC_STATE_IDLE = 1
NPC_STATE_ALERT = 2
D_HT = 1
D_LI = 3
SCHED_NONE = 0
SCHED_CHASE_ENEMY = 1
SCHED_IDLE_STAND = 2
CONTENTS_SOLID = 1
MASK_SOLID = 1
KEY_F2 = 93
TEXT_ALIGN_LEFT = 0
TEXT_ALIGN_CENTER = 1
TEXT_ALIGN_RIGHT = 2
TEXT_ALIGN_TOP = 3
TEXT_ALIGN_BOTTOM = 4
FILL = 1
TOP = 2
BOTTOM = 3
LEFT = 4
RIGHT = 5
NOTEXT = 0
FORCE_NUMBER = 1
FORCE_STRING = 2
FORCE_BOOL = 3

---------------------------------------------------------------------------
-- string-расширения GMod
---------------------------------------------------------------------------

function string.GetFileFromFilename(path)
    return string.match(path, "([^/\\]+)$") or path
end

function string.EndsWith(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

function string.StartWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

function string.Explode(sep, str, plain)
    local out = {}
    local pattern = "([^" .. sep .. "]+)"
    if plain then
        local pos = 1
        while true do
            local s, e = string.find(str, sep, pos, true)
            if not s then
                out[#out + 1] = string.sub(str, pos)
                break
            end
            out[#out + 1] = string.sub(str, pos, s - 1)
            pos = e + 1
        end
        return out
    end
    for piece in string.gmatch(str, pattern) do
        out[#out + 1] = piece
    end
    return out
end

function string.Trim(str)
    return (string.match(str, "^%s*(.-)%s*$"))
end

---------------------------------------------------------------------------
-- table / math / bit
---------------------------------------------------------------------------

function table.Count(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function table.Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == "table" and table.Copy(v) or v
    end
    return out
end

function table.Merge(dest, src)
    for k, v in pairs(src or {}) do
        if type(v) == "table" and type(dest[k]) == "table" then
            table.Merge(dest[k], v)
        else
            dest[k] = v
        end
    end
    return dest
end

function table.KeyFromValue(t, val)
    for k, v in pairs(t or {}) do
        if v == val then return k end
    end
    return nil
end

function table.HasValue(t, val)
    return table.KeyFromValue(t, val) ~= nil
end

function math.Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function math.Round(v, mult)
    mult = mult or 1
    return math.floor(v / mult + 0.5) * mult
end

function math.Rand(lo, hi)
    return lo + math.random() * (hi - lo)
end

function math.Approach(cur, target, inc)
    if cur < target then
        return math.min(cur + inc, target)
    end
    return math.max(cur - inc, target)
end

function Lerp(t, a, b)
    return a + (b - a) * t
end

bit = bit or {}

local function toBits(n)
    local out = {}
    n = math.floor(math.abs(n))
    while n > 0 do
        out[#out + 1] = n % 2
        n = math.floor(n / 2)
    end
    return out
end

local function fromBits(bits)
    local r, m = 0, 1
    for i = 1, #bits do
        if bits[i] == 1 then r = r + m end
        m = m * 2
    end
    return r
end

function bit.bor(a, b)
    local ba, bb = toBits(a), toBits(b)
    local out = {}
    for i = 1, math.max(#ba, #bb) do
        out[i] = ((ba[i] or 0) == 1 or (bb[i] or 0) == 1) and 1 or 0
    end
    return fromBits(out)
end

function bit.band(a, b)
    local ba, bb = toBits(a), toBits(b)
    local out = {}
    for i = 1, math.max(#ba, #bb) do
        out[i] = ((ba[i] or 0) == 1 and (bb[i] or 0) == 1) and 1 or 0
    end
    return fromBits(out)
end

---------------------------------------------------------------------------
-- Vector / Angle
---------------------------------------------------------------------------

local VEC = {}
VEC.__index = VEC
VEC.__add = function(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
VEC.__sub = function(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
VEC.__mul = function(a, b)
    if type(a) == "number" then return Vector(a * b.x, a * b.y, a * b.z) end
    if type(b) == "number" then return Vector(a.x * b, a.y * b, a.z * b) end
    return a.x * b.x + a.y * b.y + a.z * b.z
end
VEC.__eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end

function Vector(x, y, z)
    return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, VEC)
end

function isvector(value)
    return type(value) == "table" and getmetatable(value) == VEC
end

function VEC:Length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function VEC:Distance(other)
    return (self - other):Length()
end

function VEC:DistToSqr(other)
    local delta = self - other
    return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z
end

function VEC:Dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function VEC:Normalize()
    local len = self:Length()
    if len == 0 then return Vector(0, 0, 0) end
    return Vector(self.x / len, self.y / len, self.z / len)
end

function VEC:GetNormalized()
    return self:Normalize()
end

function VEC:Angle()
    return Angle(0, 0, 0)
end

function VEC:__tostring()
    return string.format("Vector(%s, %s, %s)", tostring(self.x), tostring(self.y), tostring(self.z))
end

function VEC:ToScreen()
    return { x = 0, y = 0, visible = true }
end

vector_origin = Vector(0, 0, 0)

function VectorRand()
    return Vector(0, 0, 0)
end

function AngleRand()
    return Angle(0, 0, 0)
end

local ANG = {}
ANG.__index = ANG

function Angle(p, y, r)
    return setmetatable({ p = p or 0, y = y or 0, r = r or 0 }, ANG)
end

function ANG:Forward()
    return Vector(0, 1, 0)
end

angle_zero = Angle(0, 0, 0)

---------------------------------------------------------------------------
-- IsValid / entity-объекты
---------------------------------------------------------------------------

function IsValid(obj)
    if obj == nil then return false end
    if type(obj) ~= "table" then return false end

    -- Panel metatables synthesize unknown methods; inspect raw flags so a
    -- vgui panel is not mistaken for an Entity by the mock runtime.
    if rawget(obj, "__entity") == true then
        return rawget(obj, "__valid") == true
    end

    if rawget(obj, "__panel") == true then
        return rawget(obj, "__removed") ~= true
    end

    return true
end

---------------------------------------------------------------------------
-- FindMetaTable: гейммод добавляет методы Player/Entity через него
---------------------------------------------------------------------------

MOCK.metaTables = {}

function FindMetaTable(name)
    MOCK.metaTables[name] = MOCK.metaTables[name] or {}
    return MOCK.metaTables[name]
end

local function EntityMetaLookup(t, k)
    local metaName = (t.__class == "player") and "Player" or "Entity"
    local meta = MOCK.metaTables[metaName]

    if meta then
        local m = meta[k]
        if m ~= nil then return m end
    end

    local metaAll = MOCK.metaTables["Entity"]
    if metaAll then
        local m = metaAll[k]
        if m ~= nil then return m end
    end

    return nil
end

-- Фабрика мок-объектов (Player, Entity): любой вызов метода — no-op,
-- известные поля имеют безопасные значения.
function MOCK.NewEntity(class)
    local e = {
        __entity = true,
        __valid = true,
        __class = class or "mock",
        __pos = Vector(0, 0, 0),
        __ang = Angle(0, 0, 0),
        __nw2 = {},
        __nw = {},
        __methods = {},
    }

    local meta = {}

    meta.__index = function(t, k)
        local raw = rawget(t, k)
        if raw ~= nil then return raw end

        local known = t.__methods[k]
        if known ~= nil then return known end

        local accessorFields = rawget(t, "__mockAccessorFields")
        if accessorFields and accessorFields[k] then return nil end

        local fromMeta = EntityMetaLookup(t, k)
        if fromMeta ~= nil then return fromMeta end

        -- Неизвестные поля/методы возвращают nil (как настоящие таблицы):
        -- автозаглушка превращала чтение полей вида self.WOCharacter в функцию.
        return nil
    end

    meta.__newindex = function(t, k, v)
        rawset(t, k, v)
    end

    setmetatable(e, meta)

    -- Базовые методы с осмысленным поведением
    e.__methods.GetPos = function(tt) return tt.__pos end
    e.__methods.SetPos = function(tt, p) tt.__pos = p end
    e.__methods.GetAngles = function(tt) return tt.__ang end
    e.__methods.SetAngles = function(tt, a) tt.__ang = a end
    e.__methods.EyeAngles = function(tt) return tt.__ang end
    e.__methods.GetEyeTrace = function(tt) return { HitPos = tt.__pos + Vector(0, 0, 64), Hit = false, Entity = nil } end
    e.__methods.GetClass = function(tt) return tt.__class end
    e.__methods.Nick = function(tt) return tt.__nick or "Player" end
    e.__methods.Ping = function(tt) return tt.__ping or 0 end
    e.__methods.SteamID = function(tt) return tt.__steamid or "STEAM_0:0:1" end
    e.__methods.SteamID64 = function(tt) return tt.__steamid64 or "76561190000000001" end
    e.__methods.UserID = function(tt) return tt.__userid or 1 end
    e.__methods.Alive = function(tt) return tt.__alive ~= false end
    e.__methods.SetNW2Bool = function(tt, k, v) tt.__nw2[k] = v end
    e.__methods.GetNW2Bool = function(tt, k, d) if tt.__nw2[k] == nil then return d end return tt.__nw2[k] end
    e.__methods.SetNW2Entity = function(tt, k, v) tt.__nw2[k] = v end
    e.__methods.GetNW2Entity = function(tt, k) return tt.__nw2[k] end
    e.__methods.SetNW2String = function(tt, k, v) tt.__nw2[k] = v end
    e.__methods.GetNW2String = function(tt, k, d) if tt.__nw2[k] == nil then return d end return tt.__nw2[k] end
    e.__methods.SetNW2Int = function(tt, k, v) tt.__nw2[k] = v end
    e.__methods.GetNW2Int = function(tt, k, d) if tt.__nw2[k] == nil then return d end return tt.__nw2[k] end
    e.__methods.SetNW2Float = function(tt, k, v) tt.__nw2[k] = v end
    e.__methods.GetNW2Float = function(tt, k, d) if tt.__nw2[k] == nil then return d end return tt.__nw2[k] end
    e.__methods.SetNWBool = e.__methods.SetNW2Bool
    e.__methods.GetNWBool = e.__methods.GetNW2Bool
    e.__methods.SetNWString = e.__methods.SetNW2String
    e.__methods.GetNWString = e.__methods.GetNW2String
    e.__methods.SetNWInt = e.__methods.SetNW2Int
    e.__methods.GetNWInt = e.__methods.GetNW2Int
    e.__methods.IsPlayer = function(tt) return tt.__class == "player" end
    e.__methods.IsNPC = function(tt) return tt.__class == "npc" end
    e.__methods.IsNextBot = function() return false end
    e.__methods.IsWeapon = function() return false end
    e.__methods.IsVehicle = function() return false end
    e.__methods.IsWorld = function() return false end
    e.__methods.EntIndex = function(tt) return tt.__index or 1 end
    e.__methods.Health = function(tt) return tt.__health or 100 end
    e.__methods.GetMaxHealth = function(tt) return tt.__maxhealth or 100 end
    e.__methods.SetHealth = function(tt, h) tt.__health = h end
    e.__methods.SetMaxHealth = function(tt, h) tt.__maxhealth = h end
    e.__methods.TakeDamage = function(tt, dmg) tt.__last_damage = dmg end
    e.__methods.GetTable = function(tt) tt.__custom = tt.__custom or {} return tt.__custom end
    e.__methods.Remove = function(tt) tt.__valid = false end
    e.__methods.GetModel = function(tt) return tt.__model or "models/player.mdl" end
    e.__methods.SetModel = function(tt, m) tt.__model = m end
    e.__methods.SetNoDraw = function(tt, v) tt.__nodraw = v end
    e.__methods.SetMoveType = function(tt, v) tt.__movetype = v end
    e.__methods.StripWeapons = function(tt)
        for _, weapon in pairs(tt.__weapons or {}) do
            if IsValid(weapon) then weapon:Remove() end
        end
        tt.__weapons = {}
        tt.__given = {}
    end
    e.__methods.StripWeapon = function(tt, class)
        local weapon = tt.__weapons and tt.__weapons[class]
        if IsValid(weapon) then weapon:Remove() end
        if tt.__weapons then tt.__weapons[class] = nil end
        if tt.__given then tt.__given[class] = nil end
    end
    e.__methods.SetWalkSpeed = function(tt, v) tt.__walk = v end
    e.__methods.SetRunSpeed = function(tt, v) tt.__run = v end
    e.__methods.SetJumpPower = function(tt, v) tt.__jump = v end
    e.__methods.SetEyeAngles = function(tt, a) tt.__ang = a end
    e.__methods.Give = function(tt, cls)
        tt.__given = tt.__given or {}
        tt.__weapons = tt.__weapons or {}
        tt.__given[cls] = true

        if not IsValid(tt.__weapons[cls]) then
            local weapon = MOCK.NewEntity("weapon")
            weapon.__weaponClass = cls
            weapon.__methods.GetClass = function(instance) return instance.__weaponClass end
            tt.__weapons[cls] = weapon
        end
    end
    e.__methods.HasWeapon = function(tt, cls) return tt.__given and tt.__given[cls] == true end
    e.__methods.GetWeapon = function(tt, cls) return tt.__weapons and tt.__weapons[cls] end
    e.__methods.GetActiveWeapon = function(tt) return tt.__weapon end
    e.__methods.SetActiveWeapon = function(tt, w) tt.__weapon = w end
    e.__methods.SelectWeapon = function(tt, class) tt.__weapon = tt.__weapons and tt.__weapons[class] end
    e.__methods.GetWeapons = function(tt)
        local out = {}
        for _, weapon in pairs(tt.__weapons or {}) do
            if IsValid(weapon) then out[#out + 1] = weapon end
        end
        return out
    end
    e.__methods.Kill = function(tt) tt.__alive = false end
    e.__methods.SetModelScale = function(tt, s) tt.__scale = s end
    e.__methods.GetHull = function(tt) return Vector(-16, -16, 0), Vector(16, 16, 72) end
    e.__methods.EyePos = function(tt) return tt.__pos + Vector(0, 0, 64) end
    e.__methods.GetShootPos = e.__methods.EyePos
    e.__methods.EyeAngles2 = e.__methods.EyeAngles
    e.__methods.GetAimVector = function(tt) return Vector(0, 1, 0) end
    e.__methods.LagCompensation = function() end
    e.__methods.SetBodygroup = function(tt, i, v) tt.__bodygroups = tt.__bodygroups or {} tt.__bodygroups[i] = v end
    e.__methods.GetBodygroup = function(tt, i) return (tt.__bodygroups and tt.__bodygroups[i]) or 0 end
    e.__methods.GetBodyGroups = function(tt) return tt.__bg_list or {} end
    e.__methods.GetNumBodyGroups = function(tt) return #(tt.__bg_list or {}) end
    e.__methods.GetBodygroupCount = function() return 1 end
    e.__methods.GetBodygroupName = function(_, i) return "Bodygroup " .. tostring(i) end
    e.__methods.SetSkin = function(tt, i) tt.__skin = i end
    e.__methods.GetSkin = function(tt) return tt.__skin or 0 end
    e.__methods.SkinCount = function() return 1 end
    e.__methods.GetMaterial = function() return "" end
    e.__methods.SetMaterial = function() end
    e.__methods.GetColor = function() return Color(255, 255, 255, 255) end
    e.__methods.SetColor = function() end
    e.__methods.Lock = function() end
    e.__methods.UnLock = function() end
    e.__methods.ChatPrint = function(tt, s) tt.__chat = s end
    e.__methods.PrintMessage = function() end
    e.__methods.SendLua = function() end
    e.__methods.GetFOV = function() return 90 end
    e.__methods.SetFOV = function() end
    e.__methods.GetVelocity = function() return Vector(0, 0, 0) end
    e.__methods.SetVelocity = function() end
    e.__methods.GetForward = function() return Vector(0, 1, 0) end
    e.__methods.GetRight = function() return Vector(1, 0, 0) end
    e.__methods.GetUp = function() return Vector(0, 0, 1) end
    e.__methods.ObeySpeed = function() end
    e.__methods.IsAdmin = function(tt) return tt.__admin == true end
    e.__methods.IsSuperAdmin = e.__methods.IsAdmin
    e.__methods.LookupSequence = function() return -1 end
    e.__methods.SetSequence = function() end
    e.__methods.GetSequence = function() return 0 end
    e.__methods.NetworkVar = function(tt, typeStr, slot, name)
        tt.__methods["Set" .. name] = function(t2, v)
            t2["__nv_" .. name] = v
        end
        tt.__methods["Get" .. name] = function(t2)
            return t2["__nv_" .. name]
        end
    end
    e.__methods.SetSolid = function(tt, value) tt.__solid = value end
    e.__methods.GetSolid = function(tt) return tt.__solid or 0 end
    e.__methods.SetCollisionGroup = function(tt, value) tt.__collisionGroup = value end
    e.__methods.PhysicsInit = function(tt, solid) tt.__physicsInit = solid end
    e.__methods.PhysicsInitBox = function(tt) tt.__physicsInit = true end
    e.__methods.GetPhysicsObject = function(tt)
        if not tt.__physicsObject then
            tt.__physicsObject = {
                Wake = function() end,
                SetMass = function(_, mass) tt.__physicsMass = mass end,
                SetVelocity = function(_, velocity) tt.__physicsVelocity = velocity end,
                AddAngleVelocity = function() end,
            }
        end
        return tt.__physicsObject
    end
    e.__methods.DropToFloor = function() end
    e.__methods.SetHullType = function() end
    e.__methods.SetHullSizeNormal = function() end
    e.__methods.SetMaxYawSpeed = function() end
    e.__methods.CapabilitiesAdd = function() end
    e.__methods.SetNPCState = function() end
    e.__methods.SetEnemy = function(tt, target) tt.__enemy = target end
    e.__methods.UpdateEnemyMemory = function() end
    e.__methods.SetSchedule = function(tt, schedule) tt.__schedule = schedule end
    e.__methods.AddEntityRelationship = function() end
    e.__methods.ResetSequence = function(tt, sequence) tt.__sequence = sequence end
    e.__methods.SetPlaybackRate = function(tt, rate) tt.__playbackRate = rate end
    e.__methods.NextThink = function(tt, at) tt.__nextThink = at end
    e.__methods.Spawn = function() end
    e.__methods.Activate = function() end
    e.__methods.SetOwner = function() end
    e.__methods.GetOwner = function() return nil end
    e.__methods.EmitSound = function() end
    e.__methods.SetUseType = function(tt, useType) tt.__useType = useType end

    return e
end

RENDERGROUP_OPAQUE = 7
RENDERGROUP_TRANSLUCENT = 8
RENDERGROUP_BOTH = 9
ClientsideModel = function(modelPath)
    local entity = MOCK.NewEntity("clientside_model")
    entity:SetModel(modelPath)
    return entity
end

---------------------------------------------------------------------------
-- include / AddCSLuaFile / file
---------------------------------------------------------------------------

MOCK.currentDir = "gamemodes/warcraftonline/gamemode"
MOCK.loadedFiles = {}
MOCK.clientFilesAdded = {}

local function ResolveMockIncludePath(path)
    path = string.gsub(path, "\\", "/")

    if string.sub(path, 1, 10) == "gamemodes/" or string.sub(path, 1, 4) == "lua/" then
        return path
    end

    -- Документированный абсолютный путь для gamemode: <FolderName>/gamemode/.
    local gamemodePrefix = (GM.FolderName or "warcraftonline") .. "/gamemode/"

    if string.sub(path, 1, #gamemodePrefix) == gamemodePrefix then
        return "gamemodes/" .. path
    end

    -- Обычный относительный include разрешается только от активного файла.
    return MOCK.currentDir .. "/" .. path
end

function include(path)
    local candidate = ResolveMockIncludePath(path)

    if not py.file_exists(candidate) then
        error("include: file not found: " .. path .. " (resolved to " .. candidate .. ")")
    end

    local src = py.file_read(candidate)

    if not src or src == "" then
        error("include: empty file " .. candidate)
    end

    local prevDir = MOCK.currentDir
    MOCK.currentDir = string.match(candidate, "^(.*)/[^/]+$") or candidate

    local chunk, err = loadstring(src, "@" .. candidate)

    if not chunk then
        MOCK.currentDir = prevDir
        error("include: syntax error in " .. candidate .. ": " .. tostring(err))
    end

    local ok, result = pcall(chunk)

    MOCK.currentDir = prevDir

    if not ok then
        error("include: runtime error in " .. candidate .. ": " .. tostring(result))
    end

    MOCK.loadedFiles[#MOCK.loadedFiles + 1] = candidate

    return result
end

function AddCSLuaFile(path)
    local candidate = ResolveMockIncludePath(path)

    if not py.file_exists(candidate) then
        error("AddCSLuaFile: file not found: " .. path .. " (resolved to " .. candidate .. ")")
    end

    MOCK.clientFilesAdded[path] = true
end

file = file or {}

function file.Find(pattern, path)
    local packed = py.file_find(pattern)
    local sep2 = "\2"
    local sep1 = "\1"

    local filesPart, dirsPart = string.match(packed, "^(.*)" .. sep2 .. "(.*)$")

    local files, folders = {}, {}

    for name in string.gmatch(filesPart or "", "[^" .. sep1 .. "]+") do
        files[#files + 1] = name
    end

    for name in string.gmatch(dirsPart or "", "[^" .. sep1 .. "]+") do
        folders[#folders + 1] = name
    end

    return files, folders
end

function file.Exists(path, searchPath)
    if MOCK.mountedFiles and MOCK.mountedFiles[path] == true then
        return true
    end

    return py.file_exists(path)
end

function file.Read(path, searchPath)
    return py.file_read(path)
end

function file.Size(path, searchPath)
    local s = py.file_read(path)
    return s and #s or 0
end

---------------------------------------------------------------------------
-- util
---------------------------------------------------------------------------

util = util or {}

function util.CRC(str)
    -- Простой стабильный хеш (формат строки не важен для логики)
    local h = 5381
    for i = 1, #str do
        h = (h * 33 + string.byte(str, i)) % 4294967296
    end
    return string.format("%08x", h)
end

function util.AddNetworkString(name)
    MOCK.networkStrings = MOCK.networkStrings or {}
    MOCK.networkStrings[name] = true
end

function util.IsValidModel(path)
    return file.Exists(path, "GAME")
end

function util.PrecacheModel(path) end

function util.TableToJSON(t, pretty)
    return MOCK.JSON.encode(t)
end

function util.JSONToTable(s)
    if not s or s == "" then return nil end
    local ok, t = pcall(MOCK.JSON.decode, s)
    if ok then return t end
    return nil
end

function util.SteamIDFrom64(id) return "STEAM_0:0:1" end
function util.SteamIDTo64(id) return "76561190000000001" end

function util.TraceLine(t)
    return {
        Hit = false, HitPos = (t and t.start or Vector()) + Vector(0, 0, 100),
        StartPos = t and t.start or Vector(), Normal = Vector(0, 0, 1),
        Fraction = 1, Entity = nil, HitNormal = Vector(0, 0, 1),
    }
end

function util.TraceHull(t)
    return util.TraceLine(t)
end

function util.RelativePathToFull(p) return p end
function util.NetworkStringToID(name) return 1 end
function util.SharedRandom(a, b, c) return b end

---------------------------------------------------------------------------
-- Мини-JSON (для util.TableToJSON / net.WriteTable)
---------------------------------------------------------------------------

MOCK.JSON = {}

function MOCK.JSON.encode(val)
    local t = type(val)
    if t == "nil" then return "null" end
    if t == "boolean" then return val and "true" or "false" end
    if t == "number" then return string.format("%.14g", val) end
    if t == "string" then
        local s = string.gsub(val, "[%c\"\\]", function(c)
            local map = { ['"'] = '\\"', ["\\"] = "\\\\" }
            if map[c] then return map[c] end
            return string.format("\\u%04x", string.byte(c))
        end)
        return '"' .. s .. '"'
    end
    if t == "table" then
        -- массив или объект?
        local n = #val
        local isArray = n > 0
        if not isArray then
            for k in pairs(val) do
                isArray = false
                break
            end
            -- пустая таблица → объект
            return next(val) == nil and "{}" or MOCK.JSON.encode_object(val)
        end
        for k in pairs(val) do
            if type(k) ~= "number" then
                return MOCK.JSON.encode_object(val)
            end
        end
        local parts = {}
        for i = 1, n do
            parts[i] = MOCK.JSON.encode(val[i])
        end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    return "null"
end

function MOCK.JSON.encode_object(val)
    local parts = {}
    for k, v in pairs(val) do
        parts[#parts + 1] = MOCK.JSON.encode(tostring(k)) .. ":" .. MOCK.JSON.encode(v)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function MOCK.JSON.decode(s)
    local pos = 1

    local function skip()
        pos = pos + (string.match(s, "^%s*", pos) and #string.match(s, "^%s*", pos) or 0)
    end

    local parseValue

    local function parseString()
        pos = pos + 1
        local out = {}
        while true do
            local c = string.sub(s, pos, pos)
            if c == "" then error("JSON: unterminated string") end
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            end
            if c == "\\" then
                local n = string.sub(s, pos + 1, pos + 1)
                if n == "u" then
                    local hex = string.sub(s, pos + 2, pos + 5)
                    out[#out + 1] = utf8.char(tonumber(hex, 16) or 0)
                    pos = pos + 6
                else
                    local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
                    out[#out + 1] = map[n] or n
                    pos = pos + 2
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end
    end

    local function parseNumber()
        local num = string.match(s, "^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        pos = pos + #num
        return tonumber(num)
    end

    local function parseArray()
        pos = pos + 1
        local out = {}
        skip()
        if string.sub(s, pos, pos) == "]" then
            pos = pos + 1
            return out
        end
        while true do
            out[#out + 1] = parseValue()
            skip()
            local c = string.sub(s, pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "]" then
                pos = pos + 1
                return out
            else
                error("JSON: expected , or ] at " .. pos)
            end
        end
    end

    local function parseObject()
        pos = pos + 1
        local out = {}
        skip()
        if string.sub(s, pos, pos) == "}" then
            pos = pos + 1
            return out
        end
        while true do
            skip()
            local key = parseString()
            skip()
            if string.sub(s, pos, pos) ~= ":" then
                error("JSON: expected : at " .. pos)
            end
            pos = pos + 1
            out[key] = parseValue()
            skip()
            local c = string.sub(s, pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "}" then
                pos = pos + 1
                return out
            else
                error("JSON: expected , or } at " .. pos)
            end
        end
    end

    parseValue = function()
        skip()
        local c = string.sub(s, pos, pos)
        if c == '"' then return parseString() end
        if c == "[" then return parseArray() end
        if c == "{" then return parseObject() end
        if string.sub(s, pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        end
        if string.sub(s, pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        end
        if string.sub(s, pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        return parseNumber()
    end

    return parseValue()
end

---------------------------------------------------------------------------
-- utf8 (GMod предоставляет библиотеку utf8; LuaJIT в lupa — нет)
---------------------------------------------------------------------------

utf8 = utf8 or {}

function utf8.codes(s)
    local i = 1

    return function()
        if i > #s then return nil end

        local c = string.byte(s, i)
        local len = 1

        if c >= 0xF0 then
            len = 4
        elseif c >= 0xE0 then
            len = 3
        elseif c >= 0xC0 then
            len = 2
        end

        local cp

        if len == 1 then
            cp = c
        elseif len == 2 then
            cp = (c % 0x20) * 0x40 + (string.byte(s, i + 1) % 0x40)
        elseif len == 3 then
            cp = (c % 0x10) * 0x1000 + (string.byte(s, i + 1) % 0x40) * 0x40 +
                (string.byte(s, i + 2) % 0x40)
        else
            cp = (c % 0x08) * 0x40000 + (string.byte(s, i + 1) % 0x40) * 0x1000 +
                (string.byte(s, i + 2) % 0x40) * 0x40 + (string.byte(s, i + 3) % 0x40)
        end

        local pos = i
        i = i + len

        return pos, cp
    end
end

local function EncodeUTF8(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
    elseif cp < 0x10000 then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + math.floor(cp / 0x40) % 0x40,
            0x80 + cp % 0x40
        )
    end
    return string.char(
        0xF0 + math.floor(cp / 0x40000),
        0x80 + math.floor(cp / 0x1000) % 0x40,
        0x80 + math.floor(cp / 0x40) % 0x40,
        0x80 + cp % 0x40
    )
end

function utf8.char(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[i] = EncodeUTF8(select(i, ...))
    end
    return table.concat(out)
end

function utf8.len(s)
    local n = 0
    for _ in utf8.codes(s) do
        n = n + 1
    end
    return n
end

function utf8.offset(s, n, init)
    return init or 1
end

function utf8.sub(s, i, j)
    local chars = {}
    local n = 0

    for _, cp in utf8.codes(s) do
        n = n + 1
        chars[n] = cp
    end

    i = math.max(1, i)
    j = math.min(n, j or n)

    local out = {}
    for k = i, j do
        out[#out + 1] = EncodeUTF8(chars[k])
    end

    return table.concat(out)
end

function utf8.codepoint(s, i, j)
    local out = {}
    for _, cp in utf8.codes(s) do
        out[#out + 1] = cp
    end
    return unpack(out, i or 1, j or #out)
end

---------------------------------------------------------------------------
-- hook
---------------------------------------------------------------------------

hook = hook or {}

local hooks = {}

function hook.Add(event, id, fn)
    hooks[event] = hooks[event] or {}
    hooks[event][id] = fn
end

function hook.Remove(event, id)
    if hooks[event] then
        hooks[event][id] = nil
    end
end

function hook.GetTable()
    return hooks
end

function hook.Call(event, gm, ...)
    local list = hooks[event]
    if not list then return end
    for _, fn in pairs(list) do
        local ok, err = pcall(fn, ...)
        if not ok then
            error("hook " .. event .. ": " .. tostring(err))
        end
    end
end

function hook.Run(event, ...)
    return hook.Call(event, nil, ...)
end

---------------------------------------------------------------------------
-- timer
---------------------------------------------------------------------------

timer = timer or {}

MOCK.timers = {}
MOCK.simpleQueue = {}

function timer.Simple(delay, fn)
    MOCK.simpleQueue[#MOCK.simpleQueue + 1] = { at = CurTime() + (delay or 0), fn = fn }
end

function timer.Create(id, delay, reps, fn)
    MOCK.timers[id] = { at = CurTime() + (delay or 0), delay = delay or 0, reps = reps or 0, fn = fn, fired = 0 }
end

function timer.Remove(id)
    MOCK.timers[id] = nil
end

function timer.Exists(id)
    return MOCK.timers[id] ~= nil
end

function timer.Adjust(id, delay, reps, fn)
    local t = MOCK.timers[id]
    if t then
        t.delay = delay or t.delay
        t.reps = reps or t.reps
        t.fn = fn or t.fn
    end
end

-- Выполняет отложенные колбэки с due <= CurTime()+eps
function MOCK.RunTimers(advance)
    clock = clock + (advance or 0)

    local again = true
    while again do
        again = false

        local queue = MOCK.simpleQueue
        MOCK.simpleQueue = {}
        for _, entry in ipairs(queue) do
            if entry.at <= clock + 0.0001 then
                local ok, err = pcall(entry.fn)
                if not ok then error("timer.Simple: " .. tostring(err)) end
                again = true
            else
                MOCK.simpleQueue[#MOCK.simpleQueue + 1] = entry
            end
        end

        for id, t in pairs(MOCK.timers) do
            if t.at <= clock + 0.0001 then
                local ok, err = pcall(t.fn)
                if not ok then error("timer " .. id .. ": " .. tostring(err)) end
                t.fired = t.fired + 1
                if t.reps == 0 or t.fired < t.reps then
                    t.at = clock + t.delay
                else
                    MOCK.timers[id] = nil
                end
                again = true
            end
        end
    end
end

---------------------------------------------------------------------------
-- net
---------------------------------------------------------------------------

net = net or {}

MOCK.netMessages = {}   -- name -> def (как в WO.Net.Messages, но и для прямых net.Receive)
MOCK.netReceivers = {}  -- name -> fn
MOCK.netOutbox = {}     -- отправленные сообщения (журнал)
MOCK.currentWrite = nil
MOCK.currentRead = nil

function net.Receive(name, fn)
    MOCK.netReceivers[name] = fn
end

function net.Start(name)
    MOCK.currentWrite = { name = name, args = {}, argn = 0 }
end

local function w(v)
    local w = MOCK.currentWrite
    if not w then error("net.Write outside net.Start") end
    w.argn = w.argn + 1
    w.args[w.argn] = v
end

function net.WriteString(v) w(v) end
function net.WriteUInt(v, bits) w(v) end
function net.WriteInt(v, bits) w(v) end
function net.WriteBool(v) w(v) end
function net.WriteFloat(v) w(v) end
function net.WriteDouble(v) w(v) end
function net.WriteAngle(v) w(v) end
function net.WriteVector(v) w(v) end
function net.WriteEntity(v) w(v) end
function net.WriteColor(v) w(v) end
function net.WriteTable(t) w(t) end
function net.WriteData(v) w(v) end
function net.WriteNormal(v) w(v) end

function net.Send(target)
    local msg = MOCK.currentWrite
    MOCK.currentWrite = nil
    if not msg then return end
    msg.target = target
    msg.kind = "toserver_or_single"
    MOCK.netOutbox[#MOCK.netOutbox + 1] = msg
end

function net.Broadcast()
    local msg = MOCK.currentWrite
    MOCK.currentWrite = nil
    if not msg then return end
    msg.kind = "broadcast"
    MOCK.netOutbox[#MOCK.netOutbox + 1] = msg
end

function net.SendToServer()
    local msg = MOCK.currentWrite
    MOCK.currentWrite = nil
    if not msg then return end
    msg.kind = "toserver"
    MOCK.netOutbox[#MOCK.netOutbox + 1] = msg
end

function net.SendOmit() net.Broadcast() end
function net.SendPVS() net.Broadcast() end

function net.BytesWritten() return 0 end

-- Доставка: вызывает net.Receive[name] с буфером чтения
function MOCK.NetDeliver(msg, len, ply)
    local receiver = MOCK.netReceivers[msg.name]
    if not receiver then
        error("MOCK.NetDeliver: no receiver for " .. tostring(msg.name))
    end

    MOCK.currentRead = { args = msg.args, pos = 0 }

    local ok, err = pcall(receiver, len or 8, ply)

    MOCK.currentRead = nil

    if not ok then
        error("MOCK.NetDeliver: handler " .. msg.name .. " failed: " .. tostring(err))
    end
end

local function r()
    local b = MOCK.currentRead
    if not b then error("net.Read outside receive") end
    b.pos = b.pos + 1
    return b.args[b.pos]
end

function net.ReadString() return r() or "" end
function net.ReadUInt(bits) return r() or 0 end
function net.ReadInt(bits) return r() or 0 end
function net.ReadBool() return r() == true end
function net.ReadFloat() return r() or 0 end
function net.ReadDouble() return r() or 0 end
function net.ReadAngle() return r() end
function net.ReadVector() return r() end
function net.ReadEntity() return r() end
function net.ReadColor() return r() end
function net.ReadTable() return r() or {} end
function net.ReadData(len) return r() or "" end
function net.ReadNormal() return r() end

---------------------------------------------------------------------------
-- sql (мост к Python sqlite3; значения — строки, как в GMod)
---------------------------------------------------------------------------

sql = sql or {}

function sql.Query(text)
    local result = py.sql_query(text)

    if result == false or result == nil then
        return false
    end

    local parsed = MOCK.JSON.decode(result)

    if not parsed.ok then
        MOCK.lastSqlError = parsed.err
        return false
    end

    MOCK.lastSqlError = ""

    return parsed.rows -- nil, если нет строк (как GMod)
end

function sql.QueryValue(text)
    local rows = sql.Query(text)
    if rows == false then return false end
    if rows == nil then return nil end
    local row = rows[1]
    if not row then return nil end
    for _, v in pairs(row) do
        return v
    end
    return nil
end

function sql.QueryRow(text)
    local rows = sql.Query(text)
    if rows == false then return false end
    return rows and rows[1] or nil
end

function sql.TableExists(name)
    local rows = sql.Query("SELECT name FROM sqlite_master WHERE type='table' AND name=" .. sql.SQLStr(name))
    return rows ~= nil and rows ~= false
end

function sql.SQLStr(str, noQuotes)
    local s = tostring(str)
    s = string.gsub(s, "'", "''")
    if noQuotes then return s end
    return "'" .. s .. "'"
end

function sql.LastError()
    return MOCK.lastSqlError or ""
end

function sql.QueryRows(text, callback)
    local rows = sql.Query(text) or {}
    for _, row in ipairs(rows) do
        callback(row)
    end
end

---------------------------------------------------------------------------
-- vgui / surface / draw / gui / input (client)
---------------------------------------------------------------------------

MOCK.vguiRegistry = {}
MOCK.createdPanels = {}

vgui = vgui or {}

function vgui.Register(name, panel, base)
    MOCK.vguiRegistry[name] = { panel = panel, base = base }
end

function vgui.GetControlTable(name)
    return MOCK.vguiRegistry[name] and MOCK.vguiRegistry[name].panel
end

local function NewPanel(class)
    local p = { __panel = true, __class = class, __children = {}, __enabled = true, __visible = true }

    p.SetText = function(tt, text) tt.__text = text end
    p.GetText = function(tt) return tt.__text or "" end
    p.SetValue = function(tt, value) tt.__value = value end
    p.GetValue = function(tt) return tt.__value or "" end
    p.SetPlaceholderText = function(tt, value) tt.__placeholder = value end
    p.SetEnabled = function(tt, enabled) tt.__enabled = enabled == true end
    p.IsEnabled = function(tt) return tt.__enabled end
    p.SetVisible = function(tt, visible) tt.__visible = visible == true end
    p.IsVisible = function(tt) return tt.__visible end
    p.Remove = function(tt)
        if rawget(tt, "__removed") == true then return end
        tt.__removed = true

        if isfunction(tt.OnRemove) then
            pcall(tt.OnRemove, tt)
        end

        for _, child in ipairs(tt.__children) do
            if child.Remove then child:Remove() end
        end
    end

    p.Close = function(tt) tt:Remove() end
    p.SetSize = function(tt, w, h) tt.__w, tt.__h = w, h end
    p.GetSize = function(tt) return tt.__w or 0, tt.__h or 0 end
    p.GetWide = function(tt) return tt.__w or 0 end
    p.GetTall = function(tt) return tt.__h or 0 end
    p.SetPos = function(tt, x, y) tt.__x, tt.__y = x, y end
    p.GetPos = function(tt) return tt.__x or 0, tt.__y or 0 end
    p.GetParent = function(tt) return tt.__parent end
    p.Center = function(tt)
        tt.__x = math.floor((ScrW() - (tt.__w or 0)) / 2)
        tt.__y = math.floor((ScrH() - (tt.__h or 0)) / 2)
    end
    p.LocalToScreen = function(tt, x, y)
        local parent = tt.__parent
        local px, py = tt.__x or 0, tt.__y or 0
        if parent and parent.LocalToScreen then
            local ox, oy = parent:LocalToScreen(px, py)
            px, py = ox or 0, oy or 0
        end
        return px + (x or 0), py + (y or 0)
    end
    p.ScreenToLocal = function(tt, x, y)
        local px, py = tt:LocalToScreen(0, 0)
        return (x or 0) - px, (y or 0) - py
    end
    p.MouseCapture = function(tt, enabled) tt.__mouseCapture = enabled == true end
    p.SetZPos = function(tt, z) tt.__zpos = z end
    p.Clear = function(tt)
        for _, child in ipairs(tt.__children) do
            if child.Remove then child:Remove() end
        end
        tt.__children = {}
    end

    local meta = {}
    meta.__index = function(t, k)
        local raw = rawget(t, k)
        if raw ~= nil then return raw end

        local accessorFields = rawget(t, "__mockAccessorFields")
        if accessorFields and accessorFields[k] then return nil end

        return function(tt, ...)
            if k == "Add" then
                local child = ...
                child.__parent = tt
                tt.__children[#tt.__children + 1] = child
                return child
            end
            return nil
        end
    end
    setmetatable(p, meta)

    -- Инициализация зарегистрированного панели
    local reg = MOCK.vguiRegistry[class]
    if reg and reg.panel then
        for k, v in pairs(reg.panel) do
            if k ~= "BaseClass" then
                p[k] = v
            end
        end
        if p.Init then
            local ok, err = pcall(p.Init, p)
            if not ok then
                error("vgui.Init " .. class .. ": " .. tostring(err))
            end
        end
    end

    -- Часто используемые derma-методы (через замыкания: чтение полей-панелей
    -- в моке возвращает автозаглушку-функцию, поэтому состояние держим локально)
    local vbar, canvas

    p.GetVBar = function(tt)
        if not vbar then
            vbar = NewPanel("DVScrollBar")
            vbar.btnGrip = NewPanel("DButton")
            vbar.btnUp = NewPanel("DButton")
            vbar.btnDown = NewPanel("DButton")
        end
        return vbar
    end

    p.GetCanvas = function(tt)
        canvas = canvas or NewPanel("DPanel")
        return canvas
    end

    MOCK.createdPanels[#MOCK.createdPanels + 1] = p

    return p
end

function vgui.Create(class, parent)
    local p = NewPanel(class)
    if parent and parent.Add then
        parent:Add(p)
    end
    return p
end

function vgui.CreateX(class, parent) return vgui.Create(class, parent) end

MOCK.dermaMenus = MOCK.dermaMenus or {}
function DermaMenu()
    local menu = { options = {}, __open = false }
    function menu:AddOption(text, callback)
        local option = { text = text, callback = callback }
        function option:SetTextColor(color) self.color = color end
        self.options[#self.options + 1] = option
        return option
    end
    function menu:AddSpacer() self.options[#self.options + 1] = { spacer = true } end
    function menu:Open() self.__open = true end
    MOCK.dermaMenus[#MOCK.dermaMenus + 1] = menu
    return menu
end

function MOCK.FindPanelByText(text)
    for i = #MOCK.createdPanels, 1, -1 do
        local panel = MOCK.createdPanels[i]

        if rawget(panel, "__removed") ~= true and
            (rawget(panel, "__text") == text or rawget(panel, "woText") == text) then
            return panel
        end
    end

    return nil
end

function vgui.GetKeyboardFocus() return nil end
function vgui.CursorPos() return 0, 0 end
function vgui.IsHoveringWorld() return false end

surface = surface or {}
function surface.CreateFont(name, def)
    MOCK.fonts = MOCK.fonts or {}
    MOCK.fonts[name] = def
end
function surface.SetFont() end
function surface.SetTextColor() end
function surface.SetDrawColor() end
function surface.DrawRect() end
function surface.DrawOutlinedRect() end
function surface.DrawTexturedRect() end
function surface.DrawTexturedRectUV() end
function surface.DrawTexturedRectRotated() end
MOCK.surfaceLineCalls = MOCK.surfaceLineCalls or 0
function surface.DrawLine()
    MOCK.surfaceLineCalls = MOCK.surfaceLineCalls + 1
end
function surface.DrawCircle() end
function surface.DrawText() end
function surface.SetTextPos() end
function surface.SetMaterial() end
function surface.GetTextureID() return 0 end
function surface.PlaySound() end
function surface.GetTextSize(txt) return #(txt or "") * 6, 12 end
function surface.GetFontName() return "default" end

draw = draw or {}
MOCK.drawTextCalls = MOCK.drawTextCalls or 0
MOCK.drawnTextValues = MOCK.drawnTextValues or {}
function draw.SimpleText(text)
    MOCK.drawTextCalls = MOCK.drawTextCalls + 1
    MOCK.drawnTextValues[#MOCK.drawnTextValues + 1] = tostring(text or "")
    return 0, 0
end
function draw.NoTexture() end

render = render or {}
MOCK.spriteDrawCalls = MOCK.spriteDrawCalls or 0
function render.SetMaterial() end
function render.DrawSprite()
    MOCK.spriteDrawCalls = MOCK.spriteDrawCalls + 1
end
function Material(path)
    return { path = path }
end
function draw.RoundedBox() end
function draw.RoundedBoxEx() end
function draw.Text() end
function draw.TextShadow() return 0, 0 end
function draw.DrawText() return 0, 0 end
function draw.WordBox() end

gui = gui or {}
function gui.MouseX() return 0 end
function gui.MouseY() return 0 end
function gui.MousePos() return 0, 0 end
function gui.EnableScreenClicker() end
function gui.IsGameUIVisible() return false end
function gui.OpenURL() end

input = input or {}
function input.IsKeyDown() return false end
function input.GetKeyCode() return 0 end
function input.LookupBinding() return "" end
function input.GetCursorPos() return 0, 0 end

ScrW = function() return MOCK.screenW or 1920 end
ScrH = function() return MOCK.screenH or 1080 end
FrameTime = function() return MOCK.frameTime or 0 end

---------------------------------------------------------------------------
-- game / ents / player / weapons / scripted_ents / player_manager / chat / sound
---------------------------------------------------------------------------

game = game or {}
function game.GetMap() return MOCK.mapName or "gm_flatgrass" end
function game.GetIPAddress() return "127.0.0.1:27015" end
function game.SinglePlayer() return true end
function game.MaxPlayers() return 16 end
function game.IsDedicated() return true end
function game.GetSkillLevel() return 1 end

list = list or {}
MOCK.listData = MOCK.listData or {}

function list.Get(category)
    return MOCK.listData[category] or {}
end

function list.Set(category, key, value)
    MOCK.listData[category] = MOCK.listData[category] or {}
    MOCK.listData[category][key] = value
end

ents = ents or {}

MOCK.worldEntities = {}

function ents.Create(class)
    local e = MOCK.NewEntity(class)

    -- Методы зарегистрированной SENT (как в настоящем движке)
    local sent = MOCK.sentList and MOCK.sentList[class]

    if sent then
        for k, v in pairs(sent) do
            if k ~= "BaseClass" and type(v) == "function" then
                e.__methods[k] = v
            elseif k ~= "BaseClass" then
                e[k] = v
            end
        end

        if sent.SetupDataTables then
            pcall(sent.SetupDataTables, e)
        end

        if sent.Initialize then
            pcall(sent.Initialize, e)
        end
    end

    MOCK.worldEntities[#MOCK.worldEntities + 1] = e
    return e
end

function ents.FindByClass(class)
    if class == "info_player_start" then
        local sp = MOCK.NewEntity("info_player_start")
        sp.__pos = Vector(0, 0, 16)
        return { sp }
    end

    local out = {}
    for _, e in ipairs(MOCK.worldEntities) do
        if e.__valid and (class == "*" or e.__class == class) then
            out[#out + 1] = e
        end
    end
    return out
end

function ents.GetAll()
    local out = {}
    for _, e in ipairs(MOCK.worldEntities) do
        if e.__valid then out[#out + 1] = e end
    end
    return out
end

function ents.FindInSphere(pos, radius)
    return {}
end

function ents.GetByIndex(i) return nil end

player = player or {}
MOCK.players = {}

function player.GetHumans()
    local out = {}
    for _, p in ipairs(MOCK.players) do
        if p.__valid then out[#out + 1] = p end
    end
    return out
end

function player.GetAll() return player.GetHumans() end
function player.GetCount() return #player.GetHumans() end
function player.GetBySteamID(sid)
    for _, p in ipairs(MOCK.players) do
        if p.__steamid == sid then return p end
    end
    return nil
end

player_manager = player_manager or {}
MOCK.playerModels = MOCK.playerModels or {}

function player_manager.AllValidModels()
    return MOCK.playerModels
end

function player_manager.AddValidModel(name, model)
    MOCK.playerModels[name] = model
end

weapons = weapons or {}
MOCK.weaponList = {}

function weapons.Register(swep, class)
    swep.ClassName = class
    MOCK.weaponList[class] = swep
end

function weapons.Get(class)
    return MOCK.weaponList[class]
end

function weapons.GetStored(class)
    return MOCK.weaponList[class]
end

function weapons.GetList()
    local out = {}
    for class, swep in pairs(MOCK.weaponList) do
        out[#out + 1] = swep
    end
    return out
end

scripted_ents = scripted_ents or {}
MOCK.sentList = {}

function scripted_ents.Register(ent, class)
    MOCK.sentList[class] = ent
end

function scripted_ents.Get(class)
    return MOCK.sentList[class]
end

function scripted_ents.GetStored(class)
    return MOCK.sentList[class]
end

function scripted_ents.GetType(class) return "anim" end

chat = chat or {}
function chat.AddText(...) end
function chat.PlaySound() end

concommand = concommand or {}
MOCK.commands = {}

function concommand.Add(name, fn, autoComplete, help, flags)
    MOCK.commands[name] = fn
end

function concommand.Remove(name)
    MOCK.commands[name] = nil
end

function concommand.GetTable()
    return MOCK.commands
end

--- Выполняет concommand из сценариев.
function MOCK.RunCommand(name, ply, args, raw)
    local fn = MOCK.commands[name]
    if not fn then
        error("MOCK.RunCommand: unknown command " .. tostring(name))
    end
    fn(ply, {}, args or {}, raw)
end

sound = sound or {}
function sound.Play() end
function sound.PlayFile() end
function sound.PlayURL() end

gameevent = gameevent or {}
function gameevent.Listen() end

cvars = cvars or {}
function cvars.AddChangeCallback() end
function cvars.Number() return 0 end
function cvars.String() return "" end
function cvars.Bool() return false end

CreateConVar = function(name, default, flags, help)
    return {
        GetString = function() return tostring(default) end,
        GetInt = function() return tonumber(default) or 0 end,
        GetFloat = function() return tonumber(default) or 0 end,
        GetBool = function() return default == true or default == "1" end,
        SetString = function() end,
        SetInt = function() end,
        SetFloat = function() end,
        SetBool = function() end,
    }
end

GetConVar = function(name)
    return CreateConVar(name, "0")
end

GetConVarNumber = function(name) return 0 end
GetConVarString = function(name) return "0" end
MOCK.consoleCommands = MOCK.consoleCommands or {}
RunConsoleCommand = function(command, ...)
    MOCK.consoleCommands[#MOCK.consoleCommands + 1] = { command, ... }
end
LocalPlayer = function()
    MOCK.localPlayer = MOCK.localPlayer or MOCK.NewEntity("player")
    return MOCK.localPlayer
end

AccessorFunc = function(target, field, name, external)
    target.__mockAccessorFields = target.__mockAccessorFields or {}
    target.__mockAccessorFields[field] = true
    target["Set" .. name] = function(self, v) self[field] = v end
    target["Get" .. name] = function(self) return self[field] end
end

Derma_Install_Convar_Functions = function() end
derma = derma or {}
function derma.DefineControl() end
function derma.GetSkinTable() return {} end
function derma.SkinHook() end

gamemode = gamemode or {}
function gamemode.Call(event, ...)
    return hook.Run(event, ...)
end

GAMEMODE = GAMEMODE or nil
GM = GM or {}

-- GM-поля (симулируем поведение GMod: Folder = "gamemodes/<name>")
GM.Name = "Warcraft Online"
GM.Folder = "gamemodes/warcraftonline"
GM.FolderName = "warcraftonline"
GAMEMODE = GM

---------------------------------------------------------------------------
-- Помощники сценариев
---------------------------------------------------------------------------

--- Создаёт мок-игрока и добавляет в player.GetHumans.
function MOCK.CreatePlayer(name, steamid)
    local p = MOCK.NewEntity("player")
    p.__class = "player"
    p.__nick = name or "Tester"
    p.__steamid = steamid or ("STEAM_0:0:" .. (#MOCK.players + 1))
    p.__steamid64 = "765611900000000" .. (#MOCK.players + 1)
    p.__userid = #MOCK.players + 1
    MOCK.players[#MOCK.players + 1] = p
    return p
end

--- Возвращает и очищает журнал net-сообщений.
function MOCK.TakeOutbox()
    local out = MOCK.netOutbox
    MOCK.netOutbox = {}
    return out
end

function MOCK.FindInbox(outbox, name)
    local out = {}
    for _, msg in ipairs(outbox) do
        if msg.name == name then
            out[#out + 1] = msg
        end
    end
    return out
end

--- Доставляет последнее исходящее сообщение сервер→клиент нужному игроку.
function MOCK.DeliverLastToClient(name, ply)
    for i = #MOCK.netOutbox, 1, -1 do
        local msg = MOCK.netOutbox[i]
        if msg.name == name then
            table.remove(MOCK.netOutbox, i)
            MOCK.NetDeliver(msg, 8, nil)
            return true
        end
    end
    return false
end

-- API для assert'ов сценария
function MOCK.Assert(cond, message)
    if not cond then
        error("ASSERT: " .. tostring(message), 2)
    end
end

return MOCK
