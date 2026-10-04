--[[
    Warcraft Online — основная конфигурация.
    Все значения можно менять без изменения системного кода.
]]

---------------------------------------------------------------------------
-- Отладка
---------------------------------------------------------------------------

-- Включает подробное логирование (plugin load, транзакции, SQL, сеть).
-- В production установите false.
WO.Config.Debug = true
WO.Config.DebugTracebackOnError = false

---------------------------------------------------------------------------
-- Персонажи
---------------------------------------------------------------------------

WO.Config.MaxCharacters = 2          -- Лимит персонажей обычного игрока
WO.Config.AdminMaxCharacters = 5     -- Лимит персонажей администратора
-- Зарезервированная точка расширения для будущих бонусных слотов; сейчас бонус равен нулю.
WO.Config.GetExtraCharacterSlots = WO.Config.GetExtraCharacterSlots or function()
    return 0
end
WO.Config.NameMinLength = 2
WO.Config.NameMaxLength = 24
WO.Config.AgeMin = 16
WO.Config.AgeMax = 100
WO.Config.StartingMoney = 50         -- Стартовые деньги (в медных монетах)

-- Пол (расширяется: можно добавить новые значения)
WO.Config.Genders = {
    "male",
    "female",
}

-- Запрещённые имена (проверка без учёта регистра)
WO.Config.BannedNames = {
    "admin",
    "administrator",
    "god",
    "root",
    "server",
    "console",
    "system",
    "valve",
    "gmod",
}

---------------------------------------------------------------------------
-- Движение / камера
---------------------------------------------------------------------------

WO.Config.DefaultWalkSpeed = 150
WO.Config.DefaultRunSpeed = 250
WO.Config.DefaultJumpPower = 200

WO.Config.CameraDistance = 150      -- Дистанция камеры по умолчанию
WO.Config.CameraMinDistance = 60
WO.Config.CameraMaxDistance = 400
WO.Config.CameraHeight = 20         -- Высота камеры
WO.Config.CameraShoulder = 14       -- Смещение в сторону (shoulder offset)
WO.Config.CameraSmooth = 12         -- Плавность (0 = без сглаживания)
WO.Config.CameraCollision = true
WO.Config.CameraFOV = 75

---------------------------------------------------------------------------
-- Сеть
---------------------------------------------------------------------------

WO.Config.MaxNetMessageLength = 65536

---------------------------------------------------------------------------
-- Сохранение
---------------------------------------------------------------------------

WO.Config.AutosaveInterval = 60     -- Периодическое сохранение (сек)
WO.Config.RespawnTime = 5           -- Время до респавна (сек)

---------------------------------------------------------------------------
-- Интеракция / предметы
---------------------------------------------------------------------------

WO.Config.InteractDistance = 100    -- Дистанция взаимодействия (E)
WO.Config.ItemPickupCooldown = 0.25 -- Короткий кулдаун, синхронизированный клиенту (сек)
WO.Config.WorldItemsPersist = false -- Сохранять ли физические предметы между рестартами
WO.Config.WorldItemLifetime = 600   -- Время жизни брошенного предмета (сек), 0 = вечно
