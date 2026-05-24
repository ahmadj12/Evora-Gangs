-- ╔══════════════════════════════════════════════════════╗
--  ahmad_gangs  —  Client Logic
-- ╚══════════════════════════════════════════════════════╝

local CURRENT_RESOURCE_NAME = GetCurrentResourceName()
local LOCKED_RESOURCE_NAME = "ahmad_gangs"

if LOCKED_RESOURCE_NAME ~= "" and CURRENT_RESOURCE_NAME ~= LOCKED_RESOURCE_NAME then
    print(("^1[ahmad_gangs]^7 Resource name lock failed on client. Expected '%s' but got '%s'.")
        :format(LOCKED_RESOURCE_NAME, CURRENT_RESOURCE_NAME))
    return
end

local isOpen = false
local playerReady = false

local territoryState = { zones = {}, active_zone = nil, active_zones = {} }
local territoryBlips = {}
local territoryHintShown = false
local territoryCaptureActive = false
local shopIsOpen = false
local rebuildTerritoryBlips

local DEBUG_NUI = false

local function dbg(msg, ...)
    if not DEBUG_NUI then return end

    local ok, text = pcall(string.format, tostring(msg), ...)
    print("^3[ahmad_gangs DEBUG]^7 " .. (ok and text or tostring(msg)))
end

local function sanitizeGangId(v)
    local s = tostring(v or "")
    s = s:gsub("[^%w_%-:]", "")
    if #s > 64 then s = s:sub(1, 64) end
    return s
end

local function sanitizeWeaponHash(v)
    local s = tostring(v or "")
    s = s:gsub("[^%w_%-]", "")
    if #s > 64 then s = s:sub(1, 64) end
    return s
end

local function toSafeInt(v, min, max)
    local n = math.floor(tonumber(v) or 0)
    if min and n < min then n = min end
    if max and n > max then n = max end
    return n
end

local function sanitizeHexColor(value, fallbackNoHash)
    local raw = tostring(value or ""):upper():gsub("#", ""):gsub("[^0-9A-F]", "")
    if #raw == 3 then
        raw = raw:sub(1, 1) .. raw:sub(1, 1)
            .. raw:sub(2, 2) .. raw:sub(2, 2)
            .. raw:sub(3, 3) .. raw:sub(3, 3)
    elseif #raw == 8 then
        -- Supports AARRGGBB by keeping RGB part.
        raw = raw:sub(3, 8)
    end

    if #raw ~= 6 then
        raw = tostring(fallbackNoHash or "D1921F")
    end

    return "#" .. raw
end

local function getUiThemePayload()
    local cfg = (type(Config) == "table" and type(Config.MenuTheme) == "table") and Config.MenuTheme or {}
    return {
        primary_color = sanitizeHexColor(cfg.primary_color, "D1921F"),
        background_color = sanitizeHexColor(cfg.background_color, "0C0903"),
    }
end

local function isPlayerReadyNow()
    local pid = PlayerId()
    local ped = PlayerPedId()
    return NetworkIsSessionStarted()
        and NetworkIsPlayerActive(pid)
        and ped and ped ~= 0
        and DoesEntityExist(ped)
        and not GetIsLoadingScreenActive()
        and IsScreenFadedIn()
end

local function waitForPlayerReady()
    while not isPlayerReadyNow() do
        Wait(300)
    end
end

local function ensureMarkerTextureDict(dictName, timeoutMs)
    if not dictName or dictName == "" then return false end
    if HasStreamedTextureDictLoaded(dictName) then return true end

    RequestStreamedTextureDict(dictName, false)
    local deadline = GetGameTimer() + (timeoutMs or 5000)

    while not HasStreamedTextureDictLoaded(dictName) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(50)
    end

    return true
end

-- ──────────────────────────────────────────────────────
-- تهيئة NUI عند بدء الريسورس (لازم يُستدعى حتى تشتغل الـ overlays)
-- ──────────────────────────────────────────────────────
CreateThread(function()
    Wait(300)
    SetNuiFocus(false, false)
end)

AddEventHandler("onClientResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    CreateThread(function()
        Wait(500)
        SetNuiFocus(false, false)
        -- طلب حالة الاستحلال بعد ما السيرفر يجهز
        Wait(2000)
        TriggerServerEvent("gang:requestTerritoryState")
    end)
end)
local nextMenuToggleAt = 0
RegisterCommand(Config.Command, function()
    local now = GetGameTimer()
    if now < nextMenuToggleAt then return end
    nextMenuToggleAt = now + 500

    if isOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeMenu" })
        TriggerServerEvent("gang:menuClosed")
        isOpen = false
        -- أعد تصفير الـ cache حتى يُعيد الـ loop إرسال حالة الـ hint في الدورة القادمة
        territoryHintShown = false
        return
    end

    TriggerServerEvent("gang:requestLaundryAccess")
    TriggerServerEvent("gang:requestMenu")
    TriggerServerEvent("gang:requestTerritoryState")
end, false)

RegisterKeyMapping(Config.Command, "فتح/غلق قائمة إدارة العصابة", "keyboard", Config.Key)

-- ──────────────────────────────────────────────────────
-- استقبال: البيانات الأولية (قائمة العصابات المدارة)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:openMenu")
AddEventHandler("gang:openMenu", function(data)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "territoryHint", show = false })
    SendNUIMessage({ type = "laundryHint", show = false })
    SendNUIMessage({ type = "shopHint", show = false })
    SendNUIMessage({ type = "openMenu", data = data, theme = getUiThemePayload() })
end)

AddEventHandler("playerSpawned", function()
    CreateThread(function()
        waitForPlayerReady()
        Wait(1200)
        playerReady = true
        SetNuiFocus(false, false)
        TriggerServerEvent("gang:refreshLaundryAccess")
        TriggerServerEvent("gang:requestShopAccess")
        TriggerServerEvent("gang:requestTerritoryState")
        -- إعادة المحاولة بعد 4 ثوانٍ في حال vRP لم يكن جاهزاً
        Wait(4000)
        TriggerServerEvent("gang:requestTerritoryState")
        -- محاولة أخيرة بعد 8 ثوانٍ
        Wait(4000)
        TriggerServerEvent("gang:requestTerritoryState")
    end)
end)

-- ──────────────────────────────────────────────────────
-- استقبال: بيانات العصابة المحددة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:gangData")
AddEventHandler("gang:gangData", function(data)
    SendNUIMessage({ type = "gangData", data = data })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: قائمة الأعضاء
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:membersData")
AddEventHandler("gang:membersData", function(members, totalSeconds)
    SendNUIMessage({ type = "membersData", members = members, total_seconds = totalSeconds })
end)

RegisterNetEvent("gang:membersRefreshNeeded")
AddEventHandler("gang:membersRefreshNeeded", function(gang_id)
    SendNUIMessage({ type = "membersRefreshNeeded", gang_id = gang_id })
end)

RegisterNetEvent("gang:territoryData")
AddEventHandler("gang:territoryData", function(data)
    local d = type(data) == "table" and data or {}
    territoryState.zones = d.zones or territoryState.zones or {}
    territoryState.active_zone = d.active_zone or nil
    territoryState.active_zones = d.active_zones or (d.active_zone and { d.active_zone } or {})
    dbg("territoryData -> zones=%d active_zones=%d", #(territoryState.zones or {}), #(territoryState.active_zones or {}))
    if rebuildTerritoryBlips then rebuildTerritoryBlips() end
    SendNUIMessage({ type = "territoryData", data = data })
end)

RegisterNetEvent("gang:territoryState")
AddEventHandler("gang:territoryState", function(data)
    local d = type(data) == "table" and data or {}
    territoryState.zones = d.zones or {}
    territoryState.active_zone = d.active_zone or nil
    territoryState.active_zones = d.active_zones or (d.active_zone and { d.active_zone } or {})
    dbg("territoryState -> zones=%d active_zones=%d", #(territoryState.zones or {}), #(territoryState.active_zones or {}))
    if rebuildTerritoryBlips then rebuildTerritoryBlips() end
    SendNUIMessage({ type = "territoryState", data = data })
end)

RegisterNetEvent("gang:territoryCaptureStart")
AddEventHandler("gang:territoryCaptureStart", function(data)
    territoryCaptureActive = true
    dbg("territoryCaptureStart -> zone_id=%s duration=%s", tostring(data and data.zone_id), tostring(data and data.duration))
    territoryHintShown = false
    SendNUIMessage({ type = "territoryHint", show = false })
    SendNUIMessage({ type = "territoryCaptureStart", data = data })
end)

RegisterNetEvent("gang:territoryCaptureStop")
AddEventHandler("gang:territoryCaptureStop", function(data)
    territoryCaptureActive = false
    dbg("territoryCaptureStop -> success=%s reason=%s", tostring(data and data.success), tostring(data and data.reason))
    territoryHintShown = false
    SendNUIMessage({ type = "territoryHint", show = false })
    SendNUIMessage({ type = "territoryCaptureStop", data = data })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: نتيجة الاستعلام
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:queryResult")
AddEventHandler("gang:queryResult", function(data)
    SendNUIMessage({ type = "queryResult", ok = data ~= nil, data = data })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: بيانات الخزنة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:treasuryData")
AddEventHandler("gang:treasuryData", function(data)
    SendNUIMessage({ type = "treasuryData", balance = data.balance, dirty_balance = data.dirty_balance or 0, log = data.log or {} })
end)

RegisterNetEvent("gang:rankingData")
AddEventHandler("gang:rankingData", function(list)
    SendNUIMessage({ type = "rankingData", data = list })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: إشعار (toast)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:notify")
AddEventHandler("gang:notify", function(notifyType, title, msg)
    SendNUIMessage({ type = "notify", notify_type = notifyType, title = title, message = msg })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: broadcast رسالة إدارية
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:broadcast")
AddEventHandler("gang:broadcast", function(data)
    SendNUIMessage({
        type        = "broadcast",
        gang_name   = data.gangName,
        gang_image  = data.gangImage,
        gang_color  = data.gangColor,
        message     = data.message,
        sender_name = data.senderName,
    })
end)

-- ──────────────────────────────────────────────────────
-- استقبال: سحب (تيليبورت) إلى موقع لاعب آخر
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:pullTo")
AddEventHandler("gang:pullTo", function(pullData)
    local x, y, z

    if type(pullData) == "table" then
        x = tonumber(pullData.x or pullData[1])
        y = tonumber(pullData.y or pullData[2])
        z = tonumber(pullData.z or pullData[3])
    else
        local managerSrc = tonumber(pullData)
        if managerSrc and managerSrc > 0 then
            local managerPlayer = GetPlayerFromServerId(managerSrc)
            if managerPlayer ~= -1 then
                local managerPed = GetPlayerPed(managerPlayer)
                if managerPed and managerPed ~= 0 and DoesEntityExist(managerPed) then
                    local coords = GetEntityCoords(managerPed)
                    x, y, z = coords.x, coords.y, coords.z
                end
            end
        end
    end

    if not x or not y or not z then return end
    if x ~= x or y ~= y or z ~= z then return end

    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    Wait(120)
    SetEntityCoords(ped, x + math.random(-2, 2) * 0.5, y + math.random(-2, 2) * 0.5, z, false, false, false, true)
end)

-- ──────────────────────────────────────────────────────
-- استقبال: إعطاء سلاح
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:receiveWeapon")
AddEventHandler("gang:receiveWeapon", function(weapon, ammo)
    local ped  = PlayerPedId()
    local hash = GetHashKey(weapon)
    GiveWeaponToPed(ped, hash, tonumber(ammo) or 0, false, true)
    SetCurrentPedWeapon(ped, hash, true)
end)

-- ──────────────────────────────────────────────────────
-- NUI Callbacks
-- ──────────────────────────────────────────────────────
RegisterNUICallback("closeMenu", function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent("gang:menuClosed")
    territoryHintShown = false
    SendNUIMessage({ type = "territoryHint", show = false })
    cb({})
end)

RegisterNUICallback("selectGang", function(data, cb)
    TriggerServerEvent("gang:selectGang", data.gang_id)
    cb({})
end)

RegisterNUICallback("getMembers", function(data, cb)
    TriggerServerEvent("gang:getMembers", data.gang_id, data.filter)
    cb({})
end)

RegisterNUICallback("promoteMember", function(data, cb)
    TriggerServerEvent("gang:promoteMember", data.gang_id, data.cid)
    cb({})
end)

RegisterNUICallback("demoteMember", function(data, cb)
    TriggerServerEvent("gang:demoteMember", data.gang_id, data.cid)
    cb({})
end)

RegisterNUICallback("fireMember", function(data, cb)
    TriggerServerEvent("gang:fireMember", data.gang_id, data.cid)
    cb({})
end)

RegisterNUICallback("pullMember", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local targetUid = toSafeInt(data and data.user_id, 1, 1000000000)
    if gangId ~= "" and targetUid > 0 then
        TriggerServerEvent("gang:pullMember", gangId, targetUid)
    end
    cb({})
end)

RegisterNUICallback("giveWeaponMember", function(data, cb)
    TriggerServerEvent("gang:giveWeaponMember", data.gang_id, data.user_id, data.weapon, data.ammo)
    cb({})
end)

RegisterNUICallback("queryPlayer", function(data, cb)
    TriggerServerEvent("gang:queryPlayer", data.gang_id, data.user_id)
    cb({})
end)

RegisterNUICallback("hirePlayer", function(data, cb)
    TriggerServerEvent("gang:hirePlayer", data.gang_id, data.user_id, data.rank_code)
    cb({})
end)

RegisterNUICallback("firePlayer", function(data, cb)
    TriggerServerEvent("gang:firePlayer", data.gang_id, data.user_id)
    cb({})
end)

RegisterNUICallback("messageAll", function(data, cb)
    TriggerServerEvent("gang:messageAll", data.gang_id, data.message)
    cb({})
end)

RegisterNUICallback("pullAll", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:pullAll", gangId)
    end
    cb({})
end)

RegisterNUICallback("giveWeaponAll", function(data, cb)
    TriggerServerEvent("gang:giveWeaponAll", data.gang_id, data.weapon, data.ammo)
    cb({})
end)

RegisterNUICallback("getTreasury", function(data, cb)
    TriggerServerEvent("gang:getTreasury", data.gang_id)
    cb({})
end)

RegisterNUICallback("getRanking", function(data, cb)
    TriggerServerEvent("gang:getRanking", data.gang_id)
    cb({})
end)

RegisterNUICallback("treasuryDeposit", function(data, cb)
    TriggerServerEvent("gang:treasuryDeposit", data.gang_id, data.amount)
    cb({})
end)

RegisterNUICallback("treasuryWithdraw", function(data, cb)
    TriggerServerEvent("gang:treasuryWithdraw", data.gang_id, data.amount)
    cb({})
end)

-- ══════════════════════════════════════════════════════════
--  Admin Panel
-- ══════════════════════════════════════════════════════════
local isAdminOpen = false
local nextAdminToggleAt = 0

RegisterCommand(Config.AdminPanel.command, function()
    local now = GetGameTimer()
    if now < nextAdminToggleAt then return end
    nextAdminToggleAt = now + 500

    if isAdminOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeAdmin" })
        isAdminOpen = false
        return
    end

    TriggerServerEvent("admin:requestPanel")
end, false)

RegisterKeyMapping(Config.AdminPanel.command, "فتح/غلق لوحة مسؤول العصابات", "keyboard", "")

RegisterNetEvent("admin:openPanel")
AddEventHandler("admin:openPanel", function(data)
    isAdminOpen = true
    SetNuiFocus(true, true)
    territoryHintShown = false
    SendNUIMessage({ type = "territoryHint", show = false })
    SendNUIMessage({ type = "laundryHint", show = false })
    SendNUIMessage({ type = "shopHint", show = false })
    SendNUIMessage({ type = "openAdmin", data = data, theme = getUiThemePayload() })
end)

RegisterNetEvent("admin:warningsData")
AddEventHandler("admin:warningsData", function(data)
    SendNUIMessage({ type = "adminWarningsData", data = data })
end)

RegisterNetEvent("admin:rankingData")
AddEventHandler("admin:rankingData", function(data)
    SendNUIMessage({ type = "adminRankingData", data = data })
end)

RegisterNetEvent("admin:gangMembersData")
AddEventHandler("admin:gangMembersData", function(data)
    SendNUIMessage({ type = "adminGangMembersData", data = data })
end)

RegisterNetEvent("admin:pointsUpdated")
AddEventHandler("admin:pointsUpdated", function(data)
    SendNUIMessage({ type = "adminPointsUpdated", data = data })
end)

RegisterNetEvent("admin:playtimeReset")
AddEventHandler("admin:playtimeReset", function(data)
    SendNUIMessage({ type = "adminPlaytimeReset", data = data })
end)

RegisterNUICallback("closeAdmin", function(_, cb)
    isAdminOpen = false
    SetNuiFocus(false, false)
    territoryHintShown = false   -- أعد تصفير الـ cache بعد إغلاق لوحة المسؤول
    cb({})
end)

RegisterNUICallback("adminMessageAllGangs", function(data, cb)
    TriggerServerEvent("admin:messageAllGangs", data.message, data.gang_id)
    cb({})
end)

RegisterNUICallback("adminGetWarnings", function(data, cb)
    TriggerServerEvent("admin:getWarnings", data.gang_id)
    cb({})
end)

RegisterNUICallback("adminAddWarning", function(data, cb)
    TriggerServerEvent("admin:addWarning", data.gang_id, data.title, data.reason, data.duration)
    cb({})
end)

RegisterNUICallback("adminRemoveWarning", function(data, cb)
    TriggerServerEvent("admin:removeWarning", data.gang_id, data.warning_id)
    cb({})
end)

RegisterNUICallback("adminGetRanking", function(_, cb)
    TriggerServerEvent("admin:getRanking")
    cb({})
end)

RegisterNUICallback("adminAddPoints", function(data, cb)
    TriggerServerEvent("admin:addPoints", data.gang_id, data.amount)
    cb({})
end)

RegisterNUICallback("adminRemovePoints", function(data, cb)
    TriggerServerEvent("admin:removePoints", data.gang_id, data.amount)
    cb({})
end)

RegisterNUICallback("adminResetPlaytime", function(data, cb)
    TriggerServerEvent("admin:resetPlaytime", data.gang_id)
    cb({})
end)

RegisterNUICallback("adminGetGangMembers", function(data, cb)
    TriggerServerEvent("admin:getGangMembers", data.gang_id)
    cb({})
end)

RegisterNUICallback("adminPromoteGangMember", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local userId = toSafeInt(data and data.user_id, 1, 1000000000)
    if gangId ~= "" and userId > 0 then
        TriggerServerEvent("admin:promoteGangMember", gangId, userId)
    end
    cb({})
end)

RegisterNUICallback("adminDemoteGangMember", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local userId = toSafeInt(data and data.user_id, 1, 1000000000)
    if gangId ~= "" and userId > 0 then
        TriggerServerEvent("admin:demoteGangMember", gangId, userId)
    end
    cb({})
end)

RegisterNUICallback("adminPullGangMember", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local userId = toSafeInt(data and data.user_id, 1, 1000000000)
    if gangId ~= "" and userId > 0 then
        TriggerServerEvent("admin:pullGangMember", gangId, userId)
    end
    cb({})
end)

RegisterNUICallback("adminGiveWeaponGangMember", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local userId = toSafeInt(data and data.user_id, 1, 1000000000)
    local weapon = sanitizeWeaponHash(data and data.weapon)
    local ammo = toSafeInt(data and data.ammo, 0, 10000)
    if gangId ~= "" and userId > 0 and weapon ~= "" then
        TriggerServerEvent("admin:giveWeaponGangMember", gangId, userId, weapon, ammo)
    end
    cb({})
end)

RegisterNUICallback("adminPullGang", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("admin:pullGang", gangId)
    end
    cb({})
end)

RegisterNUICallback("adminGiveWeaponGang", function(data, cb)
    TriggerServerEvent("admin:giveWeaponGang", data.gang_id, data.weapon, data.ammo)
    cb({})
end)

RegisterNUICallback("adminHireGangAdmin", function(data, cb)
    TriggerServerEvent("admin:hireGangAdmin", data.gang_id, data.user_id, data.rank_code)
    cb({})
end)

RegisterNUICallback("adminFireGangMember", function(data, cb)
    TriggerServerEvent("admin:fireGangMember", data.gang_id, data.user_id)
    cb({})
end)

-- ── Admin: المتاجر والخزائن القذرة
RegisterNetEvent("admin:shopsData")
AddEventHandler("admin:shopsData", function(list)
    SendNUIMessage({ type = "adminShopsData", data = list })
end)

RegisterNetEvent("admin:shopToggled")
AddEventHandler("admin:shopToggled", function(d)
    SendNUIMessage({ type = "adminShopToggled", gang_id = d.gang_id, disabled = d.disabled })
end)

RegisterNetEvent("admin:shopDeleted")
AddEventHandler("admin:shopDeleted", function(d)
    SendNUIMessage({ type = "adminShopDeleted", gang_id = d.gang_id })
end)

-- ── Admin: حساب الكنز المفقود
RegisterNetEvent("admin:treasureData")
AddEventHandler("admin:treasureData", function(list)
    SendNUIMessage({ type = "adminTreasureData", data = list or {} })
end)

RegisterNetEvent("admin:treasureUpdated")
AddEventHandler("admin:treasureUpdated", function(d)
    local data = type(d) == "table" and d or {}
    SendNUIMessage({ type = "adminTreasureUpdated", gang_id = data.gang_id, count = tonumber(data.count) or 0 })
end)

RegisterNetEvent("admin:treasureDepositPointUpdated")
AddEventHandler("admin:treasureDepositPointUpdated", function(d)
    local data = type(d) == "table" and d or {}
    SendNUIMessage({
        type = "adminTreasureDepositPointUpdated",
        has_point = data.has_point == true,
        point_label = tostring(data.point_label or "غير محددة")
    })
end)

RegisterNUICallback("adminGetShopsOverview", function(_, cb)
    TriggerServerEvent("admin:getShopsOverview")
    cb({})
end)

RegisterNUICallback("adminToggleShop", function(data, cb)
    TriggerServerEvent("admin:toggleShop", data.gang_id)
    cb({})
end)

RegisterNUICallback("adminDeleteShop", function(data, cb)
    TriggerServerEvent("admin:deleteShop", data.gang_id)
    cb({})
end)

RegisterNUICallback("adminGetTreasureData", function(_, cb)
    TriggerServerEvent("admin:getTreasureStats")
    cb({})
end)

RegisterNUICallback("adminTreasureDeduct", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local amount = toSafeInt(data and data.amount, 0, 1000000)
    if gangId ~= "" and amount > 0 then
        TriggerServerEvent("admin:treasureDeduct", gangId, amount)
    end
    cb({})
end)

RegisterNUICallback("adminTreasureReset", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("admin:treasureReset", gangId)
    end
    cb({})
end)

RegisterNUICallback("adminSetTreasureDepositPoint", function(_, cb)
    TriggerServerEvent("admin:setTreasureDepositPoint")
    cb({})
end)

RegisterNUICallback("adminGetTerritoryData", function(_, cb)
    TriggerServerEvent("admin:getTerritoryData")
    cb({})
end)

RegisterNUICallback("adminStartTerritoryBattle", function(data, cb)
    TriggerServerEvent("admin:startTerritoryBattle", data.radius, data.seconds)
    cb({})
end)

RegisterNUICallback("cancelTerritoryCapture", function(_, cb)
    TriggerEvent("gang:notify", "warning", "تنبيه", "لا يمكن إلغاء الاستحلال يدويًا، يلغى بالخروج من نطاق المنطقة")
    cb({})
end)

RegisterNUICallback("adminCancelTerritoryCapture", function(data, cb)
    TriggerServerEvent("admin:cancelTerritoryCapture", data and data.zone_id or nil)
    cb({})
end)

RegisterNUICallback("adminCancelTerritoryBattle", function(data, cb)
    TriggerServerEvent("admin:cancelTerritoryBattle", data and data.zone_id or nil)
    cb({})
end)

RegisterNUICallback("adminRenameTerritoryZone", function(data, cb)
    TriggerServerEvent("admin:renameTerritoryZone", data.zone_id, data.label)
    cb({})
end)

RegisterNUICallback("adminDeleteTerritoryZone", function(data, cb)
    TriggerServerEvent("admin:deleteTerritoryZone", data.zone_id)
    cb({})
end)

-- ══════════════════════════════════════════════════════════
--  Territory — القتال على منطقة
-- ══════════════════════════════════════════════════════════
local function clearTerritoryBlips()
    for _, pair in ipairs(territoryBlips) do
        if pair.radius and DoesBlipExist(pair.radius) then
            RemoveBlip(pair.radius)
        end
        if pair.center and DoesBlipExist(pair.center) then
            RemoveBlip(pair.center)
        end
    end
    territoryBlips = {}
end

rebuildTerritoryBlips = function()
    if not playerReady and not isPlayerReadyNow() then
        return
    end

    clearTerritoryBlips()

    local zones = territoryState.zones or {}
    if #zones <= 0 then return end

    local cfg = Config.Territory or {}
    for _, zone in ipairs(zones) do
        local radius = tonumber(zone.radius) or 0
        if radius > 0 then
            local color = 1
            if zone.status ~= "active" then
                color = tonumber(zone.owner_blip_color) or 2
            end

            local radiusBlip = AddBlipForRadius(zone.x + 0.0, zone.y + 0.0, zone.z + 0.0, radius + 0.0)
            SetBlipColour(radiusBlip, color)
            SetBlipAlpha(radiusBlip, zone.status == "active" and 115 or 80)

            local centerBlip = AddBlipForCoord(zone.x + 0.0, zone.y + 0.0, zone.z + 0.0)
            SetBlipSprite(centerBlip, tonumber(cfg.blip_sprite) or 161)
            SetBlipScale(centerBlip, tonumber(cfg.blip_scale) or 1.0)
            SetBlipDisplay(centerBlip, 4)
            SetBlipAsShortRange(centerBlip, false)
            SetBlipColour(centerBlip, color)

            BeginTextCommandSetBlipName("STRING")
            if zone.status == "active" then
                if zone.capturer_name and zone.capturer_name ~= "" then
                    AddTextComponentString("منطقة استحلال — " .. tostring(zone.capturer_name))
                else
                    AddTextComponentString("منطقة استحلال — في انتظار المستحل")
                end
            else
                local ownerLabel = tostring(zone.owner_label or "غير معروف")
                AddTextComponentString("منطقة " .. tostring(zone.label or "") .. " — " .. ownerLabel)
            end
            EndTextCommandSetBlipName(centerBlip)

            table.insert(territoryBlips, { radius = radiusBlip, center = centerBlip })
        end
    end
end

CreateThread(function()
    while type(Config) ~= "table" or type(Config.Territory) ~= "table" do
        Wait(300)
    end

    waitForPlayerReady()
    playerReady = true

    local markerDict = "a1"
    local markerTex  = "ahmad2"
    local markerType = 9
    local markerSize = 2.0
    local interactRadius = 2.0
    local drawDistance   = 10.0

    if not ensureMarkerTextureDict(markerDict, 6000) then
        markerDict = nil
        markerTex  = nil
        markerType = 1
    end

    local lastHintShow = false
    local lastTerritorySyncMs = 0

    while true do
        local sleep = 1000

        -- مزامنة دورية لحالة المنطقة حتى لا تضيع إذا فاتت رسالة من السيرفر
        local nowMs = GetGameTimer()
        -- وضع الخمول: الاكتفاء بمزامنة متباعدة لأن السيرفر يدفع الحالة عند أي تغيير.
        local syncIntervalMs = territoryCaptureActive and 8000 or ((isOpen or isAdminOpen) and 12000 or 180000)
        if (nowMs - lastTerritorySyncMs) > syncIntervalMs then
            lastTerritorySyncMs = nowMs
            TriggerServerEvent("gang:requestTerritoryState")
        end

        local ped = PlayerPedId()
        if not ped or ped == 0 or not DoesEntityExist(ped) then
            Wait(300)
        else
            local activeZones = territoryState.active_zones or {}
            if #activeZones <= 0 and territoryState.active_zone and territoryState.active_zone.status == "active" then
                activeZones = { territoryState.active_zone }
            end

            if #activeZones <= 0 then
                if lastHintShow then
                    lastHintShow = false
                    territoryHintShown = false
                    SendNUIMessage({ type = "territoryHint", show = false })
                end
                Wait(2000)
                goto continue_territory_loop
            end

            local pCoord = GetEntityCoords(ped)

            local nearZone = nil
            local nearDist = math.huge

            for _, zone in ipairs(activeZones) do
                if zone and zone.status == "active" then
                    local zoneRadius = tonumber(zone.radius) or 80.0
                    local dist3D = #(pCoord - vector3(zone.x, zone.y, zone.z))
                    local dx = (pCoord.x - zone.x)
                    local dy = (pCoord.y - zone.y)
                    local dist2D = math.sqrt((dx * dx) + (dy * dy))

                    if dist3D < drawDistance then
                        sleep = 0

                        DrawMarker(
                            1,
                            zone.x, zone.y, zone.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            (zoneRadius * 2.0), (zoneRadius * 2.0), 2.2,
                            220, 40, 40, 65,
                            false, false, 2, false,
                            nil, nil,
                            false
                        )

                        DrawMarker(
                            markerType,
                            zone.x, zone.y, zone.z + 0.08,
                            0.0, 0.0, 0.0,
                            0.0, 90.0, 0.0,
                            markerSize, markerSize, markerSize,
                            255, 255, 255, 255,
                            false, false, 2, true,
                            markerDict, markerTex,
                            false
                        )
                    end

                    -- نفس فكرة الغسيل: التفاعل يكون قريب جدًا من ماركر المركز
                    if dist2D < nearDist then
                        nearDist = dist2D
                        nearZone = zone
                    end
                end
            end

            local shouldShowHint = (nearZone ~= nil and nearDist < interactRadius and not territoryCaptureActive and not isOpen and not isAdminOpen and not shopIsOpen)
            if shouldShowHint ~= lastHintShow then
                lastHintShow = shouldShowHint
                territoryHintShown = shouldShowHint
                dbg("territoryHint -> show=%s nearDist=%.2f zone=%s", tostring(shouldShowHint), nearDist == math.huge and -1 or nearDist, tostring(nearZone and nearZone.id))
                SendNUIMessage({ type = "territoryHint", show = shouldShowHint })
            end

            if nearZone and nearDist < interactRadius and not territoryCaptureActive and not isOpen and not isAdminOpen and not shopIsOpen then
                if IsControlJustPressed(0, 38) then
                    dbg("territory E pressed -> zone=%s dist=%.2f", tostring(nearZone.id), nearDist)
                    TriggerServerEvent("gang:territoryTryCapture", nearZone.id)
                end
            end
        end

        Wait(sleep)
        ::continue_territory_loop::
    end
end)

-- ══════════════════════════════════════════════════════════
--  Laundry — غسيل الأموال
-- ══════════════════════════════════════════════════════════
local laundryState = {
    active         = false,
    gangId         = nil,
    nearSpot       = nil,
    activeSpot     = nil,
    startAtMs      = 0,
    durationSec    = 0,
    lastTickSecond = -1,
    finishSent     = false,
}

local laundrySpots = {}
local laundryBlips = {}
local laundryAllowedGangs = {}
local laundryVisibleSpots = 0
local rebuildLaundryBlips
local laundryBlipRebuildToken = 0

RegisterNetEvent("gang:laundryAccessData")
AddEventHandler("gang:laundryAccessData", function(allowed)
    laundryAllowedGangs = type(allowed) == "table" and allowed or {}
    local n = 0
    for _ in pairs(laundryAllowedGangs) do n = n + 1 end
    dbg("laundryAccessData -> allowed_gangs=%d", n)
    if not playerReady and not isPlayerReadyNow() then return end
    laundryBlipRebuildToken = laundryBlipRebuildToken + 1
    local token = laundryBlipRebuildToken

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(250)
        end
        Wait(1200)

        if token ~= laundryBlipRebuildToken then return end
        if rebuildLaundryBlips then
            rebuildLaundryBlips()
        end
    end)
end)

local function clearLaundryBlips()
    for _, b in ipairs(laundryBlips) do
        if DoesBlipExist(b) then
            RemoveBlip(b)
        end
    end
    laundryBlips = {}
end

rebuildLaundryBlips = function()
    if not playerReady and not isPlayerReadyNow() then
        return
    end

    clearLaundryBlips()
    laundryVisibleSpots = 0

    local cfg = Config.Laundry or {}
    local defaultSprite = tonumber(cfg.blip_default_sprite) or 500
    local defaultColor  = tonumber(cfg.blip_default_color) or 3
    local defaultScale  = tonumber(cfg.blip_default_scale) or 0.75
    local shortRange    = cfg.blip_short_range ~= false
    local defaultName   = tostring(cfg.blip_name or "نقطة غسيل الأموال")

    for _, spot in ipairs(laundrySpots) do
        local showBlip = spot.public_blip or laundryAllowedGangs[spot.gang_id]
        if showBlip then
            laundryVisibleSpots = laundryVisibleSpots + 1
            local sprite = tonumber(spot.blip)
            if not sprite then
                sprite = defaultSprite
            end

            if sprite and sprite > 0 then
                local b = AddBlipForCoord(spot.x, spot.y, spot.z)
                SetBlipSprite(b, sprite)
                SetBlipDisplay(b, 4)
                SetBlipScale(b, tonumber(spot.blip_scale) or defaultScale)
                SetBlipColour(b, tonumber(spot.blip_color) or defaultColor)
                SetBlipAsShortRange(b, shortRange)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(tostring(spot.blip_name or defaultName))
                EndTextCommandSetBlipName(b)

                table.insert(laundryBlips, b)
            end
        end
    end
end

local function rebuildLaundrySpots()
    laundrySpots = {}
    if type(Config) ~= "table" or type(Config.Gangs) ~= "table" then return end

    for gang_id, gang in pairs(Config.Gangs) do
        if type(gang) == "table"
        and type(gang.laundry) == "table"
        and gang.laundry.enabled ~= false   -- تجاهل النقطة إذا كانت معطّلة
        and type(gang.laundry.coords) == "table" then
            local c = gang.laundry.coords
            local x = tonumber(c[1] or c.x)
            local y = tonumber(c[2] or c.y)
            local z = tonumber(c[3] or c.z)
            if x and y and z
            and x == x and y == y and z == z
            and math.abs(x) < 10000 and math.abs(y) < 10000 and math.abs(z) < 2000 then
                table.insert(laundrySpots, {
                    gang_id     = gang_id,
                    x           = x,
                    y           = y,
                    z           = z,
                    public_blip = gang.laundry.public_blip == true,
                    blip        = gang.laundry.blip,
                    blip_color  = gang.laundry.blip_color,
                    blip_scale  = gang.laundry.blip_scale,
                    blip_name   = gang.laundry.blip_name,
                })
            end
        end
    end

    rebuildLaundryBlips()
end

CreateThread(function()
    while type(Config) ~= "table"
       or type(Config.Gangs) ~= "table"
       or type(Config.Laundry) ~= "table" do
        Wait(250)
    end

    waitForPlayerReady()
    playerReady = true

    rebuildLaundrySpots()
    TriggerServerEvent("gang:requestLaundryAccess")

    print("^2[ahmad_gangs Laundry] ^7Built " .. #laundrySpots .. " spot(s)")
    for i, s in ipairs(laundrySpots) do
        print(string.format("  #%d gang=%s x=%.3f y=%.3f z=%.3f", i, s.gang_id, s.x, s.y, s.z))
    end
    if #laundrySpots == 0 then
        print("^1[ahmad_gangs Laundry] ^7No spots in config")
    end

    -- إعدادات الماركر (ثابتة)
    local interactRadius = 2.0  -- نطاق الضغط E
    local cancelRadius   = 2.0  -- إذا ابتعد يلغي الغسيل
    local drawDistance   = 10.0 -- المسافة اللي يظهر فيها الماركر
    local markerDict = "a1"
    local markerTex  = "ahmad"
    local markerType = 9
    local markerSize = 2.8      -- حجم الماركر

    if not ensureMarkerTextureDict(markerDict, 6000) then
        markerDict = nil
        markerTex  = nil
        markerType = 1
    end

    local lastHintShow = false   -- لتتبع حالة الـ hint ومنع الإرسال المتكرر

    while true do
        local sleep    = 1000
        local ped      = PlayerPedId()
        if not ped or ped == 0 or not DoesEntityExist(ped) then
            Wait(300)
        else
            if not laundryState.active and laundryVisibleSpots <= 0 then
                if lastHintShow then
                    lastHintShow = false
                    SendNUIMessage({ type = "laundryHint", show = false })
                end
                Wait(2000)
                goto continue_laundry_loop
            end

            local pCoord   = GetEntityCoords(ped)
            local nearGang = nil
            local nearDist = math.huge

            if not laundryState.active then
                for _, spot in ipairs(laundrySpots) do
                    if spot.public_blip or laundryAllowedGangs[spot.gang_id] then
                        local dist3D = #(pCoord - vector3(spot.x, spot.y, spot.z))
                        local dx = (pCoord.x - spot.x)
                        local dy = (pCoord.y - spot.y)
                        local dist2D = math.sqrt((dx * dx) + (dy * dy))
                        if dist3D < drawDistance then
                            sleep = 0

                            DrawMarker(
                                markerType,
                                spot.x, spot.y, spot.z + 0.05,
                                0.0, 0.0, 0.0,
                                0.0, 90.0, 0.0,
                                markerSize, markerSize, markerSize,
                                255, 255, 255, 255,
                                false, false, 2, true,
                                markerDict, markerTex,
                                false
                            )

                            if dist2D < nearDist then
                                nearDist = dist2D
                                nearGang = spot
                            end
                        end
                    end
                end
            end

            laundryState.nearSpot = nearGang

            -- إرسال حالة الـ hint للـ NUI (فقط عند تغيّر الحالة)
            local shouldShowHint = (nearGang ~= nil and nearDist < interactRadius and not laundryState.active and not isOpen and not isAdminOpen and not shopIsOpen)
            if shouldShowHint ~= lastHintShow then
                lastHintShow = shouldShowHint
                dbg("laundryHint -> show=%s nearDist=%.2f gang=%s isOpen=%s isAdminOpen=%s shopIsOpen=%s", tostring(shouldShowHint), nearDist == math.huge and -1 or nearDist, tostring(nearGang and nearGang.gang_id), tostring(isOpen), tostring(isAdminOpen), tostring(shopIsOpen))
                SendNUIMessage({ type = "laundryHint", show = shouldShowHint })
            end

            -- التفاعل بضغطة E
            if nearGang and nearDist < interactRadius
               and not laundryState.active and not isOpen and not isAdminOpen then
                if IsControlJustPressed(0, 38) then
                    dbg("laundry E pressed -> gang=%s dist=%.2f", tostring(nearGang.gang_id), nearDist)
                    TriggerServerEvent("gang:startLaundry", nearGang.gang_id)
                end
            end

            if laundryState.active then
                sleep = 0

                -- تحديث عداد الواجهة بدون ثريد إضافي
                if laundryState.durationSec > 0 and laundryState.startAtMs > 0 then
                    local elapsed = math.floor((GetGameTimer() - laundryState.startAtMs) / 1000)
                    if elapsed > laundryState.durationSec then
                        elapsed = laundryState.durationSec
                    end

                    if elapsed ~= laundryState.lastTickSecond then
                        laundryState.lastTickSecond = elapsed
                        SendNUIMessage({ type = "laundryTick", elapsed = elapsed, total = laundryState.durationSec })
                    end

                    if elapsed >= laundryState.durationSec
                    and not laundryState.finishSent
                    and laundryState.gangId then
                        laundryState.finishSent = true
                        TriggerServerEvent("gang:finishLaundry", laundryState.gangId)
                    end
                end

                -- إلغاء تلقائي عند الابتعاد
                if laundryState.activeSpot then
                    local d = #(pCoord - vector3(laundryState.activeSpot.x, laundryState.activeSpot.y, laundryState.activeSpot.z))
                    if d > cancelRadius then
                        TriggerServerEvent("gang:cancelLaundry")
                    end
                end
            end

            Wait(sleep)
        end

        ::continue_laundry_loop::
    end
end)

RegisterNetEvent("laundry:started")
AddEventHandler("laundry:started", function(data)
    laundryState.active = true
    laundryState.gangId = data.gang_id or (laundryState.nearSpot and laundryState.nearSpot.gang_id) or nil
    laundryState.activeSpot = laundryState.nearSpot
    if not laundryState.activeSpot and laundryState.gangId then
        for _, s in ipairs(laundrySpots) do
            if s.gang_id == laundryState.gangId then
                laundryState.activeSpot = s
                break
            end
        end
    end
    laundryState.startAtMs = GetGameTimer()
    laundryState.durationSec = tonumber(data.duration) or 0
    laundryState.lastTickSecond = -1
    laundryState.finishSent = false
    SendNUIMessage({ type = "laundryHint", show = false })
    SendNUIMessage({ type = "laundryStart", duration = data.duration, dirty = data.dirty, clean = data.clean })

    -- فعّل الماوس كأن قائمة فُتحت
    if not isOpen and not isAdminOpen then
        SetNuiFocus(true, true)
    end
end)

RegisterNetEvent("laundry:done")
AddEventHandler("laundry:done", function(data)
    laundryState.active = false
    laundryState.gangId = nil
    laundryState.activeSpot = nil
    laundryState.startAtMs = 0
    laundryState.durationSec = 0
    laundryState.lastTickSecond = -1
    laundryState.finishSent = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "laundryDone", clean = data.clean })
end)

RegisterNetEvent("laundry:cancelled")
AddEventHandler("laundry:cancelled", function()
    laundryState.active = false
    laundryState.gangId = nil
    laundryState.activeSpot = nil
    laundryState.startAtMs = 0
    laundryState.durationSec = 0
    laundryState.lastTickSecond = -1
    laundryState.finishSent = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "laundryCancelled" })
end)

RegisterNetEvent("laundry:alreadyActive")
AddEventHandler("laundry:alreadyActive", function()
    SendNUIMessage({ type = "notify", notify_type = "warning", title = "تنبيه", message = "لديك جلسة غسيل نشطة بالفعل" })
end)

RegisterNUICallback("cancelLaundry", function(_, cb)
    TriggerServerEvent("gang:cancelLaundry")
    cb({})
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearLaundryBlips()
    clearTerritoryBlips()
    clearShopBlips()
end)

-- ══════════════════════════════════════════════════════════
--  متجر الأسلحة — Client
-- ══════════════════════════════════════════════════════════

local shopSpots     = {}
local shopBlips     = {}
local shopOwnedGangs = {}
local shopVisibleSpots = 0
local rebuildShopBlips  -- forward declare
local shopBlipRebuildToken = 0

RegisterNetEvent("gang:shopOwnedData")
AddEventHandler("gang:shopOwnedData", function(owned)
    shopOwnedGangs = type(owned) == "table" and owned or {}
    if not playerReady and not isPlayerReadyNow() then return end
    shopBlipRebuildToken = shopBlipRebuildToken + 1
    local token = shopBlipRebuildToken

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(250)
        end
        Wait(1200)

        if token ~= shopBlipRebuildToken then return end
        if rebuildShopBlips then
            rebuildShopBlips()
        end
    end)
end)

RegisterNetEvent("gang:shopItemsData")
AddEventHandler("gang:shopItemsData", function(data)
    shopIsOpen = true
    SendNUIMessage({ type = "territoryHint", show = false })
    SendNUIMessage({ type = "laundryHint", show = false })
    SendNUIMessage({ type = "shopHint", show = false })
    if not isOpen and not isAdminOpen then
        SetNuiFocus(true, true)
    end
    SendNUIMessage({ type = "openShopBuy", data = data, theme = getUiThemePayload() })
end)

RegisterNetEvent("gang:shopPurchased")
AddEventHandler("gang:shopPurchased", function(data)
    SendNUIMessage({ type = "shopPurchased", data = data })
end)

RegisterNetEvent("gang:shopManageData")
AddEventHandler("gang:shopManageData", function(data)
    SendNUIMessage({ type = "shopManageData", data = data })
end)

local function clearShopBlips()
    for _, b in ipairs(shopBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    shopBlips = {}
end

rebuildShopBlips = function()
    if not playerReady and not isPlayerReadyNow() then
        return
    end

    clearShopBlips()
    shopVisibleSpots = 0

    local cfg = Config.WeaponShop or {}
    local defaultSprite = tonumber(cfg.blip_default_sprite) or 110
    local defaultColor  = tonumber(cfg.blip_default_color)  or 1
    local defaultScale  = tonumber(cfg.blip_default_scale)  or 0.8
    local shortRange    = cfg.blip_short_range ~= false
    local defaultName   = tostring(cfg.blip_name or "متجر الأسلحة")

    for _, spot in ipairs(shopSpots) do
        if shopOwnedGangs[spot.gang_id] then
            shopVisibleSpots = shopVisibleSpots + 1
            local sprite = tonumber(spot.blip) or defaultSprite
            if sprite and sprite > 0 then
                local b = AddBlipForCoord(spot.x, spot.y, spot.z)
                SetBlipSprite(b, sprite)
                SetBlipDisplay(b, 4)
                SetBlipScale(b, defaultScale)
                SetBlipColour(b, tonumber(spot.blip_color) or defaultColor)
                SetBlipAsShortRange(b, shortRange)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(tostring(spot.blip_name or defaultName))
                EndTextCommandSetBlipName(b)
                table.insert(shopBlips, b)
            end
        end
    end
end

local function rebuildShopSpots()
    shopSpots = {}
    if type(Config) ~= "table" or type(Config.Gangs) ~= "table" then return end
    for gang_id, gang in pairs(Config.Gangs) do
        local ws = gang.weapon_shop
        if type(ws) == "table" and type(ws.coords) == "table" then
            local c = ws.coords
            local x = tonumber(c[1] or c.x)
            local y = tonumber(c[2] or c.y)
            local z = tonumber(c[3] or c.z)
            if x and y and z
            and x == x and y == y and z == z
            and math.abs(x) < 10000 and math.abs(y) < 10000 and math.abs(z) < 2000 then
                table.insert(shopSpots, {
                    gang_id   = gang_id,
                    x         = x,
                    y         = y,
                    z         = z,
                    blip      = ws.blip,
                    blip_color = ws.blip_color,
                    blip_name  = ws.blip_name,
                })
            end
        end
    end
    rebuildShopBlips()
end

-- ── Shop Proximity Thread
CreateThread(function()
    while type(Config) ~= "table"
       or type(Config.Gangs) ~= "table"
       or type(Config.WeaponShop) ~= "table" do
        Wait(250)
    end

    waitForPlayerReady()
    playerReady = true

    rebuildShopSpots()
    TriggerServerEvent("gang:requestShopAccess")

    local markerDict = "a1"
    local markerTex  = "ahmad1"
    local markerType = 9
    local markerSize = 2.5
    local interactRadius = 1.0
    local drawDistance   = 15.0

    if not ensureMarkerTextureDict(markerDict, 6000) then
        markerDict = nil
        markerTex  = nil
        markerType = 1
    end

    local lastHintShow = false

    while true do
        local sleep    = 1000
        local ped      = PlayerPedId()
        if not ped or ped == 0 or not DoesEntityExist(ped) then
            Wait(300)
        else
            if not shopIsOpen and shopVisibleSpots <= 0 then
                if lastHintShow then
                    lastHintShow = false
                    SendNUIMessage({ type = "shopHint", show = false })
                end
                Wait(2000)
                goto continue_shop_loop
            end

            local pCoord   = GetEntityCoords(ped)
            local nearShop = nil
            local nearDist = math.huge

            if not shopIsOpen then
                for _, spot in ipairs(shopSpots) do
                    if shopOwnedGangs[spot.gang_id] then
                        local dist = #(pCoord - vector3(spot.x, spot.y, spot.z))
                        if dist < drawDistance then
                            sleep = 0
                            DrawMarker(
                                markerType,
                                spot.x, spot.y, spot.z + 0.05,
                                0.0, 0.0, 0.0,
                                0.0, 90.0, 0.0,
                                markerSize, markerSize, markerSize,
                                255, 255, 255, 255,
                                false, false, 2, true,
                                markerDict, markerTex,
                                false
                            )
                            if dist < nearDist then
                                nearDist = dist
                                nearShop = spot
                            end
                        end
                    end
                end
            end

            local shouldShowHint = (nearShop ~= nil and nearDist < interactRadius and not shopIsOpen)
            if shouldShowHint ~= lastHintShow then
                lastHintShow = shouldShowHint
                SendNUIMessage({ type = "shopHint", show = shouldShowHint })
            end

            if nearShop and nearDist < interactRadius
               and not shopIsOpen and not isOpen and not isAdminOpen then
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("gang:getShopItems", nearShop.gang_id)
                end
            end

            Wait(sleep)
        end

        ::continue_shop_loop::
    end
end)

-- ══════════════════════════════════════════════════════════
--  نظام الايتم الخاص — Special Item Blip + Deposit Marker
-- ══════════════════════════════════════════════════════════

local specialBlipHolder  = nil  -- بلب على الشخص الحامل
local specialBlipDeposit = nil  -- بلب ثابت على موقع الإيداع
local specialBlipDrop    = nil  -- بلب على الصندوق الساقط
local iHoldSpecialItem  = false -- هل أنا حامل الايتم الخاص؟
local specialDepositHintShown = false
local specialDepositCoords = nil -- تُحدّث من السيرفر
local specialItemHolderData = nil
local specialItemDropData = nil
local specialDropObject = nil
local canSeeSpecialDeposit = false
local nextSpecialPickupTryAt = 0
local specialDownNotified = false
local SPECIAL_ITEM_DOWN_HEALTH = 140
local SPECIAL_DROP_MODEL = GetHashKey("prop_cs_cardbox_01")

local function isSpecialDownState(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    local okComa, inComa = pcall(function()
        return tvRP and type(tvRP.isInComa) == "function" and tvRP.isInComa() == true
    end)
    if okComa and inComa then
        return true
    end

    if IsEntityDead(ped)
        or IsPedDeadOrDying(ped, true)
        or IsPedFatallyInjured(ped)
        or ((tonumber(GetEntityHealth(ped)) or 0) <= SPECIAL_ITEM_DOWN_HEALTH) then
        return true
    end

    local st = LocalPlayer and LocalPlayer.state
    if st then
        if st.dead == true
            or st.isDead == true
            or st.isdead == true
            or st.inLastStand == true
            or st.inlaststand == true
            or st.coma == true then
            return true
        end
    end

    return false
end

local function ensureModelLoaded(modelHash, timeoutMs)
    if not modelHash or modelHash == 0 then return false end
    if HasModelLoaded(modelHash) then return true end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + (timeoutMs or 3000)
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(50)
    end
    return true
end

local function getSpecialDepositCoords()
    if specialDepositCoords then
        return specialDepositCoords.x, specialDepositCoords.y, specialDepositCoords.z
    end

    local cfg    = Config.TerritoryRewards
    local marker = cfg and cfg.deposit_marker
    local mc     = marker and marker.coords
    if type(mc) == "table" then
        local x = tonumber(mc[1] or mc.x)
        local y = tonumber(mc[2] or mc.y)
        local z = tonumber(mc[3] or mc.z)
        if x and y and z then
            return x, y, z
        end
    end

    return nil, nil, nil
end

-- تنظيف البلبين
local function clearSpecialBlip()
    if specialBlipHolder and DoesBlipExist(specialBlipHolder) then
        RemoveBlip(specialBlipHolder)
    end
    specialBlipHolder = nil
    if specialBlipDeposit and DoesBlipExist(specialBlipDeposit) then
        RemoveBlip(specialBlipDeposit)
    end
    specialBlipDeposit = nil

    if specialBlipDrop and DoesBlipExist(specialBlipDrop) then
        RemoveBlip(specialBlipDrop)
    end
    specialBlipDrop = nil

    if specialDropObject and DoesEntityExist(specialDropObject) then
        SetEntityAsMissionEntity(specialDropObject, true, true)
        DeleteObject(specialDropObject)
    end
    specialDropObject = nil
end

-- إنشاء أو تحديث البلبين
local function updateSpecialBlip(holder, dropData)
    clearSpecialBlip()

    -- بلب 1: على الشخص الحامل
    if holder and holder.src then
        local holderPed = GetPlayerPed(GetPlayerFromServerId(holder.src))
        if holderPed and holderPed ~= 0 and DoesEntityExist(holderPed) then
            specialBlipHolder = AddBlipForEntity(holderPed)
        else
            -- fallback لو اللاعب مش مرئي
            specialBlipHolder = nil
        end

        if specialBlipHolder then
            SetBlipSprite(specialBlipHolder, 84)   -- جمجمة
            SetBlipScale(specialBlipHolder, 1.3)
            SetBlipDisplay(specialBlipHolder, 4)
            SetBlipColour(specialBlipHolder, 1)    -- أحمر
            SetBlipAsShortRange(specialBlipHolder, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("✦ " .. (holder.name or "لاعب") .. " — يحمل الكنز المفقود")
            EndTextCommandSetBlipName(specialBlipHolder)
            SetBlipFlashes(specialBlipHolder, true)
        end
    end

    -- بلب 2: ثابت على موقع الإيداع
    local mx, my, mz = getSpecialDepositCoords()
    if canSeeSpecialDeposit and mx and my and mz then
        specialBlipDeposit = AddBlipForCoord(mx, my, mz)
        SetBlipSprite(specialBlipDeposit, 365)
        SetBlipScale(specialBlipDeposit, 1.0)
        SetBlipDisplay(specialBlipDeposit, 4)
        SetBlipColour(specialBlipDeposit, 46)
        SetBlipAsShortRange(specialBlipDeposit, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("📦 موقع إيداع الكنز المفقود")
        EndTextCommandSetBlipName(specialBlipDeposit)
    end

    -- صندوق على موقع السقوط (بدون بلب على الخريطة)
    if type(dropData) == "table" then
        local dx = tonumber(dropData.x)
        local dy = tonumber(dropData.y)
        local dz = tonumber(dropData.z)
        if dx and dy and dz then
            specialBlipDrop = nil

            if ensureModelLoaded(SPECIAL_DROP_MODEL, 2500) then
                specialDropObject = CreateObjectNoOffset(SPECIAL_DROP_MODEL, dx, dy, dz - 0.35, false, false, false)
                if specialDropObject and specialDropObject ~= 0 and DoesEntityExist(specialDropObject) then
                    PlaceObjectOnGroundProperly(specialDropObject)
                    FreezeEntityPosition(specialDropObject, true)
                    SetEntityInvincible(specialDropObject, true)
                else
                    specialDropObject = nil
                end
                SetModelAsNoLongerNeeded(SPECIAL_DROP_MODEL)
            end
        end
    end
end

-- استقبال حالة البلب من السيرفر
RegisterNetEvent("gang:specialItemBlip")
AddEventHandler("gang:specialItemBlip", function(payload)
    local holder = payload
    local dropData = nil
    if type(payload) == "table" and (payload.holder ~= nil or payload.drop ~= nil) then
        holder = payload.holder
        dropData = payload.drop
    end

    local myId = GetPlayerServerId(PlayerId())
    specialItemHolderData = holder
    specialItemDropData = dropData
    iHoldSpecialItem = (holder ~= nil and holder.src == myId)
    updateSpecialBlip(holder, dropData)
end)

RegisterNetEvent("gang:specialDepositPoint")
AddEventHandler("gang:specialDepositPoint", function(point)
    canSeeSpecialDeposit = (type(point) == "table")

    if type(point) == "table" then
        local x = tonumber(point.x)
        local y = tonumber(point.y)
        local z = tonumber(point.z)
        if x and y and z then
            specialDepositCoords = { x = x, y = y, z = z }
        else
            specialDepositCoords = nil
        end
    else
        specialDepositCoords = nil
    end

    updateSpecialBlip(specialItemHolderData, specialItemDropData)
end)

-- استقبال فوز الايتم الخاص (نوتيفاي جميل عبر NUI)
RegisterNetEvent("gang:specialItemWon")
AddEventHandler("gang:specialItemWon", function(data)
    SendNUIMessage({
        type   = "specialItemWon",
        label  = data.label  or "الايتم الخاص",
        icon   = data.icon   or "📦",
        looted = data.looted or false,
    })
end)

-- طلب حالة البلب عند جهوزية الكلايت
AddEventHandler("onClientResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    CreateThread(function()
        Wait(4500)
        TriggerServerEvent("gang:requestSpecialBlip")
        TriggerServerEvent("gang:requestSpecialDepositPoint")
    end)
end)

-- Thread: ماركر الإيداع + تفاعل E + كشف الموت
CreateThread(function()
    while type(Config) ~= "table" or type(Config.TerritoryRewards) ~= "table" do
        Wait(500)
    end

    waitForPlayerReady()

    local interactDist  = 2.5
    local drawDist      = 30.0
    local markerSize    = 2.0

    -- نفس التكستشر المستخدمة في بقية الماركرات
    local mDict = "a1"
    local mTex  = "ahmad3"
    local mType = 9
    if not ensureMarkerTextureDict(mDict, 6000) then
        mDict = nil ; mTex = nil ; mType = 1
    end

    while true do
        local sleep = 800
        local ped   = PlayerPedId()

        if ped and ped ~= 0 and DoesEntityExist(ped) then
            if iHoldSpecialItem then
                local isDown = isSpecialDownState(ped)
                if isDown then
                    if not specialDownNotified then
                        local dPos = GetEntityCoords(ped)
                        TriggerServerEvent("gang:specialHolderDown", {
                            x = dPos.x,
                            y = dPos.y,
                            z = dPos.z,
                        }, "down_client")
                        specialDownNotified = true
                    end
                else
                    specialDownNotified = false
                end

                local pCoord = GetEntityCoords(ped)
                local mx, my, mz = getSpecialDepositCoords()
                local dist = math.huge
                if mx and my and mz then
                    dist = #(pCoord - vector3(mx, my, mz))
                end

                if mx and my and mz and dist < drawDist then
                    sleep = 0

                    DrawMarker(
                        mType,
                        mx, my, mz + 0.08,
                        0.0, 0.0, 0.0,
                        0.0, 90.0, 0.0,
                        markerSize, markerSize, markerSize,
                        255, 255, 255, 255,
                        false, false, 2, true,
                        mDict, mTex,
                        false
                    )
                end

                local shouldHint = (mx and my and mz and dist < interactDist and not isOpen and not isAdminOpen)
                if shouldHint ~= specialDepositHintShown then
                    specialDepositHintShown = shouldHint
                    SendNUIMessage({ type = "specialDepositHint", show = shouldHint })
                end

                if mx and my and mz and dist < interactDist and not isOpen and not isAdminOpen then
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent("gang:depositSpecialItem")
                    end
                end
            else
                specialDownNotified = false
                local nowMs = GetGameTimer()
                local drop = specialItemDropData
                if type(drop) == "table" then
                    local dx = tonumber(drop.x)
                    local dy = tonumber(drop.y)
                    local dz = tonumber(drop.z)
                    if dx and dy and dz then
                        local pCoord = GetEntityCoords(ped)
                        local distDrop = #(pCoord - vector3(dx, dy, dz))
                        if distDrop < drawDist then
                            sleep = 180

                            if distDrop <= 1.55 and not isOpen and not isAdminOpen and not shopIsOpen then
                                local pickerDown = isSpecialDownState(ped)

                                if (not pickerDown) and nowMs >= nextSpecialPickupTryAt then
                                    nextSpecialPickupTryAt = nowMs + 1000
                                    TriggerServerEvent("gang:pickupDroppedSpecialItem")
                                end
                            end
                        else
                            sleep = 700
                        end
                    else
                        sleep = 1600
                    end
                else
                    sleep = 1800
                end

                if specialDepositHintShown then
                    specialDepositHintShown = false
                    SendNUIMessage({ type = "specialDepositHint", show = false })
                end
            end

        end

        Wait(sleep)
    end
end)

-- ── NUI Callbacks for Shop
RegisterNUICallback("closeShopBuy", function(_, cb)
    shopIsOpen = false
    if not isOpen and not isAdminOpen then
        SetNuiFocus(false, false)
    end
    cb({})
end)

RegisterNUICallback("shopBuyWeapon", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local weapon = sanitizeWeaponHash(data and data.weapon)
    if gangId ~= "" and weapon ~= "" then
        TriggerServerEvent("gang:buyWeapon", gangId, weapon)
    end
    cb({})
end)

RegisterNUICallback("getShopManage", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:getShopManage", gangId)
    end
    cb({})
end)

RegisterNUICallback("shopPurchase", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:purchaseShop", gangId)
    end
    cb({})
end)

RegisterNUICallback("shopRestock", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local weapon = sanitizeWeaponHash(data and data.weapon)
    if gangId ~= "" and weapon ~= "" then
        TriggerServerEvent("gang:shopRestock", gangId, weapon)
    end
    cb({})
end)

RegisterNUICallback("shopSetPrice", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local weapon = sanitizeWeaponHash(data and data.weapon)
    local price = toSafeInt(data and data.price, 1, 100000000)
    if gangId ~= "" and weapon ~= "" then
        TriggerServerEvent("gang:shopSetPrice", gangId, weapon, price)
    end
    cb({})
end)

RegisterNUICallback("withdrawDirty", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    local amount = data and data.amount
    if amount ~= "all" then
        amount = toSafeInt(amount, 0, 100000000)
    end
    if gangId ~= "" then
        TriggerServerEvent("gang:withdrawDirty", gangId, amount)
    end
    cb({})
end)

-- ════════════════════════════════════════════════════════
--  نظام لبس العصابة — Client Side
-- ════════════════════════════════════════════════════════

local GANG_OUTFIT_MODEL = GetHashKey("mp_m_freemode_01")

local function ensureGangOutfitModel()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return ped end
    if GetEntityModel(ped) == GANG_OUTFIT_MODEL then return ped end
    if not IsModelInCdimage(GANG_OUTFIT_MODEL) or not IsModelValid(GANG_OUTFIT_MODEL) then return ped end

    local hp = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    RequestModel(GANG_OUTFIT_MODEL)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(GANG_OUTFIT_MODEL) do
        if GetGameTimer() > deadline then
            return ped
        end
        Wait(50)
    end

    SetPlayerModel(PlayerId(), GANG_OUTFIT_MODEL)
    SetModelAsNoLongerNeeded(GANG_OUTFIT_MODEL)

    local newPed = PlayerPedId()
    if not newPed or newPed == 0 or not DoesEntityExist(newPed) then
        return ped
    end

    SetEntityCoordsNoOffset(newPed, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(newPed, heading)

    local maxHp = tonumber(GetEntityMaxHealth(newPed)) or 200
    SetEntityHealth(newPed, math.max(100, math.min(maxHp, tonumber(hp) or 200)))
    SetPedArmour(newPed, math.max(0, math.min(100, tonumber(armor) or 0)))
    return newPed
end

--- يجمع بيانات مكونات Ped الحالي (ملابس + accessory)
local function getPedOutfitData(ped)
    local comps = {}
    for i = 0, 11 do
        comps[i + 1] = {
            comp     = i,
            drawable = GetPedDrawableVariation(ped, i),
            texture  = GetPedTextureVariation(ped, i),
            palette  = GetPedPaletteVariation(ped, i),
        }
    end
    local props = {}
    for i = 0, 9 do
        props[i + 1] = {
            prop     = i,
            drawable = GetPedPropIndex(ped, i),
            texture  = GetPedPropTextureIndex(ped, i),
        }
    end
    return { components = comps, props = props }
end

--- يطبق بيانات الـ outfit على Ped
local function applyOutfitToPed(ped, outfitData)
    if not outfitData or type(outfitData) ~= "table" then return end

    if type(outfitData.components) == "table" then
        for _, c in ipairs(outfitData.components) do
            SetPedComponentVariation(ped, c.comp, c.drawable, c.texture, c.palette or 0)
        end
    end

    if type(outfitData.props) == "table" then
        for _, p in ipairs(outfitData.props) do
            if p.drawable == -1 then
                ClearPedProp(ped, p.prop)
            else
                SetPedPropIndex(ped, p.prop, p.drawable, p.texture, true)
            end
        end
    end
end

--- تلقي البيانات من السيرفر وإرسالها للـ NUI
RegisterNetEvent("gang:outfitData")
AddEventHandler("gang:outfitData", function(data)
    SendNUIMessage({ type = "outfitData", data = data })
end)

--- تطبيق الـ outfit على اللاعب (withAnim=true → يشغّل animation رفع الأيدي أولاً)
RegisterNetEvent("gang:applyOutfit")
AddEventHandler("gang:applyOutfit", function(outfitData, withAnim)
    local ped = ensureGangOutfitModel()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    applyOutfitToPed(ped, outfitData)
end)

--- جلب بيانات الـ outfit عند فتح التاب
RegisterNUICallback("getOutfitData", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:getOutfitData", gangId)
    end
    cb({})
end)

--- حفظ سكن اللاعب الحالي كسكن العصابة
RegisterNUICallback("setGangOutfit", function(data, cb)
    local ped = PlayerPedId()
    local gangId = sanitizeGangId(data and data.gang_id)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local outfitData = getPedOutfitData(ped)
        if gangId ~= "" then
            TriggerServerEvent("gang:saveOutfit", gangId, outfitData)
        end
    end
    cb({})
end)

--- لبس سكن العصابة
RegisterNUICallback("wearGangOutfit", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:wearGangOutfit", gangId)
    end
    cb({})
end)

--- إلباس شخص بالسيتيزن سكن العصابة
RegisterNUICallback("dressNearbyPlayer", function(data, cb)
    local cid = tonumber(data.cid)
    if not cid or cid <= 0 then cb({}); return end
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:dressNearbyPlayer", gangId, cid)
    end
    cb({})
end)

--- إلباس جميع أعضاء العصابة المتصلين
RegisterNUICallback("dressGangAll", function(data, cb)
    local gangId = sanitizeGangId(data and data.gang_id)
    if gangId ~= "" then
        TriggerServerEvent("gang:dressAllGang", gangId)
    end
    cb({})
end)

print("^2[ahmad_gangs] ^7Client loaded")
