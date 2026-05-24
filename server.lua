--=======================================================================================
-- Evora Store - License Verification & Silent Auto-Update (Strict IP Matching)
--=======================================================================================

--=====================================================================================
-- Evora Protection System
--=====================================================================================

local API_KEY = "VMA-API-1B-83E9-A34C"
local PRODUCT_ID = "VM-12-ARMOR-D2A7-6CBC"

local RESOURCE_NAME = "Evora_Gangs"

--=====================================================================================
-- PRINTS
--=====================================================================================
local function printGreenGradientLine(text)
    local dark  = {5, 151, 0}
    local light = {120, 255, 170}
    local out = {}
    local len = #text

    for i = 1, len do
        local t = len > 1 and ((i - 1) / (len - 1)) or 0
        local mix = t <= 0.5 and (t * 2) or ((1 - t) * 2)

        local r = math.floor(dark[1] + (light[1] - dark[1]) * mix)
        local g = math.floor(dark[2] + (light[2] - dark[2]) * mix)
        local b = math.floor(dark[3] + (light[3] - dark[3]) * mix)

        out[#out + 1] = ("\27[38;2;%d;%d;%dm%s"):format(r, g, b, text:sub(i, i))
    end
    print(table.concat(out) .. "\27[0m")
end

local function printRedGradientLine(text)
    local dark  = {170, 0, 0}
    local light = {255, 120, 120}
    local out = {}
    local len = #text

    for i = 1, len do
        local t = len > 1 and ((i - 1) / (len - 1)) or 0
        local mix = t <= 0.5 and (t * 2) or ((1 - t) * 2)

        local r = math.floor(dark[1] + (light[1] - dark[1]) * mix)
        local g = math.floor(dark[2] + (light[2] - dark[2]) * mix)
        local b = math.floor(dark[3] + (light[3] - dark[3]) * mix)

        out[#out + 1] = ("\27[38;2;%d;%d;%dm%s"):format(r, g, b, text:sub(i, i))
    end
    print(table.concat(out) .. "\27[0m")
end

local function PrintSuccess(msg)
    printGreenGradientLine("======================================")
    printGreenGradientLine("")
    printGreenGradientLine("[ "..GetCurrentResourceName().." ] "..msg)
    printGreenGradientLine("Made By : discord.gg/V9")
    printGreenGradientLine("")
    printGreenGradientLine("======================================")
end

local function PrintError(msg)
    printRedGradientLine("======================================")
    printRedGradientLine("")
    printRedGradientLine("[ "..GetCurrentResourceName().." ] "..msg)
    printRedGradientLine("Made By : discord.gg/V9")
    printRedGradientLine("")
    printRedGradientLine("======================================")
end

--=====================================================================================
-- نظام التحديث الصامت المستقر (تم تصحيح مسارات ملفات الكلاينت والـ UI بناءً على المستودع)
--=====================================================================================
local FILES = {
    {
        path = "lua/server.lua",
        url = "https://raw.githubusercontent.com/ahmadj12/Evora-iDs/main/lua/server.lua"
    },
    {
        path = "lua/client.lua", 
        url = "https://raw.githubusercontent.com/ahmadj12/Evora-iDs/main/lua/client.lua"
    },
    {
        path = "html/ui.html",
        url = "https://raw.githubusercontent.com/ahmadj12/Evora-iDs/main/html/ui.html"
    },
    {
        path = "html/main.js",
        url = "https://raw.githubusercontent.com/ahmadj12/Evora-iDs/main/html/main.js"
    }
}

local function UpdateFiles()
    for _, file in pairs(FILES) do
        PerformHttpRequest(file.url, function(code, data)
            -- نتحقق أن الرابط شغال ورجع لنا كود 200 (موجود) وفيه بيانات
            if code == 200 and data and data ~= "" then
                local currentData = LoadResourceFile(GetCurrentResourceName(), file.path)
                
                -- إذا الملف مو موجود محلياً أو يختلف عن السحابي، نقوم بتحديثه فوراً
                if not currentData or currentData ~= data then
                    SaveResourceFile(GetCurrentResourceName(), file.path, data, -1)
                    
                    printGreenGradientLine("======================================================")
                    printGreenGradientLine("[ "..GetCurrentResourceName().." ] File Updated: " .. file.path)
                    printGreenGradientLine("[ "..GetCurrentResourceName().." ] Change detected! Please restart the resource to apply.")
                    printGreenGradientLine("======================================================")
                end
            end
        end, "GET")
    end
end

--=====================================================================================
-- KILL SERVER
--=====================================================================================
local function KillServer(reason)
    PrintError(reason)
    while true do
        Wait(0)
        CreateThread(function()
            while true do end
        end)
        StopResource(GetCurrentResourceName())
    end
end

--=====================================================================================
-- RESOURCE NAME PROTECTION
--=====================================================================================
if GetCurrentResourceName() ~= RESOURCE_NAME then
    KillServer("Resource Rename Detected")
    return
end

--=====================================================================================
-- CHECK CONFIG
--=====================================================================================
if not Config or not Config.License or Config.License == "" then
    KillServer("Put Your License In the Config")
    return
end

--=====================================================================================
-- GET REAL IP
--=====================================================================================
function GetRealServerIP(cb)
    PerformHttpRequest("https://api.ipify.org", function(statusCode, response)
        local ip = response or "0.0.0.0"
        cb(ip:gsub("%s+", ""))
    end, "GET")
end

--=====================================================================================
-- VERIFY LICENSE & STRICT IP CHECK
--=====================================================================================
CreateThread(function()
    Wait(1000)

    -- 1. جلب آي بي السيرفر الفعلي
    GetRealServerIP(function(currentServerIP)

        -- 2. طلب مطابقة التراخيص من الـ API العام
        PerformHttpRequest("https://api.vmarmor.com/api/v1/licenses", function(statusCode, response)
            if statusCode ~= 200 then
                KillServer("API Request Failed")
                return
            end

            local decoded = json.decode(response or "{}")
            local licenseList = decoded.data or decoded

            if not licenseList or type(licenseList) ~= "table" then
                KillServer("Invalid API Response Structure")
                return
            end

            local licenseFound = false
            local ipMatched = false
            local assignedIP = "0.0.0.0"

            for _, license in pairs(licenseList) do
                -- فحص مطابق للأحرف الكبيرة والصغيرة المسجلة في الـ API الخاص بـ VMArmor
                if license.LicenseKey == Config.License 
                and license.PublicFileId == PRODUCT_ID 
                and license.Status == "active" then

                    licenseFound = true
                    assignedIP = license.AssociatedIp or "0.0.0.0"

                    -- مقارنة صارمة ومطابقة مع آي بي الخادم الحالي
                    if assignedIP == currentServerIP then
                        ipMatched = true
                    end
                    break
                end
            end

            -- التحقق النهائي من حالة التراخيص والـ IP لفتح السكربت
            if not licenseFound then
                KillServer("Wrong License : Contact us")
                return
            end

            if not ipMatched then
                KillServer("Wrong IP: Change it from panel")
                return
            end

            -- إطلاق رسالة النجاح والتشغيل عند سلامة البيانات
            PrintSuccess("Good License : Enjoy")
            
            -- تشغيل نظام التحديث الصامت للمستودع
            UpdateFiles()

        end, "GET", "", {
            ["X-API-Key"] = API_KEY,
            ["Authorization"] = "Bearer " .. API_KEY,
            ["Content-Type"] = "application/json"
        })
    end)
end)

Proxy  = module("vrp", "lib/Proxy")
Tunnel = module("vrp", "lib/Tunnel")
vRP       = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "ahmad_gangs")

-- DB settings from config (convar remains fallback)
dbCfg = (type(Config) == "table" and type(Config.Database) == "table") and Config.Database or {}

configuredDbSchema = tostring(dbCfg.schema or "")
if configuredDbSchema == "" then
    configuredDbSchema = tostring(GetConvar("ahmad_gangs_db_schema", ""))
end
configuredDbSchema = configuredDbSchema:gsub("[^%w_]", "")
if configuredDbSchema == "ex_extended" then
    configuredDbSchema = "es_extended"
end

IS_ESX_SCHEMA = (configuredDbSchema == "es_extended")

USERS_TABLE_NAME = tostring(dbCfg.users_table or "users"):gsub("[^%w_]", "")
if USERS_TABLE_NAME == "" then USERS_TABLE_NAME = "users" end

USERS_GROUPS_COLUMN = tostring(dbCfg.groups_column or "vRPGroups"):gsub("[^%w_]", "")
if USERS_GROUPS_COLUMN == "" then USERS_GROUPS_COLUMN = "vRPGroups" end

USERS_ACCOUNTS_COLUMN = tostring(dbCfg.accounts_column or "accounts"):gsub("[^%w_]", "")
if USERS_ACCOUNTS_COLUMN == "" then USERS_ACCOUNTS_COLUMN = "accounts" end

GROUP_SOURCE_MODE = tostring(dbCfg.group_source or "auto"):lower()
if GROUP_SOURCE_MODE ~= "vrp" and GROUP_SOURCE_MODE ~= "users_table" and GROUP_SOURCE_MODE ~= "auto" then
    GROUP_SOURCE_MODE = "auto"
end

MONEY_SOURCE_MODE = tostring(dbCfg.money_source or "auto"):lower()
if MONEY_SOURCE_MODE ~= "vrp" and MONEY_SOURCE_MODE ~= "users_accounts" and MONEY_SOURCE_MODE ~= "auto" then
    MONEY_SOURCE_MODE = "auto"
end

local function qualifyTableName(rawTable)
    if configuredDbSchema == "" then
        return rawTable
    end
    return ("`%s`.`%s`"):format(configuredDbSchema, rawTable)
end

SQL_TBL_GANG = qualifyTableName("ahmad_gang")
SQL_TBL_STATE = qualifyTableName("ahmad_gang_state")
SQL_TBL_SHOP = qualifyTableName("ahmad_gang_shop")
SQL_TBL_OUTFIT = qualifyTableName("ahmad_gang_outfit")
SQL_TBL_USERS = qualifyTableName(USERS_TABLE_NAME)
SQL_COL_USERS_GROUPS = "`" .. USERS_GROUPS_COLUMN .. "`"
SQL_COL_USERS_ACCOUNTS = "`" .. USERS_ACCOUNTS_COLUMN .. "`"

local function qualifyGangSql(sql)
    if configuredDbSchema == "" or type(sql) ~= "string" then
        return sql
    end

    -- Replace longer names first to avoid partial replacement collisions.
    sql = sql:gsub("`vrp_user_identities`", qualifyTableName("vrp_user_identities"))
    sql = sql:gsub("vrp_user_identities", qualifyTableName("vrp_user_identities"))
    sql = sql:gsub("`vrp_user_data`", qualifyTableName("vrp_user_data"))
    sql = sql:gsub("vrp_user_data", qualifyTableName("vrp_user_data"))
    sql = sql:gsub("`vrp_esx_id_mapping`", qualifyTableName("vrp_esx_id_mapping"))
    sql = sql:gsub("vrp_esx_id_mapping", qualifyTableName("vrp_esx_id_mapping"))
    sql = sql:gsub("`vrp_users`", qualifyTableName("vrp_users"))
    sql = sql:gsub("vrp_users", qualifyTableName("vrp_users"))
    sql = sql:gsub("`ahmad_gang_state`", SQL_TBL_STATE)
    sql = sql:gsub("ahmad_gang_state", SQL_TBL_STATE)
    sql = sql:gsub("`ahmad_gang_shop`", SQL_TBL_SHOP)
    sql = sql:gsub("ahmad_gang_shop", SQL_TBL_SHOP)
    sql = sql:gsub("`ahmad_gang_outfit`", SQL_TBL_OUTFIT)
    sql = sql:gsub("ahmad_gang_outfit", SQL_TBL_OUTFIT)
    sql = sql:gsub("`ahmad_gang`", SQL_TBL_GANG)
    sql = sql:gsub("ahmad_gang", SQL_TBL_GANG)
    sql = sql:gsub("`users`", SQL_TBL_USERS)
    sql = sql:gsub("(%f[%w_])users(%f[^%w_])", SQL_TBL_USERS)
    return sql
end

local function wrapMySqlMethod(methodName)
    local fn = MySQL[methodName]
    if type(fn) ~= "function" then return end

    local wrapped = function(sql, params, cb)
        return fn(qualifyGangSql(sql), params, cb)
    end

    if type(fn.await) == "function" then
        wrapped.await = function(sql, params)
            return fn.await(qualifyGangSql(sql), params)
        end
    end

    MySQL[methodName] = wrapped
end

wrapMySqlMethod("query")
wrapMySqlMethod("single")
wrapMySqlMethod("scalar")
wrapMySqlMethod("update")
wrapMySqlMethod("insert")

-- ──────────────────────────────────────────────────────
-- DB  —  إنشاء الجداول عند الأول تشغيل
-- ──────────────────────────────────────────────────────
DB_MIGRATION_KVP_KEY = "ahmad_gangs:db_migration_rev"
DB_MIGRATION_REV = 2
dbStateStorageReady = false

MySQL.ready(function()
    if configuredDbSchema ~= "" then
        pcall(function()
            MySQL.query((
                "CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            ):format(configuredDbSchema), {})
        end)
        print(("^2[ahmad_gangs]^7 DB schema override active: %s"):format(configuredDbSchema))
    end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ahmad_gang (
            id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
            row_type    VARCHAR(24)  NOT NULL,
            gang_id     VARCHAR(64)  NOT NULL DEFAULT '',
            citizen_id  INT          DEFAULT NULL,
            rank_code   VARCHAR(64)  DEFAULT NULL,
            name        VARCHAR(128) DEFAULT '',
            discord_id  VARCHAR(64)  DEFAULT '',
            last_avatar TEXT         DEFAULT '',
            hired_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            seconds     BIGINT       DEFAULT 0,
            balance     BIGINT       DEFAULT 0,
            log_type    VARCHAR(16)  DEFAULT NULL,
            amount      BIGINT       DEFAULT 0,
            by_name     VARCHAR(128) DEFAULT '',
            by_cid      INT          DEFAULT 0,
            note        VARCHAR(256) DEFAULT '',
            created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_row_cid  (row_type, gang_id, citizen_id),
            INDEX idx_row_gang     (row_type, gang_id),
            INDEX idx_log_gang     (row_type, gang_id, id)
        )
    ]], {})

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ahmad_gang_state (
            state_key   VARCHAR(64) PRIMARY KEY,
            state_json  LONGTEXT NOT NULL,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})

    dbStateStorageReady = true

    local migrationRev = tonumber(GetResourceKvpString(DB_MIGRATION_KVP_KEY) or "0") or 0
    if migrationRev >= DB_MIGRATION_REV then
        return
    end

    -- شغّل المايجريشن الثقيلة مرة واحدة فقط لتجنب spikes عند كل restart.
    CreateThread(function()
        Wait(250)
        local ok = pcall(function()
            local dbRow = MySQL.single.await('SELECT DATABASE() AS db', {})
            local currentDb = dbRow and dbRow.db
            local schemaDb = configuredDbSchema ~= "" and configuredDbSchema or currentDb
            Wait(0)

            -- Migration: إزالة الـ index القديم uq_treasury (إن وُجد)
            if schemaDb then
                local badIdx = MySQL.single.await(
                    'SELECT 1 AS ok FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? AND index_name = ? LIMIT 1',
                    { schemaDb, 'ahmad_gang', 'uq_treasury' }
                )
                Wait(0)
                if badIdx then
                    MySQL.query('ALTER TABLE ahmad_gang DROP INDEX uq_treasury', {})
                end
            end

            -- ثبّت صف الخزنة على citizen_id = 0
            MySQL.query('UPDATE ahmad_gang SET citizen_id = 0 WHERE row_type = ? AND citizen_id IS NULL', { 'treasury' })
            Wait(0)

            -- ══════════════════════════════════════════════════════════
            -- Migration: نقل ahmad_gang_shop → ahmad_gang ثم حذفه
            -- (تعمل مرة واحدة فقط، بعدها الجدول لا يوجد)
            -- ══════════════════════════════════════════════════════════
            if schemaDb then
                local shopTbl = MySQL.single.await(
                    'SELECT 1 AS ok FROM information_schema.tables WHERE table_schema = ? AND table_name = ? LIMIT 1',
                    { schemaDb, 'ahmad_gang_shop' }
                )
                Wait(0)
                if shopTbl then
                    -- نقل سجل الملكية (_owned → row_type='shop_owned', citizen_id=0)
                    MySQL.query([[
                        INSERT IGNORE INTO ahmad_gang (row_type, gang_id, citizen_id)
                        SELECT 'shop_owned', gang_id, 0
                        FROM ahmad_gang_shop
                        WHERE weapon = '_owned' AND stock >= 1
                    ]], {})
                    -- نقل عناصر المتجر (weapon → row_type='shop_item', name=weapon, amount=stock, balance=price)
                    MySQL.query([[
                        INSERT INTO ahmad_gang (row_type, gang_id, name, amount, balance)
                        SELECT 'shop_item', gang_id, weapon, stock, sale_price
                        FROM ahmad_gang_shop
                        WHERE weapon != '_owned'
                    ]], {})
                    -- حذف الجدول القديم
                    MySQL.query('DROP TABLE ahmad_gang_shop', {})
                    print("^2[ahmad_gangs] ^7Migration: ahmad_gang_shop → ahmad_gang (done, table dropped)")
                end
                Wait(0)

                -- Migration: حذف جدول outfit القديم (البيانات أصبحت ضمن ahmad_gang_state)
                local outfitTbl = MySQL.single.await(
                    'SELECT 1 AS ok FROM information_schema.tables WHERE table_schema = ? AND table_name = ? LIMIT 1',
                    { schemaDb, 'ahmad_gang_outfit' }
                )
                if outfitTbl then
                    MySQL.query('DROP TABLE ahmad_gang_outfit', {})
                    print("^2[ahmad_gangs] ^7Migration: ahmad_gang_outfit dropped (outfits now stored in ahmad_gang_state)")
                end
            end
        end)

        if ok then
            SetResourceKvp(DB_MIGRATION_KVP_KEY, tostring(DB_MIGRATION_REV))
        end
    end)

    -- ███ إضافة فهارس مفقودة (IF NOT EXISTS يمنع الخطأ عند إعادة التشغيل) ███
    CreateThread(function()
        Wait(500)
        pcall(function()
            MySQL.query('CREATE INDEX IF NOT EXISTS idx_row_cid ON ahmad_gang (row_type, citizen_id)', {})
        end)
        pcall(function()
            MySQL.query('CREATE INDEX IF NOT EXISTS idx_row_gang_name ON ahmad_gang (row_type, gang_id, name(64))', {})
        end)
    end)
end)

RT_MEMBER     = "member"
RT_PLAYTIME   = "playtime"
RT_TREASURY   = "treasury"
RT_TLOG       = "treasury_log"
RT_DIRTY      = "dirty_treasury"
RT_WARNING    = "warning"
RT_POINTS     = "points"
RT_TREASURE   = "treasure_account"
RT_SHOP_OWNED = "shop_owned"   -- existence = العصابة تملك المتجر (citizen_id=0)
RT_SHOP_ITEM  = "shop_item"    -- name=weapon, amount=stock, balance=sale_price

-- ──────────────────────────────────────────────────────
-- Rate Limiting
-- ──────────────────────────────────────────────────────
rateLimits = {}

local function checkRate(src, key, ms)
    local keyPart = tostring(key or "")
    keyPart = keyPart:gsub("[%c\r\n\t]", "")
    if #keyPart > 96 then
        keyPart = keyPart:sub(1, 96)
    end
    local k   = tostring(src) .. ":" .. keyPart
    local now = GetGameTimer()
    if rateLimits[k] and now < rateLimits[k] then return false end
    rateLimits[k] = now + ms
    return true
end

-- ──────────────────────────────────────────────────────
-- Runtime Profiler (opt-in via convar)
-- setr ahmad_gangs_profiler 1
-- ──────────────────────────────────────────────────────
PERF_ENABLED = (tonumber(GetConvar("ahmad_gangs_profiler", "0")) or 0) == 1
PERF_WARN_MS = math.max(25, tonumber(GetConvar("ahmad_gangs_profiler_warn_ms", "90")) or 90)

function perfStart()
    if not PERF_ENABLED then return nil end
    return GetGameTimer()
end

function perfDone(tag, startedAt, extra)
    if not PERF_ENABLED or not startedAt then return end
    local elapsed = GetGameTimer() - startedAt
    if elapsed >= PERF_WARN_MS then
        local suffix = (extra and extra ~= "") and (" | " .. extra) or ""
        print(("^3[ahmad_gangs][perf]^7 %s took %dms%s"):format(tostring(tag), elapsed, suffix))
    end
end

-- ──────────────────────────────────────────────────────
-- DB Write Queue (multi-worker parallel)
-- يقلل spikes الناتجة من انفجار عمليات الكتابة المتزامنة
-- ──────────────────────────────────────────────────────
DB_QUEUE_ENABLED = (tonumber(GetConvar("ahmad_gangs_db_queue", "1")) or 1) == 1
DB_QUEUE_BATCH_SIZE = math.max(1, tonumber(GetConvar("ahmad_gangs_db_queue_batch", "24")) or 24)
DB_QUEUE_IDLE_WAIT_MS = math.max(10, tonumber(GetConvar("ahmad_gangs_db_queue_idle_wait", "80")) or 80)
DB_QUEUE_BUSY_WAIT_MS = math.max(0, tonumber(GetConvar("ahmad_gangs_db_queue_busy_wait", "4")) or 4)
DB_QUEUE_WARN_AT = math.max(100, tonumber(GetConvar("ahmad_gangs_db_queue_warn_at", "700")) or 700)
DB_QUEUE_MAX_WORKERS = math.max(1, math.min(4, tonumber(GetConvar("ahmad_gangs_db_queue_workers", "3")) or 3))

dbWriteQueue = {}
dbWriteQueueHead = 1
dbWriteQueueTail = 0
dbWriteQueueSize = 0
dbQueueActiveWorkers = 0

local function _dbQueueTakeJob()
    if dbWriteQueueSize <= 0 then return nil end
    local job = dbWriteQueue[dbWriteQueueHead]
    dbWriteQueue[dbWriteQueueHead] = nil
    dbWriteQueueHead = dbWriteQueueHead + 1
    dbWriteQueueSize = dbWriteQueueSize - 1
    if dbWriteQueueSize == 0 then
        dbWriteQueueHead = 1
        dbWriteQueueTail = 0
    end
    return job
end

function ensureDbQueueWorker()
    if not DB_QUEUE_ENABLED or dbWriteQueueSize <= 0 then return end
    -- شغّل workers إضافية حتى الحد الأقصى
    while dbQueueActiveWorkers < DB_QUEUE_MAX_WORKERS and dbWriteQueueSize > 0 do
        dbQueueActiveWorkers = dbQueueActiveWorkers + 1
        CreateThread(function()
            while dbWriteQueueSize > 0 do
                local processed = 0
                while processed < DB_QUEUE_BATCH_SIZE and dbWriteQueueSize > 0 do
                    local job = _dbQueueTakeJob()
                    processed = processed + 1

                    if job and job.sql then
                        -- fire-and-forget: oxmysql يسجل الأخطاء تلقائياً
                        MySQL.query(job.sql, job.params)
                    end
                end

                -- yield بين الدفعات حتى لو كانت non-blocking (لتجنب CPU spike)
                Wait(DB_QUEUE_BUSY_WAIT_MS)
            end

            dbQueueActiveWorkers = dbQueueActiveWorkers - 1
            -- لو تراكمت jobs جديدة أثناء الإيقاف، أعد تشغيل
            if dbWriteQueueSize > 0 then
                ensureDbQueueWorker()
            end
        end)
    end
end

function dbQueueWrite(sql, params, tag)
    if not DB_QUEUE_ENABLED then
        MySQL.query(sql, params or {})
        return
    end

    dbWriteQueueTail = dbWriteQueueTail + 1
    dbWriteQueue[dbWriteQueueTail] = {
        sql = sql,
        params = params or {},
        tag = tostring(tag or "db_write"),
    }
    dbWriteQueueSize = dbWriteQueueSize + 1

    if dbWriteQueueSize == DB_QUEUE_WARN_AT then
        print(("^3[ahmad_gangs]^7 db write queue backlog=%d"):format(dbWriteQueueSize))
    end

    ensureDbQueueWorker()
end

function flushDbWriteQueueNow(maxJobs)
    if not DB_QUEUE_ENABLED then return end
    local cap = math.max(1, tonumber(maxJobs) or 5000)
    local processed = 0

    while dbWriteQueueSize > 0 and processed < cap do
        local job = _dbQueueTakeJob()
        processed = processed + 1

        if job and job.sql then
            -- fire-and-forget: oxmysql يكمل الكتابة داخلياً حتى بعد إيقاف الريسورس
            MySQL.query(job.sql, job.params)
        end
    end
end

function dbLoadStateJson(stateKey)
    if not dbStateStorageReady then return nil end

    local ok, row = pcall(function()
        return MySQL.single.await(
            'SELECT state_json FROM ahmad_gang_state WHERE state_key = ? LIMIT 1',
            { tostring(stateKey or "") }
        )
    end)
    if not ok then return nil end

    local raw = row and row.state_json or nil
    if not raw or raw == "" or raw == "{}" then return nil end

    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

function dbQueueSaveStateJson(stateKey, data, tag)
    if not dbStateStorageReady then return false end

    local encoded = json.encode(data or {})
    dbQueueWrite(
        'INSERT INTO ahmad_gang_state (state_key, state_json) VALUES (?, ?) ON DUPLICATE KEY UPDATE state_json = VALUES(state_json), updated_at = CURRENT_TIMESTAMP',
        { tostring(stateKey or ""), encoded },
        tag or ("state:" .. tostring(stateKey or ""))
    )
    return true
end

function dbSaveStateJsonNow(stateKey, data)
    if not dbStateStorageReady then return false end

    local encoded = json.encode(data or {})
    local ok, err = pcall(function()
        MySQL.query.await(
            'INSERT INTO ahmad_gang_state (state_key, state_json) VALUES (?, ?) ON DUPLICATE KEY UPDATE state_json = VALUES(state_json), updated_at = CURRENT_TIMESTAMP',
            { tostring(stateKey or ""), encoded }
        )
    end)
    if not ok then
        print(("^1[ahmad_gangs] ^7ERROR: failed saving state '%s' to DB: %s"):format(tostring(stateKey or ""), tostring(err)))
        return false
    end
    return true
end

-- تنظيف rate limiter يتم في playerDropped لتجنب الثريد الكنسي (أسلوب ahmad_rank)
-- ──────────────────────────────────────────────────────
-- كاش اللاعبين المتصلين — يتجنب GetPlayers() في كل طلب
-- ──────────────────────────────────────────────────────
onlineCidMap = {}   -- [cid] = { uid, src }
activeMemberViewGang = {} -- [src] = gang_id currently opened in members UI
playtimeSessionStart = {} -- [cid] = os.time() عند الدخول  (event-driven بدون ثريد)
onlineGangMemberFlag = {} -- [uid] = true/false (cache membership for hot broadcast paths)
dbGetGangMemberCids = nil
gangMemberCache = nil
gangByRankCode = {}

local function refreshOnlineGangMemberFlag(uid, groups)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end
    local g = groups
    if type(g) ~= "table" then
        local ok, result = pcall(vRP.getUserGroups, { targetUid })
        g = (ok and type(result) == "table" and result) or {}
    end
    local has = hasAnyGangFromGroups(g) == true

    if (not has) and GROUP_SOURCE_MODE ~= "vrp" then
        local usersGroups = dbGetUsersGroupsByUid(targetUid)
        has = hasAnyGangFromGroups(usersGroups) == true

        if not has then
            local row = MySQL.single.await(
                'SELECT gang_id FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? LIMIT 1',
                { RT_MEMBER, targetUid }
            )
            has = row ~= nil
        end
    end

    onlineGangMemberFlag[targetUid] = has
    return has
end

local function rebuildGangRankLookup()
    gangByRankCode = {}
    for gang_id, gang in pairs(Config.Gangs or {}) do
        for _, rank in ipairs((gang and gang.ranks) or {}) do
            local code = tostring(rank and rank.code or "")
            if code ~= "" then
                gangByRankCode[code] = gang_id
            end
        end
    end
end

rebuildGangRankLookup()

local function forEachOnlineSource(fn)
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        if src and src > 0 and GetPlayerName(src) then
            fn(src, tonumber(info.uid) or nil, tonumber(cid) or nil)
        end
    end
end

function forEachOnlineSourceBatched(batchSize, fn)
    local n = 0
    local step = math.max(1, tonumber(batchSize) or 48)
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        if src and src > 0 and GetPlayerName(src) then
            fn(src, tonumber(info.uid) or nil, tonumber(cid) or nil)
            n = n + 1
            if (n % step) == 0 then
                Wait(0)
            end
        end
    end
end

local function getOnlineGangMemberSources(gang_id)
    local out = {}
    -- استخدم كاش الأعضاء إن كان متاحاً لتجنب DB query إضافي
    local cRows = gangMemberCache[gang_id]
    local rows = (cRows and os.time() < cRows.expires) and cRows.rows or dbGetGangMemberCids(gang_id)
    for _, row in ipairs(rows or {}) do
        local cid = tonumber(row.citizen_id)
        if cid then
            local info = onlineCidMap[cid]
            local src = info and tonumber(info.src) or nil
            if src and src > 0 and GetPlayerName(src) then
                table.insert(out, src)
            end
        end
    end
    return out
end

function hasAnyGangFromGroups(groups)
    for groupCode, hasGroup in pairs(groups or {}) do
        if hasGroup and gangByRankCode[tostring(groupCode)] then
            return true
        end
    end
    return false
end

function getAnyGangIdFromGroups(groups)
    for groupCode, hasGroup in pairs(groups or {}) do
        if hasGroup then
            local gid = gangByRankCode[tostring(groupCode)]
            if gid then return gid end
        end
    end
    return nil
end

-- ──────────────────────────────────────────────────────
-- كاش قائمة الأعضاء (60 ثانية لكل عصابة)
-- يقلل DB queries بشكل كبير على سيرفر 500+ لاعب
-- ──────────────────────────────────────────────────────
gangMemberCache = {}   -- [gang_id] = { rows, playtimeMap, expires }
CACHE_TTL       = 90   -- ثانية (يُبطل فوراً عبر invalidateGangCache عند أي تغيير)

-- كاش فحص الرتب الخارجية من vrp_user_data
externalGangRankScanCache = {} -- [gang_id] = { data = { [uid] = rank_code }, expires = os.time()+ttl }
EXTERNAL_GANG_SCAN_TTL    = 90 -- ثانية
invalidateRankingCache = nil
invalidateGangStatsCache = nil

local function invalidateGangCache(gang_id)
    gangMemberCache[gang_id] = nil
    externalGangRankScanCache[gang_id] = nil
    if invalidateGangStatsCache then
        invalidateGangStatsCache()
    end
    if invalidateRankingCache then
        invalidateRankingCache()
    end
end

-- ──────────────────────────────────────────────────────
-- كاش الخزنة — رصيد + سجل الإيداع/السحب
-- لا حاجة لـ TTL: يتحدث فور كل عملية ولا يُقرأ من DB إلا عند أول طلب
-- ──────────────────────────────────────────────────────
treasuryBalanceCache = {}  -- [gang_id] = number
treasuryLogCache     = {}  -- [gang_id] = { list of log entries }
dirtyTreasuryCache   = {}  -- [gang_id] = number (أموال قذرة من إيرادات المتجر)
dirtyLogCache        = {}  -- [gang_id] = { list of dirty log entries }
warningsListCache    = {}  -- [gang_id] = { data = {...}, expires = os.time()+ttl }
WARNINGS_CACHE_TTL   = 90

-- كاش أسماء اللاعبين — 5 دقائق (تجنب DB في كل استدعاء)
userNameCache = {}   -- [uid] = { name, expires }
userExistsCache = {} -- [uid] = { exists = bool, expires = os.time()+ttl }
USER_EXISTS_CACHE_TTL = 300
knownMemberNameCache = {} -- [cid] = { name, expires }
KNOWN_MEMBER_NAME_CACHE_TTL = 600

-- كاش التصنيف — 60 ثانية (3 DB queries × N عصابة في كل طلب)
rankingCache  = { data = nil, expires = 0 }
gangStatsCache = { data = nil, expires = 0 }
GANG_STATS_CACHE_TTL = 90

invalidateRankingCache = function()
    rankingCache.data = nil
    rankingCache.expires = 0
end

invalidateGangStatsCache = function()
    gangStatsCache.data = nil
    gangStatsCache.expires = 0
end

-- ──────────────────────────────────────────────────────
-- Discord Avatar
-- ──────────────────────────────────────────────────────
avatarCache    = {}
CACHE_SECONDS  = 1800
DEFAULT_AVATAR = Config.Discord.defaultAvatar
AVATAR_BACKFILL_BUDGET_PER_LIST = math.max(0, tonumber(GetConvar("ahmad_gangs_avatar_backfill_budget", "2")) or 2)
AVATAR_BACKFILL_COOLDOWN_SEC = math.max(30, tonumber(GetConvar("ahmad_gangs_avatar_backfill_cooldown", "600")) or 600)
LIVE_RANK_CHECK_BUDGET_PER_LIST = math.max(0, tonumber(GetConvar("ahmad_gangs_live_rank_check_budget", "2")) or 2)
LIVE_RANK_CHECK_COOLDOWN_SEC = math.max(5, tonumber(GetConvar("ahmad_gangs_live_rank_check_cooldown", "120")) or 120)
avatarBackfillNextAtByCid = {}
playtimeFlushNextAtByUid = {}
liveRankCheckNextAtByUidGang = {}

local function fetchDiscordAvatar(discordId, cb)
    if not discordId or discordId == "" then return cb(DEFAULT_AVATAR) end

    local cached = avatarCache[discordId]
    if cached and cached.expires > os.time() then return cb(cached.url) end

    PerformHttpRequest(
        "https://discord.com/api/v10/users/" .. discordId,
        function(code, body)
            if code == 200 then
                local ok, data = pcall(json.decode, body)
                if ok and data and data.avatar and data.id then
                    local ext = data.avatar:sub(1, 2) == "a_" and "gif" or "png"
                    local url = ("https://cdn.discordapp.com/avatars/%s/%s.%s?size=128"):format(data.id, data.avatar, ext)
                    avatarCache[discordId] = { url = url, expires = os.time() + CACHE_SECONDS }
                    return cb(url)
                end
            end
            cb(DEFAULT_AVATAR)
        end,
        "GET", "", { ["Authorization"] = "Bot " .. Config.Discord.botToken }
    )
end

local function getDiscordFromSource(src)
    for _, ident in ipairs(GetPlayerIdentifiers(src) or {}) do
        if ident:sub(1, 8) == "discord:" then return ident:sub(9) end
    end
    return ""
end

-- ──────────────────────────────────────────────────────
-- helpers
-- ──────────────────────────────────────────────────────
local function formatPlaytime(seconds)
    seconds = tonumber(seconds) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    return h, m
end

-- ── كاش src→uid بأسلوب ahmad_rank (hit + miss TTL لتجنب spam vRP IPC) ──
srcToUidCache = {}  -- [src] = { uid, exp }  (مسح عند playerDropped)

local function getUserId(src)
    local n = tonumber(src)
    if not n then return nil end
    local c = srcToUidCache[n]
    if c then
        if c.uid then return c.uid end           -- كاش ناجح
        if GetGameTimer() < c.exp then return nil end  -- كاش فشل ولم ينته بعد
    end
    local uid = vRP.getUserId({ n })
    srcToUidCache[n] = { uid = uid or nil, exp = GetGameTimer() + 1200 }
    return uid
end

local function getOnlineSourceByUserId(uid)
    local targetUid = tonumber(uid)
    if targetUid == nil then return nil end
    -- في vRP3 uid == cid، لذا نتحقق من onlineCidMap أولاً قبل vRP Proxy
    local cached = onlineCidMap[targetUid]
    if cached then
        local numSrc = tonumber(cached.src)
        if numSrc and numSrc > 0 and GetPlayerName(numSrc) then return numSrc end
    end
    local src = vRP.getUserSource({ targetUid })
    local numSrc = tonumber(src)
    if not numSrc or numSrc <= 0 or not GetPlayerName(numSrc) then return nil end
    return numSrc
end

local function getSourceCoordsSafe(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    local pos = GetEntityCoords(ped)
    if not pos then return nil end

    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    local z = tonumber(pos.z)
    if not x or not y or not z then return nil end
    if x ~= x or y ~= y or z ~= z then return nil end
    if math.abs(x) > 100000.0 or math.abs(y) > 100000.0 or math.abs(z) > 100000.0 then return nil end

    return { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
end

local function getOnlineGangPullTargets(gang_id, excludeSrc)
    local out = {}
    local seenSrc = {}
    local rows = dbGetGangMemberCids(gang_id)

    for _, row in ipairs(rows or {}) do
        local cid = tonumber(row.citizen_id)
        if cid then
            local info = onlineCidMap[cid]
            local tSrc = info and tonumber(info.src) or nil
            if tSrc and tSrc > 0 and tSrc ~= excludeSrc and not seenSrc[tSrc] and GetPlayerName(tSrc) then
                seenSrc[tSrc] = true
                table.insert(out, tSrc)
            end
        end
    end

    return out
end

local function pullTargetsToCoords(targetSources, coords)
    local moved = 0
    local burst = 0

    for _, tSrc in ipairs(targetSources or {}) do
        if tSrc and tSrc > 0 and GetPlayerName(tSrc) then
            TriggerClientEvent("gang:pullTo", tSrc, coords)
            moved = moved + 1
            burst = burst + 1

            if burst >= 12 then
                burst = 0
                Wait(80)
            end
        end
    end

    return moved
end

local function getCid(uid)
    -- في vRP3, user_id == citizen_id
    return uid
end

function hasAnyEntries(t)
    if type(t) ~= "table" then return false end
    for _ in pairs(t) do return true end
    return false
end

function tryDecodeJsonTable(raw)
    if type(raw) == "table" then return raw end
    if raw == nil then return nil end
    local text = tostring(raw)
    if text == "" or text == "null" then return nil end
    local ok, data = pcall(json.decode, text)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

function normalizeGroupsMap(groups)
    local out = {}
    if type(groups) ~= "table" then return out end

    local nested = groups.groups
    if type(nested) == "table" then
        groups = nested
    end

    if #groups > 0 then
        for _, entry in ipairs(groups) do
            local code = tostring(entry or "")
            if code ~= "" then
                out[code] = true
            end
        end
    end

    for k, v in pairs(groups) do
        if type(k) == "string" then
            if v == true then
                out[k] = true
            elseif type(v) == "number" and v ~= 0 then
                out[k] = true
            elseif type(v) == "string" then
                local lv = v:lower()
                if lv ~= "" and lv ~= "0" and lv ~= "false" and lv ~= "nil" then
                    out[k] = true
                end
            end
        elseif type(k) == "number" and type(v) == "string" and v ~= "" then
            out[v] = true
        end
    end

    return out
end

function parseGroupsFromRaw(raw)
    local data = tryDecodeJsonTable(raw)
    if type(data) == "table" then
        return normalizeGroupsMap(data)
    end

    local out = {}
    local text = tostring(raw or "")
    if text ~= "" then
        for token in text:gmatch("[^,%s]+") do
            local code = tostring(token or "")
            if code ~= "" then
                out[code] = true
            end
        end
    end
    return out
end

function getRowValueCaseInsensitive(row, keyName)
    if type(row) ~= "table" then return nil end
    local wanted = tostring(keyName or ""):lower()
    if wanted == "" then return nil end

    for k, v in pairs(row) do
        if tostring(k):lower() == wanted then
            return v
        end
    end
    return nil
end

function addUniqueNumeric(tbl, seen, value)
    local n = tonumber(value)
    if n == nil then return end
    if seen[n] then return end
    seen[n] = true
    tbl[#tbl + 1] = n
end

function resolveUsersUidCandidates(uid)
    local out, seen = {}, {}
    local nUid = tonumber(uid)
    if nUid == nil then
        return out
    end

    local ok, row = pcall(function()
        return MySQL.single.await(
            'SELECT user_id, esx_id FROM vrp_esx_id_mapping WHERE user_id = ? OR esx_id = ? LIMIT 1',
            { nUid, nUid }
        )
    end)

    if ok and type(row) == "table" then
        -- في بيئات vRP<->ESX: فضّل esx_id أولاً لأنه غالباً المفتاح الحقيقي في users.id
        addUniqueNumeric(out, seen, row.esx_id)
        addUniqueNumeric(out, seen, row.user_id)
    end

    -- fallback أخير: الـ uid الخام
    addUniqueNumeric(out, seen, uid)

    return out
end

function pushAccountsHudUpdate(uid, cash, bank)
    local src = getOnlineSourceByUserId(uid)
    if not src then
        for _, candidate in ipairs(resolveUsersUidCandidates(uid)) do
            src = getOnlineSourceByUserId(candidate)
            if src then break end
        end
    end
    if not src then return false end

    local moneyVal = math.max(0, math.floor(tonumber(cash) or 0))
    local bankVal = math.max(0, math.floor(tonumber(bank) or 0))

    TriggerClientEvent("esx:setAccountMoney", src, { name = "money", money = moneyVal, label = "Cash" })
    TriggerClientEvent("esx:setAccountMoney", src, { name = "bank", money = bankVal, label = "Bank" })
    TriggerClientEvent("esx:setMoney", src, moneyVal)
    TriggerClientEvent("gang:accountsUpdated", src, {
        money = moneyVal,
        bank = bankVal,
        cash = moneyVal,
    })

    local okState, stateObj = pcall(function()
        local p = Player(src)
        return p and p.state or nil
    end)
    if okState and stateObj then
        pcall(function() stateObj:set("money", moneyVal, true) end)
        pcall(function() stateObj:set("bank", bankVal, true) end)
        pcall(function() stateObj:set("cash", moneyVal, true) end)
    end

    return true
end

function dbGetUsersRowByUid(uid)
    local candidates = resolveUsersUidCandidates(uid)
    if #candidates == 0 then return nil, nil, nil end

    for _, candidate in ipairs(candidates) do
        local okById, rowById = pcall(function()
            return MySQL.single.await('SELECT * FROM ' .. SQL_TBL_USERS .. ' WHERE id = ? LIMIT 1', { candidate })
        end)
        if okById and type(rowById) == "table" then
            return rowById, "id", candidate
        end

        local okByUserId, rowByUserId = pcall(function()
            return MySQL.single.await('SELECT * FROM ' .. SQL_TBL_USERS .. ' WHERE user_id = ? LIMIT 1', { candidate })
        end)
        if okByUserId and type(rowByUserId) == "table" then
            return rowByUserId, "user_id", candidate
        end
    end

    return nil, nil, nil
end

function dbGetUsersGroupsByUid(uid)
    local row = dbGetUsersRowByUid(uid)
    if not row then return {} end

    local raw = getRowValueCaseInsensitive(row, USERS_GROUPS_COLUMN)
    return parseGroupsFromRaw(raw)
end

function dbSaveUsersGroupsByUid(uid, groupsMap)
    local nUid = tonumber(uid)
    if nUid == nil then return false end

    local row, keyField, keyValue = dbGetUsersRowByUid(nUid)
    if not row or not keyField then return false end

    local ok = pcall(function()
        MySQL.query.await(
            'UPDATE ' .. SQL_TBL_USERS .. ' SET ' .. SQL_COL_USERS_GROUPS .. ' = ? WHERE `' .. keyField .. '` = ? LIMIT 1',
            { json.encode(groupsMap or {}), tonumber(keyValue) or nUid }
        )
    end)
    return ok == true
end

function dbGetUsersGroupsMapByUserIds(userIds)
    local ids, seen = {}, {}
    for _, uid in ipairs(userIds or {}) do
        local n = tonumber(uid)
        if n ~= nil and not seen[n] then
            seen[n] = true
            ids[#ids + 1] = n
        end
    end
    if #ids == 0 then return {} end

    local out = {}
    local CHUNK_SIZE = 80
    for i = 1, #ids, CHUNK_SIZE do
        local placeholders, params = {}, {}
        local upper = math.min(i + CHUNK_SIZE - 1, #ids)
        for j = i, upper do
            placeholders[#placeholders + 1] = "?"
            params[#params + 1] = ids[j]
        end

        local inSql = table.concat(placeholders, ',')

        local okById, rowsById = pcall(function()
            return MySQL.query.await(
                'SELECT id, ' .. SQL_COL_USERS_GROUPS .. ' AS groups_raw FROM ' .. SQL_TBL_USERS .. ' WHERE id IN (' .. inSql .. ')',
                params
            )
        end)
        if okById and type(rowsById) == "table" then
            for _, row in ipairs(rowsById) do
                local nUid = tonumber(row.id)
                if nUid ~= nil then
                    local parsed = parseGroupsFromRaw(row.groups_raw)
                    if hasAnyEntries(parsed) then
                        out[nUid] = parsed
                    end
                end
            end
        end

        local okByUserId, rowsByUserId = pcall(function()
            return MySQL.query.await(
                'SELECT user_id, ' .. SQL_COL_USERS_GROUPS .. ' AS groups_raw FROM ' .. SQL_TBL_USERS .. ' WHERE user_id IN (' .. inSql .. ')',
                params
            )
        end)
        if okByUserId and type(rowsByUserId) == "table" then
            for _, row in ipairs(rowsByUserId) do
                local nUid = tonumber(row.user_id)
                if nUid ~= nil then
                    local parsed = parseGroupsFromRaw(row.groups_raw)
                    if hasAnyEntries(parsed) then
                        out[nUid] = parsed
                    end
                end
            end
        end

        if upper < #ids then
            Wait(0)
        end
    end

    return out
end

function dbGetUserAccountsSnapshot(uid)
    local row, keyField, keyValue = dbGetUsersRowByUid(uid)
    if not row or not keyField then return nil end

    local raw = getRowValueCaseInsensitive(row, USERS_ACCOUNTS_COLUMN)
    local parsed = tryDecodeJsonTable(raw)
    if type(parsed) ~= "table" then
        return nil
    end

    local cash, bank = 0, 0
    local foundCash, foundBank = false, false
    local cashKey, bankKey = nil, nil
    local isArray = (#parsed > 0)

    if isArray then
        for _, entry in ipairs(parsed) do
            if type(entry) == "table" then
                local accName = tostring(entry.name or entry.account or ""):lower()
                local value = tonumber(entry.money or entry.amount or entry.balance or entry.cash)
                if value then
                    if accName == "cash" or accName == "money" then
                        cash = value
                        foundCash = true
                        if not cashKey then cashKey = accName end
                    elseif accName == "bank" then
                        bank = value
                        foundBank = true
                        if not bankKey then bankKey = accName end
                    end
                end
            end
        end
    end

    local function pickValue(tbl, keys)
        for _, key in ipairs(keys) do
            local v = tbl[key]
            if type(v) == "table" then
                local n = tonumber(v.money or v.amount or v.balance or v.cash)
                if n ~= nil then return n, key end
            else
                local n = tonumber(v)
                if n ~= nil then return n, key end
            end
        end
        return nil, nil
    end

    local mapCash, mapCashKey = pickValue(parsed, { "money", "cash", "wallet" })
    if mapCash ~= nil then
        cash = mapCash
        foundCash = true
        cashKey = mapCashKey or cashKey
    end
    local mapBank, mapBankKey = pickValue(parsed, { "bank", "bankmoney", "bank_money", "bankbalance", "bank_balance" })
    if mapBank ~= nil then
        bank = mapBank
        foundBank = true
        bankKey = mapBankKey or bankKey
    end

    if not foundCash and not foundBank then
        return nil
    end

    return {
        uid = tonumber(uid),
        keyField = keyField,
        keyValue = tonumber(keyValue) or tonumber(uid),
        rawAccounts = parsed,
        isArray = isArray,
        cashKey = cashKey,
        bankKey = bankKey,
        cash = math.max(0, math.floor(tonumber(cash) or 0)),
        bank = math.max(0, math.floor(tonumber(bank) or 0)),
    }
end

function dbSaveUserAccountsSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    local uid = tonumber(snapshot.uid)
    if uid == nil then return false end

    local accounts = snapshot.rawAccounts
    local cash = math.max(0, math.floor(tonumber(snapshot.cash) or 0))
    local bank = math.max(0, math.floor(tonumber(snapshot.bank) or 0))
    local keyValue = tonumber(snapshot.keyValue) or uid

    local function setAccountValue(tbl, key, value)
        local existing = tbl[key]
        if type(existing) == "table" then
            if existing.money ~= nil then
                existing.money = value
            elseif existing.amount ~= nil then
                existing.amount = value
            elseif existing.balance ~= nil then
                existing.balance = value
            elseif existing.cash ~= nil then
                existing.cash = value
            else
                existing.money = value
            end
        else
            tbl[key] = value
        end
    end

    if type(accounts) ~= "table" then
        accounts = { money = cash, bank = bank }
    elseif snapshot.isArray == true or #accounts > 0 then
        local hasCash, hasBank = false, false
        for _, entry in ipairs(accounts) do
            if type(entry) == "table" then
                local accName = tostring(entry.name or entry.account or ""):lower()
                if accName == "cash" or accName == "money" then
                    entry.money = cash
                    hasCash = true
                elseif accName == "bank" then
                    entry.money = bank
                    hasBank = true
                end
            end
        end
        if not hasCash then
            local fallbackCashName = tostring(snapshot.cashKey or "money")
            if fallbackCashName ~= "cash" and fallbackCashName ~= "money" then
                fallbackCashName = "money"
            end
            accounts[#accounts + 1] = { name = fallbackCashName, money = cash }
        end
        if not hasBank then accounts[#accounts + 1] = { name = "bank", money = bank } end
    else
        local cashKey = tostring(snapshot.cashKey or ((accounts.money ~= nil and "money") or (accounts.cash ~= nil and "cash") or (accounts.wallet ~= nil and "wallet") or "money"))
        local bankKey = tostring(snapshot.bankKey or ((accounts.bank ~= nil and "bank") or "bank"))
        setAccountValue(accounts, cashKey, cash)
        setAccountValue(accounts, bankKey, bank)
    end

    snapshot.rawAccounts = accounts
    snapshot.cash = cash
    snapshot.bank = bank

    local ok = pcall(function()
        MySQL.query.await(
            'UPDATE ' .. SQL_TBL_USERS .. ' SET ' .. SQL_COL_USERS_ACCOUNTS .. ' = ? WHERE `' .. tostring(snapshot.keyField or "id") .. '` = ? LIMIT 1',
            { json.encode(accounts), keyValue }
        )
    end)
    if not ok then
        return false
    end

    pushAccountsHudUpdate(uid, cash, bank)
    return true
end

-- ── كاش مجموعات اللاعب (5 ثوانٍ) — يقضي على أكبر مصدر لـ vRP IPC spikes ──
groupsCache = {}   -- [uid] = { groups = {...}, exp = gameTimer+ms }
GROUPS_CACHE_TTL_MS = math.max(3000, tonumber(GetConvar("ahmad_gangs_groups_cache_ttl_ms", "30000")) or 30000)

local function invalidateGroupsCache(uid)
    groupsCache[tostring(uid)] = nil
    local targetUid = tonumber(uid)
    if targetUid ~= nil then
        onlineGangMemberFlag[targetUid] = nil
    end
end

local function getGroups(uid)
    local n   = tostring(uid)
    local now = GetGameTimer()
    local c   = groupsCache[n]
    if c and now < c.exp then return c.groups end

    local g = {}
    local fromUsers = {}
    local canUseUsers = (GROUP_SOURCE_MODE == "users_table" or GROUP_SOURCE_MODE == "auto")

    if canUseUsers then
        fromUsers = dbGetUsersGroupsByUid(uid)
    end

    if GROUP_SOURCE_MODE == "users_table" then
        g = fromUsers
    else
        local ok, result = pcall(vRP.getUserGroups, { uid })
        g = (ok and type(result) == "table" and normalizeGroupsMap(result)) or {}

        if GROUP_SOURCE_MODE == "auto" and not hasAnyEntries(g) and hasAnyEntries(fromUsers) then
            g = fromUsers
        end
    end

    groupsCache[n] = { groups = g, exp = now + GROUPS_CACHE_TTL_MS }
    return g
end

local function hasGroup(uid, groupName)
    local g = getGroups(uid)
    return g[groupName] == true
end

local function getLiveGangRankCode(uid, gang_id)
    local gang = Config.Gangs[gang_id]
    if not gang then return nil end

    local groups = getGroups(uid)
    if GROUP_SOURCE_MODE ~= "vrp" and not hasAnyEntries(groups) then
        local row = MySQL.single.await(
            'SELECT rank_code FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? AND gang_id = ? LIMIT 1',
            { RT_MEMBER, getCid(uid), gang_id }
        )
        local fallbackRank = row and tostring(row.rank_code or "") or ""
        if fallbackRank ~= "" then
            return fallbackRank
        end
    end

    for _, rank in ipairs(gang.ranks or {}) do
        if groups[rank.code] then
            return rank.code
        end
    end
    return nil
end

local function getGangRankCodeFromGroups(groups, gang_id)
    local gang = Config.Gangs[gang_id]
    if not gang then return nil end

    for _, rank in ipairs(gang.ranks or {}) do
        if groups[rank.code] then
            return rank.code
        end
    end
    return nil
end

local function buildLaundryAccessMap(uid)
    local allowed = {}
    local groups = getGroups(uid)

    for gang_id, gang in pairs(Config.Gangs or {}) do
        -- تجاهل العصابات التي نقطة غسيلها معطّلة
        if type(gang.laundry) == "table" and gang.laundry.enabled ~= false then
            -- نقطة عامة: مرئية وقابلة للاستخدام لأي لاعب
            if gang.laundry.public_blip == true then
                allowed[gang_id] = true
            else
                for _, r in ipairs(gang.ranks or {}) do
                    if groups[r.code] then
                        allowed[gang_id] = true
                        break
                    end
                end
            end
        end
    end

    return allowed
end

local function pushLaundryAccessToUser(uid)
    local src = getOnlineSourceByUserId(uid)
    if not src then return end
    TriggerClientEvent("gang:laundryAccessData", src, buildLaundryAccessMap(uid))
end

-- للاستخدام من أي سكربت سيرفر خارجي بعد تغيير الرتب
exports("RefreshLaundryAccessByUserId", function(targetUid)
    local uid = tonumber(targetUid)
    if uid == nil then return false end
    pushLaundryAccessToUser(uid)
    return true
end)

local function giveGroup(uid, group)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end
    pcall(vRP.addUserGroup, { targetUid, group })

    local usersGroups = dbGetUsersGroupsByUid(targetUid)
    usersGroups[tostring(group or "")] = true
    dbSaveUsersGroupsByUid(targetUid, usersGroups)
    return true
end

local function removeGroup(uid, group)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end
    pcall(vRP.removeUserGroup, { targetUid, group })

    local usersGroups = dbGetUsersGroupsByUid(targetUid)
    usersGroups[tostring(group or "")] = nil
    dbSaveUsersGroupsByUid(targetUid, usersGroups)
    return true
end

local function setUserGangRank(uid, gang_id, rank_code)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end

    local gang = Config.Gangs[gang_id]
    if not gang then return false end

    local isValidRank = false
    for _, rank in ipairs(gang.ranks or {}) do
        if rank.code == rank_code then
            isValidRank = true
            break
        end
    end
    if not isValidRank then return false end

    for _, rank in ipairs(gang.ranks or {}) do
        if rank.code ~= rank_code then
            removeGroup(targetUid, rank.code)
        end
    end

    giveGroup(targetUid, rank_code)
    invalidateGroupsCache(targetUid)
    refreshOnlineGangMemberFlag(targetUid)
    pushLaundryAccessToUser(targetUid)
    return true
end

local function clearUserGangRanks(uid, gang_id)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end

    local gang = Config.Gangs[gang_id]
    if not gang then return false end

    for _, rank in ipairs(gang.ranks or {}) do
        removeGroup(targetUid, rank.code)
    end

    invalidateGroupsCache(targetUid)
    refreshOnlineGangMemberFlag(targetUid)
    pushLaundryAccessToUser(targetUid)
    return true
end

local function normalizeText(v)
    return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function sanitizeInputText(v, maxLen)
    local s = tostring(v or "")
    s = s:gsub("[%c\r\n\t]", " ")
    s = normalizeText(s)
    if maxLen and maxLen > 0 and #s > maxLen then
        s = s:sub(1, maxLen)
    end
    return s
end

local function isBadDisplayName(v)
    local t = normalizeText(v)
    if t == "" then return true end

    local lower = t:lower()
    if lower == "unknown" or lower == "undefined" or lower == "null" then return true end
    if lower:match("^user_%d+$") then return true end

    if t == "لا يوجد" or t == "هوية" then return true end
    if t:find("لا يوجد") or t:find("هوية") then return true end

    return false
end

local function getUserName(uid)
    uid = tonumber(uid) or uid

    -- كاش 10 دقائق — تجنب DB في كل استدعاء
    local _cached = userNameCache[uid]
    if _cached and _cached.expires > os.time() then return _cached.name end

    local function _cache(name)
        userNameCache[uid] = { name = name, expires = os.time() + 600 }
        return name
    end

    -- محاولة 0: نفس أسلوب ahmad_manage (prepared query vRP/get_user_identity)
    local okPrepared, rows = pcall(function()
        return MySQL.query.await("vRP/get_user_identity", { user_id = uid })
    end)
    if okPrepared and type(rows) == "table" and #rows > 0 then
        local idRow = rows[1]
        local first = normalizeText(idRow.firstname)
        local last  = normalizeText(idRow.lastname or idRow.name)
        local full  = normalizeText((first ~= "" and last ~= "") and (first .. " " .. last) or (first ~= "" and first) or last)
        if not isBadDisplayName(full) then return _cache(full) end
    end
    Wait(0)

    -- محاولة 1: vrp_user_identities مباشرة
    local ok, row = pcall(function()
        return MySQL.single.await(
            'SELECT firstname, name, lastname FROM vrp_user_identities WHERE user_id = ?',
            { uid }
        )
    end)
    if ok and type(row) == "table" then
        local first = normalizeText(row.firstname)
        local last  = normalizeText(row.lastname or row.name)
        local full  = normalizeText((first ~= "" and last ~= "") and (first .. " " .. last) or (first ~= "" and first) or last)
        if not isBadDisplayName(full) then return _cache(full) end
    end
    Wait(0)

    -- محاولة 1.5: users table (es_extended / custom)
    local rowUsers = dbGetUsersRowByUid(uid)
    if type(rowUsers) == "table" then
        local first = normalizeText(getRowValueCaseInsensitive(rowUsers, "firstname"))
        local last  = normalizeText(getRowValueCaseInsensitive(rowUsers, "lastname") or getRowValueCaseInsensitive(rowUsers, "name"))
        local full  = normalizeText((first ~= "" and last ~= "") and (first .. " " .. last) or (first ~= "" and first) or last)
        if not isBadDisplayName(full) then return _cache(full) end

        local fallbackName = normalizeText(getRowValueCaseInsensitive(rowUsers, "name") or getRowValueCaseInsensitive(rowUsers, "username"))
        if not isBadDisplayName(fallbackName) then return _cache(fallbackName) end
    end
    Wait(0)

    -- محاولة 2: اسم المشغل من FiveM مباشرة (مثل ahmad_manage)
    local ok2, src = pcall(vRP.getUserSource, { uid })
    if ok2 and src then
        local numSrc = tonumber(src)
        if numSrc and numSrc > 0 and GetPlayerName(numSrc) ~= nil then
            local playerName = normalizeText(GetPlayerName(numSrc))
            if not isBadDisplayName(playerName) then return _cache(playerName) end
        end
    end

    return _cache("ID: " .. tostring(uid))
end

local function userIdExistsInDB(uid)
    uid = tonumber(uid)
    if uid == nil then return false end

    local now = os.time()
    local cached = userExistsCache[uid]
    if cached and cached.expires > now then
        return cached.exists == true
    end

    -- إذا اللاعب متصل حالياً → موجود حتماً بدون DB
    for _, info in pairs(onlineCidMap) do
        if info and tonumber(info.uid) == uid then
            userExistsCache[uid] = { exists = true, expires = now + USER_EXISTS_CACHE_TTL }
            return true
        end
    end

    local function cacheAndReturn(val)
        userExistsCache[uid] = { exists = val == true, expires = now + USER_EXISTS_CACHE_TTL }
        return val == true
    end

    local okPrepared, rows = pcall(function()
        return MySQL.query.await("vRP/get_user_identity", { user_id = uid })
    end)
    if okPrepared and type(rows) == "table" and #rows > 0 then
        return cacheAndReturn(true)
    end
    Wait(0)

    local usersRow = dbGetUsersRowByUid(uid)
    if type(usersRow) == "table" then
        return cacheAndReturn(true)
    end
    Wait(0)

    local okIdentity, rowIdentity = pcall(function()
        return MySQL.single.await('SELECT user_id FROM vrp_user_identities WHERE user_id = ? LIMIT 1', { uid })
    end)
    if okIdentity and rowIdentity then
        return cacheAndReturn(true)
    end
    Wait(0)

    local okUsersUserId, rowUsersUserId = pcall(function()
        return MySQL.single.await('SELECT user_id FROM vrp_users WHERE user_id = ? LIMIT 1', { uid })
    end)
    if okUsersUserId and rowUsersUserId then
        return cacheAndReturn(true)
    end
    Wait(0)

    local okUsersId, rowUsersId = pcall(function()
        return MySQL.single.await('SELECT id FROM vrp_users WHERE id = ? LIMIT 1', { uid })
    end)
    if okUsersId and rowUsersId then
        return cacheAndReturn(true)
    end

    Wait(0)
    local okMap, rowMap = pcall(function()
        return MySQL.single.await('SELECT user_id FROM vrp_esx_id_mapping WHERE user_id = ? LIMIT 1', { uid })
    end)
    if okMap and rowMap then
        return cacheAndReturn(true)
    end

    return cacheAndReturn(false)
end

-- helper wrapper (متوافق مع vRP3 table args)
local function callVrp(fn, ...)
    if type(fn) ~= "function" then return false, nil end
    -- vRP Proxy يتوقع الـ args كـ table واحد: fn({uid, item, amount})
    local ok, res = pcall(fn, {...})
    return ok, res
end

-- مشغّل المال (متوافق مع أغلب إعدادات vRP3)
local function getWallet(uid)
    if MONEY_SOURCE_MODE ~= "vrp" then
        local snapshot = dbGetUserAccountsSnapshot(uid)
        if snapshot then
            return snapshot.cash or 0
        end
        if MONEY_SOURCE_MODE == "users_accounts" then
            return 0
        end
    end

    local ok, amount = callVrp(vRP.getMoney, uid)
    if ok then return tonumber(amount) or 0 end
    return 0
end

local function deductWallet(uid, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if MONEY_SOURCE_MODE ~= "vrp" then
        local snapshot = dbGetUserAccountsSnapshot(uid)
        if snapshot then
            local cash = math.max(0, tonumber(snapshot.cash) or 0)
            local bank = math.max(0, tonumber(snapshot.bank) or 0)
            if (cash + bank) < amount then
                return false
            end

            local fromCash = math.min(cash, amount)
            local remaining = amount - fromCash
            snapshot.cash = cash - fromCash
            snapshot.bank = bank - remaining
            if dbSaveUserAccountsSnapshot(snapshot) then
                return true
            end
            if MONEY_SOURCE_MODE == "users_accounts" then
                return false
            end
        elseif MONEY_SOURCE_MODE == "users_accounts" then
            return false
        end
    end

    local ok, paid = callVrp(vRP.tryFullPayment, uid, amount)
    return ok and paid == true
end

local function getBankMoney(uid)
    if MONEY_SOURCE_MODE ~= "vrp" then
        local snapshot = dbGetUserAccountsSnapshot(uid)
        if snapshot then
            return snapshot.bank or 0
        end
        if MONEY_SOURCE_MODE == "users_accounts" then
            return 0
        end
    end

    local ok, amount = callVrp(vRP.getBankMoney, uid)
    if ok then return tonumber(amount) or 0 end
    return 0
end

local function creditWallet(uid, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    if MONEY_SOURCE_MODE ~= "vrp" then
        local snapshot = dbGetUserAccountsSnapshot(uid)
        if snapshot then
            snapshot.cash = math.max(0, tonumber(snapshot.cash) or 0) + amount
            if dbSaveUserAccountsSnapshot(snapshot) then
                return
            end
            if MONEY_SOURCE_MODE == "users_accounts" then
                return
            end
        elseif MONEY_SOURCE_MODE == "users_accounts" then
            return
        end
    end

    local ok = callVrp(vRP.giveMoney, uid, amount)
    if not ok then
        callVrp(vRP.reward, uid, amount)
    end
end

-- متوافق مع أكثر من نسخة vRP (بعض النسخ لا تحتوي getInventoryItem)
local function getInventoryItemAmountSafe(uid, item)
    local ok, amount = callVrp(vRP.getInventoryItemAmount, uid, item)
    if ok and amount ~= nil then
        return tonumber(amount) or 0
    end

    ok, amount = callVrp(vRP.getInventoryItem, uid, item)
    if ok then
        if type(amount) == "table" then
            return tonumber(amount.amount or amount.qty or amount.count or amount[1]) or 0
        end
        return tonumber(amount) or 0
    end

    return 0
end

local function giveInventoryItemSafe(uid, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local before = getInventoryItemAmountSafe(uid, item)

    local ok = callVrp(vRP.giveInventoryItem, uid, item, amount)
    if ok then
        local after = getInventoryItemAmountSafe(uid, item)
        if after >= (before + amount) then
            return true
        end
    end

    ok = callVrp(vRP.tryGiveInventoryItem, uid, item, amount)
    if ok then
        local after = getInventoryItemAmountSafe(uid, item)
        if after >= (before + amount) then
            return true
        end
    end

    return false
end

-- يحاول خصم عنصر من المخزون عبر أكثر من API
local function tryTakeInventoryItemSafe(uid, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local before = getInventoryItemAmountSafe(uid, item)
    if before < amount then return false end

    local methods = {
        function() return callVrp(vRP.tryGetInventoryItem, uid, item, amount) end,
        function() return callVrp(vRP.tryGetInventoryItem, uid, item, amount, true) end,
        function() return callVrp(vRP.tryGetInventoryItem, uid, item, amount, false) end,
        function() return callVrp(vRP.tryGetItem, uid, item, amount) end,
    }

    for _, method in ipairs(methods) do
        local ok, res = method()
        if ok and (res == true or tonumber(res) == 1) then
            return true
        end
    end

    local after = getInventoryItemAmountSafe(uid, item)
    return after <= (before - amount)
end

-- ──────────────────────────────────────────────────────
-- Gang membership helpers
-- ──────────────────────────────────────────────────────

local managedGangsCache = {}
local MANAGED_GANGS_CACHE_TTL = 30
local permissionCheckCache = {}
local PERM_CHECK_CACHE_MS = math.max(3000, tonumber(GetConvar("ahmad_gangs_perm_cache_ttl_ms", "30000")) or 30000)

local function hasPermissionCached(uid, perm)
    if not uid then return false end
    local p = tostring(perm or "")
    if p == "" then return false end

    local now = GetGameTimer()
    local key = tostring(uid) .. "|" .. p
    local cached = permissionCheckCache[key]
    if cached and now < cached.expires then
        return cached.value == true
    end

    local ok = vRP.hasPermission({ uid, p }) and true or false
    permissionCheckCache[key] = {
        value = ok,
        expires = now + PERM_CHECK_CACHE_MS,
    }
    return ok
end

local function clearPermissionCacheForUser(uid)
    local prefix = tostring(uid) .. "|"
    for key in pairs(permissionCheckCache) do
        if key:sub(1, #prefix) == prefix then
            permissionCheckCache[key] = nil
        end
    end
end

local function hasGangRankFromConfig(uid, gang)
    if not uid or type(gang) ~= "table" then return false end
    local groups = getGroups(uid)
    for _, rank in ipairs(gang.ranks or {}) do
        local code = tostring(rank and rank.code or "")
        if code ~= "" and groups[code] then
            return true
        end
    end
    return false
end

function hasAnyGangPermission(uid, gang)
    if not uid or type(gang) ~= "table" then return false end
    for _, perm in pairs(gang.permissions or {}) do
        local p = tostring(perm or "")
        if p ~= "" and hasPermissionCached(uid, p) then
            return true
        end
    end
    return false
end

-- يرجع قائمة العصابات التي يملك اللاعب أي permission فيها
local function getManagedGangs(uid)
    local now = os.time()
    local cached = managedGangsCache[uid]
    if cached and cached.expires > now then
        return cached.data
    end

    local managed = {}
    for gang_id, gang in pairs(Config.Gangs) do
        if hasAnyGangPermission(uid, gang) then
            table.insert(managed, { id = gang_id, label = gang.label, color = gang.color, logo = gang.logo })
        end
    end

    managedGangsCache[uid] = {
        data = managed,
        expires = now + MANAGED_GANGS_CACHE_TTL,
    }

    return managed
end

-- هل يملك اللاعب صلاحية معينة؟
local function hasPerm(uid, gang_id, perm_name)
    if not uid then return false end
    local gang = Config.Gangs[gang_id]
    if not gang then return false end
    local perm = gang.permissions[perm_name]
    if not perm or perm == "" then return false end
    return hasPermissionCached(uid, perm)
end

-- يبني جدول permissions المرسل للـ NUI
local function buildPermTable(uid, gang_id)
    local gang  = Config.Gangs[gang_id]
    if not gang then return {} end
    local perms = {}
    for key, _ in pairs(gang.permissions) do
        perms[key] = hasPerm(uid, gang_id, key)
    end
    return perms
end

local function dbGetMember(cid, gang_id)
    -- كاش-أولاً: نبحث في gangMemberCache (المحملة مسبقاً) قبل DB
    local nCid = tonumber(cid)
    local cached = gangMemberCache[gang_id]
    if cached and cached.rows and cached.expires > os.time() then
        for _, r in ipairs(cached.rows) do
            if tonumber(r.citizen_id) == nCid then
                return r
            end
        end
        -- العضو غير موجود في الكاش → غالباً غير موجود فعلاً
        return nil
    end
    return MySQL.single.await(
        'SELECT rank_code, name, discord_id, last_avatar FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? AND gang_id = ? LIMIT 1',
        { RT_MEMBER, cid, gang_id }
    )
end

local function dbGetMemberName(cid, gang_id)
    -- استخدم dbGetMember (كاش-أولاً) بدل DB مباشرة
    local row = dbGetMember(cid, gang_id)
    return row and row.name or nil
end

local function dbGetAnyKnownName(cid)
    local nCid = tonumber(cid)
    if nCid and nCid > 0 then
        local now = os.time()
        local cached = knownMemberNameCache[nCid]
        if cached and cached.expires > now then
            return cached.name
        end
    end

    local row = MySQL.single.await(
        'SELECT name FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? AND name IS NOT NULL AND name <> "" ORDER BY hired_at DESC LIMIT 1',
        { RT_MEMBER, cid }
    )

    local name = row and row.name or nil
    if nCid and nCid > 0 then
        knownMemberNameCache[nCid] = {
            name = name,
            expires = os.time() + KNOWN_MEMBER_NAME_CACHE_TTL,
        }
    end

    return name
end

local function dbGetMembersByGang(gang_id)
    return MySQL.query.await(
        'SELECT citizen_id, rank_code, name, discord_id, last_avatar FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_MEMBER, gang_id }
    ) or {}
end

local function dbUpsertMember(cid, gang_id, rank_code, name, discord_id)
    MySQL.query(
        'INSERT INTO ahmad_gang (row_type, citizen_id, gang_id, rank_code, name, discord_id, hired_at) VALUES (?, ?, ?, ?, ?, ?, NOW()) '
     .. 'ON DUPLICATE KEY UPDATE rank_code = VALUES(rank_code), name = VALUES(name), discord_id = VALUES(discord_id)',
        { RT_MEMBER, cid, gang_id, rank_code, name or "", discord_id or "" }
    )
    knownMemberNameCache[tonumber(cid) or -1] = nil
end

local function dbUpdateMemberRank(cid, gang_id, rank_code)
    MySQL.query(
        'UPDATE ahmad_gang SET rank_code = ? WHERE row_type = ? AND citizen_id = ? AND gang_id = ?',
        { rank_code, RT_MEMBER, cid, gang_id }
    )
end

local function dbUpdateMemberMetaByCid(cid, name, discord_id)
    MySQL.query(
        'UPDATE ahmad_gang SET name = ?, discord_id = ? WHERE row_type = ? AND citizen_id = ?',
        { name or "", discord_id or "", RT_MEMBER, cid }
    )
    knownMemberNameCache[tonumber(cid) or -1] = nil
end

local function dbUpdateMemberAvatar(cid, gang_id, avatarUrl)
    dbQueueWrite(
        'UPDATE ahmad_gang SET last_avatar = ? WHERE row_type = ? AND citizen_id = ? AND gang_id = ?',
        { avatarUrl, RT_MEMBER, cid, gang_id },
        "member_avatar"
    )
end

local function dbDeleteMember(cid, gang_id)
    MySQL.query(
        'DELETE FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? AND gang_id = ?',
        { RT_MEMBER, cid, gang_id }
    )
    knownMemberNameCache[tonumber(cid) or -1] = nil
end

local function dbGetMemberRowsByCid(cid)
    return MySQL.query.await(
        'SELECT gang_id, rank_code, name, discord_id FROM ahmad_gang WHERE row_type = ? AND citizen_id = ?',
        { RT_MEMBER, cid }
    ) or {}
end

local function dbGetVrpDatatableGroupsMapByUserIds(userIds)
    local ids = {}
    local seen = {}
    for _, uid in ipairs(userIds or {}) do
        local n = tonumber(uid)
        if n ~= nil and not seen[n] then
            seen[n] = true
            table.insert(ids, n)
        end
    end

    if #ids == 0 then return {} end

    local out = {}

    if GROUP_SOURCE_MODE ~= "vrp" then
        out = dbGetUsersGroupsMapByUserIds(ids)
        if GROUP_SOURCE_MODE == "users_table" then
            return out
        end
    end

    local CHUNK_SIZE = 80
    for i = 1, #ids, CHUNK_SIZE do
        local qs, params = {}, { "vRP:datatable" }
        local upper = math.min(i + CHUNK_SIZE - 1, #ids)
        for j = i, upper do
            table.insert(qs, "?")
            table.insert(params, ids[j])
        end

        local rows = MySQL.query.await(
            'SELECT user_id, dvalue FROM vrp_user_data WHERE dkey = ? AND user_id IN (' .. table.concat(qs, ',') .. ')',
            params
        ) or {}

        for _, row in ipairs(rows) do
            local uid = tonumber(row.user_id)
            if uid ~= nil and not out[uid] then
                local raw = tostring(row.dvalue or "")
                local ok, data = pcall(json.decode, raw)
                if ok and type(data) == "table" and type(data.groups) == "table" then
                    out[uid] = data.groups
                end
            end
        end

        if upper < #ids then
            Wait(0)
        end
    end

    return out
end

local function dbGetGangExternalRankCodeMap(gang_id)
    local gang = Config.Gangs[gang_id]
    if not gang then return {} end

    local likeParts = {}
    local usersLikeParams = {}
    local vrpLikeParams = { "vRP:datatable" }
    for _, rank in ipairs(gang.ranks or {}) do
        local code = normalizeText(rank.code)
        if code ~= "" then
            table.insert(likeParts, "dvalue LIKE ?")
            table.insert(vrpLikeParams, '%"' .. code .. '"%')
            table.insert(usersLikeParams, '%"' .. code .. '"%')
        end
    end

    if #likeParts == 0 then return {} end

    local out = {}

    if GROUP_SOURCE_MODE ~= "vrp" then
        local sqlUsers =
            'SELECT id, user_id, ' .. SQL_COL_USERS_GROUPS .. ' AS groups_raw FROM ' .. SQL_TBL_USERS
            .. ' WHERE ' .. SQL_COL_USERS_GROUPS .. ' IS NOT NULL AND ' .. SQL_COL_USERS_GROUPS .. ' <> ""'
            .. ' AND (' .. table.concat(likeParts, ' OR '):gsub("dvalue", SQL_COL_USERS_GROUPS) .. ')'

        local okUsers, rowsUsers = pcall(function()
            return MySQL.query.await(sqlUsers, usersLikeParams)
        end)

        if okUsers and type(rowsUsers) == "table" then
            for _, row in ipairs(rowsUsers) do
                local uid = tonumber(row.id)
                if uid == nil then
                    uid = tonumber(row.user_id)
                end

                if uid ~= nil then
                    local groups = parseGroupsFromRaw(row.groups_raw)
                    local rankCode = getGangRankCodeFromGroups(groups, gang_id)
                    if rankCode then
                        out[uid] = rankCode
                    end
                end
            end
        end

        if GROUP_SOURCE_MODE == "users_table" then
            return out
        end
    end

    local sql = 'SELECT user_id, dvalue FROM vrp_user_data WHERE dkey = ? AND (' .. table.concat(likeParts, ' OR ') .. ')'
    local rows = MySQL.query.await(sql, vrpLikeParams) or {}

    for _, row in ipairs(rows) do
        local uid = tonumber(row.user_id)
        if uid ~= nil and not out[uid] then
            local ok, data = pcall(json.decode, tostring(row.dvalue or ""))
            if ok and type(data) == "table" and type(data.groups) == "table" then
                local rankCode = getGangRankCodeFromGroups(data.groups, gang_id)
                if rankCode then
                    out[uid] = rankCode
                end
            end
        end
    end

    return out
end

local function getGangExternalRankCodeMapCached(gang_id, force)
    local now = os.time()
    local cached = externalGangRankScanCache[gang_id]
    if not force and cached and cached.expires > now then
        return cached.data or {}
    end

    local data = dbGetGangExternalRankCodeMap(gang_id)
    externalGangRankScanCache[gang_id] = {
        data = data,
        expires = now + EXTERNAL_GANG_SCAN_TTL
    }
    return data
end

local function dbGetPlaytimeMap(gang_id)
    local rows = MySQL.query.await(
        'SELECT citizen_id, seconds FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_PLAYTIME, gang_id }
    ) or {}

    local m = {}
    for _, row in ipairs(rows) do
        m[row.citizen_id] = tonumber(row.seconds) or 0
    end
    return m
end

local function dbGetPlaytimeSeconds(cid, gang_id)
    -- كاش-أولاً: gangMemberCache.playtimeMap
    local cached = gangMemberCache[gang_id]
    if cached and cached.playtimeMap and cached.expires > os.time() then
        return cached.playtimeMap[tonumber(cid)] or cached.playtimeMap[cid] or 0
    end
    local row = MySQL.single.await(
        'SELECT seconds FROM ahmad_gang WHERE row_type = ? AND citizen_id = ? AND gang_id = ? LIMIT 1',
        { RT_PLAYTIME, cid, gang_id }
    )
    return row and (tonumber(row.seconds) or 0) or 0
end

local function dbIncPlaytime(cid, gang_id, seconds)
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, citizen_id, gang_id, seconds) VALUES (?, ?, ?, ?) '
     .. 'ON DUPLICATE KEY UPDATE seconds = seconds + VALUES(seconds)',
        { RT_PLAYTIME, cid, gang_id, seconds },
        "playtime_inc"
    )
end

local function dbEnsurePlaytime(cid, gang_id)
    MySQL.query(
        'INSERT IGNORE INTO ahmad_gang (row_type, citizen_id, gang_id, seconds) VALUES (?, ?, ?, 0)',
        { RT_PLAYTIME, cid, gang_id }
    )
end

dbGetGangMemberCids = function(gang_id)
    -- كاش-أولاً: gangMemberCache يحتوي قائمة الأعضاء كاملة
    local cached = gangMemberCache[gang_id]
    if cached and cached.rows and cached.expires > os.time() then
        local out = {}
        for _, r in ipairs(cached.rows) do
            out[#out + 1] = { citizen_id = r.citizen_id }
        end
        return out
    end
    return MySQL.query.await(
        'SELECT citizen_id FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_MEMBER, gang_id }
    ) or {}
end

local function dbGetTreasuryBalance(gang_id)
    local row = MySQL.single.await(
        'SELECT balance FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND (citizen_id = 0 OR citizen_id IS NULL) ORDER BY id DESC LIMIT 1',
        { RT_TREASURY, gang_id }
    )
    return row and (tonumber(row.balance) or 0) or 0
end

local function dbSetTreasuryBalance(gang_id, amount)
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, citizen_id, balance) VALUES (?, ?, 0, ?) '
     .. 'ON DUPLICATE KEY UPDATE balance = VALUES(balance)',
        { RT_TREASURY, gang_id, amount },
        "treasury_balance"
    )
end

local function dbGetDirtyBalance(gang_id)
    local row = MySQL.single.await(
        'SELECT balance FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND (citizen_id = 0 OR citizen_id IS NULL) ORDER BY id DESC LIMIT 1',
        { RT_DIRTY, gang_id }
    )
    return row and (tonumber(row.balance) or 0) or 0
end

local function dbSetDirtyBalance(gang_id, amount)
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, citizen_id, balance) VALUES (?, ?, 0, ?) '
     .. 'ON DUPLICATE KEY UPDATE balance = VALUES(balance)',
        { RT_DIRTY, gang_id, amount },
        "dirty_balance"
    )
end

local treasureBalanceCache = {}

local function dbGetTreasureBalance(gang_id)
    if treasureBalanceCache[gang_id] ~= nil then
        return treasureBalanceCache[gang_id]
    end
    local row = MySQL.single.await(
        'SELECT balance FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND (citizen_id = 0 OR citizen_id IS NULL) ORDER BY id DESC LIMIT 1',
        { RT_TREASURE, gang_id }
    )
    local v = row and (tonumber(row.balance) or 0) or 0
    treasureBalanceCache[gang_id] = v
    return v
end

local function dbSetTreasureBalance(gang_id, amount)
    local v = math.max(0, math.floor(tonumber(amount) or 0))
    treasureBalanceCache[gang_id] = v
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, citizen_id, balance) VALUES (?, ?, 0, ?) '
     .. 'ON DUPLICATE KEY UPDATE balance = VALUES(balance)',
        { RT_TREASURE, gang_id, v },
        "treasure_balance"
    )
end

-- dbAddTreasuryLog / dbGetTreasuryLog: محذوفتان — السجل في الكاش فقط (بدون DB)

-- ──────────────────────────────────────────────────────
-- Admin Panel — DB Helpers
-- ──────────────────────────────────────────────────────
local function dbGetWarnings(gang_id)
    local now = os.time()
    local cached = warningsListCache[gang_id]
    if cached and cached.expires > now then
        return cached.data
    end

    local rows = MySQL.query.await(
        'SELECT id, log_type AS title, note AS reason, seconds AS duration, by_name, '
     .. 'DATE_FORMAT(created_at, "%Y-%m-%d %H:%i") AS created_at '
     .. 'FROM ahmad_gang WHERE row_type = ? AND gang_id = ? ORDER BY id DESC',
        { RT_WARNING, gang_id }
    ) or {}

    warningsListCache[gang_id] = {
        data = rows,
        expires = now + WARNINGS_CACHE_TTL,
    }

    return rows
end

local function dbAddWarning(gang_id, title, reason, duration, byName)
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, log_type, note, seconds, by_name, created_at) '
     .. 'VALUES (?, ?, ?, ?, ?, ?, NOW())',
        { RT_WARNING, gang_id, tostring(title):sub(1,64), tostring(reason):sub(1,256), tonumber(duration) or 0, byName },
        "warning_add"
    )
    warningsListCache[gang_id] = nil
    invalidateGangStatsCache()
end

local function dbRemoveWarning(warning_id)
    dbQueueWrite(
        'DELETE FROM ahmad_gang WHERE id = ? AND row_type = ?',
        { warning_id, RT_WARNING },
        "warning_remove"
    )
    warningsListCache = {}
    invalidateGangStatsCache()
end

local pointsBalanceCache = {}   -- [gang_id] = number

local function dbGetPoints(gang_id)
    if pointsBalanceCache[gang_id] ~= nil then
        return pointsBalanceCache[gang_id]
    end
    local row = MySQL.single.await(
        'SELECT balance FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND citizen_id = 0 LIMIT 1',
        { RT_POINTS, gang_id }
    )
    local v = row and (tonumber(row.balance) or 0) or 0
    pointsBalanceCache[gang_id] = v
    return v
end

local function dbSetPoints(gang_id, points)
    local v = math.max(0, math.floor(points))
    pointsBalanceCache[gang_id] = v
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, citizen_id, balance) VALUES (?, ?, 0, ?) '
     .. 'ON DUPLICATE KEY UPDATE balance = VALUES(balance)',
        { RT_POINTS, gang_id, v },
        "points_set"
    )
    invalidateGangStatsCache()
end

local function dbGetGangTotalPlaytime(gang_id)
    local row = MySQL.single.await(
        'SELECT COALESCE(SUM(seconds), 0) AS total FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_PLAYTIME, gang_id }
    )
    return row and (tonumber(row.total) or 0) or 0
end

local function dbResetGangPlaytime(gang_id)
    dbQueueWrite(
        'UPDATE ahmad_gang SET seconds = 0 WHERE row_type = ? AND gang_id = ?',
        { RT_PLAYTIME, gang_id },
        "playtime_reset"
    )
    invalidateGangStatsCache()
end

local function getGangStatsSnapshot(forceRefresh)
    local now = os.time()
    if not forceRefresh and gangStatsCache.data and now < gangStatsCache.expires then
        return gangStatsCache.data
    end

    local out = {}
    for gang_id, _ in pairs(Config.Gangs or {}) do
        out[gang_id] = {
            members = 0,
            online = 0,
            points = 0,
            total_seconds = 0,
            warning_count = 0,
        }
    end

    -- ███ استعلام واحد مُجمّع بدل 4 استعلامات منفصلة ███
    local comboRows = MySQL.query.await(
        'SELECT gang_id, '
     .. 'SUM(CASE WHEN row_type = ? THEN 1 ELSE 0 END) AS member_count, '
     .. 'COALESCE(SUM(CASE WHEN row_type = ? THEN seconds END), 0) AS total_seconds, '
     .. 'SUM(CASE WHEN row_type = ? THEN 1 ELSE 0 END) AS warning_count, '
     .. 'COALESCE(MAX(CASE WHEN row_type = ? AND citizen_id = 0 THEN balance END), 0) AS points '
     .. 'FROM ahmad_gang WHERE row_type IN (?, ?, ?, ?) GROUP BY gang_id',
        { RT_MEMBER, RT_PLAYTIME, RT_WARNING, RT_POINTS,
          RT_MEMBER, RT_PLAYTIME, RT_WARNING, RT_POINTS }
    ) or {}
    for _, row in ipairs(comboRows) do
        local gid = tostring(row.gang_id or "")
        if out[gid] then
            out[gid].members       = tonumber(row.member_count) or 0
            out[gid].total_seconds = tonumber(row.total_seconds) or 0
            out[gid].warning_count = tonumber(row.warning_count) or 0
            out[gid].points        = tonumber(row.points) or 0
        end
    end

    -- حساب المتصلين من الذاكرة مباشرة (بدون DB)
    Wait(0)
    for cid, info in pairs(onlineCidMap) do
        local uid = info and tonumber(info.uid) or nil
        if uid ~= nil then
            local gCache = groupsCache[tostring(uid)]
            local groups = gCache and gCache.groups or nil
            if groups then
                for groupCode, hasGroup in pairs(groups) do
                    if hasGroup then
                        local gid = gangByRankCode[tostring(groupCode)]
                        if gid and out[gid] then
                            out[gid].online = out[gid].online + 1
                        end
                    end
                end
            end
        end
    end

    gangStatsCache.data = out
    gangStatsCache.expires = now + GANG_STATS_CACHE_TTL
    return out
end

-- ──────────────────────────────────────────────────────
-- Admin Panel — Permission Helpers
-- ──────────────────────────────────────────────────────
local function hasAdminPerm(uid, perm_name)
    if not Config.AdminPanel then return false end
    local perm = Config.AdminPanel.permissions[perm_name]
    if not perm or perm == "" then return false end
    return hasPermissionCached(uid, perm)
end

local function buildAdminPermTable(uid)
    if not Config.AdminPanel then return {} end
    local perms = {}
    for key, _ in pairs(Config.AdminPanel.permissions) do
        perms[key] = hasAdminPerm(uid, key)
    end
    return perms
end

-- يجلب رتبة العضو في عصابة من الـ DB
local function getMemberRank(cid, gang_id)
    local row = dbGetMember(cid, gang_id)
    return row and row.rank_code or nil
end

-- ──────────────────────────────────────────────────────
-- Webhook logger
-- ──────────────────────────────────────────────────────
local function webhookLog(gang_id, title, description, color)
    local gang = Config.Gangs[gang_id]
    if not gang or not gang.logs or not gang.logs.enabled or gang.logs.url == "" then return end

    local hexColor = tostring(gang.color or "#4d7fff"):gsub("#", "")
    local intColor = tonumber(hexColor, 16) or 5299231

    PerformHttpRequest(gang.logs.url, function() end, "POST",
        json.encode({
            username   = "Ahmad Gangs | " .. (gang.label or gang_id),
            avatar_url = gang.logo or "",
            embeds     = {{
                title       = title,
                description = description,
                color       = intColor,
                footer      = { text = "ahmad_gangs" },
                timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }),
        { ["Content-Type"] = "application/json" }
    )
end

-- لوق Gang Manager — يرسل للويبهوك المركزي (Config.AdminLogs)
local function adminWebhookLog(title, description, gang_id)
    local cfg = Config.AdminLogs
    if not cfg or not cfg.enabled or not cfg.url or cfg.url == "" then return end

    local gang     = gang_id and Config.Gangs[gang_id]
    local intColor = 0xE74C3C   -- أحمر أدمن افتراضي
    if gang and gang.color then
        local hex = tostring(gang.color):gsub("#", "")
        intColor = tonumber(hex, 16) or intColor
    end
    local gangLine = gang and ("\n**العصابة:** " .. gang.label) or ""

    PerformHttpRequest(cfg.url, function() end, "POST",
        json.encode({
            username   = "ahmad_gangs Manager",
            embeds     = {{
                title       = title,
                description = description .. gangLine,
                color       = intColor,
                footer      = { text = "ahmad_gangs | admin" },
                timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }),
        { ["Content-Type"] = "application/json" }
    )
end

-- ──────────────────────────────────────────────────────
-- وقت التواجد — event-driven بدون ثريد (أسلوب ahmad_rank)
-- تسجيل وقت البداية عند الدخول، كتابة DB عند الخروج أو فتح القائمة.
-- ──────────────────────────────────────────────────────
local function flushPlaytimeForUid(uid)
    local cid     = getCid(uid)
    local started = playtimeSessionStart[cid]
    if not started then return end
    local elapsed = math.floor(os.time() - started)
    if elapsed < 1 then return end

    local g    = groupsCache[tostring(uid)]
    if not g then
        g = { groups = getGroups(uid) }
    end
    local grps = (g and g.groups) or {}
    local batchParts  = {}
    local batchValues = {}
    local dirtyGangs  = {}
    for groupCode, hasGroup in pairs(grps) do
        if hasGroup then
            local gang_id = gangByRankCode[tostring(groupCode)]
            if gang_id and not dirtyGangs[gang_id] then
                dirtyGangs[gang_id] = true
            end
        end
    end

    if not hasAnyEntries(dirtyGangs) then
        local memberRows = dbGetMemberRowsByCid(cid)
        for _, row in ipairs(memberRows or {}) do
            local gang_id = tostring(row and row.gang_id or "")
            if gang_id ~= "" then
                dirtyGangs[gang_id] = true
            end
        end
    end

    for gang_id in pairs(dirtyGangs) do
        table.insert(batchParts,  "(?, ?, ?, ?)")
        table.insert(batchValues, RT_PLAYTIME)
        table.insert(batchValues, cid)
        table.insert(batchValues, gang_id)
        table.insert(batchValues, elapsed)
    end

    if #batchParts > 0 then
        dbQueueWrite(
            'INSERT INTO ahmad_gang (row_type, citizen_id, gang_id, seconds) VALUES '
            .. table.concat(batchParts, ",")
            .. ' ON DUPLICATE KEY UPDATE seconds = seconds + VALUES(seconds)',
            batchValues,
            "playtime_flush"
        )
        for gang_id in pairs(dirtyGangs) do
            invalidateGangCache(gang_id)
        end
        invalidateGangStatsCache()
    end
    -- إعادة ضبط الساعة (flush جزئي — الجلسة مستمرة)
    playtimeSessionStart[cid] = os.time()
end

-- ──────────────────────────────────────────────────────
-- مزامنة مجموعات vRP مع gang_members
-- يُستخدم عند دخول اللاعب وبشكل دوري
-- ──────────────────────────────────────────────────────
local function syncPlayerGangGroups(uid, src)
    local cid     = getCid(uid)
    if not cid then return false end
    local groups  = getGroups(uid)

    refreshOnlineGangMemberFlag(uid, groups)

    -- في وضع users_table: إذا فشل/تأخر جلب الجروبات لا تمسح العضويات من DB.
    if GROUP_SOURCE_MODE ~= "vrp" and not hasAnyEntries(groups) then
        return false
    end

    Wait(0)
    local name    = getUserName(uid)
    Wait(0)
    local discord = (src and tonumber(src) and tonumber(src) > 0) and getDiscordFromSource(tonumber(src)) or ""

    local desiredByGang = {}
    for groupCode, hasGroup in pairs(groups or {}) do
        if hasGroup then
            local gid = gangByRankCode[tostring(groupCode)]
            if gid then
                desiredByGang[gid] = tostring(groupCode)
            end
        end
    end

    local existingRows = dbGetMemberRowsByCid(cid)
    Wait(0)
    local existingByGang = {}
    for _, row in ipairs(existingRows or {}) do
        local gid = tostring(row and row.gang_id or "")
        if gid ~= "" then
            existingByGang[gid] = row
        end
    end

    local changed = false
    local touchedGangs = {}

    for gang_id, row in pairs(existingByGang) do
        local desiredRank = desiredByGang[gang_id]
        if not desiredRank then
            dbDeleteMember(cid, gang_id)
            touchedGangs[gang_id] = true
            changed = true
        else
            local currentRank = tostring(row.rank_code or "")
            local currentName = normalizeText(row.name)
            local currentDisc = tostring(row.discord_id or "")
            local wantName = normalizeText(name)
            local wantDisc = tostring(discord or "")

            if currentRank ~= desiredRank or currentName ~= wantName or currentDisc ~= wantDisc then
                dbUpsertMember(cid, gang_id, desiredRank, name, discord)
                dbEnsurePlaytime(cid, gang_id)
                touchedGangs[gang_id] = true
                changed = true
            end

            desiredByGang[gang_id] = nil
        end
    end

    for gang_id, desiredRank in pairs(desiredByGang) do
        dbUpsertMember(cid, gang_id, desiredRank, name, discord)
        dbEnsurePlaytime(cid, gang_id)
        touchedGangs[gang_id] = true
        changed = true
    end

    if changed then
        for gang_id in pairs(touchedGangs) do
            invalidateGangCache(gang_id)
        end
    end

    return changed
end

local function markActiveMemberViewer(src, gang_id)
    local nSrc = tonumber(src)
    if not nSrc or nSrc <= 0 then return end
    if not gang_id or gang_id == "" then
        activeMemberViewGang[nSrc] = nil
    else
        activeMemberViewGang[nSrc] = gang_id
    end
end

-- أبلغ كل من لديه قائمة أعضاء مفتوحة لهذه العصابة بوجود تغيير (بدون ثريد)
local function notifyActiveMembersViewers(gang_id)
    for src, viewedGang in pairs(activeMemberViewGang) do
        if viewedGang == gang_id and GetPlayerName(src) then
            TriggerClientEvent("gang:membersRefreshNeeded", src, gang_id)
        end
    end
end

local reconcileFallbackWarmAt = 0

local function reconcileGangMembersFromVrpUserData(gang_id, includeOfflineCandidates, forceOfflineScan)
    local rows = dbGetMembersByGang(gang_id)
    local ids = {}
    local existingByUid = {}
    local seenIds = {}
    local onlineSrcByUid = {}
    local nowMs = GetGameTimer()

    local function addUidCandidate(uid, src)
        local nUid = tonumber(uid)
        if nUid == nil then return end
        if not seenIds[nUid] then
            seenIds[nUid] = true
            table.insert(ids, nUid)
        end
        if src then
            local nSrc = tonumber(src)
            if nSrc and nSrc > 0 then
                onlineSrcByUid[nUid] = nSrc
            end
        end
    end

    -- إضافة اللاعبين الأونلاين لالتقاط "توظيف خارجي" (عضو جديد) فوراً.
    for _, row in ipairs(rows) do
        local uid = tonumber(row.citizen_id)
        if uid ~= nil then
            addUidCandidate(uid, nil)
            existingByUid[uid] = row
        end
    end

    local hasOnlineInMap = false
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        local uid = info and tonumber(info.uid) or tonumber(cid)
        if src and src > 0 and uid ~= nil and GetPlayerName(src) then
            hasOnlineInMap = true
            addUidCandidate(uid, src)
        end
    end

    -- fallback احتياطي إذا الكاش لم يُبنَ بعد (مثل أول ثواني بعد تشغيل الريسورس)
    if not hasOnlineInMap then
        if (nowMs - reconcileFallbackWarmAt) > 5000 then
            reconcileFallbackWarmAt = nowMs
            for _, srcStr in ipairs(GetPlayers()) do
                local src = tonumber(srcStr)
                local uid = src and getUserId(src) or nil
                if uid ~= nil then
                    addUidCandidate(uid, src)
                    local cid = getCid(uid)
                    if cid and not onlineCidMap[cid] then
                        onlineCidMap[cid] = { uid = uid, src = src }
                    end
                end
            end
        end
    end

    if #ids == 0 and not includeOfflineCandidates then return false end

    local offlineIds = {}
    for _, uid in ipairs(ids) do
        if not onlineSrcByUid[uid] then
            table.insert(offlineIds, uid)
        end
    end

    local groupsMap = (#offlineIds > 0) and dbGetVrpDatatableGroupsMapByUserIds(offlineIds) or {}
    Wait(0)
    local changed = false

    for _, row in ipairs(rows) do
        local uid = tonumber(row.citizen_id)
        if uid then
            local liveRank = nil
            if onlineSrcByUid[uid] then
                liveRank = getLiveGangRankCode(uid, gang_id)
            else
                local groups = groupsMap[uid]
                if type(groups) == "table" then
                    liveRank = getGangRankCodeFromGroups(groups, gang_id)
                end
            end

            if not liveRank then
                if onlineSrcByUid[uid] then
                    dbDeleteMember(uid, gang_id)
                    changed = true
                    pushLaundryAccessToUser(uid)
                end
            elseif liveRank ~= row.rank_code then
                dbUpdateMemberRank(uid, gang_id, liveRank)
                changed = true
                pushLaundryAccessToUser(uid)
            end
        end
        ::continue::
    end

    -- توظيف خارجي: إذا اللاعب أونلاين وحصل رتبة من الكونفق ولم يكن مسجلاً بجدولنا.
    local _reconcileOnlineCount = 0
    for uid, src in pairs(onlineSrcByUid) do
        if not existingByUid[uid] then
            local liveRank = getLiveGangRankCode(uid, gang_id)
            if liveRank then
                local name = getUserName(uid)
                local discord = getDiscordFromSource(src)
                dbUpsertMember(uid, gang_id, liveRank, name, discord)
                dbEnsurePlaytime(uid, gang_id)
                changed = true
                pushLaundryAccessToUser(uid)
                existingByUid[uid] = { citizen_id = uid, rank_code = liveRank, name = name, discord_id = discord }
                _reconcileOnlineCount = _reconcileOnlineCount + 1
                if (_reconcileOnlineCount % 3) == 0 then Wait(0) end
            end
        end
    end

    if includeOfflineCandidates then
        local rankMap = getGangExternalRankCodeMapCached(gang_id, forceOfflineScan == true)
        Wait(0)
        local _reconcileOfflineCount = 0
        for uid, rankCode in pairs(rankMap) do
            if not existingByUid[uid] then
                local name = getUserName(uid)
                local src = onlineSrcByUid[uid]
                local discord = (src and getDiscordFromSource(src)) or ""
                dbUpsertMember(uid, gang_id, rankCode, name, discord)
                dbEnsurePlaytime(uid, gang_id)
                changed = true
                pushLaundryAccessToUser(uid)
                existingByUid[uid] = { citizen_id = uid, rank_code = rankCode, name = name, discord_id = discord }
                _reconcileOfflineCount = _reconcileOfflineCount + 1
                if (_reconcileOfflineCount % 3) == 0 then Wait(0) end
            end
        end
    end

    if changed then
        invalidateGangCache(gang_id)
    end

    return changed
end

local reconcileNextAtByGang = {}
local RECONCILE_MIN_INTERVAL_MS = 6000

local function reconcileGangMembersThrottled(gang_id, includeOfflineCandidates, forceOfflineScan)
    local now = GetGameTimer()
    local gid = tostring(gang_id or "")
    if gid == "" then return false end

    if forceOfflineScan == true then
        reconcileNextAtByGang[gid] = now + RECONCILE_MIN_INTERVAL_MS
        return reconcileGangMembersFromVrpUserData(gang_id, includeOfflineCandidates, forceOfflineScan)
    end

    local nextAt = reconcileNextAtByGang[gid] or 0
    if now < nextAt then
        return false
    end

    reconcileNextAtByGang[gid] = now + RECONCILE_MIN_INTERVAL_MS
    return reconcileGangMembersFromVrpUserData(gang_id, includeOfflineCandidates, forceOfflineScan)
end

-- للاستخدام من أي سكربت سيرفر خارجي بعد تعديل رتب/جروبات لاعب
exports("RefreshGangMemberByUserId", function(targetUid)
    local uid = tonumber(targetUid)
    if uid == nil then return false end

    local src = getOnlineSourceByUserId(uid)
    syncPlayerGangGroups(uid, src)
    clearPermissionCacheForUser(uid)

    -- إبطال كاش كل العصابات حتى تنعكس التغييرات فوراً في أي قائمة مفتوحة
    for gang_id, _ in pairs(Config.Gangs or {}) do
        invalidateGangCache(gang_id)
    end

    if src then
        pushLaundryAccessToUser(uid)
    end

    return true
end)

-- حدّث بيانات العضو (اسم + discord) عند دخوله، ومزامنة المجموعات
AddEventHandler("playerConnecting", function()
    -- يُستدعى بشكل عبر حدث آخر أدناه
end)

local function ensureOnlinePlayerRuntimeState(uid, src)
    local targetUid = tonumber(uid)
    local targetSrc = tonumber(src)
    if targetUid == nil or not targetSrc or targetSrc <= 0 or not GetPlayerName(targetSrc) then
        return nil, nil
    end

    local cid = getCid(targetUid)
    onlineCidMap[cid] = { uid = targetUid, src = targetSrc }
    if not playtimeSessionStart[cid] then
        playtimeSessionStart[cid] = os.time()
    end

    managedGangsCache[targetUid] = nil
    clearPermissionCacheForUser(targetUid)
    refreshOnlineGangMemberFlag(targetUid)

    return targetUid, cid
end

AddEventHandler("vRP:playerJoin", function(uid)
    -- نؤجل المعالجة قليلاً حتى ينهي vRP تحميل بيانات اللاعب بالكامل
    -- (groups / identity قد لا تكون جاهزة مباشرةً عند هذا الحدث)
    -- تأخير عشوائي (800-2500ms) يوزّع الحمل عند restart بـ 500 لاعب
    CreateThread(function()
        Wait(800 + math.random(0, 1700))

        local ok, src = pcall(vRP.getUserSource, { uid })
        if not ok or not src then return end
        src = tonumber(src)
        if not src or src <= 0 then return end
        if not GetPlayerName(src) then return end

        local targetUid, cid = ensureOnlinePlayerRuntimeState(uid, src)
        if not targetUid then return end

        local name    = getUserName(targetUid)
        Wait(0)
        local discord = getDiscordFromSource(src)
        dbUpdateMemberMetaByCid(cid, name, discord)
        Wait(0)

        -- مزامنة المجموعات بعد ما vRP حمّل بيانات اللاعب كاملاً
        syncPlayerGangGroups(targetUid, src)
    end)
end)

AddEventHandler("vRP:playerSpawn", function(user_id, src, first_spawn)
    if first_spawn ~= true then return end

    local targetUid = tonumber(user_id) or getUserId(src)
    local uid, cid = ensureOnlinePlayerRuntimeState(targetUid, src)
    if not uid then return end

    local name = getUserName(uid)
    Wait(0)
    local discord = getDiscordFromSource(src)
    dbUpdateMemberMetaByCid(cid, name, discord)
    Wait(0)

    syncPlayerGangGroups(uid, src)
end)

AddEventHandler("playerDropped", function()
    local src    = source
    local nSrc   = tonumber(src) or 0
    local uid    = getUserId(src)

    if not uid then
        local cached = srcToUidCache[nSrc]
        if type(cached) == "table" and cached.uid ~= nil then
            uid = tonumber(cached.uid)
        end
    end

    if not uid then
        for cid, info in pairs(onlineCidMap) do
            local infoSrc = info and tonumber(info.src) or nil
            if infoSrc and infoSrc == nSrc then
                uid = tonumber(info.uid) or tonumber(cid)
                break
            end
        end
    end

    srcToUidCache[nSrc] = nil
    activeMemberViewGang[src] = nil

    -- تنظيف rate limits لهذا اللاعب عند الخروج (بدون ثريد كنسي)
    local srcPrefix = tostring(src) .. ":"
    local prefixLen = #srcPrefix
    for k in pairs(rateLimits) do
        if k:sub(1, prefixLen) == srcPrefix then
            rateLimits[k] = nil
        end
    end
    if uid then
        -- ── كتابة وقت التواجد المتراكم للجلسة الحالية (بدون ثريد) ──
        local cid = getCid(uid)
        local started = playtimeSessionStart[cid]
        if started then
            local elapsed = math.floor(os.time() - started)
            if elapsed > 0 then
                local g = groupsCache[tostring(uid)]
                if not g then
                    g = { groups = getGroups(uid) }
                end
                local grps = (g and g.groups) or {}
                local batchParts  = {}
                local batchValues = {}
                local dirtyGangs  = {}
                for groupCode, hasGroup in pairs(grps) do
                    if hasGroup then
                        local gang_id = gangByRankCode[tostring(groupCode)]
                        if gang_id and not dirtyGangs[gang_id] then
                            dirtyGangs[gang_id] = true
                        end
                    end
                end

                if not hasAnyEntries(dirtyGangs) then
                    local memberRows = dbGetMemberRowsByCid(cid)
                    for _, row in ipairs(memberRows or {}) do
                        local gang_id = tostring(row and row.gang_id or "")
                        if gang_id ~= "" then
                            dirtyGangs[gang_id] = true
                        end
                    end
                end

                for gang_id in pairs(dirtyGangs) do
                    table.insert(batchParts,  "(?, ?, ?, ?)")
                    table.insert(batchValues, RT_PLAYTIME)
                    table.insert(batchValues, cid)
                    table.insert(batchValues, gang_id)
                    table.insert(batchValues, elapsed)
                end

                if #batchParts > 0 then
                    dbQueueWrite(
                        'INSERT INTO ahmad_gang (row_type, citizen_id, gang_id, seconds) VALUES '
                        .. table.concat(batchParts, ",")
                        .. ' ON DUPLICATE KEY UPDATE seconds = seconds + VALUES(seconds)',
                        batchValues,
                        "playtime_drop"
                    )
                    for gang_id in pairs(dirtyGangs) do
                        invalidateGangCache(gang_id)
                    end
                    invalidateGangStatsCache()
                end
            end
            playtimeSessionStart[cid] = nil
        end

        managedGangsCache[uid] = nil
        clearPermissionCacheForUser(uid)
        invalidateGroupsCache(uid)
        onlineCidMap[cid] = nil
    end
end)

-- الكاشات الدائمة (permissionCheckCache / groupsCache / managedGangsCache / srcToUidCache)
-- تنظّف نفسها بالـ TTL عند القراءة — لا يلزم ثريد كنسي.

local BOOT_SYNC_PLAYER_WAIT_MS = 120
local BOOT_OFFLINE_IMPORT_DELAY_MS = 90000
local BOOT_OFFLINE_IMPORT_STEP_WAIT_MS = 1200

function runOnlineGangSyncTick()
    local processed = 0
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        local targetUid = info and tonumber(info.uid) or tonumber(cid)
        if src and src > 0 and targetUid ~= nil and GetPlayerName(src) then
            local targetCid = getCid(targetUid)
            if not playtimeSessionStart[targetCid] then
                playtimeSessionStart[targetCid] = os.time()
            end

            local changed = syncPlayerGangGroups(targetUid, src)
            if changed then
                managedGangsCache[targetUid] = nil
                clearPermissionCacheForUser(targetUid)
            end
            processed = processed + 1
            if (processed % 6) == 0 then
                Wait(50)
            end
        end
    end

    SetTimeout(600000, runOnlineGangSyncTick)
end

-- مزامنة دورية للاعبين المتصلين (خفيفة على الإقلاع)
CreateThread(function()
    -- مزامنة أولية على دفعات لتجنب spike وقت تشغيل الريسورس.
    Wait(2500)
    local mappedCount = 0
    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        local uid = getUserId(src)
        if uid then
            local ensuredUid = select(1, ensureOnlinePlayerRuntimeState(uid, src))
            if ensuredUid then
                syncPlayerGangGroups(ensuredUid, src)
                mappedCount = mappedCount + 1
            end

            if (mappedCount % 10) == 0 then
                Wait(50)
            end
        end
    end

    -- الاستيراد الشامل للأعضاء الأوفلاين اختياري — فعّله بتغيير false→true بالكود لو احتجته.
    -- if true then
    --     CreateThread(function()
    --         Wait(BOOT_OFFLINE_IMPORT_DELAY_MS)
    --         for gang_id, _ in pairs(Config.Gangs or {}) do
    --             reconcileGangMembersThrottled(gang_id, true, true)
    --             Wait(BOOT_OFFLINE_IMPORT_STEP_WAIT_MS)
    --         end
    --     end)
    -- end

    SetTimeout(600000, runOnlineGangSyncTick)  -- 10 دقائق بدل 3 (تقليل الضغط على DB في السيرفرات الكبيرة)

    -- ███ تسخين الكاش عند الإقلاع — استعلامات مجمّعة (bulk) بدل per-gang ███
    CreateThread(function()
        Wait(2000)

        -- ─── 1) إحصائيات العصابات (استعلام واحد مجمّع) ───
        pcall(function() getGangStatsSnapshot(true) end)
        Wait(0)

        -- ─── 2) أرصدة الخزائن + الأوساخ + النقاط + الكنز (bulk واحد) ───
        pcall(function()
            local balRows = MySQL.query.await(
                'SELECT row_type, gang_id, balance FROM ahmad_gang '
             .. 'WHERE row_type IN (?, ?, ?, ?) AND (citizen_id = 0 OR citizen_id IS NULL)',
                { RT_TREASURY, RT_DIRTY, RT_POINTS, RT_TREASURE }
            ) or {}
            for _, r in ipairs(balRows) do
                local gid = tostring(r.gang_id or "")
                local rt  = r.row_type
                local val = tonumber(r.balance) or 0
                if rt == RT_TREASURY then
                    treasuryBalanceCache[gid] = val
                elseif rt == RT_DIRTY then
                    dirtyTreasuryCache[gid] = val
                elseif rt == RT_POINTS then
                    pointsBalanceCache[gid] = val
                elseif rt == RT_TREASURE then
                    treasureBalanceCache[gid] = val
                end
            end
        end)
        Wait(0)

        -- ─── 3) أعضاء كل العصابات (bulk واحد) ───
        pcall(function()
            local memberRows = MySQL.query.await(
                'SELECT gang_id, citizen_id, rank_code, name, discord_id, last_avatar FROM ahmad_gang WHERE row_type = ?',
                { RT_MEMBER }
            ) or {}
            Wait(0)
            local ptRows = MySQL.query.await(
                'SELECT gang_id, citizen_id, seconds FROM ahmad_gang WHERE row_type = ?',
                { RT_PLAYTIME }
            ) or {}

            -- تجميع حسب العصابة
            local membersByGang = {}
            for _, r in ipairs(memberRows) do
                local gid = tostring(r.gang_id or "")
                if not membersByGang[gid] then membersByGang[gid] = {} end
                table.insert(membersByGang[gid], r)
            end
            local ptByGang = {}
            for _, r in ipairs(ptRows) do
                local gid = tostring(r.gang_id or "")
                if not ptByGang[gid] then ptByGang[gid] = {} end
                ptByGang[gid][r.citizen_id] = tonumber(r.seconds) or 0
            end
            local nowTs = os.time()
            for gang_id, _ in pairs(Config.Gangs or {}) do
                local rows  = membersByGang[gang_id] or {}
                local ptMap = ptByGang[gang_id] or {}
                gangMemberCache[gang_id] = { rows = rows, playtimeMap = ptMap, expires = nowTs + CACHE_TTL }
            end
        end)
        Wait(0)

        -- ─── 4) حالة المتاجر (bulk واحد) ───
        pcall(function()
            local ownedRows = MySQL.query.await(
                'SELECT gang_id FROM ahmad_gang WHERE row_type = ? AND citizen_id = 0',
                { RT_SHOP_OWNED }
            ) or {}
            Wait(0)
            local itemRows = MySQL.query.await(
                'SELECT gang_id, name, amount, balance FROM ahmad_gang WHERE row_type = ?',
                { RT_SHOP_ITEM }
            ) or {}

            local ownedSet = {}
            for _, r in ipairs(ownedRows) do
                ownedSet[tostring(r.gang_id or "")] = true
            end
            local itemsByGang = {}
            for _, r in ipairs(itemRows) do
                local gid = tostring(r.gang_id or "")
                if not itemsByGang[gid] then itemsByGang[gid] = {} end
                if r.name and r.name ~= '' then
                    itemsByGang[gid][r.name] = {
                        stock = tonumber(r.amount) or 0,
                        price = tonumber(r.balance) or 0,
                    }
                end
            end
            for gang_id, _ in pairs(Config.Gangs or {}) do
                shopStateCache[gang_id] = {
                    owned = ownedSet[gang_id] == true,
                    items = itemsByGang[gang_id] or {},
                }
            end
        end)

        local gangCount = 0
        for _ in pairs(Config.Gangs or {}) do gangCount = gangCount + 1 end
        print(("^2[ahmad_gangs]^7 boot cache pre-warm done (%d gangs)"):format(gangCount))
    end)
end)

-- ──────────────────────────────────────────────────────
-- جلب قائمة الأعضاء (مع أفاتار) — محسّن بكاش + onlineCidMap
-- ──────────────────────────────────────────────────────
local function buildMemberList(gang_id, filter, cb)
    -- filter: 'all' | 'online' | 'offline'
    local gang = Config.Gangs[gang_id]
    if not gang then return cb({}) end
    local tPerf = perfStart()

    -- استخدام الكاش لتجنب query مزدوج في كل طلب
    local rows, playtimeMap
    local cached = gangMemberCache[gang_id]
    if cached and os.time() < cached.expires then
        rows        = cached.rows
        playtimeMap = cached.playtimeMap
    else
        rows        = dbGetMembersByGang(gang_id)
        playtimeMap = dbGetPlaytimeMap(gang_id)
        if rows then
            gangMemberCache[gang_id] = { rows = rows, playtimeMap = playtimeMap, expires = os.time() + CACHE_TTL }
        end
    end

    if not rows then return cb({}) end

    -- استخدام onlineCidMap بدل GetPlayers() (يتجنب O(500) على كل طلب)
    local onlineMap = onlineCidMap

    -- ترتيب الرتب
    local rankOrder = {}
    for i, r in ipairs(gang.ranks) do rankOrder[r.code] = i end

    local list = {}
    if #rows == 0 then return cb({}) end
    local avatarBackfillBudget = AVATAR_BACKFILL_BUDGET_PER_LIST
    local liveRankCheckBudget = LIVE_RANK_CHECK_BUDGET_PER_LIST
    local nowTs = os.time()

    local scanned = 0
    for _, row in ipairs(rows) do
        scanned = scanned + 1
        if (scanned % 15) == 0 then
            Wait(0)
        end

        local cid        = row.citizen_id
        local onlineInfo = onlineMap[cid]
        local isOnline   = onlineInfo ~= nil

        local effectiveRankCode = row.rank_code
        if isOnline and onlineInfo and onlineInfo.uid then
            local doLiveRankCheck = false
            if liveRankCheckBudget > 0 then
                local lrKey = tostring(onlineInfo.uid) .. ":" .. tostring(gang_id)
                local nextCheckAt = tonumber(liveRankCheckNextAtByUidGang[lrKey]) or 0
                if nowTs >= nextCheckAt then
                    doLiveRankCheck = true
                    liveRankCheckBudget = liveRankCheckBudget - 1
                    liveRankCheckNextAtByUidGang[lrKey] = nowTs + LIVE_RANK_CHECK_COOLDOWN_SEC
                end
            end

            if doLiveRankCheck then
                local liveRankCode = getLiveGangRankCode(onlineInfo.uid, gang_id)

                -- إذا أزيلت رتبة اللاعب من سكربت خارجي: احذف صف العضوية فوراً
                if not liveRankCode then
                    dbDeleteMember(cid, gang_id)
                    invalidateGangCache(gang_id)
                    goto continue
                end

                -- إذا تغيّرت الرتبة من سكربت خارجي: حدثها فوراً
                if liveRankCode ~= row.rank_code then
                    dbUpdateMemberRank(cid, gang_id, liveRankCode)
                    invalidateGangCache(gang_id)
                    effectiveRankCode = liveRankCode
                end
            end
        end

        if filter == "online"  and not isOnline then goto continue end
        if filter == "offline" and isOnline     then goto continue end

        local rankLabel = ""
        for _, r in ipairs(gang.ranks) do
            if r.code == effectiveRankCode then rankLabel = r.label; break end
        end

        local seconds = tonumber(playtimeMap[cid]) or 0
        local h, m = formatPlaytime(seconds)
        local avatar = (row.last_avatar or "") ~= "" and row.last_avatar or DEFAULT_AVATAR

        -- لا تنتظر Discord API حتى لا يتأخر عرض القائمة
        if avatar == DEFAULT_AVATAR and isOnline and (row.discord_id or "") ~= "" and avatarBackfillBudget > 0 then
            local nextAt = tonumber(avatarBackfillNextAtByCid[cid]) or 0
            if nowTs >= nextAt then
                avatarBackfillBudget = avatarBackfillBudget - 1
                avatarBackfillNextAtByCid[cid] = nowTs + AVATAR_BACKFILL_COOLDOWN_SEC
                fetchDiscordAvatar(row.discord_id, function(avatarUrl)
                    if avatarUrl and avatarUrl ~= DEFAULT_AVATAR then
                        dbUpdateMemberAvatar(cid, gang_id, avatarUrl)
                    end
                end)
            end
        end

        local displayName = normalizeText(row.name)
        if isBadDisplayName(displayName) then
            if isOnline and onlineInfo and onlineInfo.src then
                local numSrc = tonumber(onlineInfo.src)
                local liveName = (numSrc and numSrc > 0 and GetPlayerName(numSrc)) and normalizeText(GetPlayerName(numSrc)) or ""
                displayName = isBadDisplayName(liveName) and ("ID: " .. tostring(cid)) or liveName
            else
                local fallbackName = normalizeText(dbGetAnyKnownName(cid) or getUserName(cid))
                displayName = isBadDisplayName(fallbackName) and ("ID: " .. tostring(cid)) or fallbackName
            end
        end

        table.insert(list, {
            cid        = cid,
            user_id    = cid,
            name       = displayName,
            avatar     = avatar,
            rank_code  = effectiveRankCode,
            rank_label = rankLabel,
            rank_order = rankOrder[effectiveRankCode] or 999,
            hours      = h,
            minutes    = m,
            seconds    = seconds,
            online     = isOnline,
        })

        ::continue::
    end

    table.sort(list, function(a, b)
        if a.rank_order ~= b.rank_order then return a.rank_order < b.rank_order end
        return (a.seconds or 0) > (b.seconds or 0)
    end)
    perfDone("buildMemberList", tPerf, ("gang=%s rows=%d out=%d"):format(tostring(gang_id), #rows, #list))
    cb(list)
end

-- ──────────────────────────────────────────────────────
-- Dashboard: total playtime + top5
-- ──────────────────────────────────────────────────────
local function buildDashboard(gang_id, cb)
    local members = dbGetMembersByGang(gang_id)
    local playtimeMap = dbGetPlaytimeMap(gang_id)
    local rows = {}
    for _, m in ipairs(members) do
        table.insert(rows, {
            citizen_id = m.citizen_id,
            name       = m.name,
            seconds    = tonumber(playtimeMap[m.citizen_id]) or 0,
        })
    end
    table.sort(rows, function(a, b) return (a.seconds or 0) > (b.seconds or 0) end)
    if not rows then return cb(0, {}) end

    local total = 0
    local top5  = {}
    for i, row in ipairs(rows) do
        total = total + (row.seconds or 0)
        if i <= 5 then
            local h, m = formatPlaytime(row.seconds)
            table.insert(top5, { name = row.name, hours = h, minutes = m })
        end
    end
    cb(total, top5)
end

-- ──────────────────────────────────────────────────────
-- Treasury helpers
-- ──────────────────────────────────────────────────────
local function getTreasuryBalance(gang_id)
    if treasuryBalanceCache[gang_id] ~= nil then
        return treasuryBalanceCache[gang_id]
    end
    local bal = dbGetTreasuryBalance(gang_id)
    treasuryBalanceCache[gang_id] = bal
    return bal
end

local function setTreasuryBalance(gang_id, amount)
    dbSetTreasuryBalance(gang_id, amount)
    treasuryBalanceCache[gang_id] = amount
end

local function getDirtyBalance(gang_id)
    if dirtyTreasuryCache[gang_id] ~= nil then
        return dirtyTreasuryCache[gang_id]
    end
    local bal = dbGetDirtyBalance(gang_id)
    dirtyTreasuryCache[gang_id] = bal
    return bal
end

local function setDirtyBalance(gang_id, amount)
    dbSetDirtyBalance(gang_id, amount)
    dirtyTreasuryCache[gang_id] = amount
end

local function addTreasuryLog(gang_id, logType, amount, byName, byCid, note)
    -- السجل في الكاش فقط — لا كتابة DB
    if not treasuryLogCache[gang_id] then treasuryLogCache[gang_id] = {} end
    if treasuryLogCache[gang_id] then
        local entry = {
            id         = 0,
            type       = logType,
            amount     = amount,
            by_name    = byName,
            by_cid     = byCid or 0,
            note       = note or "",
            created_at = os.date("%Y-%m-%d %H:%M")
        }
        table.insert(treasuryLogCache[gang_id], 1, entry)
        -- احتفظ بآخر 5 فقط
        while #treasuryLogCache[gang_id] > 5 do
            table.remove(treasuryLogCache[gang_id])
        end
    end
end

local function getTreasuryLog(gang_id)
    if not treasuryLogCache[gang_id] then
        treasuryLogCache[gang_id] = {}
    end
    return treasuryLogCache[gang_id]
end

local function addDirtyLog(gang_id, logType, amount, byName, byCid, note)
    if not dirtyLogCache[gang_id] then dirtyLogCache[gang_id] = {} end
    local entry = {
        type       = logType,
        amount     = amount,
        by_name    = byName,
        by_cid     = byCid or 0,
        note       = note or "",
        created_at = os.date("%Y-%m-%d %H:%M")
    }
    table.insert(dirtyLogCache[gang_id], 1, entry)
    while #dirtyLogCache[gang_id] > 5 do
        table.remove(dirtyLogCache[gang_id])
    end
end

local function getDirtyLog(gang_id)
    if not dirtyLogCache[gang_id] then dirtyLogCache[gang_id] = {} end
    return dirtyLogCache[gang_id]
end

local function openGangMenuForPlayer(src, uid, silentNoPerm)
    if not src then return false end
    uid = uid or getUserId(src)
    if not uid then return false end

    -- طبّق تغييرات الصلاحيات فوراً (حتى لو تغيّرت خارج هذا السكربت).
    managedGangsCache[uid] = nil
    clearPermissionCacheForUser(uid)

    -- كتابة وقت التواجد المتراكم بشكل مُخفف لتجنب spike عند فتح القائمة المتكرر.
    local nowTs = os.time()
    local nextFlushAt = tonumber(playtimeFlushNextAtByUid[uid]) or 0
    if nowTs >= nextFlushAt then
        playtimeFlushNextAtByUid[uid] = nowTs + 180
        flushPlaytimeForUid(uid)
    end

    markActiveMemberViewer(src, nil)

    local managed = getManagedGangs(uid)
    if #managed == 0 then
        if not silentNoPerm then
            TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "أنت لست مديراً لأي عصابة")
        end
        return false
    end

    TriggerClientEvent("gang:openMenu", src, { managed = managed })
    return true
end

local function openAdminPanelForPlayer(src, uid, silentNoPerm)
    if not src then return false end
    uid = uid or getUserId(src)
    if not uid then return false end

    -- تأكد من أن صلاحية الأدمن محدثة بدون انتظار TTL.
    clearPermissionCacheForUser(uid)

    if not hasAdminPerm(uid, "open_panel") then
        if not silentNoPerm then
            TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "ليس لديك صلاحية فتح لوحة المسؤول")
        end
        return false
    end

    local canViewAllTreasury = hasAdminPerm(uid, "view_all_treasury")
    local canTreasureControl = hasAdminPerm(uid, "treasure_control")
    local statsSnapshot = getGangStatsSnapshot(false)

    local gangs = {}
    local _adminGangIdx = 0
    for gang_id, gang in pairs(Config.Gangs) do
        _adminGangIdx = _adminGangIdx + 1
        local s = statsSnapshot[gang_id] or {}
        local memberCount = tonumber(s.members) or 0
        local onlineCount = tonumber(s.online) or 0
        local points       = tonumber(s.points) or 0
        local totalSeconds = tonumber(s.total_seconds) or 0
        local ph, pm       = formatPlaytime(totalSeconds)
        local warningCount = tonumber(s.warning_count) or 0
        local gangEntry = {
            id            = gang_id,
            label         = gang.label,
            color         = gang.color,
            logo          = gang.logo,
            ranks         = gang.ranks,
            weapons       = gang.weapons or {},
            members       = memberCount,
            online        = onlineCount,
            points        = points,
            playtime_h    = ph,
            playtime_m    = pm,
            warning_count = warningCount,
        }

        if canViewAllTreasury then
            gangEntry.treasury = getTreasuryBalance(gang_id)
        end

        if canTreasureControl then
            gangEntry.treasure_count = dbGetTreasureBalance(gang_id)
        end

        table.insert(gangs, gangEntry)
        if (_adminGangIdx % 3) == 0 then Wait(0) end
    end

    local allWeapons = {}
    local weaponsSeen = {}
    for _, gang in pairs(Config.Gangs) do
        for _, w in ipairs(gang.weapons or {}) do
            if not weaponsSeen[w.weapon] then
                weaponsSeen[w.weapon] = true
                table.insert(allWeapons, w)
            end
        end
    end

    TriggerClientEvent("admin:openPanel", src, {
        gangs   = gangs,
        perms   = buildAdminPermTable(uid),
        weapons = allWeapons,
    })

    return true
end

-- ──────────────────────────────────────────────────────
-- ربط فتح القوائم داخل vRP GUI (الجوال)
-- ──────────────────────────────────────────────────────
do
    local function menuBuilderCallback(add, data)
        local user_id = vRP.getUserId({ data.player })
        if user_id == nil then return end

        local choices = {}

        local canOpenGangMenu = false
        for _, gang in pairs(Config.Gangs or {}) do
            for _, perm in pairs(gang.permissions or {}) do
                local p = tostring(perm or "")
                if p ~= "" and vRP.hasPermission({ user_id, p }) then
                    canOpenGangMenu = true
                    break
                end
            end
            if canOpenGangMenu then break end
        end

        if canOpenGangMenu then
            choices["ادارة العصابة"] = {
                function(player, choice)
                    openGangMenuForPlayer(player, getUserId(player), false)
                end,
                "فتح قائمة ادارة العصابة"
            }
        end

        if Config.AdminPanel and Config.AdminPanel.permissions and Config.AdminPanel.permissions.open_panel
            and vRP.hasPermission({ user_id, Config.AdminPanel.permissions.open_panel }) then
            choices["لوحة Gang Manager"] = {
                function(player, choice)
                    openAdminPanelForPlayer(player, getUserId(player), false)
                end,
                "فتح لوحة Gang Manager"
            }
        end

        add(choices)
    end

    local function tryRegisterMobileMenu()
        if type(vRP) ~= "table" then return false end
        local ok, err = pcall(vRP.registerMenuBuilder, {"main", menuBuilderCallback})
        return ok
    end

    -- محاولة فورية
    if not tryRegisterMobileMenu() then
        -- إعادة المحاولة بعد تأخير (بعض إصدارات vRP تحتاج وقت لتحميل الـ Proxy)
        Citizen.CreateThread(function()
            Citizen.Wait(2000)
            if not tryRegisterMobileMenu() then
                Citizen.Wait(5000)
                if not tryRegisterMobileMenu() then
                    print("^3[ahmad_gangs]^7 vRP.registerMenuBuilder غير متوفر — تخطّي ربط خيارات الجوال")
                end
            end
        end)
    end
end

-- ──────────────────────────────────────────────────────
-- Event: طلب فتح القائمة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:requestMenu")
AddEventHandler("gang:requestMenu", function()
    local src = source
    if not checkRate(src, "requestMenu", 2000) then return end

    openGangMenuForPlayer(src, getUserId(src), false)
end)

-- ──────────────────────────────────────────────────────
-- Event: تحديد عصابة والحصول على بياناتها
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:selectGang")
AddEventHandler("gang:selectGang", function(gang_id)
    local src = source
    if not checkRate(src, "selectGang", 1000) then return end

    local uid  = getUserId(src)
    if not uid then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    -- تحقق أن اللاعب يملك أي permission في هذه العصابة
    if not hasAnyGangPermission(uid, gang) then return end

    markActiveMemberViewer(src, gang_id)

    local perms = buildPermTable(uid, gang_id)
    Wait(0)
    local statsSnapshot = getGangStatsSnapshot(false)
    local gangStats = statsSnapshot[gang_id] or {}
    Wait(0)
    local _warnings = dbGetWarnings(gang_id)

    -- أرسل بيانات العصابة مباشرة (بدون buildDashboard — العميل يبني الإحصاء من قائمة الأعضاء)
    TriggerClientEvent("gang:gangData", src, {
        gang_id  = gang_id,
        label    = gang.label,
        color    = gang.color,
        logo     = gang.logo,
        ranks    = gang.ranks,
        weapons  = gang.weapons or {},
        perms    = perms,
        warnings = _warnings,
        total_seconds = tonumber(gangStats.total_seconds) or 0,
    })
end)

RegisterNetEvent("gang:menuClosed")
AddEventHandler("gang:menuClosed", function()
    markActiveMemberViewer(source, nil)
end)

-- ──────────────────────────────────────────────────────
-- Event: جلب قائمة الأعضاء
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getMembers")
AddEventHandler("gang:getMembers", function(gang_id, filter)
    local src = source
    if not checkRate(src, "getMembers:" .. tostring(gang_id), 1500) then return end

    local uid = getUserId(src)
    if not uid then return end

    markActiveMemberViewer(src, gang_id)
    if not hasPerm(uid, gang_id, "view_" .. (filter == "online" and "online" or filter == "offline" and "offline" or "all")) then
        -- fallback: at least one view perm
        if not hasPerm(uid, gang_id, "view_all") and
           not hasPerm(uid, gang_id, "view_online") and
           not hasPerm(uid, gang_id, "view_offline") then
            return
        end
    end

    -- reconcile محدود التكرار (6ث) — لا يستخدم ثريد، الكاش يجعله خفيفاً
    reconcileGangMembersThrottled(gang_id, false, false)

    buildMemberList(gang_id, filter or "all", function(list)
        local statsSnapshot = getGangStatsSnapshot(false)
        local gangStats = statsSnapshot[gang_id] or {}
        TriggerClientEvent("gang:membersData", src, list, tonumber(gangStats.total_seconds) or 0)
    end)
end)

-- ──────────────────────────────────────────────────────
-- Event: ترقية عضو من كرت القائمة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:promoteMember")
AddEventHandler("gang:promoteMember", function(gang_id, target_cid)
    local src = source
    if not checkRate(src, "promoteMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "promote_member") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local row = dbGetMember(target_cid, gang_id)
    if not row then TriggerClientEvent("gang:notify", src, "error", "خطأ", "العضو غير موجود"); return end

    local currentIdx = nil
    for i, r in ipairs(gang.ranks) do
        if r.code == row.rank_code then currentIdx = i; break end
    end

    if not currentIdx or currentIdx <= 1 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا العضو يمتلك أعلى رتبة مسموحة"); return
    end

    local newRank = gang.ranks[currentIdx - 1]
    local targetUid = tonumber(target_cid)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "User ID غير صحيح"); return
    end

    setUserGangRank(targetUid, gang_id, newRank.code)

    dbUpsertMember(target_cid, gang_id, newRank.code, row.name, row.discord_id)
    dbEnsurePlaytime(target_cid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    local managerName = getUserName(uid)
    local memberName  = (not isBadDisplayName(row.name or "")) and row.name or tostring(target_cid)

    webhookLog(gang_id, "ترقية عضو",
        ("**المدير:** %s [%d]\n**العضو:** %s [CID:%s]\n**الرتبة الجديدة:** %s"):format(managerName, uid, memberName, tostring(target_cid), newRank.label),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تمت الترقية", memberName .. " ← " .. newRank.label)
end)

-- ──────────────────────────────────────────────────────
-- Event: تنزيل عضو
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:demoteMember")
AddEventHandler("gang:demoteMember", function(gang_id, target_cid)
    local src = source
    if not checkRate(src, "demoteMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "demote_member") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local row = dbGetMember(target_cid, gang_id)
    if not row then TriggerClientEvent("gang:notify", src, "error", "خطأ", "العضو غير موجود"); return end

    local currentIdx = nil
    for i, r in ipairs(gang.ranks) do
        if r.code == row.rank_code then currentIdx = i; break end
    end

    if not currentIdx or currentIdx >= #gang.ranks then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا العضو يمتلك أدنى رتبة"); return
    end

    local newRank = gang.ranks[currentIdx + 1]
    local targetUid = tonumber(target_cid)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "User ID غير صحيح"); return
    end

    setUserGangRank(targetUid, gang_id, newRank.code)

    dbUpsertMember(target_cid, gang_id, newRank.code, row.name, row.discord_id)
    dbEnsurePlaytime(target_cid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    webhookLog(gang_id, "تنزيل عضو",
        ("**المدير:** %s [%d]\n**العضو:** %s [CID:%s]\n**الرتبة الجديدة:** %s"):format(getUserName(uid), uid, row.name or tostring(target_cid), tostring(target_cid), newRank.label),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تم التنزيل", (row.name or tostring(target_cid)) .. " ← " .. newRank.label)
end)

-- ──────────────────────────────────────────────────────
-- Event: فصل عضو من كرت القائمة (يعمل offline)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:fireMember")
AddEventHandler("gang:fireMember", function(gang_id, target_cid)
    local src = source
    if not checkRate(src, "fireMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "fire_member") then return end

    local row = dbGetMember(target_cid, gang_id)
    if not row then TriggerClientEvent("gang:notify", src, "error", "خطأ", "العضو غير موجود"); return end

    local targetUid = tonumber(target_cid)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "User ID غير صحيح"); return
    end

    clearUserGangRanks(targetUid, gang_id)

    dbDeleteMember(target_cid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    local gang = Config.Gangs[gang_id]
    webhookLog(gang_id, "فصل عضو",
        ("**المدير:** %s [%d]\n**العضو:** %s [CID:%s]"):format(getUserName(uid), uid, row.name or tostring(target_cid), tostring(target_cid)),
        gang and gang.color or "#4d7fff")

    TriggerClientEvent("gang:notify", src, "success", "تم الفصل", row.name or tostring(target_cid))
end)

-- ──────────────────────────────────────────────────────
-- Event: سحب لاعب واحد (تيليبورت)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:pullMember")
AddEventHandler("gang:pullMember", function(gang_id, target_user_id)
    local src    = source
    if not checkRate(src, "pullMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "pull_member") then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end

    local targetSrc = getOnlineSourceByUserId(targetUid)
    if not targetSrc then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "اللاعب غير متصل"); return
    end

    local memberRow = dbGetMember(targetUid, gang_id)
    if not memberRow then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "اللاعب ليس عضواً في العصابة"); return
    end

    local pullCoords = getSourceCoordsSafe(src)
    if not pullCoords then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر تحديد موقعك الحالي"); return
    end

    TriggerClientEvent("gang:pullTo", targetSrc, pullCoords)
    webhookLog(gang_id, "سحب عضو",
        ("‫**المدير:** %s [%d]\n**العضو:** %s [%d]‬"):format(getUserName(uid), uid, getUserName(targetUid), targetUid),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#4d7fff")
    TriggerClientEvent("gang:notify", src, "success", "تم السحب", "تم سحب العضو بنجاح")
end)

-- ──────────────────────────────────────────────────────
-- Event: إعطاء سلاح لعضو واحد
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:giveWeaponMember")
AddEventHandler("gang:giveWeaponMember", function(gang_id, target_user_id, weapon, ammo)
    local src = source
    if not checkRate(src, "giveWeaponMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "give_weapon_member") then return end

    -- تحقق أن السلاح موجود في كونفق العصابة
    local gang = Config.Gangs[gang_id]
    local validWeapon = false
    for _, w in ipairs(gang and gang.weapons or {}) do
        if w.weapon == weapon then validWeapon = true; break end
    end
    if not validWeapon then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end

    local targetSrc = getOnlineSourceByUserId(targetUid)
    if not targetSrc then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "اللاعب غير متصل"); return
    end

    local safeAmmo = math.max(0, math.min(10000, math.floor(tonumber(ammo) or 0)))
    TriggerClientEvent("gang:receiveWeapon", targetSrc, weapon, safeAmmo)
    webhookLog(gang_id, "إعطاء سلاح لعضو",
        ("‫**المدير:** %s [%d]\n**العضو:** %s [%d]\n**السلاح:** %s‬"):format(getUserName(uid), uid, getUserName(targetUid), targetUid, weapon),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#4d7fff")
    TriggerClientEvent("gang:notify", src, "success", "تم الإعطاء", "تم إعطاء السلاح بنجاح")
end)

-- ──────────────────────────────────────────────────────
-- Event: استعلام عن لاعب (التوظيف)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:queryPlayer")
AddEventHandler("gang:queryPlayer", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "queryPlayer", 1500) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "query_player") then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end

    if not userIdExistsInDB(targetUid) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "هذا User ID غير موجود في قاعدة البيانات"); return
    end
    Wait(0)

    local targetSrc = getOnlineSourceByUserId(targetUid)
    local targetCid    = getCid(targetUid)
    local targetName   = getUserName(targetUid)
    Wait(0)
    local memberRow    = dbGetMember(targetCid, gang_id)

    if isBadDisplayName(targetName) then
        local fallbackName = normalizeText((memberRow and memberRow.name) or dbGetAnyKnownName(targetCid) or "")
        targetName = isBadDisplayName(fallbackName) and ("ID: " .. tostring(targetUid)) or fallbackName
    end

    local targetDisc = ""
    if targetSrc then
        targetDisc = getDiscordFromSource(targetSrc)
    elseif memberRow and (memberRow.discord_id or "") ~= "" then
        targetDisc = memberRow.discord_id
    end

    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    if liveRank and (not memberRow or memberRow.rank_code ~= liveRank) then
        dbUpsertMember(targetCid, gang_id, liveRank, targetName, targetDisc)
        dbEnsurePlaytime(targetCid, gang_id)
        invalidateGangCache(gang_id)
        memberRow = dbGetMember(targetCid, gang_id)
    elseif not liveRank and memberRow and targetSrc then
        dbDeleteMember(targetCid, gang_id)
        invalidateGangCache(gang_id)
        memberRow = nil
    end

    -- هل هو عضو في هذه العصابة؟
    local memberRank = liveRank or (memberRow and memberRow.rank_code or nil)
    local gang      = Config.Gangs[gang_id]
    local rankLabel = "ليس عضواً"
    local rankCode  = nil
    if memberRank then
        rankCode = memberRank
        for _, r in ipairs(gang.ranks) do
            if r.code == rankCode then rankLabel = r.label; break end
        end
    end

    -- ساعات تواجده
    local h, m  = formatPlaytime(dbGetPlaytimeSeconds(targetCid, gang_id))

    local baseAvatar = DEFAULT_AVATAR
    if memberRow and normalizeText(memberRow.last_avatar) ~= "" then
        baseAvatar = memberRow.last_avatar
    end

    local emitResult = function(avatarUrl)
        TriggerClientEvent("gang:queryResult", src, {
            user_id    = targetUid,
            cid        = targetCid,
            name       = targetName,
            avatar     = (avatarUrl and avatarUrl ~= "") and avatarUrl or baseAvatar,
            rank_label = rankLabel,
            rank_code  = rankCode,
            hours      = h,
            minutes    = m,
            is_member  = memberRank ~= nil,
        })
    end

    if targetDisc ~= "" then
        fetchDiscordAvatar(targetDisc, function(avatarUrl)
            emitResult(avatarUrl or baseAvatar)
        end)
    else
        emitResult(baseAvatar)
    end
end)

-- ──────────────────────────────────────────────────────
-- Event: توظيف لاعب
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:hirePlayer")
AddEventHandler("gang:hirePlayer", function(gang_id, target_user_id, rank_code)
    local src = source
    if not checkRate(src, "hirePlayer", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "hire_player") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    -- تحقق أن الرتبة موجودة في الكونفق
    local rankLabel = nil
    for _, r in ipairs(gang.ranks) do
        if r.code == rank_code then rankLabel = r.label; break end
    end
    if not rankLabel then TriggerClientEvent("gang:notify", src, "error", "خطأ", "رتبة غير صحيحة"); return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end

    if not userIdExistsInDB(targetUid) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "هذا User ID غير موجود في قاعدة البيانات"); return
    end
    Wait(0)

    local targetCid  = getCid(targetUid)
    local targetSrc  = getOnlineSourceByUserId(targetUid)
    local targetName = getUserName(targetUid)
    Wait(0)
    local targetDisc = targetSrc and getDiscordFromSource(targetSrc) or ""

    local existing = getMemberRank(targetCid, gang_id)
    Wait(0)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    local currentRank = liveRank or existing

    if currentRank and currentRank == rank_code then
        dbUpsertMember(targetCid, gang_id, rank_code, targetName, targetDisc)
        dbEnsurePlaytime(targetCid, gang_id)
        invalidateGangCache(gang_id)
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "اللاعب عضو مسبقاً وتمت مزامنة بياناته")
        return
    end

    setUserGangRank(targetUid, gang_id, rank_code)

    dbUpsertMember(targetCid, gang_id, rank_code, targetName, targetDisc)
    dbEnsurePlaytime(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    webhookLog(gang_id, "تعيين عضو جديد",
        ("**المدير:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة:** %s"):format(getUserName(uid), uid, targetName, targetUid, rankLabel),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تم التوظيف", targetName .. " ← " .. rankLabel)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "success", "مبروك!", "تم تعيينك في " .. gang.label .. " كـ " .. rankLabel)
    end
end)

-- ──────────────────────────────────────────────────────
-- Event: فصل لاعب (التوظيف — يتطلب user_id)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:firePlayer")
AddEventHandler("gang:firePlayer", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "firePlayer", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "fire_player") then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    Wait(0)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    if not row and not liveRank then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً"); return end

    clearUserGangRanks(targetUid, gang_id)
    dbDeleteMember(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)
    Wait(0)

    local targetSrc = getOnlineSourceByUserId(targetUid)
    local firedName = (row and row.name) or getUserName(targetUid) or tostring(targetCid)

    local gang = Config.Gangs[gang_id]
    webhookLog(gang_id, "فصل عضو",
        ("**المدير:** %s [%d]\n**العضو:** %s [%d]"):format(getUserName(uid), uid, firedName, targetUid),
        gang and gang.color or "#4d7fff")

    TriggerClientEvent("gang:notify", src, "success", "تم الفصل", firedName)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "error", "إشعار", "تم فصلك من " .. (gang and gang.label or gang_id))
    end
end)

-- ──────────────────────────────────────────────────────
-- Event: رسالة لجميع الأعضاء
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:messageAll")
AddEventHandler("gang:messageAll", function(gang_id, message)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "messageAll", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "message_all") then return end

    message = tostring(message or ""):sub(1, 200)
    if message == "" then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "الرسالة فارغة"); return end

    local gang       = Config.Gangs[gang_id]
    local senderName = getUserName(uid)
    Wait(0)

    -- أرسل للأعضاء المتصلين فقط — onlineCidMap بدل GetPlayers+getUserId loop
    local rows = dbGetGangMemberCids(gang_id)
    local sent = 0
    for _, row in ipairs(rows) do
        local cid = tonumber(row and row.citizen_id)
        local info = cid and onlineCidMap[cid] or nil
        if info and info.src then
            TriggerClientEvent("gang:broadcast", info.src, {
                gangName   = gang.label,
                gangImage  = gang.logo,
                gangColor  = gang.color,
                message    = message,
                senderName = senderName,
            })
            sent = sent + 1
            if (sent % 60) == 0 then
                Wait(0)
            end
        end
    end

    webhookLog(gang_id, "رسالة للأعضاء",
        ("**المدير:** %s [%d]\n**الرسالة:** %s"):format(senderName, uid, message), gang.color)

    perfDone("event:gang:messageAll", tPerf, "sent=" .. tostring(sent))
    TriggerClientEvent("gang:notify", src, "success", "تم الإرسال", "تم إرسال الرسالة للأعضاء")
end)

-- ──────────────────────────────────────────────────────
-- Event: سحب جميع الأعضاء
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:pullAll")
AddEventHandler("gang:pullAll", function(gang_id)
    local src = source
    if not checkRate(src, "pullAll", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "pull_all") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local pullCoords = getSourceCoordsSafe(src)
    if not pullCoords then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر تحديد موقعك الحالي"); return
    end

    local targets = getOnlineGangPullTargets(gang_id, src)
    local count = pullTargetsToCoords(targets, pullCoords)

    webhookLog(gang_id, "سحب جميع الأعضاء",
        ("‫**المدير:** %s [%d]\n**العدد المسحوب:** %d‬"):format(getUserName(uid), uid, count),
        gang.color or "#4d7fff")
    TriggerClientEvent("gang:notify", src, "success", "تم السحب", "تم سحب " .. count .. " عضو")
end)

-- ──────────────────────────────────────────────────────
-- Event: عتاد للجميع
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:giveWeaponAll")
AddEventHandler("gang:giveWeaponAll", function(gang_id, weapon, ammo)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "giveWeaponAll", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "give_weapon_all") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local validWeapon = false
    for _, w in ipairs(gang.weapons or {}) do
        if w.weapon == weapon then
            validWeapon = true
            ammo = math.max(0, math.min(10000, math.floor(tonumber(ammo) or tonumber(w.ammo) or 0)))
            break
        end
    end
    if not validWeapon then return end

    -- onlineCidMap بدل GetPlayers+getUserId loop
    local rows = dbGetGangMemberCids(gang_id)
    local count = 0
    for _, row in ipairs(rows) do
        local cid = tonumber(row and row.citizen_id)
        local info = cid and onlineCidMap[cid] or nil
        if info and info.src then
            TriggerClientEvent("gang:receiveWeapon", info.src, weapon, ammo)
            count = count + 1
            if (count % 60) == 0 then
                Wait(0)
            end
        end
    end

    webhookLog(gang_id, "توزيع عتاد على الجميع",
        ("‫**المدير:** %s [%d]\n**السلاح:** %s\n**العدد:** %d عضو‬"):format(getUserName(uid), uid, weapon, count),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#4d7fff")
    perfDone("event:gang:giveWeaponAll", tPerf, "sent=" .. tostring(count))
    TriggerClientEvent("gang:notify", src, "success", "تم الإعطاء", "تم توزيع السلاح على " .. count .. " عضو")
end)

-- ──────────────────────────────────────────────────────
-- Event: التصنيف — جلب ترتيب جميع العصابات (للأعضاء)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getRanking")
AddEventHandler("gang:getRanking", function(gang_id)
    local src = source
    if not checkRate(src, "gangGetRanking", 3000) then return end

    local uid = getUserId(src)
    if not uid then return end

    -- تحقق إن اللاعب فعلاً يدير هذه العصابة
    local gang = Config.Gangs[gang_id]
    if not gang then return end
    if not hasAnyGangPermission(uid, gang) then return end

    -- كاش 60 ثانية — يمنع N*3 DB queries في كل طلب
    local _now = os.time()
    if not rankingCache.data or _now >= rankingCache.expires then
        local statsSnapshot = getGangStatsSnapshot(false)
        local base = {}
        for gid, g in pairs(Config.Gangs) do
            local s = statsSnapshot[gid] or {}
            local pts  = tonumber(s.points) or 0
            local secs = tonumber(s.total_seconds) or 0
            local h, m = formatPlaytime(secs)
            table.insert(base, {
                id         = gid,
                label      = g.label,
                color      = g.color,
                logo       = g.logo,
                points     = pts,
                playtime_h = h,
                playtime_m = m,
                seconds    = secs,
                members    = tonumber(s.members) or 0,
            })
        end
        table.sort(base, function(a, b)
            if a.points ~= b.points then return a.points > b.points end
            return (a.seconds or 0) > (b.seconds or 0)
        end)
        rankingCache.data    = base
        rankingCache.expires = _now + 60
    end

    -- أضف is_self حسب عصابة الطالب
    local list = {}
    for _, entry in ipairs(rankingCache.data) do
        local e = {}
        for k, v in pairs(entry) do e[k] = v end
        e.is_self = (e.id == gang_id)
        table.insert(list, e)
    end

    TriggerClientEvent("gang:rankingData", src, list)
end)

-- ──────────────────────────────────────────────────────
-- Event: الخزنة — جلب البيانات
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getTreasury")
AddEventHandler("gang:getTreasury", function(gang_id)
    local src = source
    if not checkRate(src, "getTreasury", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "treasury_view") then return end

    local balance       = getTreasuryBalance(gang_id)
    Wait(0)
    local dirty_balance = getDirtyBalance(gang_id)
    local log           = hasPerm(uid, gang_id, "treasury_log") and getTreasuryLog(gang_id) or {}
    local dirty_log     = hasPerm(uid, gang_id, "dirty_view") and getDirtyLog(gang_id) or {}

    TriggerClientEvent("gang:treasuryData", src, { balance = balance, dirty_balance = dirty_balance, log = log, dirty_log = dirty_log })
end)

-- ──────────────────────────────────────────────────────
-- Event: الخزنة — إيداع
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:treasuryDeposit")
AddEventHandler("gang:treasuryDeposit", function(gang_id, amount)
    local src = source
    if not checkRate(src, "treasuryDeposit", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "treasury_deposit") then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "مبلغ غير صحيح"); return end

    local wallet = getWallet(uid)
    local bank   = getBankMoney(uid)
    Wait(0)
    if wallet + bank < amount then
        TriggerClientEvent("gang:notify", src, "error", "خطأ",
            "رصيد غير كافٍ (محفظة: " .. wallet .. "$ | بنك: " .. bank .. "$)"); return
    end

    -- vRP.tryFullPayment يسحب من المحفظة أولاً ثم البنك (بدون tryBankPayment)
    if not deductWallet(uid, amount) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر خصم المبلغ، حاول مرة أخرى"); return
    end
    Wait(0)

    local newBalance = getTreasuryBalance(gang_id) + amount
    setTreasuryBalance(gang_id, newBalance)
    addTreasuryLog(gang_id, "deposit", amount, getUserName(uid), getCid(uid), "إيداع")

    webhookLog(gang_id, "إيداع في الخزنة",
        ("**المدير:** %s [%d]\n**المبلغ:** %d$\n**الرصيد الجديد:** %d$"):format(getUserName(uid), uid, amount, newBalance),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#4d7fff")

    TriggerClientEvent("gang:treasuryData", src, { balance = newBalance, dirty_balance = getDirtyBalance(gang_id), log = getTreasuryLog(gang_id), dirty_log = getDirtyLog(gang_id) })
    TriggerClientEvent("gang:notify", src, "success", "إيداع ناجح", "تم إيداع " .. amount .. "$ في الخزنة")
end)

-- ──────────────────────────────────────────────────────
-- Event: الخزنة — سحب
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:treasuryWithdraw")
AddEventHandler("gang:treasuryWithdraw", function(gang_id, amount)
    local src = source
    if not checkRate(src, "treasuryWithdraw", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasPerm(uid, gang_id, "treasury_withdraw") then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "مبلغ غير صحيح"); return end

    local balance = getTreasuryBalance(gang_id)
    if balance < amount then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "رصيد الخزنة غير كافٍ (" .. balance .. "$)"); return
    end

    creditWallet(uid, amount)

    local newBalance = balance - amount
    setTreasuryBalance(gang_id, newBalance)
    addTreasuryLog(gang_id, "withdraw", amount, getUserName(uid), getCid(uid), "سحب")

    webhookLog(gang_id, "سحب من الخزنة",
        ("**المدير:** %s [%d]\n**المبلغ:** %d$\n**الرصيد الجديد:** %d$"):format(getUserName(uid), uid, amount, newBalance),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#4d7fff")

    TriggerClientEvent("gang:treasuryData", src, { balance = newBalance, dirty_balance = getDirtyBalance(gang_id), log = getTreasuryLog(gang_id) })
    TriggerClientEvent("gang:notify", src, "success", "سحب ناجح", "تم سحب " .. amount .. "$ من الخزنة")
end)

-- ──────────────────────────────────────────────────────
-- Event: الخزنة — سحب الأموال القذرة (إيرادات المتجر)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:withdrawDirty")
AddEventHandler("gang:withdrawDirty", function(gang_id, amount)
    local src = source
    if not checkRate(src, "withdrawDirty", 2000) then return end

    local uid = getUserId(src)
    if not uid or not (hasPerm(uid, gang_id, "dirty_withdraw") or hasPerm(uid, gang_id, "treasury_withdraw")) then return end

    local dirty = getDirtyBalance(gang_id)
    amount = (amount == "all") and dirty or math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "مبلغ غير صحيح")
        return
    end
    if dirty < amount then
        TriggerClientEvent("gang:notify", src, "error", "خطأ",
            "الأموال القذرة غير كافية — الرصيد: " .. dirty .. "$")
        return
    end

    if not giveInventoryItemSafe(uid, "dirty_money", amount) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ",
            "تعذر منح الأموال القذرة — المخزون ممتلئ أو غير متوفر")
        return
    end

    local newDirty = dirty - amount
    setDirtyBalance(gang_id, newDirty)

    webhookLog(gang_id, "سحب أموال قذرة من المتجر",
        ("**المدير:** %s [%d]\n**المبلغ:** %d$\n**المتبقي:** %d$"):format(
            getUserName(uid), uid, amount, newDirty),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color or "#e0b800")

    TriggerClientEvent("gang:treasuryData", src, {
        balance       = getTreasuryBalance(gang_id),
        dirty_balance = newDirty,
        log           = getTreasuryLog(gang_id),
    })
    TriggerClientEvent("gang:notify", src, "success", "تم السحب",
        ("استلمت %d$ كأموال قذرة"):format(amount))
end)

-- ════════════════════════════════════════════════════════
--  Admin Panel Events
-- ════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────
-- Admin: فتح اللوحة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:requestPanel")
AddEventHandler("admin:requestPanel", function()
    local src = source
    if not checkRate(src, "adminRequestPanel", 2000) then return end

    openAdminPanelForPlayer(src, getUserId(src), false)
end)

-- ──────────────────────────────────────────────────────
-- Admin: رسالة لجميع العصابات
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:messageAllGangs")
AddEventHandler("admin:messageAllGangs", function(message, targetGangId)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "adminMessageAllGangs", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "message_all_gangs") then return end

    message = sanitizeInputText(message, 300)
    if message == "" then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "الرسالة فارغة"); return end
    if targetGangId and targetGangId ~= "" and not Config.Gangs[targetGangId] then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "العصابة المحددة غير موجودة")
        return
    end

    local senderName = getUserName(uid)
    local totalSent  = 0
    local sentSrc = {}
    local sentBatch = 0
    for gang_id, gang in pairs(Config.Gangs) do
        if not targetGangId or targetGangId == "" or targetGangId == gang_id then
            for _, tSrc in ipairs(getOnlineGangMemberSources(gang_id)) do
                if not sentSrc[tSrc] then
                    sentSrc[tSrc] = true
                    TriggerClientEvent("gang:broadcast", tSrc, {
                        gangName   = "Gang Manager",
                        gangImage  = "",
                        gangColor  = "#e74c3c",
                        message    = message,
                        senderName = senderName,
                    })
                    totalSent = totalSent + 1
                    sentBatch = sentBatch + 1
                    if (sentBatch % 60) == 0 then
                        Wait(0)
                    end
                end
            end
        end
    end
    adminWebhookLog("رسالة لجميع العصابات",
        ("‫**المسؤول:** %s [%d]\n**الرسالة:** %s\n**المستلمون:** %d لاعب‬"):format(senderName, uid, message, totalSent))
    perfDone("event:admin:messageAllGangs", tPerf, "sent=" .. tostring(totalSent))
    TriggerClientEvent("gang:notify", src, "success", "تم الإرسال", "تم إرسال الرسالة لـ " .. totalSent .. " لاعب")
end)

-- ──────────────────────────────────────────────────────
-- Admin: جلب تحذيرات عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:getWarnings")
AddEventHandler("admin:getWarnings", function(gang_id)
    local src = source
    if not checkRate(src, "adminGetWarnings", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "add_warning") then return end

    local warnings = dbGetWarnings(gang_id)
    TriggerClientEvent("admin:warningsData", src, { gang_id = gang_id, warnings = warnings })
end)

-- ──────────────────────────────────────────────────────
-- Admin: إضافة تحذير
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:addWarning")
AddEventHandler("admin:addWarning", function(gang_id, title, reason, duration)
    local src = source
    if not checkRate(src, "adminAddWarning", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "add_warning") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    title  = sanitizeInputText(title or "تحذير", 64)
    reason = sanitizeInputText(reason or "", 256)
    if title == "" then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "عنوان التحذير فارغ"); return end

    local adminName = getUserName(uid)
    Wait(0)
    dbAddWarning(gang_id, title, reason, tonumber(duration) or 0, adminName)

    -- أشعر أعضاء العصابة المتصلين
    for _, tSrc in ipairs(getOnlineGangMemberSources(gang_id)) do
        TriggerClientEvent("gang:notify", tSrc, "error", "⚠ تحذير", "صدر تحذير جديد لعصابة " .. gang.label)
    end

    webhookLog(gang_id, "تحذير جديد",
        ("‫**المسؤول:** %s [%d]\n**العنوان:** %s\n**السبب:** %s‬"):format(adminName, uid, title, reason), gang.color)
    adminWebhookLog("تحذير جديد",
        ("‫**المسؤول:** %s [%d]\n**العنوان:** %s\n**السبب:** %s‬"):format(adminName, uid, title, reason), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم الإصدار", "صدر التحذير لعصابة " .. gang.label)
    local updated = dbGetWarnings(gang_id)
    TriggerClientEvent("admin:warningsData", src, { gang_id = gang_id, warnings = updated })
end)

-- ──────────────────────────────────────────────────────
-- Admin: حذف تحذير
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:removeWarning")
AddEventHandler("admin:removeWarning", function(gang_id, warning_id)
    local src = source
    if not checkRate(src, "adminRemoveWarning", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "remove_warning") then return end

    warning_id = tonumber(warning_id)
    if not warning_id then return end

    local gang = Config.Gangs[gang_id]
    dbRemoveWarning(warning_id)
    webhookLog(gang_id, "حذف تحذير",
        ("‫**المسؤول:** %s [%d]‬"):format(getUserName(uid), uid), gang and gang.color)
    adminWebhookLog("حذف تحذير",
        ("‫**المسؤول:** %s [%d]\n**رقم التحذير:** %d‬"):format(getUserName(uid), uid, warning_id), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم الحذف", "تم حذف التحذير بنجاح")
    local updated = dbGetWarnings(gang_id)
    TriggerClientEvent("admin:warningsData", src, { gang_id = gang_id, warnings = updated })
end)

-- ──────────────────────────────────────────────────────
-- Admin: جلب التصنيف
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:getRanking")
AddEventHandler("admin:getRanking", function()
    local src = source
    if not checkRate(src, "adminGetRanking", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "view_ranking") then return end

    local statsSnapshot = getGangStatsSnapshot(false)
    local ranking = {}
    for gang_id, gang in pairs(Config.Gangs) do
        local s = statsSnapshot[gang_id] or {}
        local points       = tonumber(s.points) or 0
        local totalSeconds = tonumber(s.total_seconds) or 0
        local h, m         = formatPlaytime(totalSeconds)
        local memberCount  = tonumber(s.members) or 0
        table.insert(ranking, {
            id         = gang_id,
            label      = gang.label,
            color      = gang.color,
            logo       = gang.logo,
            points     = points,
            playtime_h = h,
            playtime_m = m,
            seconds    = totalSeconds,
            members    = memberCount,
        })
    end
    table.sort(ranking, function(a, b)
        if a.points ~= b.points then return a.points > b.points end
        return (a.seconds or 0) > (b.seconds or 0)
    end)
    TriggerClientEvent("admin:rankingData", src, ranking)
end)

-- ──────────────────────────────────────────────────────
-- Admin: إضافة نقاط
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:addPoints")
AddEventHandler("admin:addPoints", function(gang_id, amount)
    local src = source
    if not checkRate(src, "adminAddPoints", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "add_points") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    amount = math.max(1, math.floor(tonumber(amount) or 0))
    local newPoints = dbGetPoints(gang_id) + amount
    dbSetPoints(gang_id, newPoints)
    invalidateRankingCache()
    webhookLog(gang_id, "إضافة نقاط",
        ("‫**المسؤول:** %s [%d]\n**النقاط المضافة:** +%d\n**الرصيد الجديد:** %d‬"):format(getUserName(uid), uid, amount, newPoints), gang.color)
    adminWebhookLog("إضافة نقاط",
        ("‫**المسؤول:** %s [%d]\n**+%d نقطة**\n**الرصيد:** %d‬"):format(getUserName(uid), uid, amount, newPoints), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم", "أضفت " .. amount .. " نقطة لـ " .. gang.label)
    TriggerClientEvent("admin:pointsUpdated", src, { gang_id = gang_id, points = newPoints })
end)

-- ──────────────────────────────────────────────────────
-- Admin: خصم نقاط
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:removePoints")
AddEventHandler("admin:removePoints", function(gang_id, amount)
    local src = source
    if not checkRate(src, "adminRemovePoints", 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "remove_points") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    amount = math.max(1, math.floor(tonumber(amount) or 0))
    local newPoints = math.max(0, dbGetPoints(gang_id) - amount)
    dbSetPoints(gang_id, newPoints)
    invalidateRankingCache()
    webhookLog(gang_id, "خصم نقاط",
        ("‫**المسؤول:** %s [%d]\n**النقاط المخصومة:** -%d\n**الرصيد الجديد:** %d‬"):format(getUserName(uid), uid, amount, newPoints), gang.color)
    adminWebhookLog("خصم نقاط",
        ("‫**المسؤول:** %s [%d]\n**-%d نقطة**\n**الرصيد:** %d‬"):format(getUserName(uid), uid, amount, newPoints), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم", "خُصمت " .. amount .. " نقطة من " .. gang.label)
    TriggerClientEvent("admin:pointsUpdated", src, { gang_id = gang_id, points = newPoints })
end)

-- ──────────────────────────────────────────────────────
-- Admin: تصفير تواجد عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:resetPlaytime")
AddEventHandler("admin:resetPlaytime", function(gang_id)
    local src = source
    if not checkRate(src, "adminResetPlaytime", 1500) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "reset_playtime") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    dbResetGangPlaytime(gang_id)
    invalidateGangCache(gang_id)
    invalidateRankingCache()

    webhookLog(gang_id, "تصفير التواجد",
        ("‫**المسؤول:** %s [%d]\n**الإجراء:** تصفير تواجد العصابة‬"):format(getUserName(uid), uid),
        gang.color)
    adminWebhookLog("تصفير تواجد عصابة",
        ("‫**المسؤول:** %s [%d]\n**الإجراء:** تصفير التواجد‬"):format(getUserName(uid), uid), gang_id)

    TriggerClientEvent("gang:notify", src, "success", "تم", "تم تصفير تواجد " .. gang.label)
    TriggerClientEvent("admin:playtimeReset", src, {
        gang_id = gang_id,
        seconds = 0,
        playtime_h = 0,
        playtime_m = 0,
    })
end)

-- ──────────────────────────────────────────────────────
-- Admin: جلب أعضاء عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:getGangMembers")
AddEventHandler("admin:getGangMembers", function(gang_id)
    local src = source
    if not checkRate(src, "adminGetGangMembers:" .. tostring(gang_id), 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "view_members") then return end
    if not Config.Gangs[gang_id] then return end

    -- reconcile محدود التكرار (6ث) — لا يستخدم ثريد
    reconcileGangMembersThrottled(gang_id, false, false)

    buildMemberList(gang_id, "all", function(list)
        TriggerClientEvent("admin:gangMembersData", src, { gang_id = gang_id, members = list })
    end)
end)

-- ──────────────────────────────────────────────────────
-- Admin: ترقية عضو من عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:promoteGangMember")
AddEventHandler("admin:promoteGangMember", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "adminPromoteGangMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not (hasAdminPerm(uid, "members_promote") or hasAdminPerm(uid, "hire_gang_admin")) then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح")
        return
    end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    local rankCode = liveRank or (row and row.rank_code or nil)
    if not rankCode then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً في العصابة")
        return
    end

    local currentIdx = nil
    for i, r in ipairs(gang.ranks or {}) do
        if r.code == rankCode then currentIdx = i; break end
    end
    if not currentIdx or currentIdx <= 1 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا العضو يمتلك أعلى رتبة مسموحة")
        return
    end

    local newRank = gang.ranks[currentIdx - 1]
    local targetName = getUserName(targetUid)
    local targetSrc = getOnlineSourceByUserId(targetUid)
    local targetDisc = targetSrc and getDiscordFromSource(targetSrc) or ""

    setUserGangRank(targetUid, gang_id, newRank.code)
    dbUpsertMember(targetCid, gang_id, newRank.code, targetName, targetDisc)
    dbEnsurePlaytime(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    webhookLog(gang_id, "ترقية عضو (مسؤول)",
        ("**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة الجديدة:** %s"):format(getUserName(uid), uid, targetName, targetUid, newRank.label),
        gang.color)
    adminWebhookLog("ترقية عضو",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة:** %s‬"):format(getUserName(uid), uid, targetName, targetUid, newRank.label), gang_id)

    TriggerClientEvent("gang:notify", src, "success", "تمت الترقية", targetName .. " ← " .. newRank.label)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "success", "ترقية", "تمت ترقيتك إلى " .. newRank.label)
    end
end)

-- ──────────────────────────────────────────────────────
-- Admin: تنزيل رتبة عضو من عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:demoteGangMember")
AddEventHandler("admin:demoteGangMember", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "adminDemoteGangMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not (hasAdminPerm(uid, "members_demote") or hasAdminPerm(uid, "hire_gang_admin")) then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح")
        return
    end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    local rankCode = liveRank or (row and row.rank_code or nil)
    if not rankCode then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً في العصابة")
        return
    end

    local currentIdx = nil
    for i, r in ipairs(gang.ranks or {}) do
        if r.code == rankCode then currentIdx = i; break end
    end
    if not currentIdx or currentIdx >= #gang.ranks then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا العضو يمتلك أدنى رتبة")
        return
    end

    local newRank = gang.ranks[currentIdx + 1]
    local targetName = getUserName(targetUid)
    local targetSrc = getOnlineSourceByUserId(targetUid)
    local targetDisc = targetSrc and getDiscordFromSource(targetSrc) or ""

    setUserGangRank(targetUid, gang_id, newRank.code)
    dbUpsertMember(targetCid, gang_id, newRank.code, targetName, targetDisc)
    dbEnsurePlaytime(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    webhookLog(gang_id, "تنزيل عضو (مسؤول)",
        ("**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة الجديدة:** %s"):format(getUserName(uid), uid, targetName, targetUid, newRank.label),
        gang.color)
    adminWebhookLog("تنزيل عضو",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة:** %s‬"):format(getUserName(uid), uid, targetName, targetUid, newRank.label), gang_id)

    TriggerClientEvent("gang:notify", src, "success", "تم التنزيل", targetName .. " ← " .. newRank.label)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "warning", "تنزيل رتبة", "تم تنزيل رتبتك إلى " .. newRank.label)
    end
end)

-- ──────────────────────────────────────────────────────
-- Admin: سحب عضو واحد من عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:pullGangMember")
AddEventHandler("admin:pullGangMember", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "adminPullGangMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not (hasAdminPerm(uid, "members_pull") or hasAdminPerm(uid, "pull_gang")) then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح")
        return
    end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    if not row and not liveRank then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً في العصابة")
        return
    end

    local targetSrc = getOnlineSourceByUserId(targetUid)
    if not targetSrc then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "اللاعب غير متصل")
        return
    end

    local pullCoords = getSourceCoordsSafe(src)
    if not pullCoords then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر تحديد موقعك الحالي")
        return
    end

    TriggerClientEvent("gang:pullTo", targetSrc, pullCoords)
    local targetName = getUserName(targetUid)
    webhookLog(gang_id, "سحب عضو (مسؤول)",
        ("**المسؤول:** %s [%d]\n**العضو:** %s [%d]"):format(getUserName(uid), uid, targetName, targetUid),
        gang.color)
    adminWebhookLog("سحب عضو",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]‬"):format(getUserName(uid), uid, targetName, targetUid), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم السحب", "تم سحب " .. targetName)
end)

-- ──────────────────────────────────────────────────────
-- Admin: إعطاء عتاد لعضو واحد من عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:giveWeaponGangMember")
AddEventHandler("admin:giveWeaponGangMember", function(gang_id, target_user_id, weapon, ammo)
    local src = source
    if not checkRate(src, "adminGiveWeaponGangMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not (hasAdminPerm(uid, "members_give_weapon") or hasAdminPerm(uid, "give_weapon_gang")) then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح")
        return
    end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    if not row and not liveRank then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً في العصابة")
        return
    end

    local targetSrc = getOnlineSourceByUserId(targetUid)
    if not targetSrc then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "اللاعب غير متصل")
        return
    end

    weapon = tostring(weapon or "")
    ammo   = math.max(0, math.min(10000, math.floor(tonumber(ammo) or 0)))
    if weapon == "" then return end

    local allowedWeapon = false
    for _, g in pairs(Config.Gangs or {}) do
        for _, w in ipairs(g.weapons or {}) do
            if w.weapon == weapon then
                allowedWeapon = true
                break
            end
        end
        if allowedWeapon then break end
    end
    if not allowedWeapon then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "السلاح غير مسموح")
        return
    end

    TriggerClientEvent("gang:receiveWeapon", targetSrc, weapon, ammo)
    local targetName = getUserName(targetUid)
    webhookLog(gang_id, "إعطاء عتاد لعضو (مسؤول)",
        ("**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**السلاح:** %s"):format(getUserName(uid), uid, targetName, targetUid, weapon),
        gang.color)
    adminWebhookLog("إعطاء عتاد لعضو",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**السلاح:** %s‬"):format(getUserName(uid), uid, targetName, targetUid, weapon), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم", "تم إعطاء العتاد لـ " .. targetName)
end)

-- ──────────────────────────────────────────────────────
-- Admin: سحب جميع أعضاء عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:pullGang")
AddEventHandler("admin:pullGang", function(gang_id)
    local src = source
    if not checkRate(src, "adminPullGang", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "pull_gang") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local pullCoords = getSourceCoordsSafe(src)
    if not pullCoords then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر تحديد موقعك الحالي"); return
    end

    local targets = getOnlineGangPullTargets(gang_id, src)
    local count = pullTargetsToCoords(targets, pullCoords)

    local label = gang.label or gang_id
    webhookLog(gang_id, "سحب جميع الأعضاء (مسؤول)",
        ("‫**المسؤول:** %s [%d]\n**العدد:** %d‬"):format(getUserName(uid), uid, count),
        gang.color)
    adminWebhookLog("سحب عصابة",
        ("‫**المسؤول:** %s [%d]\n**سُحب %d عضو‬"):format(getUserName(uid), uid, count), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم السحب", "سُحب " .. count .. " عضو من " .. label)
end)

-- ──────────────────────────────────────────────────────
-- Admin: توزيع عتاد على عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:giveWeaponGang")
AddEventHandler("admin:giveWeaponGang", function(gang_id, weapon, ammo)
    local src = source
    if not checkRate(src, "adminGiveWeaponGang", 3000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "give_weapon_gang") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    weapon = tostring(weapon or "")
    ammo   = math.max(0, math.min(10000, math.floor(tonumber(ammo) or 0)))
    if weapon == "" then return end

    local allowedWeapon = false
    for _, g in pairs(Config.Gangs or {}) do
        for _, w in ipairs(g.weapons or {}) do
            if w.weapon == weapon then
                allowedWeapon = true
                break
            end
        end
        if allowedWeapon then break end
    end
    if not allowedWeapon then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "السلاح غير مسموح")
        return
    end

    local count  = 0
    for _, tSrc in ipairs(getOnlineGangMemberSources(gang_id)) do
        TriggerClientEvent("gang:receiveWeapon", tSrc, weapon, ammo)
        count = count + 1
    end
    webhookLog(gang_id, "توزيع عتاد (مسؤول)",
        ("‫**المسؤول:** %s [%d]\n**السلاح:** %s\n**العدد:** %d‬"):format(getUserName(uid), uid, weapon, count),
        gang.color)
    adminWebhookLog("توزيع عتاد",
        ("‫**المسؤول:** %s [%d]\n**السلاح:** %s (%d)‬"):format(getUserName(uid), uid, weapon, count), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم", "وُزّع السلاح على " .. count .. " عضو")
end)

-- ──────────────────────────────────────────────────────
-- Admin: توظيف مسؤول عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:hireGangAdmin")
AddEventHandler("admin:hireGangAdmin", function(gang_id, target_user_id, rank_code)
    local src = source
    if not checkRate(src, "adminHireGangAdmin", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "hire_gang_admin") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local rankLabel = nil
    for _, r in ipairs(gang.ranks) do
        if r.code == rank_code then rankLabel = r.label; break end
    end
    if not rankLabel then TriggerClientEvent("gang:notify", src, "error", "خطأ", "رتبة غير صحيحة"); return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "User ID غير صحيح"); return
    end
    if not userIdExistsInDB(targetUid) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "هذا User ID غير موجود في قاعدة البيانات"); return
    end

    local targetCid  = getCid(targetUid)
    local targetName = getUserName(targetUid)
    local targetSrc  = getOnlineSourceByUserId(targetUid)
    local targetDisc = targetSrc and getDiscordFromSource(targetSrc) or ""

    local existing = getMemberRank(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    local currentRank = liveRank or existing

    if currentRank and currentRank == rank_code then
        dbUpsertMember(targetCid, gang_id, rank_code, targetName, targetDisc)
        dbEnsurePlaytime(targetCid, gang_id)
        invalidateGangCache(gang_id)
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "اللاعب عضو مسبقاً وتمت مزامنة بياناته")
        return
    end

    setUserGangRank(targetUid, gang_id, rank_code)
    dbUpsertMember(targetCid, gang_id, rank_code, targetName, targetDisc)
    dbEnsurePlaytime(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    webhookLog(gang_id, "تعيين مسؤول",
        ("**المسؤول العام:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة:** %s"):format(getUserName(uid), uid, targetName, targetUid, rankLabel),
        gang.color)
    adminWebhookLog("تعيين مسؤول عصابة",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]\n**الرتبة:** %s‬"):format(getUserName(uid), uid, targetName, targetUid, rankLabel), gang_id)

    TriggerClientEvent("gang:notify", src, "success", "تم التوظيف", targetName .. " ← " .. rankLabel)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "success", "مبروك!", "تم تعيينك في " .. gang.label .. " كـ " .. rankLabel)
    end
end)

-- ──────────────────────────────────────────────────────
-- Admin: فصل عضو من عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:fireGangMember")
AddEventHandler("admin:fireGangMember", function(gang_id, target_user_id)
    local src = source
    if not checkRate(src, "adminFireGangMember", 1000) then return end

    local uid = getUserId(src)
    if not uid or not (hasAdminPerm(uid, "members_fire") or hasAdminPerm(uid, "hire_gang_admin")) then return end

    local targetUid = tonumber(target_user_id)
    if targetUid == nil then return end

    local targetCid = getCid(targetUid)
    local row = dbGetMember(targetCid, gang_id)
    local liveRank = getLiveGangRankCode(targetUid, gang_id)
    if not row and not liveRank then TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "هذا اللاعب ليس عضواً"); return end

    clearUserGangRanks(targetUid, gang_id)
    dbDeleteMember(targetCid, gang_id)
    invalidateGangCache(gang_id)
    notifyActiveMembersViewers(gang_id)

    local targetSrc  = getOnlineSourceByUserId(targetUid)
    local gang       = Config.Gangs[gang_id]
    local firedName  = (row and row.name) or getUserName(targetUid) or tostring(targetCid)
    webhookLog(gang_id, "فصل عضو (مسؤول)",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]‬"):format(getUserName(uid), uid, firedName, targetUid),
        gang and gang.color)
    adminWebhookLog("فصل عضو من عصابة",
        ("‫**المسؤول:** %s [%d]\n**العضو:** %s [%d]‬"):format(getUserName(uid), uid, firedName, targetUid), gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم الفصل", firedName)
    if targetSrc then
        TriggerClientEvent("gang:notify", targetSrc, "error", "إشعار", "تم فصلك من " .. (gang and gang.label or gang_id) .. " بأمر الإدارة")
    end
end)

-- ════════════════════════════════════════════════════════
--  Laundry — غسيل الأموال
-- ════════════════════════════════════════════════════════
local isAnyGangMember   -- forward-declare: يُستخدم في Territory
local getUserGangId     -- forward-declare: يُستخدم في Territory rewards
;(function() -- IIFE: laundry scope

-- جلسات الغسيل النشطة: [src] = { gang_id, finishAt }
local launderySessions = {}

-- يتحقق أن اللاعب عضو في العصابة (له رتبة منها)
local function isGangMember(uid, gang_id)
    local gang = Config.Gangs[gang_id]
    if not gang then return false end
    local groups = getGroups(uid)
    for _, r in ipairs(gang.ranks or {}) do
        if groups[r.code] then return true end
    end
    return false
end

local function getAnyGangIdFromMemberRows(uid)
    local targetUid = tonumber(uid)
    if targetUid == nil then return nil end

    local rows = dbGetMemberRowsByCid(getCid(targetUid))
    for _, row in ipairs(rows or {}) do
        local gid = tostring(row and row.gang_id or "")
        if gid ~= "" and Config.Gangs[gid] then
            return gid
        end
    end

    return nil
end

getUserGangId = function(uid)
    local groups = getGroups(uid)
    local gangId = getAnyGangIdFromGroups(groups)
    if gangId then
        return gangId
    end

    if GROUP_SOURCE_MODE ~= "vrp" then
        return getAnyGangIdFromMemberRows(uid)
    end

    return nil
end

isAnyGangMember = function(uid)
    local targetUid = tonumber(uid)
    if targetUid == nil then return false end

    local cached = onlineGangMemberFlag[targetUid]
    if cached ~= nil then
        if cached == true then
            return true
        end

        if GROUP_SOURCE_MODE ~= "vrp" and getAnyGangIdFromMemberRows(targetUid) ~= nil then
            onlineGangMemberFlag[targetUid] = true
            return true
        end

        return false
    end

    local now = GetGameTimer()
    local gCache = groupsCache[tostring(targetUid)]
    if not gCache or now >= (gCache.exp or 0) then
        return refreshOnlineGangMemberFlag(targetUid)
    end

    local has = hasAnyGangFromGroups(gCache.groups) == true
    if (not has) and GROUP_SOURCE_MODE ~= "vrp" then
        has = getAnyGangIdFromMemberRows(targetUid) ~= nil
    end

    onlineGangMemberFlag[targetUid] = has
    return has
end

-- جلب العصابات التي يحق للاعب رؤية نقاط غسيلها (ماركر + بلب)
RegisterNetEvent("gang:requestLaundryAccess")
AddEventHandler("gang:requestLaundryAccess", function()
    local src = source
    if not checkRate(src, "requestLaundryAccess", 1000) then return end

    local uid = getUserId(src)
    if not uid then return end

    TriggerClientEvent("gang:laundryAccessData", src, buildLaundryAccessMap(uid))
end)

-- تحديث ذاتي لحظي (اللاعب يطلب إعادة المزامنة لنفسه فقط)
RegisterNetEvent("gang:refreshLaundryAccess")
AddEventHandler("gang:refreshLaundryAccess", function()
    local src = source
    local uid = getUserId(src)
    if not uid then return end
    TriggerClientEvent("gang:laundryAccessData", src, buildLaundryAccessMap(uid))
end)

-- عند سباون اللاعب ادفع صلاحيات نقاط الغسيل مباشرة
AddEventHandler("vRP:playerSpawn", function(user_id, src, first_spawn)
    -- Client-driven refresh only (playerSpawned + requestLaundryAccess)
    -- تجنب سباق تزامن عند الدخول قد يسبب ضغط natives على الكلاينت.
    return
end)

-- ──────────────────────────────────────────────────────
-- gang:startLaundry  — بدء الغسيل
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:startLaundry")
AddEventHandler("gang:startLaundry", function(gang_id)
    local src = source
    if not checkRate(src, "startLaundry", 3000) then return end

    local uid = getUserId(src)
    if not uid then return end

    local gang = Config.Gangs[gang_id]
    if not gang then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "Gang not found")
        return
    end

    local isPublic = type(gang.laundry) == "table" and gang.laundry.public_blip == true
    if not isPublic and not isGangMember(uid, gang_id) then
        TriggerClientEvent("gang:notify", src, "error", "ممنوع", "هذه النقطة ليست لعصابتك")
        return
    end

    -- تحقق أنه لا توجد جلسة نشطة
    if launderySessions[src] then
        TriggerClientEvent("laundry:alreadyActive", src)
        return
    end

    -- اقرأ كل الأموال القذرة التي يملكها اللاعب
    local cfg       = Config.Laundry
    local dirtyItem = "dirty_money"
    local totalDirty = getInventoryItemAmountSafe(uid, dirtyItem)

    if totalDirty <= 0 then
        TriggerClientEvent("gang:notify", src, "error", "لا يوجد مال قذر", "ليس لديك أموال قذرة للغسيل")
        return
    end

    -- حساب الوقت: 5 ثواني لكل 100 ألف (مع fallback للإعداد القديم)
    local secsPer100k = tonumber(cfg.seconds_per_100k)
    if not secsPer100k then
        local secsPerMil = tonumber(cfg.seconds_per_million) or 60
        secsPer100k = math.max(1, math.floor(secsPerMil / 10))
    end
    local duration = math.max(secsPer100k, math.ceil(totalDirty / 100000) * secsPer100k)

    -- نسبة تحويل عشوائية بين الحد الأدنى والأعلى
    local rMin   = tonumber(cfg.clean_ratio_min) or 0.75
    local rMax   = tonumber(cfg.clean_ratio_max) or 0.90
    local ratio  = rMin + math.random() * (rMax - rMin)
    local cleanAmt = math.floor(totalDirty * ratio)

    -- سجّل الجلسة مع تفاصيل المبالغ
    local finishAt = GetGameTimer() + (duration * 1000)
    launderySessions[src] = {
        gang_id    = gang_id,
        finishAt   = finishAt,
        uid        = uid,
        totalDirty = totalDirty,
        cleanAmt   = cleanAmt,
    }

    TriggerClientEvent("laundry:started", src, {
        gang_id  = gang_id,
        duration = duration,
        dirty    = totalDirty,
        clean    = cleanAmt,
    })
end)

-- ──────────────────────────────────────────────────────
-- gang:cancelLaundry  — إلغاء الغسيل (بُعد أو يدوي)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:cancelLaundry")
AddEventHandler("gang:cancelLaundry", function()
    local src = source
    if launderySessions[src] then
        launderySessions[src] = nil
        TriggerClientEvent("laundry:cancelled", src)
    end
end)

-- ──────────────────────────────────────────────────────
-- gang:finishLaundry  — إتمام الغسيل (الكلاينت يرسلها عند انتهاء العداد)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:finishLaundry")
AddEventHandler("gang:finishLaundry", function(gang_id)
    local src = source
    if not checkRate(src, "finishLaundry", 5000) then return end

    local session = launderySessions[src]
    if not session or session.gang_id ~= gang_id then return end

    -- تحقق من التوقيت (لا يقدر يتلاعب ويرسل قبل الوقت)
    if GetGameTimer() < session.finishAt - 3000 then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "الغسيل لم ينتهِ بعد")
        return
    end

    local uid        = session.uid or getUserId(src)
    local cfg        = Config.Laundry
    local dirtyItem  = "dirty_money"
    local totalDirty = session.totalDirty or 0
    local cleanAmt   = session.cleanAmt   or 0

    -- إزالة الجلسة أولاً لمنع الاستدعاء المزدوج
    launderySessions[src] = nil

    -- تحقق ثانية من وجود العنصر
    local count = getInventoryItemAmountSafe(uid, dirtyItem)
    if count <= 0 then
        TriggerClientEvent("gang:notify", src, "error", "انتهى المال القذر", "اختفت الأموال القذرة أثناء الغسيل!")
        TriggerClientEvent("laundry:cancelled", src)
        return
    end

    -- إذا تغيّر المبلغ، اغسل ما هو موجود فقط وأعد حساب النظيف
    if count < totalDirty then
        totalDirty = count
        local rMin  = tonumber(cfg.clean_ratio_min) or 0.75
        local rMax  = tonumber(cfg.clean_ratio_max) or 0.90
        local ratio = rMin + math.random() * (rMax - rMin)
        cleanAmt    = math.floor(totalDirty * ratio)
    end

    -- خصم الأموال القذرة
    if not tryTakeInventoryItemSafe(uid, dirtyItem, totalDirty) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر خصم المال القذر من المخزون")
        TriggerClientEvent("laundry:cancelled", src)
        return
    end
    creditWallet(uid, cleanAmt)

    TriggerClientEvent("laundry:done", src, { clean = cleanAmt })
    TriggerClientEvent("gang:notify", src, "success", "✓ تم الغسيل",
        ("غُسلت %s$ وحصلت على %s$"):format(totalDirty, cleanAmt))
end)

-- تنظيف الجلسات عند مغادرة اللاعب
AddEventHandler("playerDropped", function()
    local src = source
    launderySessions[src] = nil
end)

end)() -- laundry IIFE

-- ════════════════════════════════════════════════════════
--  نظام القتال على منطقة — Territory Conquest (DB-only)
-- ════════════════════════════════════════════════════════
local gangOwnsTerritory  -- forward-declare: يُستخدم في متجر الأسلحة
;(function() -- IIFE: نطاق دالة مستقل بحد 200 local خاص به

-- تحويل لون HEX إلى أقرب كود لون blip في FiveM
local function hexToBlipColor(hex)
    local blipColors = {
        {id=1,  r=220, g=20,  b=20  },   -- أحمر
        {id=2,  r=0,   g=150, b=0   },   -- أخضر
        {id=3,  r=30,  g=80,  b=230 },   -- أزرق
        {id=5,  r=240, g=200, b=0   },   -- أصفر
        {id=7,  r=120, g=40,  b=240 },   -- بنفسجي/Violet
        {id=8,  r=240, g=90,  b=170 },   -- وردي
        {id=17, r=200, g=100, b=0   },   -- برتقالي
        {id=27, r=230, g=0,   b=230 },   -- ماجينتا
        {id=40, r=0,   g=200, b=200 },   -- سماوي
        {id=53, r=130, g=0,   b=160 },   -- بنفسجي داكن
    }
    if type(hex) ~= "string" then return 2 end
    local h = hex:gsub("#","")
    if #h ~= 6 then return 2 end
    local r = tonumber(h:sub(1,2), 16) or 0
    local g = tonumber(h:sub(3,4), 16) or 0
    local b = tonumber(h:sub(5,6), 16) or 0
    local best, bestDist = 2, math.huge
    for _, c in ipairs(blipColors) do
        local dr, dg, db = r - c.r, g - c.g, b - c.b
        local dist = dr*dr + dg*dg + db*db
        if dist < bestDist then
            bestDist = dist
            best = c.id
        end
    end
    return best
end
local territoryState = {
    zones = {},
    next_id = 1,
}
local territorySavePending = false
local territorySaveScheduled = false

local function loadTerritoryFile()
    if not dbStateStorageReady then return false end

    local dbData = dbLoadStateJson("territory_state")
    if type(dbData) == "table" then
        territoryState.zones = type(dbData.zones) == "table" and dbData.zones or {}
        territoryState.next_id = math.max(1, math.floor(tonumber(dbData.next_id) or 1))

        local legacyActiveId = dbData.active_zone_id and tostring(dbData.active_zone_id) or nil
        if legacyActiveId and territoryState.zones[legacyActiveId] then
            territoryState.zones[legacyActiveId].status = "active"
        end

        for zId, z in pairs(territoryState.zones) do
            if type(z) == "table" then
                z.id = tostring(z.id or zId)
                if z.capture and z.status ~= "active" then
                    z.status = "active"
                end
            end
        end
        return true
    end

    territoryState = { zones = {}, next_id = 1 }
    dbQueueSaveStateJson("territory_state", territoryState, "state_territory")
    return true
end

function flushTerritoryFileNow()
    if not dbQueueSaveStateJson("territory_state", territoryState, "state_territory") then
        print("^1[ahmad_gangs] ^7ERROR: Failed to queue territory_state into DB")
    end
end

function saveTerritoryFile(forceNow)
    territorySavePending = true

    if forceNow == true then
        territorySavePending = false
        territorySaveScheduled = false
        if not dbSaveStateJsonNow("territory_state", territoryState) then
            print("^1[ahmad_gangs] ^7ERROR: Failed to persist territory_state immediately in DB")
        end
        return
    end

    if territorySaveScheduled then return end
    territorySaveScheduled = true

    SetTimeout(300, function()
        territorySaveScheduled = false
        if territorySavePending then
            territorySavePending = false
            flushTerritoryFileNow()
        end
    end)
end

function flushTerritorySaveIfPending()
    if territorySavePending or territorySaveScheduled then
        territorySavePending = false
        territorySaveScheduled = false
        flushTerritoryFileNow()
    end
end

local function isSrcInsideZone(src, zone)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    local dx = (pos.x - zone.x)
    local dy = (pos.y - zone.y)
    local dz = (pos.z - zone.z)
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    return dist <= (tonumber(zone.radius) or 0)
end

gangOwnsTerritory = function(gang_id)
    for _, zone in pairs(territoryState.zones or {}) do
        if zone.owner_gang_id == gang_id then
            return true
        end
    end
    return false
end

local function findZoneCapturedBySource(src)
    for id, zone in pairs(territoryState.zones or {}) do
        if zone and zone.status == "active" and zone.capture and zone.capture.src == src then
            return tostring(id), zone
        end
    end
    return nil, nil
end

local function findFirstActiveCaptureZone()
    for id, zone in pairs(territoryState.zones or {}) do
        if zone and zone.status == "active" and zone.capture then
            return tostring(id), zone
        end
    end
    return nil, nil
end

local function findFirstActiveZone()
    for id, zone in pairs(territoryState.zones or {}) do
        if zone and zone.status == "active" then
            return tostring(id), zone
        end
    end
    return nil, nil
end

local function buildTerritorySnapshot(viewerUid, includeActiveForViewer)
    local canSeeActive = includeActiveForViewer == true or (viewerUid and isAnyGangMember(viewerUid))
    local list = {}
    local activeList = {}

    for id, zone in pairs(territoryState.zones or {}) do
        local status = zone.status or "idle"
        if status ~= "active" or canSeeActive then
            local row = {
            id = tostring(id),
            label = zone.label or ("منطقة #" .. tostring(id)),
            x = tonumber(zone.x) or 0.0,
            y = tonumber(zone.y) or 0.0,
            z = tonumber(zone.z) or 0.0,
            radius = tonumber(zone.radius) or 0,
            capture_seconds = tonumber(zone.capture_seconds) or 0,
            status = status,
            owner_gang_id = zone.owner_gang_id,
            owner_label = zone.owner_label or "",
            owner_color = zone.owner_color or "#4d7fff",
            owner_blip_color = tonumber(zone.owner_blip_color) or 2,
            capturer_name = zone.capture and zone.capture.capturer_name or "",
            capturer_gang_id = zone.capture and zone.capture.gang_id or "",
            capture_ends_at_ms = zone.capture and tonumber(zone.capture.ends_at_ms) or 0,
            }
            table.insert(list, row)
            if status == "active" then
                table.insert(activeList, row)
            end
        end
    end

    table.sort(list, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)
    table.sort(activeList, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)

    return {
        zones = list,
        active_zone = activeList[1] or nil,
        active_zones = activeList,
        server_now_ms = GetGameTimer(),
    }
end

local function pushTerritoryStateToPlayer(src)
    local uid = getUserId(src)
    TriggerClientEvent("gang:territoryState", src, buildTerritorySnapshot(uid, false))
end

local function buildTerritorySnapshotsForBroadcast()
    local listMembers = {}
    local listPublic = {}
    local activeMembers = {}

    for id, zone in pairs(territoryState.zones or {}) do
        local status = zone.status or "idle"
        local row = {
            id = tostring(id),
            label = zone.label or ("منطقة #" .. tostring(id)),
            x = tonumber(zone.x) or 0.0,
            y = tonumber(zone.y) or 0.0,
            z = tonumber(zone.z) or 0.0,
            radius = tonumber(zone.radius) or 0,
            capture_seconds = tonumber(zone.capture_seconds) or 0,
            status = status,
            owner_gang_id = zone.owner_gang_id,
            owner_label = zone.owner_label or "",
            owner_color = zone.owner_color or "#4d7fff",
            owner_blip_color = tonumber(zone.owner_blip_color) or 2,
            capturer_name = zone.capture and zone.capture.capturer_name or "",
            capturer_gang_id = zone.capture and zone.capture.gang_id or "",
            capture_ends_at_ms = zone.capture and tonumber(zone.capture.ends_at_ms) or 0,
        }

        table.insert(listMembers, row)
        if status == "active" then
            table.insert(activeMembers, row)
        else
            table.insert(listPublic, row)
        end
    end

    table.sort(listMembers, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)
    table.sort(listPublic, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)
    table.sort(activeMembers, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)

    local nowMs = GetGameTimer()
    local snapshotMembers = {
        zones = listMembers,
        active_zone = activeMembers[1] or nil,
        active_zones = activeMembers,
        server_now_ms = nowMs,
    }
    local snapshotPublic = {
        zones = listPublic,
        active_zone = nil,
        active_zones = {},
        server_now_ms = nowMs,
    }

    return snapshotMembers, snapshotPublic
end

local function pushTerritoryStateToAllPlayers()
    local tPerf = perfStart()
    local snapshotMembers, snapshotPublic = buildTerritorySnapshotsForBroadcast()
    local sent = 0

    forEachOnlineSourceBatched(48, function(src, uid)
        local targetUid = uid or getUserId(src)
        if targetUid and isAnyGangMember(targetUid) then
            TriggerClientEvent("gang:territoryState", src, snapshotMembers)
        else
            TriggerClientEvent("gang:territoryState", src, snapshotPublic)
        end
        sent = sent + 1
    end)
    perfDone("pushTerritoryStateToAllPlayers", tPerf, "players=" .. tostring(sent))
end

local function pushTerritoryStateToGangMembers()
    local tPerf = perfStart()
    local snapshotMembers = buildTerritorySnapshot(nil, true)
    local sent = 0

    local burst = 0
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        local targetUid = info and tonumber(info.uid) or tonumber(cid)
        if src and src > 0 and targetUid ~= nil and GetPlayerName(src) and isAnyGangMember(targetUid) then
            TriggerClientEvent("gang:territoryState", src, snapshotMembers)
            sent = sent + 1
            burst = burst + 1
            if burst >= 8 then
                burst = 0
                Wait(2)
            end
        end
    end
    perfDone("pushTerritoryStateToGangMembers", tPerf, "sent=" .. tostring(sent))
end

local territoryMembersPushPending = false
local territoryMembersPushScheduled = false

local function schedulePushTerritoryStateToGangMembers(delayMs)
    territoryMembersPushPending = true
    if territoryMembersPushScheduled then return end

    territoryMembersPushScheduled = true
    local waitMs = math.max(0, tonumber(delayMs) or 75)
    SetTimeout(waitMs, function()
        territoryMembersPushScheduled = false
        if not territoryMembersPushPending then return end
        territoryMembersPushPending = false
        pushTerritoryStateToGangMembers()
        if territoryMembersPushPending then
            schedulePushTerritoryStateToGangMembers(45)
        end
    end)
end

local function pushTerritoryUiData(src)
    local cfg = Config.Territory or {}
    local uid = getUserId(src)
    local payload = buildTerritorySnapshot(uid, true)
    payload.can_start = true
    payload.default_radius = tonumber(cfg.default_radius) or 80
    payload.default_seconds = tonumber(cfg.default_seconds) or 180
    payload.min_radius = tonumber(cfg.min_radius) or 35
    payload.max_radius = tonumber(cfg.max_radius) or 180
    payload.min_seconds = tonumber(cfg.min_seconds) or 30
    payload.max_seconds = tonumber(cfg.max_seconds) or 900
    TriggerClientEvent("gang:territoryData", src, payload)
end

local function notifyAllGangMembers(ntype, title, message)
    local tPerf = perfStart()
    local sent = 0

    local burst = 0
    for cid, info in pairs(onlineCidMap) do
        local src = info and tonumber(info.src) or nil
        local targetUid = info and tonumber(info.uid) or tonumber(cid)
        if src and src > 0 and targetUid ~= nil and GetPlayerName(src) and isAnyGangMember(targetUid) then
            TriggerClientEvent("gang:notify", src, ntype, title, message)
            sent = sent + 1
            burst = burst + 1
            if burst >= 12 then
                burst = 0
                Wait(2)
            end
        end
    end
    perfDone("notifyAllGangMembers", tPerf, "sent=" .. tostring(sent))
end

-- ════════════════════════════════════════════════════════
--  نظام جوائز الاستحلال — Territory Capture Rewards
-- ════════════════════════════════════════════════════════

local specialItemHolder = nil
specialItemDrop = nil
specialItemMonitorRunning = false
SPECIAL_ITEM_DOWN_HEALTH = 101
local specialDepositPoint = nil

function isSpecialCarrierDown(src, ped)
    local hp = tonumber(GetEntityHealth(ped)) or 0
    local threshold = math.max(101, tonumber(GetConvar("ahmad_gangs_special_down_health", "140")) or 140)
    if hp <= threshold then
        return true
    end

    local okDead, deadState = pcall(function()
        return IsPedDeadOrDying(ped, true)
    end)
    if okDead and deadState == true then
        return true
    end

    local okFatal, fatalState = pcall(function()
        return IsPedFatallyInjured(ped)
    end)
    if okFatal and fatalState == true then
        return true
    end

    local okState, state = pcall(function()
        local p = Player(tonumber(src) or 0)
        return p and p.state or nil
    end)
    if okState and state then
        if state.dead == true
            or state.isDead == true
            or state.isdead == true
            or state.inLastStand == true
            or state.inlaststand == true
            or state.coma == true then
            return true
        end
    end

    return false
end

function formatPointLabel(p)
    if not p then return "غير محددة" end
    return ("X: %.2f | Y: %.2f | Z: %.2f"):format(tonumber(p.x) or 0.0, tonumber(p.y) or 0.0, tonumber(p.z) or 0.0)
end

function setSpecialDepositPoint(point)
    if type(point) ~= "table" then return false end
    local x = tonumber(point.x)
    local y = tonumber(point.y)
    local z = tonumber(point.z)
    if not x or not y or not z then return false end

    specialDepositPoint = { x = x + 0.0, y = y + 0.0, z = z + 0.0 }

    Config.TerritoryRewards = Config.TerritoryRewards or {}
    Config.TerritoryRewards.deposit_marker = Config.TerritoryRewards.deposit_marker or {}
    Config.TerritoryRewards.deposit_marker.coords = {
        specialDepositPoint.x,
        specialDepositPoint.y,
        specialDepositPoint.z,
    }

    return true
end

local function loadSpecialDepositPoint()
    if not dbStateStorageReady then return false end

    local loaded = false

    local dbData = dbLoadStateJson("treasure_deposit_point")
    if type(dbData) == "table" then
        loaded = setSpecialDepositPoint(dbData)
    end

    if loaded then return true end

    local cfg = Config.TerritoryRewards
    local marker = cfg and cfg.deposit_marker
    local coords = marker and marker.coords
    if type(coords) == "table" then
        if setSpecialDepositPoint({ x = coords[1] or coords.x, y = coords[2] or coords.y, z = coords[3] or coords.z }) then
            dbQueueSaveStateJson("treasure_deposit_point", {
                x = specialDepositPoint.x,
                y = specialDepositPoint.y,
                z = specialDepositPoint.z,
            }, "state_deposit_point")
        end
    end

    return true
end

function saveSpecialDepositPoint()
    if not specialDepositPoint then return end
    local payload = {
        x = specialDepositPoint.x,
        y = specialDepositPoint.y,
        z = specialDepositPoint.z,
    }

    if not dbQueueSaveStateJson("treasure_deposit_point", payload, "state_deposit_point") then
        print("^1[ahmad_gangs] ^7ERROR: Failed to queue treasure_deposit_point into DB")
    end
end

function broadcastSpecialDepositPoint(target)
    local payload = specialDepositPoint and {
        x = specialDepositPoint.x,
        y = specialDepositPoint.y,
        z = specialDepositPoint.z,
    } or nil

    if target then
        local src = tonumber(target)
        if not src or src <= 0 or not GetPlayerName(src) then return end
        local uid = getUserId(src)
        local isHolder = specialItemHolder and tonumber(specialItemHolder.src) == src
        if isHolder or (uid and isAnyGangMember(uid)) then
            TriggerClientEvent("gang:specialDepositPoint", src, payload)
        else
            TriggerClientEvent("gang:specialDepositPoint", src, nil)
        end
        return
    end

    local tPerf = perfStart()
    local sent = 0
    forEachOnlineSourceBatched(48, function(src, uid)
        local targetUid = uid or getUserId(src)
        local isHolder = specialItemHolder and tonumber(specialItemHolder.src) == tonumber(src)
        if isHolder or (targetUid and isAnyGangMember(targetUid)) then
            TriggerClientEvent("gang:specialDepositPoint", src, payload)
            sent = sent + 1
        else
            TriggerClientEvent("gang:specialDepositPoint", src, nil)
        end
    end)
    perfDone("broadcastSpecialDepositPoint", tPerf, "sent=" .. tostring(sent))
end

function broadcastTreasureDepositPointToAdmins()
    local payload = {
        has_point = specialDepositPoint ~= nil,
        point_label = formatPointLabel(specialDepositPoint),
    }

    forEachOnlineSourceBatched(48, function(src, uid)
        local targetUid = uid or getUserId(src)
        if targetUid and hasAdminPerm(targetUid, "treasure_control") then
            TriggerClientEvent("admin:treasureDepositPointUpdated", src, payload)
        end
    end)
end

function getSpecialHolderCoords(src)
    local holderSrc = tonumber(src)
    if not holderSrc or holderSrc <= 0 or not GetPlayerName(holderSrc) then
        return nil
    end
    local ped = GetPlayerPed(holderSrc)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end
    local pos = GetEntityCoords(ped)
    if not pos then return nil end
    return { x = pos.x + 0.0, y = pos.y + 0.0, z = pos.z + 0.0 }
end

function buildSpecialItemBlipPayload()
    local holder = nil
    if specialItemHolder then
        holder = {
            src = tonumber(specialItemHolder.src) or nil,
            uid = tonumber(specialItemHolder.uid) or nil,
            name = tostring(specialItemHolder.name or "لاعب"),
        }
    end

    local dropped = nil
    if specialItemDrop then
        dropped = {
            x = tonumber(specialItemDrop.x) or 0.0,
            y = tonumber(specialItemDrop.y) or 0.0,
            z = tonumber(specialItemDrop.z) or 0.0,
            by_name = tostring(specialItemDrop.by_name or "لاعب"),
            dropped_at = tonumber(specialItemDrop.dropped_at) or os.time(),
        }
    end

    if not holder and not dropped then return nil end
    return {
        holder = holder,
        drop = dropped,
    }
end

function dropSpecialItemFromHolder(reason, overrideCoords)
    if not specialItemHolder then return false end

    local holderSrc = tonumber(specialItemHolder.src) or 0
    local holderUid = tonumber(specialItemHolder.uid) or 0
    local holderName = tostring(specialItemHolder.name or ((holderUid > 0 and getUserName(holderUid)) or "لاعب"))

    local pos = nil
    if type(overrideCoords) == "table" then
        local x = tonumber(overrideCoords.x)
        local y = tonumber(overrideCoords.y)
        local z = tonumber(overrideCoords.z)
        if x and y and z then
            pos = { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
        end
    end
    if not pos then
        pos = getSpecialHolderCoords(holderSrc)
    end
    if not pos and type(specialItemHolder.last_pos) == "table" then
        local lx = tonumber(specialItemHolder.last_pos.x)
        local ly = tonumber(specialItemHolder.last_pos.y)
        local lz = tonumber(specialItemHolder.last_pos.z)
        if lx and ly and lz then
            pos = { x = lx + 0.0, y = ly + 0.0, z = lz + 0.0 }
        end
    end

    local cfg = Config.TerritoryRewards or {}
    local special = cfg.special_item
    if holderUid > 0 and special and special.name then
        pcall(function()
            tryTakeInventoryItemSafe(holderUid, special.name, 1)
        end)
    end

    specialItemHolder = nil
    if pos then
        specialItemDrop = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            by_name = holderName,
            dropped_at = os.time(),
        }
        notifyAllGangMembers("warning", "سقوط الكنز", holderName .. " سقط منه الكنز المفقود! اقتربوا من الصندوق لالتقاطه")
    else
        specialItemDrop = nil
    end

    broadcastSpecialBlip()

    if pos then
        webhookLog(nil, "سقوط الكنز المفقود",
            ("**الحامل:** %s\n**السبب:** %s\n**الإحداثيات:** %.2f, %.2f, %.2f"):format(
                holderName,
                tostring(reason or "unknown"),
                pos.x,
                pos.y,
                pos.z
            ),
            "#ff4d4d"
        )
    end

    return true
end

function ensureSpecialItemMonitor()
    if specialItemMonitorRunning or not specialItemHolder then return end

    specialItemMonitorRunning = true
    CreateThread(function()
        while specialItemHolder do
            local holderSrc = tonumber(specialItemHolder.src) or 0
            if holderSrc <= 0 or not GetPlayerName(holderSrc) then
                dropSpecialItemFromHolder("disconnect")
                break
            end

            local pos = getSpecialHolderCoords(holderSrc)
            if pos then
                specialItemHolder.last_pos = pos
            end

            local ped = GetPlayerPed(holderSrc)
            if not ped or ped == 0 or not DoesEntityExist(ped) then
                dropSpecialItemFromHolder("no_ped", specialItemHolder.last_pos)
                break
            end

            if isSpecialCarrierDown(holderSrc, ped) then
                dropSpecialItemFromHolder("down", specialItemHolder.last_pos)
                break
            end

            Wait(700)
        end

        specialItemMonitorRunning = false
        if specialItemHolder then
            ensureSpecialItemMonitor()
        end
    end)
end

function broadcastSpecialBlip()
    local tPerf = perfStart()
    local sent = 0
    local payload = buildSpecialItemBlipPayload()
    forEachOnlineSourceBatched(48, function(src, uid)
        local targetUid = uid or getUserId(src)
        local isHolder = specialItemHolder and tonumber(specialItemHolder.src) == tonumber(src)
        if isHolder or (targetUid and isAnyGangMember(targetUid)) then
            TriggerClientEvent("gang:specialItemBlip", src, payload)
            sent = sent + 1
        end
    end)
    perfDone("broadcastSpecialBlip", tPerf, "sent=" .. tostring(sent))
end

function broadcastTreasureAccountUpdate(gang_id)
    local gid = tostring(gang_id or "")
    if gid == "" or not Config.Gangs[gid] then return end
    local count = dbGetTreasureBalance(gid)
    local tPerf = perfStart()
    local sent = 0

    forEachOnlineSourceBatched(48, function(src, uid)
        local targetUid = uid or getUserId(src)
        if targetUid and hasAdminPerm(targetUid, "treasure_control") then
            TriggerClientEvent("admin:treasureUpdated", src, { gang_id = gid, count = count })
            sent = sent + 1
        end
    end)
    perfDone("broadcastTreasureAccountUpdate", tPerf, "admins=" .. tostring(sent))
end

local function ensureSpecialItemDefinedRuntime()
    local cfg = Config.TerritoryRewards or {}
    local sp = cfg.special_item
    local itemName = tostring(sp and sp.name or "")
    if itemName == "" then return false end

    local ok = pcall(function()
        vRP.defInventoryItem({ itemName, sp.label or itemName, "آيتم خاص من استحلال المنطقة", nil, 0.5 })
    end)

    return ok == true
end

local function giveCapturReward(winSrc, winUid, winGangLabel, zoneName)
    local cfg = Config.TerritoryRewards
    if not cfg then return end

    local special = cfg.special_item
    local pName = GetPlayerName(winSrc) or "لاعب"

    local roll = math.random(1, 100)
    if special and (tonumber(special.special_chance) or 0) >= roll then
        local specialName = tostring(special.name or "")
        if specialName == "" then return end

        ensureSpecialItemDefinedRuntime()

        if not specialDepositPoint then
            local autoPos = getSpecialHolderCoords(winSrc)
            if autoPos and setSpecialDepositPoint(autoPos) then
                saveSpecialDepositPoint()
                broadcastSpecialDepositPoint()
                broadcastTreasureDepositPointToAdmins()
            end
        end

        local gotInInventory = giveInventoryItemSafe(winUid, specialName, 1)
        specialItemDrop = nil
        specialItemHolder = {
            src = winSrc,
            uid = winUid,
            name = pName,
            virtual = (not gotInInventory),
            last_pos = getSpecialHolderCoords(winSrc),
        }
        ensureSpecialItemMonitor()

        TriggerClientEvent("gang:specialItemWon", winSrc, {
            label = special.label,
            icon  = special.item_icon or "📦",
            in_inventory = gotInInventory,
        })

        if not gotInInventory then
            TriggerClientEvent("gang:notify", winSrc, "warning", "تنبيه", "تعذر إضافة الكنز للحقيبة، لكن تم احتسابه محمولًا عليك")
        end

        notifyAllGangMembers("special", "🏆 ظهر الكنز المفقود!", pName .. " حصل على " .. (special.label or "الايتم الخاص") .. " بعد استحلال " .. zoneName)
        broadcastSpecialBlip()

        webhookLog(nil, "الايتم الخاص ظهر",
            ("**اللاعب:** %s\n**المنطقة:** %s"):format(pName, zoneName),
            "#FFD700")
        return
    end

    local rewards = cfg.items
    if not rewards or #rewards == 0 then return end

    local totalWeight = 0
    for _, r in ipairs(rewards) do
        totalWeight = totalWeight + (tonumber(r.weight) or 1)
    end

    local pick = math.random(1, totalWeight)
    local cumulative = 0
    local chosen = rewards[1]
    for _, r in ipairs(rewards) do
        cumulative = cumulative + (tonumber(r.weight) or 1)
        if pick <= cumulative then
            chosen = r
            break
        end
    end

    if chosen.type == "item" then
        giveInventoryItemSafe(winUid, chosen.name, tonumber(chosen.amount) or 1)
    elseif chosen.type == "weapon" then
        local ammo = tonumber(chosen.ammo) or 50
        callVrp(vRP.giveInventoryItem, winUid, chosen.name, 1)
        if ammo > 0 then
            local ammoItem = chosen.name:lower():gsub("weapon_", "") .. "_ammo"
            giveInventoryItemSafe(winUid, ammoItem, ammo)
        end
    elseif chosen.type == "dirty" then
        giveInventoryItemSafe(winUid, "dirty_money", tonumber(chosen.amount) or 1000)
    end

    TriggerClientEvent("gang:notify", winSrc, "success", "🎁 مكافأة الاستحلال", "حصلت على: " .. (chosen.label or chosen.name or ""))
end

RegisterNetEvent("gang:depositSpecialItem")
AddEventHandler("gang:depositSpecialItem", function()
    local src = source
    if not checkRate(src, "depositSpecialItem", 3000) then return end

    if not specialItemHolder or specialItemHolder.src ~= src then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "لا تحمل الايتم الخاص")
        return
    end

    local uid = getUserId(src)
    if not uid then return end

    local gang_id = getUserGangId(uid)
    if not gang_id or not Config.Gangs[gang_id] then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "لا يمكن الإيداع لأنك لست ضمن عصابة")
        return
    end

    local cfg = Config.TerritoryRewards
    local special = cfg and cfg.special_item
    if not special then return end

    local amount = getInventoryItemAmountSafe(uid, special.name)
    local isHolder = (specialItemHolder and specialItemHolder.src == src)
    local useVirtualHolder = (isHolder and (specialItemHolder.virtual == true or amount <= 0))

    if amount <= 0 and not isHolder then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "الايتم غير موجود في حوزتك")
        specialItemHolder = nil
        broadcastSpecialBlip()
        return
    end

    local taken = true
    if amount > 0 then
        taken = tryTakeInventoryItemSafe(uid, special.name, 1)
    end

    if not taken then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "فشل سحب الايتم من حقيبتك")
        return
    end

    local currentTreasure = dbGetTreasureBalance(gang_id)
    dbSetTreasureBalance(gang_id, currentTreasure + 1)

    specialItemHolder = nil
    specialItemDrop = nil
    broadcastSpecialBlip()

    local gangLabel = (Config.Gangs[gang_id] and Config.Gangs[gang_id].label) or gang_id
    local newTreasure = currentTreasure + 1

    TriggerClientEvent("gang:notify", src, "success", "✅ تم الإيداع", "تم إيداع " .. (special.label or "الايتم الخاص") .. " في حساب " .. gangLabel)
    notifyAllGangMembers("info", "تم إيداع الكنز", (GetPlayerName(src) or "لاعب") .. " أودع الكنز لحساب " .. gangLabel .. " (الرصيد: " .. tostring(newTreasure) .. ")")
    broadcastTreasureAccountUpdate(gang_id)

    webhookLog(nil, "إيداع الايتم الخاص",
        ("**اللاعب:** %s"):format(GetPlayerName(src) or "لاعب"),
        "#00FF7F")
end)

RegisterNetEvent("gang:requestSpecialBlip")
AddEventHandler("gang:requestSpecialBlip", function()
    local src = source
    local uid = getUserId(src)
    local isHolder = specialItemHolder and tonumber(specialItemHolder.src) == tonumber(src)
    if isHolder or (uid and isAnyGangMember(uid)) then
        TriggerClientEvent("gang:specialItemBlip", src, buildSpecialItemBlipPayload())
    else
        TriggerClientEvent("gang:specialItemBlip", src, nil)
    end
end)

RegisterNetEvent("gang:pickupDroppedSpecialItem")
AddEventHandler("gang:pickupDroppedSpecialItem", function()
    local src = source
    if not checkRate(src, "pickupDroppedSpecialItem", 900) then return end

    if specialItemHolder or not specialItemDrop then return end

    local uid = getUserId(src)
    if not uid or not isAnyGangMember(uid) then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    if isSpecialCarrierDown(src, ped) then
        return
    end

    local pos = GetEntityCoords(ped)
    if not pos then return end

    local dx = (pos.x - (tonumber(specialItemDrop.x) or 0.0))
    local dy = (pos.y - (tonumber(specialItemDrop.y) or 0.0))
    local dz = (pos.z - (tonumber(specialItemDrop.z) or 0.0))
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist > 2.4 then return end

    local cfg = Config.TerritoryRewards or {}
    local special = cfg.special_item
    if not special or not special.name then return end

    ensureSpecialItemDefinedRuntime()

    local pickerName = getUserName(uid)
    if not specialDepositPoint then
        local autoPos = getSpecialHolderCoords(src)
        if autoPos and setSpecialDepositPoint(autoPos) then
            saveSpecialDepositPoint()
            broadcastSpecialDepositPoint()
            broadcastTreasureDepositPointToAdmins()
        end
    end

    local gotInInventory = giveInventoryItemSafe(uid, special.name, 1)

    specialItemDrop = nil
    specialItemHolder = {
        src = src,
        uid = uid,
        name = pickerName,
        virtual = (not gotInInventory),
        last_pos = getSpecialHolderCoords(src),
    }
    ensureSpecialItemMonitor()

    TriggerClientEvent("gang:specialItemWon", src, {
        label = special.label,
        icon  = special.item_icon or "📦",
        looted = true,
        in_inventory = gotInInventory,
    })
    if gotInInventory then
        TriggerClientEvent("gang:notify", src, "success", "تم الالتقاط", "التقطت الكنز المفقود بنجاح")
    else
        TriggerClientEvent("gang:notify", src, "warning", "تم الالتقاط", "التقطت الكنز لكن تعذر إضافته للحقيبة، وسيبقى محمولًا عليك")
    end
    notifyAllGangMembers("special", "تم التقاط الكنز", pickerName .. " التقط الكنز المفقود")
    broadcastSpecialBlip()

    webhookLog(nil, "التقاط الكنز المفقود",
        ("**اللاعب:** %s [%d]"):format(pickerName, uid),
        "#00d4ff")
end)

RegisterNetEvent("gang:specialHolderDown")
AddEventHandler("gang:specialHolderDown", function(coords, reason)
    local src = source
    if not checkRate(src, "specialHolderDown", 600) then return end
    if not specialItemHolder or tonumber(specialItemHolder.src) ~= tonumber(src) then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        dropSpecialItemFromHolder(reason or "holder_down", coords)
        return
    end

    local r = tostring(reason or "")
    if (r ~= "down_client") and (not isSpecialCarrierDown(src, ped)) then return end

    dropSpecialItemFromHolder(reason or "holder_down", coords)
end)

AddEventHandler("playerDropped", function()
    local src = source
    if specialItemHolder and tonumber(specialItemHolder.src) == tonumber(src) then
        dropSpecialItemFromHolder("disconnect", specialItemHolder.last_pos)
    end
end)

RegisterNetEvent("gang:requestSpecialDepositPoint")
AddEventHandler("gang:requestSpecialDepositPoint", function()
    local src = source
    broadcastSpecialDepositPoint(src)
end)

loadTerritoryFile()
loadSpecialDepositPoint()

CreateThread(function()
    while not dbStateStorageReady do
        Wait(100)
    end
    Wait(150)
    loadTerritoryFile()
    Wait(0)
    loadSpecialDepositPoint()
end)

-- تعريف آيتمات الجوائز في vRP عند بدء الريسورس
AddEventHandler("onResourceStart", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    Wait(1000) -- ننتظر حتى يكون vRP جاهز

    local cfg = Config.TerritoryRewards
    if not cfg then return end

    -- تعريف الايتم الخاص
    local sp = cfg.special_item
    if sp and sp.name then
        vRP.defInventoryItem({ sp.name, sp.label or sp.name, "آيتم خاص من استحلال المنطقة", nil, 0.5 })
    end

    -- تعريف الجوائز العادية (نوع item فقط — weapon/dirty معرّفة مسبقاً في vRP)
    for _, reward in ipairs(cfg.items or {}) do
        if reward.type == "item" and reward.name then
            vRP.defInventoryItem({ reward.name, reward.label or reward.name, "", nil, 0.3 })
        end
    end
end)

AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    flushTerritorySaveIfPending()
    flushDbWriteQueueNow(8000)
end)

RegisterNetEvent("gang:requestTerritoryState")
AddEventHandler("gang:requestTerritoryState", function()
    local src = source
    if not checkRate(src, "requestTerritoryState", 1500) then return end
    pushTerritoryStateToPlayer(src)
end)

RegisterNetEvent("admin:getTerritoryData")
AddEventHandler("admin:getTerritoryData", function()
    local src = source
    if not checkRate(src, "adminGetTerritoryData", 1000) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not Config.Territory or Config.Territory.enabled == false then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إدارة الاستحلال من لوحة الأدمن")
        return
    end

    pushTerritoryUiData(src)
end)

RegisterNetEvent("admin:startTerritoryBattle")
AddEventHandler("admin:startTerritoryBattle", function(radius, seconds)
    local src = source
    if not checkRate(src, "adminStartTerritoryBattle", 3000) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not Config.Territory or Config.Territory.enabled == false then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية بدء الاستحلال من لوحة الأدمن")
        return
    end

    local cfg = Config.Territory or {}
    local minR = tonumber(cfg.min_radius) or 35
    local maxR = tonumber(cfg.max_radius) or 180
    local minS = tonumber(cfg.min_seconds) or 30
    local maxS = tonumber(cfg.max_seconds) or 900

    local finalRadius = math.max(minR, math.min(maxR, math.floor(tonumber(radius) or (tonumber(cfg.default_radius) or 80))))
    local finalSeconds = math.max(minS, math.min(maxS, math.floor(tonumber(seconds) or (tonumber(cfg.default_seconds) or 180))))

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pos = GetEntityCoords(ped)

    local id = tostring(territoryState.next_id or 1)
    territoryState.next_id = (tonumber(id) or 0) + 1

    territoryState.zones[id] = {
        id = id,
        label = "منطقة #" .. id,
        x = pos.x,
        y = pos.y,
        z = pos.z,
        radius = finalRadius,
        capture_seconds = finalSeconds,
        status = "active",
        owner_gang_id = nil,
        owner_label = "",
        owner_color = "#ff3b3b",
        owner_blip_color = 1,
        started_by_uid = uid,
        started_at = os.time(),
        capture = nil,
    }

    saveTerritoryFile()
    schedulePushTerritoryStateToGangMembers(80)
    pushTerritoryUiData(src)
    TriggerClientEvent("gang:notify", src, "success", "تم البدء", "تم إنشاء منطقة استحلال جديدة بنجاح")

    CreateThread(function()
        Wait(60)
        notifyAllGangMembers("warning", "إنذار استحلال", "تم بدء قتال على منطقة جديدة! توجهوا بسرعة للاستحلال")
    end)

    adminWebhookLog("بدء قتال على منطقة",
        ("**المسؤول:** %s [%d]\n**النطاق:** %dm\n**المدة:** %d ثانية"):format(getUserName(uid), uid, finalRadius, finalSeconds))
end)

RegisterNetEvent("gang:territoryTryCapture")
AddEventHandler("gang:territoryTryCapture", function(zone_id)
    local src = source
    if not checkRate(src, "territoryTryCapture", 600) then return end

    local uid = getUserId(src)
    if not uid then return end

    local userGang = getUserGangId(uid)
    if not userGang then return end

    local zId = tostring(zone_id or "")
    if zId == "" then return end
    local zone = territoryState.zones[zId]
    if not zone or zone.status ~= "active" then return end

    local currentCaptureId = findZoneCapturedBySource(src)
    if currentCaptureId and currentCaptureId ~= zId then
        TriggerClientEvent("gang:notify", src, "warning", "استحلال آخر نشط", "أنت تستحل منطقة أخرى حالياً")
        return
    end

    if zone.capture and zone.capture.src and GetPlayerName(zone.capture.src) then
        TriggerClientEvent("gang:notify", src, "warning", "قيد الاستحلال", "المنطقة قيد الاستحلال حالياً")
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if GetEntityHealth(ped) <= 0 then return end
    if not isSrcInsideZone(src, zone) then
        TriggerClientEvent("gang:notify", src, "warning", "بعيد عن المنطقة", "ادخل نطاق الاستحلال أولاً")
        return
    end

    local nowMs = GetGameTimer()
    zone.capture = {
        src = src,
        uid = uid,
        capturer_name = getUserName(uid),
        gang_id = userGang,
        start_at_ms = nowMs,
        ends_at_ms = nowMs + ((tonumber(zone.capture_seconds) or 0) * 1000),
    }

    saveTerritoryFile()
    schedulePushTerritoryStateToGangMembers(55)
    ensureTerritoryCaptureMonitor()

    TriggerClientEvent("gang:territoryCaptureStart", src, {
        zone_id = zId,
        duration = tonumber(zone.capture_seconds) or 0,
        end_at_ms = zone.capture.ends_at_ms,
    })

    webhookLog(userGang, "بدء الاستحلال",
        ("**المستحل:** %s [%d]\n**المنطقة:** %s"):format(getUserName(uid), uid, zone.label or zId),
        Config.Gangs[userGang] and Config.Gangs[userGang].color or "#ff3b3b")
end)

territoryCaptureMonitorRunning = false
territoryCapturePollMs = 900

function ensureTerritoryCaptureMonitor()
    if territoryCaptureMonitorRunning then return end

    local activeCaptureId = findFirstActiveCaptureZone()
    if not activeCaptureId then return end

    territoryCaptureMonitorRunning = true
    CreateThread(function()
        while true do
            local hasCapture = false
            local dirty = false

            for zId, zone in pairs(territoryState.zones or {}) do
                if zone and zone.status == "active" and zone.capture then
                    hasCapture = true
                    local cap = zone.capture
                    local capSrc = cap.src

                    local function resetCapture(msg)
                        zone.capture = nil
                        dirty = true
                        if capSrc and GetPlayerName(capSrc) then
                            TriggerClientEvent("gang:territoryCaptureStop", capSrc, { success = false, reason = msg })
                        end
                        notifyAllGangMembers("warning", "فشل الاستحلال", msg)
                    end

                    if not capSrc or not GetPlayerName(capSrc) then
                        resetCapture("انقطع اللاعب المستحل في " .. (zone.label or zId) .. " — تم تصفير الاستحلال")
                    else
                        local ped = GetPlayerPed(capSrc)
                        if not ped or ped == 0 or GetEntityHealth(ped) <= 0 then
                            resetCapture("مات المستحل في " .. (zone.label or zId) .. " — تم تصفير الاستحلال")
                        elseif not isSrcInsideZone(capSrc, zone) then
                            resetCapture("خرج المستحل من نطاق " .. (zone.label or zId) .. " — تم تصفير الاستحلال")
                        elseif GetGameTimer() >= (tonumber(cap.ends_at_ms) or 0) then
                            local winGangId = cap.gang_id
                            local winGang = Config.Gangs[winGangId] or {}

                            zone.owner_gang_id = winGangId
                            zone.owner_label = winGang.label or winGangId
                            zone.owner_color = winGang.color or "#4d7fff"
                            zone.owner_blip_color = hexToBlipColor(winGang.color or "#4d7fff")
                            zone.status = "secured"
                            zone.capture = nil
                            dirty = true

                            if capSrc and GetPlayerName(capSrc) then
                                TriggerClientEvent("gang:territoryCaptureStop", capSrc, { success = true, reason = "تم الاستحلال بنجاح" })
                            end

                            notifyAllGangMembers("success", "تم استحلال المنطقة", "العصابة " .. (zone.owner_label or "") .. " استحلت " .. (zone.label or zId) .. " بنجاح")

                            -- ★ إعطاء جائزة عشوائية للفائز
                            local winUid = getUserId(capSrc)
                            if winUid and capSrc and GetPlayerName(capSrc) then
                                giveCapturReward(capSrc, winUid, zone.owner_label or winGangId, zone.label or zId)
                            end

                            webhookLog(winGangId, "نجاح الاستحلال",
                                ("**العصابة:** %s\n**المنطقة:** %s"):format(zone.owner_label or winGangId, zone.label or zId),
                                zone.owner_color)
                        end
                    end
                end
            end

            if dirty then
                saveTerritoryFile()
                pushTerritoryStateToAllPlayers()
            end

            if not hasCapture then
                territoryCaptureMonitorRunning = false
                if findFirstActiveCaptureZone() then
                    ensureTerritoryCaptureMonitor()
                end
                return
            end

            Wait(territoryCapturePollMs)
        end
    end)
end

ensureTerritoryCaptureMonitor()

-- ──────────────────────────────────────────────────────
-- gang:cancelTerritoryCapture  — إلغاء الاستحلال يدوياً
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:cancelTerritoryCapture")
AddEventHandler("gang:cancelTerritoryCapture", function()
    local src = source
    if not checkRate(src, "cancelTerritoryCapture", 1000) then return end

    local captureZoneId, zone = findZoneCapturedBySource(src)
    if not captureZoneId or not zone then return end

    zone.capture = nil
    saveTerritoryFile()
    schedulePushTerritoryStateToGangMembers(20)
    TriggerClientEvent("gang:territoryCaptureStop", src, { success = false, reason = "ألغيت الاستحلال" })
    TriggerClientEvent("gang:notify", src, "warning", "تم الإلغاء", "ألغيت عملية الاستحلال")
end)

-- ──────────────────────────────────────────────────────
-- admin:cancelTerritoryCapture  — مسؤول يلغي استحلال أي عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:cancelTerritoryCapture")
AddEventHandler("admin:cancelTerritoryCapture", function(zone_id)
    local src = source
    if not checkRate(src, "adminCancelTerritoryCapture", 1000) then return end
    local uid = getUserId(src)
    if not uid then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إلغاء الاستحلال")
        return
    end

    local targetId = tostring(zone_id or "")
    local activeId, zone

    if targetId ~= "" then
        activeId = targetId
        zone = territoryState.zones[activeId]
        if not zone or zone.status ~= "active" or not zone.capture then
            TriggerClientEvent("gang:notify", src, "warning", "لا يوجد", "المنطقة المحددة لا تحتوي عملية استحلال جارية")
            return
        end
    else
        activeId, zone = findFirstActiveCaptureZone()
    end

    if not activeId or not zone then
        TriggerClientEvent("gang:notify", src, "warning", "لا يوجد", "لا يوجد استحلال نشط حالياً")
        return
    end

    local capSrc = zone.capture.src
    zone.capture = nil
    saveTerritoryFile()
    schedulePushTerritoryStateToGangMembers(20)

    if capSrc and GetPlayerName(capSrc) then
        TriggerClientEvent("gang:territoryCaptureStop", capSrc, { success = false, reason = "سحب المسؤول عملية الاستحلال" })
        TriggerClientEvent("gang:notify", capSrc, "warning", "تم السحب", "سحب المسؤول عملية الاستحلال منك")
    end

    TriggerClientEvent("gang:notify", src, "success", "تم السحب", "تم سحب عملية الاستحلال بنجاح")
    pushTerritoryUiData(src)
    adminWebhookLog("سحب استحلال", ("**المسؤول:** %s [%d]"):format(getUserName(uid), uid))
end)

-- ──────────────────────────────────────────────────────
-- admin:cancelTerritoryBattle  — مسؤول يلغي الاستحلال بالكامل
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:cancelTerritoryBattle")
AddEventHandler("admin:cancelTerritoryBattle", function(zone_id)
    local src = source
    if not checkRate(src, "adminCancelTerritoryBattle", 1200) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إلغاء الاستحلال بالكامل")
        return
    end

    local targetId = tostring(zone_id or "")
    local activeId, zone

    if targetId ~= "" then
        activeId = targetId
        zone = territoryState.zones[activeId]
    else
        activeId, zone = findFirstActiveZone()
    end

    if not zone or zone.status ~= "active" then
        TriggerClientEvent("gang:notify", src, "warning", "لا يوجد", "لا يوجد استحلال نشط لإلغائه")
        return
    end

    local capSrc = zone.capture and zone.capture.src or nil

    -- حذف المنطقة النشطة بالكامل
    territoryState.zones[activeId] = nil

    saveTerritoryFile()
    pushTerritoryStateToAllPlayers()

    if capSrc and GetPlayerName(capSrc) then
        TriggerClientEvent("gang:territoryCaptureStop", capSrc, { success = false, reason = "تم إلغاء الاستحلال بالكامل من المسؤول" })
        TriggerClientEvent("gang:notify", capSrc, "warning", "تم الإلغاء", "ألغى المسؤول عملية الاستحلال بالكامل")
    end

    notifyAllGangMembers("warning", "إلغاء الاستحلال", "تم إلغاء عملية الاستحلال بالكامل من المسؤول")
    TriggerClientEvent("gang:notify", src, "success", "تم الإلغاء", "تم إلغاء الاستحلال بالكامل وحذف المنطقة النشطة")
    pushTerritoryUiData(src)

    adminWebhookLog("إلغاء كامل للاستحلال",
        ("**المسؤول:** %s [%d]\n**المنطقة الملغاة:** %s"):format(getUserName(uid), uid, tostring(zone.label or activeId)))
end)

-- ──────────────────────────────────────────────────────
-- admin:renameTerritoryZone  — مسؤول يعدل اسم المنطقة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:renameTerritoryZone")
AddEventHandler("admin:renameTerritoryZone", function(zone_id, new_label)
    local src = source
    if not checkRate(src, "adminRenameTerritoryZone", 1000) then return end
    local uid = getUserId(src)
    if not uid then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية تعديل المنطقة")
        return
    end

    local zId = tostring(zone_id or "")
    local zone = territoryState.zones[zId]
    if not zone then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "المنطقة غير موجودة")
        return
    end

    local label = tostring(new_label or ""):gsub("^%s*(.-)%s*$", "%1")
    if label == "" then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "الاسم لا يمكن أن يكون فارغاً")
        return
    end
    if #label > 40 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "الاسم طويل جداً (الحد 40 حرف)")
        return
    end

    zone.label = label
    saveTerritoryFile()
    pushTerritoryStateToAllPlayers()
    pushTerritoryUiData(src)
    TriggerClientEvent("gang:notify", src, "success", "تم", "تم تغيير اسم المنطقة إلى: " .. label)
end)

-- ──────────────────────────────────────────────────────
-- admin:deleteTerritoryZone  — حذف منطقة (نشطة/مستقرة)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:deleteTerritoryZone")
AddEventHandler("admin:deleteTerritoryZone", function(zone_id)
    local src = source
    if not checkRate(src, "adminDeleteTerritoryZone", 900) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not hasAdminPerm(uid, "territory_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية حذف المناطق")
        return
    end

    local zId = tostring(zone_id or "")
    local zone = territoryState.zones[zId]
    if not zone then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "المنطقة غير موجودة")
        return
    end

    local capSrc = zone.capture and zone.capture.src or nil

    territoryState.zones[zId] = nil

    saveTerritoryFile()
    pushTerritoryStateToAllPlayers()
    pushTerritoryUiData(src)

    if capSrc and GetPlayerName(capSrc) then
        TriggerClientEvent("gang:territoryCaptureStop", capSrc, { success = false, reason = "تم حذف المنطقة من المسؤول" })
        TriggerClientEvent("gang:notify", capSrc, "warning", "توقف الاستحلال", "تم حذف المنطقة من المسؤول")
    end

    TriggerClientEvent("gang:notify", src, "success", "تم الحذف", "تم حذف المنطقة بنجاح")
    adminWebhookLog("حذف منطقة",
        ("**المسؤول:** %s [%d]\n**المنطقة:** %s"):format(getUserName(uid), uid, tostring(zone.label or zId)))
end)

end)() -- territory IIFE

-- ════════════════════════════════════════════════════════
--  متجر الأسلحة — Weapon Shop System
-- ════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────
-- Shop State Cache: [gang_id] = { owned, items={[weapon]={stock,price}} }
-- ──────────────────────────────────────────────────────
shopStateCache       = {}
shopDisabledByAdmin  = {}   -- [gang_id] = true  →  أغلق المسؤول متجر هذه العصابة مؤقتاً

function dbLoadShopState(gang_id)
    -- ملكية المتجر: صف واحد بـ row_type='shop_owned', citizen_id=0
    local ownedRow = MySQL.single.await(
        'SELECT id FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND citizen_id = 0 LIMIT 1',
        { RT_SHOP_OWNED, gang_id }
    )
    Wait(0)
    -- عناصر المتجر: row_type='shop_item', name=weapon, amount=stock, balance=price
    local itemRows = MySQL.query.await(
        'SELECT name, amount, balance FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_SHOP_ITEM, gang_id }
    ) or {}
    local state = { owned = ownedRow ~= nil, items = {} }
    for _, row in ipairs(itemRows) do
        if row.name and row.name ~= '' then
            state.items[row.name] = {
                stock = tonumber(row.amount) or 0,
                price = tonumber(row.balance) or 0,
            }
        end
    end
    shopStateCache[gang_id] = state
    return state
end

function getShopState(gang_id)
    if shopStateCache[gang_id] then return shopStateCache[gang_id] end
    return dbLoadShopState(gang_id)
end

function dbSetShopOwned(gang_id)
    -- INSERT IGNORE: الـ unique key (row_type, gang_id, citizen_id=0) يمنع التكرار
    dbQueueWrite(
        'INSERT IGNORE INTO ahmad_gang (row_type, gang_id, citizen_id) VALUES (?, ?, 0)',
        { RT_SHOP_OWNED, gang_id },
        "shop_owned"
    )
end

function dbUpsertShopItem(gang_id, weapon, stock, price)
    -- حذف الصف القديم (إن وُجد) ثم إدراج الجديد — بدون .await لتجنب blocking
    dbQueueWrite(
        'DELETE FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND name = ?',
        { RT_SHOP_ITEM, gang_id, weapon },
        "shop_item_del"
    )
    dbQueueWrite(
        'INSERT INTO ahmad_gang (row_type, gang_id, name, amount, balance) VALUES (?, ?, ?, ?, ?)',
        { RT_SHOP_ITEM, gang_id, weapon, stock, price },
        "shop_item_ins"
    )
end

function dbAddShopStock(gang_id, weapon, amount)
    -- UPDATE مباشر بدون SELECT — يُحدث الصف إن وُجد (بدون .await)
    -- إذا الصف غير موجود، UPDATE يرجع 0 rows affected لكن لن يخرب شيء
    -- (الصف يُنشأ عند أول dbUpsertShopItem عبر إدارة المتجر)
    dbQueueWrite(
        'UPDATE ahmad_gang SET amount = amount + ? WHERE row_type = ? AND gang_id = ? AND name = ? LIMIT 1',
        { amount, RT_SHOP_ITEM, gang_id, weapon },
        "shop_stock_add"
    )
end

function buildShopOwnedMap()
    local map = {}
    for gang_id in pairs(Config.Gangs) do
        local s = getShopState(gang_id)
        if s and s.owned then map[gang_id] = true end
    end
    return map
end

function pushShopAccessAll()
    TriggerClientEvent("gang:shopOwnedData", -1, buildShopOwnedMap())
end

function pushShopAccessToPlayer(src)
    TriggerClientEvent("gang:shopOwnedData", src, buildShopOwnedMap())
end

function buildShopItemsForManager(gang_id)
    local gang  = Config.Gangs[gang_id]
    local ws    = gang and gang.weapon_shop
    if not ws then return {} end
    local state = getShopState(gang_id)
    local items = {}
    for _, item in ipairs(ws.items or {}) do
        local s = state.items[item.weapon] or { stock = 0, price = 0 }
        table.insert(items, {
            label          = item.label,
            weapon         = item.weapon,
            ammo           = item.ammo or 0,
            base_price     = item.base_price or 0,
            restock_price  = item.restock_price or 0,
            restock_amount = item.restock_amount or 10,
            stock          = s.stock,
            price          = s.price > 0 and s.price or (item.base_price or 0),
        })
    end
    return items
end

function buildShopItemsForBuyer(gang_id)
    local gang  = Config.Gangs[gang_id]
    local ws    = gang and gang.weapon_shop
    if not ws then return {} end
    local state = getShopState(gang_id)
    local items = {}
    for _, item in ipairs(ws.items or {}) do
        local s = state.items[item.weapon] or { stock = 0, price = 0 }
        table.insert(items, {
            label  = item.label,
            weapon = item.weapon,
            ammo   = item.ammo or 0,
            price  = s.price > 0 and s.price or (item.base_price or 0),
            stock  = s.stock,
        })
    end
    return items
end

-- ──────────────────────────────────────────────────────
-- shop push on player spawn (extend existing vRP:playerSpawn)
-- ──────────────────────────────────────────────────────
AddEventHandler("vRP:playerSpawn", function(user_id, src, first_spawn)
    -- Client-driven refresh only (playerSpawned + requestShopAccess)
    -- تجنب إرسال مبكر قد يتزامن مع تحميل اللاعب.
    return
end)

-- ──────────────────────────────────────────────────────
-- طلب خريطة المتاجر المفتوحة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:requestShopAccess")
AddEventHandler("gang:requestShopAccess", function()
    local src = source
    if not checkRate(src, "requestShopAccess", 2000) then return end
    pushShopAccessToPlayer(src)
end)

-- ──────────────────────────────────────────────────────
-- Admin: جلب نظرة عامة على المتاجر والخزائن القذرة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:getShopsOverview")
AddEventHandler("admin:getShopsOverview", function()
    local src = source
    if not checkRate(src, "adminGetShopsOverview", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "shop_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية هذا القسم")
        return
    end

    local list = {}
    local _shopIdx = 0
    for gang_id, gang in pairs(Config.Gangs) do
        _shopIdx = _shopIdx + 1
        local ws    = gang.weapon_shop
        local state = getShopState(gang_id)
        local items = {}
        for _, item in ipairs(ws and ws.items or {}) do
            local s = state.items[item.weapon] or { stock = 0, price = 0 }
            table.insert(items, {
                label  = item.label,
                weapon = item.weapon,
                stock  = s.stock,
                price  = s.price > 0 and s.price or (item.base_price or 0),
            })
        end
        table.insert(list, {
            gang_id       = gang_id,
            label         = gang.label,
            color         = gang.color or "#4d7fff",
            logo          = gang.logo  or "",
            shop_owned    = state.owned,
            shop_disabled = shopDisabledByAdmin[gang_id] == true,
            dirty_balance = getDirtyBalance(gang_id),
            items         = items,
        })
        if (_shopIdx % 3) == 0 then Wait(0) end
    end

    TriggerClientEvent("admin:shopsData", src, list)
end)

-- ──────────────────────────────────────────────────────
-- Admin: حساب الكنز المفقود — جلب بيانات كل العصابات
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:getTreasureStats")
AddEventHandler("admin:getTreasureStats", function()
    local src = source
    if not checkRate(src, "adminGetTreasureStats", 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "treasure_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية هذا القسم")
        return
    end

    local list = {}
    local _treasureIdx = 0
    for gang_id, gang in pairs(Config.Gangs) do
        _treasureIdx = _treasureIdx + 1
        table.insert(list, {
            gang_id = gang_id,
            label   = gang.label,
            color   = gang.color or "#4d7fff",
            logo    = gang.logo  or "",
            count   = dbGetTreasureBalance(gang_id),
        })
        if (_treasureIdx % 4) == 0 then Wait(0) end
    end

    table.sort(list, function(a, b) return (a.count or 0) > (b.count or 0) end)
    TriggerClientEvent("admin:treasureData", src, {
        list = list,
        has_point = specialDepositPoint ~= nil,
        point_label = formatPointLabel(specialDepositPoint),
    })
end)

RegisterNetEvent("admin:setTreasureDepositPoint")
AddEventHandler("admin:setTreasureDepositPoint", function()
    local src = source
    if not checkRate(src, "adminSetTreasureDepositPoint", 1200) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "treasure_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية تعديل نقطة الإيداع")
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر قراءة موقعك الحالي")
        return
    end

    local pos = GetEntityCoords(ped)
    if not pos then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذر تحديد النقطة")
        return
    end

    if not setSpecialDepositPoint({ x = pos.x, y = pos.y, z = pos.z }) then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "بيانات نقطة الإيداع غير صالحة")
        return
    end

    saveSpecialDepositPoint()
    broadcastSpecialDepositPoint()
    broadcastTreasureDepositPointToAdmins()

    TriggerClientEvent("gang:notify", src, "success", "تم", "تم تحديد/تحديث نقطة إيداع الكنز بنجاح")
end)

-- ──────────────────────────────────────────────────────
-- Admin: خصم عدد معين من كنز عصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:treasureDeduct")
AddEventHandler("admin:treasureDeduct", function(gang_id, amount)
    local src = source
    if not checkRate(src, "adminTreasureDeduct:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "treasure_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إدارة الكنز المفقود")
        return
    end

    gang_id = tostring(gang_id or "")
    amount  = tonumber(amount) or 0
    if gang_id == "" or amount <= 0 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "قيمة الخصم غير صحيحة")
        return
    end
    if not Config.Gangs[gang_id] then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "العصابة غير موجودة")
        return
    end

    local current = dbGetTreasureBalance(gang_id)
    if current <= 0 then
        TriggerClientEvent("admin:treasureUpdated", src, { gang_id = gang_id, count = 0 })
        broadcastTreasureAccountUpdate(gang_id)
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "رصيد الكنز لهذه العصابة يساوي صفر")
        return
    end

    local deductAmount = math.max(1, math.floor(amount))
    local newBalance = math.max(0, current - deductAmount)
    local appliedDeduct = current - newBalance
    dbSetTreasureBalance(gang_id, newBalance)
    TriggerClientEvent("admin:treasureUpdated", src, { gang_id = gang_id, count = newBalance })
    broadcastTreasureAccountUpdate(gang_id)

    local gangLabel = (Config.Gangs[gang_id] and Config.Gangs[gang_id].label) or gang_id
    TriggerClientEvent("gang:notify", src, "success", "تم الخصم", ("تم خصم %d من رصيد %s (المتبقي: %d)"):format(appliedDeduct, gangLabel, newBalance))
end)

-- ──────────────────────────────────────────────────────
-- Admin: تصفير كنز عصابة بالكامل
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:treasureReset")
AddEventHandler("admin:treasureReset", function(gang_id)
    local src = source
    if not checkRate(src, "adminTreasureReset:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "treasure_control") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إدارة الكنز المفقود")
        return
    end

    gang_id = tostring(gang_id or "")
    if gang_id == "" or not Config.Gangs[gang_id] then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "العصابة غير موجودة")
        return
    end

    local current = dbGetTreasureBalance(gang_id)
    dbSetTreasureBalance(gang_id, 0)
    TriggerClientEvent("admin:treasureUpdated", src, { gang_id = gang_id, count = 0 })
    broadcastTreasureAccountUpdate(gang_id)

    local gangLabel = (Config.Gangs[gang_id] and Config.Gangs[gang_id].label) or gang_id
    if current <= 0 then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", ("رصيد %s كان مصفّرًا بالفعل"):format(gangLabel))
    else
        TriggerClientEvent("gang:notify", src, "success", "تم التصفير", ("تم تصفير رصيد %s من %d إلى 0"):format(gangLabel, current))
    end
end)

-- ──────────────────────────────────────────────────────
-- Admin: تفعيل / تعطيل متجر مؤقت
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:toggleShop")
AddEventHandler("admin:toggleShop", function(gang_id)
    local src = source
    if not checkRate(src, "adminToggleShop:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "shop_control") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    local nowDisabled = not shopDisabledByAdmin[gang_id]
    shopDisabledByAdmin[gang_id] = nowDisabled or nil

    local action = nowDisabled and "تعطيل متجر مؤقت" or "إعادة تفعيل متجر"
    adminWebhookLog(action,
        ("‫**المسؤول:** %s [%d]\n**العصابة:** %s‬"):format(getUserName(uid), uid, gang.label),
        gang_id)

    local msg = nowDisabled and "تم إغلاق متجر " .. gang.label .. " مؤقتاً"
                             or "تم إعادة فتح متجر " .. gang.label
    TriggerClientEvent("gang:notify", src, nowDisabled and "warning" or "success", "تم", msg)
    TriggerClientEvent("admin:shopToggled", src, { gang_id = gang_id, disabled = nowDisabled == true })
end)

-- ──────────────────────────────────────────────────────
-- Admin: حذف ملكية متجر العصابة نهائياً
-- ──────────────────────────────────────────────────────
RegisterNetEvent("admin:deleteShop")
AddEventHandler("admin:deleteShop", function(gang_id)
    local src = source
    if not checkRate(src, "adminDeleteShop:" .. tostring(gang_id), 2000) then return end

    local uid = getUserId(src)
    if not uid or not hasAdminPerm(uid, "shop_control") then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    dbQueueWrite('DELETE FROM ahmad_gang WHERE row_type = ? AND gang_id = ? AND citizen_id = 0',
        { RT_SHOP_OWNED, gang_id }, "shop_delete_owned")
    dbQueueWrite('DELETE FROM ahmad_gang WHERE row_type = ? AND gang_id = ?',
        { RT_SHOP_ITEM, gang_id }, "shop_delete_items")

    shopStateCache[gang_id]      = { owned = false, items = {} }
    shopDisabledByAdmin[gang_id] = nil
    pushShopAccessAll()

    adminWebhookLog("حذف متجر عصابة نهائياً",
        ("‫**المسؤول:** %s [%d]\n**العصابة:** %s‬"):format(getUserName(uid), uid, gang.label),
        gang_id)
    TriggerClientEvent("gang:notify", src, "success", "تم الحذف", "تم حذف متجر " .. gang.label .. " نهائياً")
    TriggerClientEvent("admin:shopDeleted", src, { gang_id = gang_id })
end)

-- ──────────────────────────────────────────────────────
-- شراء المحل (من قائمة إدارة العصابة)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:purchaseShop")
AddEventHandler("gang:purchaseShop", function(gang_id)
    local src = source
    if not checkRate(src, "purchaseShop:" .. tostring(gang_id), 5000) then return end

    local uid = getUserId(src)
    if not uid then return end

    if not hasPerm(uid, gang_id, "shop_purchase") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية شراء المحل")
        return
    end

    local gang = Config.Gangs[gang_id]
    if not gang then return end
    local ws = gang.weapon_shop
    if not ws then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "لا يوجد إعداد متجر لهذه العصابة")
        return
    end

    if not gangOwnsTerritory(gang_id) then
        TriggerClientEvent("gang:notify", src, "warning", "منطقة غير مستحلة", "يجب استحلال منطقة أولاً قبل فتح متجر الأسلحة")
        return
    end

    local state = getShopState(gang_id)
    if state.owned then
        TriggerClientEvent("gang:notify", src, "warning", "تنبيه", "المتجر مفتوح بالفعل")
        return
    end
    Wait(0)

    -- تحقق من النقاط
    local requiredPoints = tonumber(ws.required_points) or 0
    local currentPoints  = dbGetPoints(gang_id)
    if currentPoints < requiredPoints then
        TriggerClientEvent("gang:notify", src, "error", "نقاط غير كافية",
            ("تحتاج %d نقطة — لديك %d فقط"):format(requiredPoints, currentPoints))
        return
    end

    -- خصم السعر من خزنة العصابة
    local buyCost = tonumber(ws.buy_cost) or 0
    if buyCost > 0 then
        local bal = getTreasuryBalance(gang_id)
        if bal < buyCost then
            TriggerClientEvent("gang:notify", src, "error", "رصيد الخزنة غير كافٍ",
                ("تحتاج %d$ في الخزنة"):format(buyCost))
            return
        end
        setTreasuryBalance(gang_id, bal - buyCost)
        Wait(0)
        addTreasuryLog(gang_id, "shop_purchase", buyCost, getUserName(uid), getCid(uid), "شراء متجر الأسلحة")
    end

    -- تفعيل المتجر
    dbSetShopOwned(gang_id)
    shopStateCache[gang_id] = { owned = true, items = (shopStateCache[gang_id] and shopStateCache[gang_id].items) or {} }

    -- بث تحديث البلبات لجميع اللاعبين
    pushShopAccessAll()

    webhookLog(gang_id, "شراء متجر الأسلحة",
        ("‫**المدير:** %s [%d]\n**التكلفة:** %s$‬"):format(getUserName(uid), uid, tostring(buyCost)),
        gang.color)

    local shopItems = buildShopItemsForManager(gang_id)
    TriggerClientEvent("gang:shopPurchased", src, { gang_id = gang_id, shop_items = shopItems })
    TriggerClientEvent("gang:notify", src, "success", "تم الشراء", "تم فتح متجر الأسلحة بنجاح!")
end)

-- ──────────────────────────────────────────────────────
-- جلب بيانات المتجر للمدير
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getShopManage")
AddEventHandler("gang:getShopManage", function(gang_id)
    local src = source
    if not checkRate(src, "getShopManage:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not hasPerm(uid, gang_id, "shop_view") and not hasPerm(uid, gang_id, "shop_manage") then return end

    local gang   = Config.Gangs[gang_id]
    local ws     = gang and gang.weapon_shop
    local state  = getShopState(gang_id)
    Wait(0)
    local points = dbGetPoints(gang_id)

    TriggerClientEvent("gang:shopManageData", src, {
        gang_id         = gang_id,
        owned           = state.owned,
        territory_owned = gangOwnsTerritory(gang_id),
        required_points = tonumber(ws and ws.required_points) or 0,
        buy_cost        = tonumber(ws and ws.buy_cost) or 0,
        current_points  = points,
        items           = buildShopItemsForManager(gang_id),
    })
end)

-- ──────────────────────────────────────────────────────
-- إعادة تعبئة مخزون سلاح (مدير)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:shopRestock")
AddEventHandler("gang:shopRestock", function(gang_id, weapon_hash)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "shopRestock:" .. tostring(gang_id), 2000) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not hasPerm(uid, gang_id, "shop_manage") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إدارة المتجر")
        return
    end

    local gang  = Config.Gangs[gang_id]
    local ws    = gang and gang.weapon_shop
    if not ws then return end

    if not gangOwnsTerritory(gang_id) then
        TriggerClientEvent("gang:notify", src, "warning", "منطقة غير مستحلة", "لا يمكنك إدارة المتجر قبل استحلال منطقة")
        return
    end

    local state = getShopState(gang_id)
    if not state.owned then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "المتجر لم يُفتح بعد")
        return
    end
    Wait(0)

    local itemCfg = nil
    for _, item in ipairs(ws.items or {}) do
        if item.weapon == weapon_hash then itemCfg = item; break end
    end
    if not itemCfg then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "السلاح غير موجود في إعدادات المتجر")
        return
    end

    local restockPrice  = tonumber(itemCfg.restock_price) or 0
    local restockAmount = tonumber(itemCfg.restock_amount) or 10
    local totalCost     = restockPrice * restockAmount

    if totalCost > 0 then
        local treasury = getTreasuryBalance(gang_id)
        if treasury < totalCost then
            TriggerClientEvent("gang:notify", src, "error", "رصيد الخزنة غير كافٍ",
                ("الخزنة تحتاج %d$ — الرصيد الحالي %d$"):format(totalCost, treasury))
            return
        end
        setTreasuryBalance(gang_id, treasury - totalCost)
        Wait(0)
        addTreasuryLog(gang_id, "withdraw", totalCost,
            getUserName(uid), uid,
            ("تعبئة مخزون: %s (+%d قطعة)"):format(itemCfg.label, restockAmount))
    end

    dbAddShopStock(gang_id, weapon_hash, restockAmount)

    if not shopStateCache[gang_id] then shopStateCache[gang_id] = { owned = true, items = {} } end
    local cur = shopStateCache[gang_id].items[weapon_hash] or { stock = 0, price = 0 }
    shopStateCache[gang_id].items[weapon_hash] = {
        stock = cur.stock + restockAmount,
        price = cur.price,
    }

    webhookLog(gang_id, "تعبئة مخزون",
        ("‫**المدير:** %s [%d]\n**السلاح:** %s\n**الكمية:** +%d\n**التكلفة:** %d$‬"):format(
            getUserName(uid), uid, itemCfg.label, restockAmount, totalCost),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تمت التعبئة",
        ("تم إضافة %d قطعة — التكلفة %d$"):format(restockAmount, totalCost))

    TriggerClientEvent("gang:shopManageData", src, {
        gang_id         = gang_id,
        owned           = true,
        territory_owned = gangOwnsTerritory(gang_id),
        required_points = tonumber(ws.required_points) or 0,
        buy_cost        = tonumber(ws.buy_cost) or 0,
        current_points  = dbGetPoints(gang_id),
        items           = buildShopItemsForManager(gang_id),
    })
    perfDone("event:gang:shopRestock", tPerf, "weapon=" .. tostring(weapon_hash))
end)

-- ──────────────────────────────────────────────────────
-- تعديل سعر سلاح (مدير)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:shopSetPrice")
AddEventHandler("gang:shopSetPrice", function(gang_id, weapon_hash, new_price)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "shopSetPrice:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid then return end
    if not hasPerm(uid, gang_id, "shop_manage") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إدارة المتجر")
        return
    end

    local gang  = Config.Gangs[gang_id]
    local ws    = gang and gang.weapon_shop
    new_price   = math.max(1, math.floor(tonumber(new_price) or 0))

    if not gangOwnsTerritory(gang_id) then
        TriggerClientEvent("gang:notify", src, "warning", "منطقة غير مستحلة", "لا يمكنك إدارة المتجر قبل استحلال منطقة")
        return
    end

    local itemCfg = nil
    for _, item in ipairs(ws and ws.items or {}) do
        if item.weapon == weapon_hash then itemCfg = item; break end
    end
    if not itemCfg then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "السلاح غير موجود")
        return
    end

    local state    = getShopState(gang_id)
    local curStock = (state.items[weapon_hash] or { stock = 0 }).stock
    dbUpsertShopItem(gang_id, weapon_hash, curStock, new_price)

    if not shopStateCache[gang_id] then shopStateCache[gang_id] = { owned = true, items = {} } end
    shopStateCache[gang_id].items[weapon_hash] = { stock = curStock, price = new_price }

    webhookLog(gang_id, "تعديل سعر سلاح",
        ("‫**المدير:** %s [%d]\n**السلاح:** %s\n**السعر الجديد:** %d$‬"):format(
            getUserName(uid), uid, itemCfg.label, new_price),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تم التعديل",
        ("%s — السعر الجديد: %d$"):format(itemCfg.label, new_price))

    TriggerClientEvent("gang:shopManageData", src, {
        gang_id         = gang_id,
        owned           = state.owned,
        territory_owned = gangOwnsTerritory(gang_id),
        required_points = tonumber(ws and ws.required_points) or 0,
        buy_cost        = tonumber(ws and ws.buy_cost) or 0,
        current_points  = dbGetPoints(gang_id),
        items           = buildShopItemsForManager(gang_id),
    })
    perfDone("event:gang:shopSetPrice", tPerf, "weapon=" .. tostring(weapon_hash))
end)

-- ──────────────────────────────────────────────────────
-- جلب قائمة الأسلحة للمشتري (عند الاقتراب من الماركر)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getShopItems")
AddEventHandler("gang:getShopItems", function(gang_id)
    local src = source
    if not checkRate(src, "getShopItems", 1000) then return end

    local state = getShopState(gang_id)
    if not state.owned then return end
    if shopDisabledByAdmin[gang_id] then
        TriggerClientEvent("gang:notify", src, "warning", "المتجر مغلق", "أغلق المسؤول هذا المتجر مؤقتاً")
        return
    end

    local gang = Config.Gangs[gang_id]
    TriggerClientEvent("gang:shopItemsData", src, {
        gang_id    = gang_id,
        gang_label = gang and gang.label or gang_id,
        gang_color = gang and gang.color or "#4d7fff",
        gang_logo  = gang and gang.logo  or "",
        items      = buildShopItemsForBuyer(gang_id),
    })
end)

-- ──────────────────────────────────────────────────────
-- شراء سلاح من المتجر (أي لاعب)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:buyWeapon")
AddEventHandler("gang:buyWeapon", function(gang_id, weapon_hash)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "buyWeapon", 2000) then return end

    local uid = getUserId(src)
    if not uid then return end

    local gang  = Config.Gangs[gang_id]
    local ws    = gang and gang.weapon_shop
    if not ws then return end

    local state = getShopState(gang_id)
    if not state.owned then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "المتجر غير مفتوح")
        return
    end
    if shopDisabledByAdmin[gang_id] then
        TriggerClientEvent("gang:notify", src, "warning", "المتجر مغلق", "أغلق المسؤول هذا المتجر مؤقتاً")
        return
    end

    weapon_hash = tostring(weapon_hash or "")
    if weapon_hash == "" or #weapon_hash > 64 then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "سلاح غير صالح")
        return
    end

    local itemCfg = nil
    for _, item in ipairs(ws.items or {}) do
        if item.weapon == weapon_hash then itemCfg = item; break end
    end
    if not itemCfg then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "السلاح غير موجود")
        return
    end

    local itemState = state.items[weapon_hash] or { stock = 0, price = 0 }
    if itemState.stock <= 0 then
        TriggerClientEvent("gang:notify", src, "error", "نفذ المخزون", itemCfg.label .. " — غير متوفر حالياً")
        return
    end

    local price = itemState.price > 0 and itemState.price or (itemCfg.base_price or 0)

    if price > 0 then
        local wallet = getWallet(uid)
        if wallet < price then
            TriggerClientEvent("gang:notify", src, "error", "رصيد غير كافٍ",
                ("السعر: %d$ — رصيدك: %d$"):format(price, wallet))
            return
        end
        if not deductWallet(uid, price) then
            TriggerClientEvent("gang:notify", src, "error", "خطأ", "تعذّر معالجة الدفع")
            return
        end
        Wait(0)
    end

    -- نسبة العائد للخزنة (أموال قذرة — تُضاف لرصيد الأموال القذرة)
    local revenuePercent = tonumber(ws.revenue_percent) or 0
    if revenuePercent > 0 and price > 0 then
        local revenue = math.floor(price * revenuePercent)
        if revenue > 0 then
            local newDirty = getDirtyBalance(gang_id) + revenue
            setDirtyBalance(gang_id, newDirty)
            addDirtyLog(gang_id, "revenue", revenue, getUserName(uid), getCid(uid),
                "مشترى: " .. (itemCfg.label or weapon_hash))
        end
    end

    -- تقليل المخزون
    local newStock = math.max(0, itemState.stock - 1)
    dbUpsertShopItem(gang_id, weapon_hash, newStock, itemState.price)
    if not shopStateCache[gang_id] then shopStateCache[gang_id] = { owned = true, items = {} } end
    shopStateCache[gang_id].items[weapon_hash] = { stock = newStock, price = itemState.price }

    -- إعطاء السلاح للمشتري
    TriggerClientEvent("gang:receiveWeapon", src, weapon_hash, tonumber(itemCfg.ammo) or 0)
    TriggerClientEvent("gang:notify", src, "success", "تم الشراء",
        ("%s — دفعت %d$"):format(itemCfg.label, price))

    -- لوق شراء السلاح
    webhookLog(gang_id, "شراء سلاح من المتجر",
        ("**المشتري:** %s [%d]\n**السلاح:** %s\n**السعر:** %d$"):format(
            getUserName(uid), uid, itemCfg.label, price),
        gang.color)

    -- تحديث واجهة المشتري بالمخزون الجديد
    TriggerClientEvent("gang:shopItemsData", src, {
        gang_id    = gang_id,
        gang_label = gang.label,
        gang_color = gang.color,
        items      = buildShopItemsForBuyer(gang_id),
    })
    perfDone("event:gang:buyWeapon", tPerf, "weapon=" .. tostring(weapon_hash))
end)

-- ════════════════════════════════════════════════════════
--  نظام لبس العصابة — Gang Outfit System (DB-only)
-- ════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────
-- مصدر البيانات: ahmad_gang_state (state_key='gang_outfits')
-- ──────────────────────────────────────────────────────
gangOutfits = {}  -- كاش في الذاكرة، يُحمّل مرة واحدة عند بدء السيرفر
gangOutfitsLoaded = false

function loadOutfitFile()
    if not dbStateStorageReady then return false end

    local dbData = dbLoadStateJson("gang_outfits")
    if type(dbData) == "table" then
        gangOutfits = dbData
        return true
    end

    gangOutfits = {}
    dbQueueSaveStateJson("gang_outfits", gangOutfits, "state_outfits")
    return true
end

function ensureOutfitFileLoaded()
    if gangOutfitsLoaded then return end
    if not loadOutfitFile() then return end
    gangOutfitsLoaded = true
    print("^2[ahmad_gangs] ^7Outfit state loaded — " .. (next(gangOutfits) and "has data" or "empty"))
end

function saveOutfitFile()
    if not dbQueueSaveStateJson("gang_outfits", gangOutfits, "state_outfits") then
        print("^1[ahmad_gangs] ^7ERROR: Failed to queue gang_outfits into DB")
    end
end

-- Prewarm lazy بعد الإقلاع لتقليل الضغط في أول tick.
CreateThread(function()
    while not dbStateStorageReady do
        Wait(120)
    end
    Wait(4000)
    ensureOutfitFileLoaded()
end)

-- ──────────────────────────────────────────────────────
-- gang:getOutfitData — جلب بيانات الـ outfit لعصابة
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:getOutfitData")
AddEventHandler("gang:getOutfitData", function(gang_id)
    local src = source
    if not checkRate(src, "getOutfitData:" .. tostring(gang_id), 1000) then return end

    local uid = getUserId(src)
    if not uid then return end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    ensureOutfitFileLoaded()

    -- يجب أن يملك أي صلاحية في العصابة
    if not hasAnyGangPermission(uid, gang) then return end

    local outfit = gangOutfits[gang_id]
    TriggerClientEvent("gang:outfitData", src, {
        gang_id    = gang_id,
        has_outfit = outfit ~= nil,
        outfit     = outfit,
    })
end)

-- ──────────────────────────────────────────────────────
-- gang:saveOutfit — حفظ سكن اللاعب كسكن العصابة (outfit_set)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:saveOutfit")
AddEventHandler("gang:saveOutfit", function(gang_id, outfitData)
    local src = source
    if not checkRate(src, "saveOutfit:" .. tostring(gang_id), 3000) then return end

    local uid = getUserId(src)
    if not uid then return end

    if not hasPerm(uid, gang_id, "outfit_set") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية تعيين سكن العصابة")
        return
    end
    if type(outfitData) ~= "table" then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "بيانات السكن غير صحيحة")
        return
    end
    if type(outfitData.components) ~= "table" or type(outfitData.props) ~= "table" then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "صيغة بيانات السكن غير صحيحة")
        return
    end

    local gang = Config.Gangs[gang_id]
    if not gang then return end

    ensureOutfitFileLoaded()

    local managerName = getUserName(uid)

    local safeComps = {}
    local safeProps = {}

    for i = 1, math.min(#outfitData.components, 12) do
        local c = outfitData.components[i]
        if type(c) == "table" then
            local comp = math.max(0, math.min(11, math.floor(tonumber(c.comp) or -1)))
            local drawable = math.max(0, math.floor(tonumber(c.drawable) or 0))
            local texture = math.max(0, math.floor(tonumber(c.texture) or 0))
            local palette = math.max(0, math.floor(tonumber(c.palette) or 0))
            if comp >= 0 then
                table.insert(safeComps, {
                    comp = comp,
                    drawable = drawable,
                    texture = texture,
                    palette = palette,
                })
            end
        end
    end

    for i = 1, math.min(#outfitData.props, 10) do
        local p = outfitData.props[i]
        if type(p) == "table" then
            local prop = math.max(0, math.min(9, math.floor(tonumber(p.prop) or -1)))
            local drawable = math.floor(tonumber(p.drawable) or -1)
            local texture = math.max(0, math.floor(tonumber(p.texture) or 0))
            if prop >= 0 then
                table.insert(safeProps, {
                    prop = prop,
                    drawable = drawable,
                    texture = texture,
                })
            end
        end
    end

    if #safeComps == 0 then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "بيانات السكن غير مكتملة")
        return
    end

    local okEncoded, encoded = pcall(json.encode, { components = safeComps, props = safeProps })
    if not okEncoded or type(encoded) ~= "string" or #encoded > 12000 then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "حجم بيانات السكن كبير جداً")
        return
    end

    -- احفظ في الكاش ثم اكتب للملف
    gangOutfits[gang_id] = {
        components = safeComps,
        props      = safeProps,
        set_by     = managerName,
        set_at     = os.date("%Y-%m-%d %H:%M:%S"),
    }
    saveOutfitFile()

    webhookLog(gang_id, "تعيين سكن العصابة",
        ("**المدير:** %s [%d]"):format(managerName, uid),
        gang.color)

    TriggerClientEvent("gang:notify", src, "success", "تم الحفظ", "تم حفظ سكن العصابة في قاعدة البيانات")
    TriggerClientEvent("gang:outfitData", src, {
        gang_id    = gang_id,
        has_outfit = true,
        outfit     = gangOutfits[gang_id],
    })
end)

-- ──────────────────────────────────────────────────────
-- gang:wearGangOutfit — لبس سكن العصابة (outfit_wear)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:wearGangOutfit")
AddEventHandler("gang:wearGangOutfit", function(gang_id)
    local src = source
    if not checkRate(src, "wearGangOutfit", 2000) then return end

    local uid = getUserId(src)
    if not uid then return end

    if not hasPerm(uid, gang_id, "outfit_wear") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية لبس سكن العصابة")
        return
    end

    ensureOutfitFileLoaded()

    local outfit = gangOutfits[gang_id]
    if not outfit then
        TriggerClientEvent("gang:notify", src, "warning", "لا يوجد سكن", "لم يُعيَّن سكن للعصابة بعد")
        return
    end

    webhookLog(gang_id, "لبس سكن العصابة",
        ("**العضو:** %s [%d]"):format(getUserName(uid), uid),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color)

    TriggerClientEvent("gang:applyOutfit", src, outfit)
end)

-- ──────────────────────────────────────────────────────
-- gang:dressNearbyPlayer — إلباس شخص قريب (outfit_dress_nearby)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:dressNearbyPlayer")
AddEventHandler("gang:dressNearbyPlayer", function(gang_id, cid)
    local src = source
    if not checkRate(src, "dressNearbyPlayer", 2000) then return end

    local uid = getUserId(src)
    if not uid then return end

    if not hasPerm(uid, gang_id, "outfit_dress_nearby") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إلباس الآخرين")
        return
    end

    ensureOutfitFileLoaded()

    local outfit = gangOutfits[gang_id]
    if not outfit then
        TriggerClientEvent("gang:notify", src, "warning", "لا يوجد سكن", "لم يُعيَّن سكن للعصابة بعد")
        return
    end

    cid = tonumber(cid)
    local info = cid and onlineCidMap[cid]
    if not info or not info.src then
        TriggerClientEvent("gang:notify", src, "error", "خطأ", "اللاعب غير متصل أو الهوية خاطئة")
        return
    end

    local targetSrc  = info.src
    local targetName = GetPlayerName(targetSrc) or tostring(cid)
    webhookLog(gang_id, "إلباس شخص سكن العصابة",
        ("**المدير:** %s [%d]\n**اللاعب:** %s [%d]"):format(getUserName(uid), uid, targetName, cid),
        Config.Gangs[gang_id] and Config.Gangs[gang_id].color)

    TriggerClientEvent("gang:applyOutfit", targetSrc, outfit, true)
    TriggerClientEvent("gang:notify", src, "success", "تم", "تم إلباس " .. targetName .. " سكن العصابة")
end)

-- ──────────────────────────────────────────────────────
-- gang:dressAllGang — إلباس جميع الأعضاء المتصلين (outfit_dress_all)
-- ──────────────────────────────────────────────────────
RegisterNetEvent("gang:dressAllGang")
AddEventHandler("gang:dressAllGang", function(gang_id)
    local tPerf = perfStart()
    local src = source
    if not checkRate(src, "dressAllGang", 5000) then return end

    local uid = getUserId(src)
    if not uid then return end

    if not hasPerm(uid, gang_id, "outfit_dress_all") then
        TriggerClientEvent("gang:notify", src, "error", "لا صلاحية", "لا تملك صلاحية إلباس العصابة كلها")
        return
    end

    ensureOutfitFileLoaded()

    local outfit = gangOutfits[gang_id]
    if not outfit then
        TriggerClientEvent("gang:notify", src, "warning", "لا يوجد سكن", "لم يُعيَّن سكن للعصابة بعد")
        return
    end

    local rows  = dbGetGangMemberCids(gang_id)
    Wait(0)
    local count = 0
    for _, row in ipairs(rows) do
        local cid = tonumber(row and row.citizen_id)
        local info = cid and onlineCidMap[cid] or nil
        if info and info.src then
            TriggerClientEvent("gang:applyOutfit", info.src, outfit)
            count = count + 1
            if (count % 60) == 0 then
                Wait(0)
            end
        end
    end

    local gang = Config.Gangs[gang_id]
    webhookLog(gang_id, "إلباس العصابة",
        ("**المدير:** %s [%d]\n**العدد:** %d عضو"):format(getUserName(uid), uid, count),
        gang and gang.color)

    perfDone("event:gang:dressAllGang", tPerf, "sent=" .. tostring(count))
    TriggerClientEvent("gang:notify", src, "success", "تم", "تم إلباس " .. count .. " عضو متصل")
end)

print("^2[ahmad_gangs] ^7Server loaded")


