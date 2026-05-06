local function resolvePlayer(source)
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayer(source)
    end
    return nil
end

local function playerCanTune(source)
    local cfg = Config.TuningAccess
    if not cfg or cfg.enabled ~= true then return true end
    local player = resolvePlayer(source)
    if not player or not player.PlayerData.job then return false end
    local job = player.PlayerData.job
    if cfg.requireOnDuty and job.onduty == false then return false end
    for _, j in ipairs(cfg.jobs or {}) do
        if job.name == j then return true end
    end
    return false
end

local function removeMoney(player, amount)
    if Config.PaymentAccount == 'cash_or_bank' then
        return player.Functions.RemoveMoney('cash', amount, 'sp-tuning')
            or player.Functions.RemoveMoney('bank', amount, 'sp-tuning')
    end
    return player.Functions.RemoveMoney(Config.PaymentAccount, amount, 'sp-tuning')
end

local profitLog = {}

local function playerDisplayName(src)
    local p = resolvePlayer(src)
    if not p or not p.PlayerData.charinfo then return GetPlayerName(src) or ('ID %s'):format(src) end
    local c = p.PlayerData.charinfo
    return ('%s %s'):format(c.firstname or '', c.lastname or '')
end

local function societyAdd(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local acc = Config.BossMenu and Config.BossMenu.societyAccount or 'mechanic'
    if GetResourceState('Renewed-Banking') ~= 'started' then
        print(('[sp_tuning] Renewed-Banking nicht gestartet – %s $ nicht gebucht.'):format(amount))
        return false
    end
    local ok, added = pcall(function()
        return exports['Renewed-Banking']:addAccountMoney(acc, amount)
    end)
    if not ok or added ~= true then
        print(('[sp_tuning] Firmenkonto "%s": Buchung von %s $ fehlgeschlagen (Konto fehlt?).'):format(acc, amount))
        return false
    end
    return true
end

local function societyBalance()
    local acc = Config.BossMenu and Config.BossMenu.societyAccount or 'mechanic'
    if GetResourceState('Renewed-Banking') ~= 'started' then return 0 end
    local ok, bal = pcall(function()
        return exports['Renewed-Banking']:getAccountMoney(acc)
    end)
    if ok and type(bal) == 'number' then return bal end
    return 0
end

local function logTuningSale(source, amount)
    table.insert(profitLog, 1, {
        ts = os.time(),
        amount = amount,
        customer = playerDisplayName(source),
    })
    while #profitLog > 80 do
        table.remove(profitLog)
    end
end

local function startOfToday()
    local t = os.date('*t')
    return os.time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
end

local function startOfWeek()
    local t = os.date('*t')
    local day = t.wday - 1
    if day == 0 then day = 7 end
    local midnight = os.time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
    return midnight - (day - 1) * 86400
end

local function sumSince(entries, sinceTs)
    local n = 0
    for _, e in ipairs(entries) do
        if e.ts >= sinceTs then n = n + (e.amount or 0) end
    end
    return n
end

local function isMechanicBoss(source)
    local cfg = Config.BossMenu
    if not cfg or not cfg.enabled then return false end
    local p = resolvePlayer(source)
    if not p then return false end
    local job = p.PlayerData.job
    if not job or job.name ~= cfg.job or not job.isboss then return false end
    return true
end

local function buildBossDashboard()
    local today0 = startOfToday()
    local week0 = startOfWeek()
    local list = {}
    for i = 1, math.min(20, #profitLog) do
        list[#list + 1] = profitLog[i]
    end
    return {
        currency = Config.Currency,
        balance = societyBalance(),
        today = sumSince(profitLog, today0),
        week = sumSince(profitLog, week0),
        transactions = list,
    }
end

lib.callback.register('sp_tuning:server:getBossDashboard', function(source)
    if not isMechanicBoss(source) then return nil end
    return buildBossDashboard()
end)

lib.callback.register('sp_tuning:server:bossWithdraw', function(source, amount)
    if not isMechanicBoss(source) then
        return { ok = false, error = L('boss_err_permission') }
    end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then
        return { ok = false, error = L('boss_err_invalid_amount') }
    end
    local acc = Config.BossMenu.societyAccount
    if GetResourceState('Renewed-Banking') ~= 'started' then
        return { ok = false, error = L('boss_err_no_banking') }
    end
    local bal = societyBalance()
    if amount > bal then
        return { ok = false, error = L('boss_err_low_balance') }
    end
    local okRm, removed = pcall(function()
        return exports['Renewed-Banking']:removeAccountMoney(acc, amount)
    end)
    if not okRm or removed ~= true then
        return { ok = false, error = L('boss_err_charge') }
    end
    local p = resolvePlayer(source)
    if not p then
        exports['Renewed-Banking']:addAccountMoney(acc, amount)
        return { ok = false, error = L('boss_err_player_nf') }
    end
    local to = Config.BossMenu.withdrawTo == 'cash' and 'cash' or 'bank'
    p.Functions.AddMoney(to, amount, 'werkstatt-auszahlung')
    return { ok = true, dashboard = buildBossDashboard() }
end)

lib.callback.register('sp_tuning:server:pay', function(source, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then
        return true
    end

    if not playerCanTune(source) then
        return false, L('pay_err_no_access')
    end

    local player = resolvePlayer(source)
    if not player then
        return false, L('pay_err_player')
    end

    if not removeMoney(player, amount) then
        return false, L('pay_err_money')
    end

    if Config.BossMenu and Config.BossMenu.enabled then
        local cut = math.floor(amount * (tonumber(Config.BossMenu.societyCut) or 1.0))
        if cut > 0 and societyAdd(cut) then
            logTuningSale(source, cut)
        end
    end

    return true
end)
