local bossOpen = false

local function closeBoss()
    if not bossOpen then return end
    bossOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'bossClose' })
end

local function openBossMenu()
    if bossOpen then return end
    local cfg = Config.BossMenu
    if not cfg or not cfg.enabled then return end

    lib.callback('sp_tuning:server:getBossDashboard', false, function(data)
        if not data then
            lib.notify({
                title = L('notify_title_shop'),
                description = L('boss_err_access'),
                type = 'error'
            })
            return
        end
        bossOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'bossOpen',
            data = data,
            localeTag = LocaleTagForIntl(),
            strings = LocalePackForNui()
        })
    end)
end

RegisterNUICallback('bossClose', function(_, cb)
    closeBoss()
    cb({ ok = true })
end)

RegisterNUICallback('bossWithdraw', function(data, cb)
    local amount = tonumber(data.amount) or 0
    lib.callback('sp_tuning:server:bossWithdraw', false, function(result)
        if result.ok and result.dashboard then
            SendNUIMessage({ action = 'bossData', data = result.dashboard })
            lib.notify({
                title = L('notify_title_shop'),
                description = L('boss_withdraw_done'),
                type = 'success'
            })
        elseif not result.ok and result.error then
            lib.notify({
                title = L('notify_title_shop'),
                description = result.error,
                type = 'error'
            })
        end
        cb(result or { ok = false })
    end, amount)
end)

if Config.BossMenu and Config.BossMenu.openCommand then
    RegisterCommand(Config.BossMenu.openCommand, function()
        openBossMenu()
    end, false)
end

CreateThread(function()
    local cfg = Config.BossMenu
    if not cfg or not cfg.enabled or not cfg.bossLocation then return end

    lib.zones.sphere({
        coords = cfg.bossLocation,
        radius = cfg.bossRadius or 2.0,
        debug = Config.Debug,
        inside = function()
            if bossOpen then return end
            lib.showTextUI(L('prompt_boss'))
            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                openBossMenu()
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if bossOpen then
        SetNuiFocus(false, false)
    end
end)
