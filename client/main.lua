local isOpen = false
local activeVehicle
local originalSnapshots = {}
local lastPreviewMeta
local currentCategoryId
local blips = {}

local function notify(msg, type)
    lib.notify({
        title = L('notify_title_tuning'),
        description = msg,
        type = type or 'inform'
    })
end

local function canAccessTuning()
    local cfg = Config.TuningAccess
    if not cfg or cfg.enabled ~= true then return true end
    if GetResourceState('qbx_core') ~= 'started' then return false end
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)
    if not ok or not data or not data.job then return false end
    local job = data.job
    if cfg.requireOnDuty and job.onduty == false then return false end
    for _, j in ipairs(cfg.jobs or {}) do
        if job.name == j then return true end
    end
    return false
end

local function createBlips()
    for _, loc in ipairs(Config.Locations) do
        if loc.blip and loc.blip.enabled then
            local blip = AddBlipForCoord(loc.trigger.x, loc.trigger.y, loc.trigger.z)
            SetBlipSprite(blip, loc.blip.sprite)
            SetBlipColour(blip, loc.blip.color)
            SetBlipScale(blip, loc.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(loc.label)
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
end

local function snapshotVehicleState(vehicle)
    SetVehicleModKit(vehicle, 0)
    local snap = { mods = {}, paint = {}, extras = {} }
    for modType = 0, 50 do
        snap.mods[modType] = GetVehicleMod(vehicle, modType)
    end
    snap.turbo = IsToggleModOn(vehicle, 18)
    snap.xenon = IsToggleModOn(vehicle, 22)
    snap.tireSmokeToggle = IsToggleModOn(vehicle, 20)

    local p, s = GetVehicleColours(vehicle)
    local pe, wc = GetVehicleExtraColours(vehicle)
    snap.paint.primary = p
    snap.paint.secondary = s
    snap.paint.pearl = pe
    snap.paint.wheelColor = wc

    snap.modColor1 = { GetVehicleModColor_1(vehicle) }
    snap.modColor2 = { GetVehicleModColor_2(vehicle) }
    snap.wheelType = GetVehicleWheelType(vehicle)
    snap.windowTint = GetVehicleWindowTint(vehicle)
    snap.plateIndex = GetVehicleNumberPlateTextIndex(vehicle)
    local r, g, b = GetVehicleTyreSmokeColor(vehicle)
    snap.tireSmokeColor = { r = r, g = g, b = b }
    if GetVehicleXenonLightsColor then
        snap.xenonColor = GetVehicleXenonLightsColor(vehicle)
    end
    return snap
end

local function restoreSnapshot(vehicle, snap)
    if not snap then return end
    SetVehicleModKit(vehicle, 0)
    for modType, value in pairs(snap.mods) do
        SetVehicleMod(vehicle, modType, value, false)
    end
    ToggleVehicleMod(vehicle, 18, snap.turbo)
    ToggleVehicleMod(vehicle, 22, snap.xenon)
    ToggleVehicleMod(vehicle, 20, snap.tireSmokeToggle)
    SetVehicleColours(vehicle, snap.paint.primary, snap.paint.secondary)
    SetVehicleExtraColours(vehicle, snap.paint.pearl, snap.paint.wheelColor)
    if snap.modColor1 then
        SetVehicleModColor_1(vehicle, snap.modColor1[1], snap.modColor1[2], snap.modColor1[3] or 0)
    end
    if snap.modColor2 then
        SetVehicleModColor_2(vehicle, snap.modColor2[1], snap.modColor2[2])
    end
    SetVehicleWheelType(vehicle, snap.wheelType)
    SetVehicleWindowTint(vehicle, snap.windowTint)
    SetVehicleNumberPlateTextIndex(vehicle, snap.plateIndex)
    if snap.tireSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, snap.tireSmokeColor.r, snap.tireSmokeColor.g, snap.tireSmokeColor.b)
    end
    if snap.xenonColor and SetVehicleXenonLightsColor then
        SetVehicleXenonLightsColor(vehicle, snap.xenonColor)
    end
end

local function openTuning()
    if isOpen then return end
    if not canAccessTuning() then
        notify(L('err_job_only'), 'error')
        return
    end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify(L('err_need_vehicle'), 'error')
        return
    end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        notify(L('err_need_driver'), 'error')
        return
    end

    activeVehicle = vehicle
    isOpen = true
    originalSnapshots = snapshotVehicleState(vehicle)

    SetVehicleEngineOn(vehicle, false, true, true)
    FreezeEntityPosition(vehicle, true)

    Camera.start(vehicle)

    SetVehicleModKit(vehicle, 0)
    local stepperMeta = {
        engine       = { modType = 11, max = GetNumVehicleMods(vehicle, 11) - 1, current = GetVehicleMod(vehicle, 11), prices = Config.StepperPrices.engine },
        transmission = { modType = 13, max = GetNumVehicleMods(vehicle, 13) - 1, current = GetVehicleMod(vehicle, 13), prices = Config.StepperPrices.transmission },
        brakes       = { modType = 12, max = GetNumVehicleMods(vehicle, 12) - 1, current = GetVehicleMod(vehicle, 12), prices = Config.StepperPrices.brakes },
        suspension   = { modType = 15, max = GetNumVehicleMods(vehicle, 15) - 1, current = GetVehicleMod(vehicle, 15), prices = Config.StepperPrices.suspension },
        armor        = { modType = 16, max = GetNumVehicleMods(vehicle, 16) - 1, current = GetVehicleMod(vehicle, 16), prices = Config.StepperPrices.armor },
        turbo        = { kind = 'toggle', modType = 18, current = IsToggleModOn(vehicle, 18), price = Config.StepperPrices.turbo }
    }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        currency = Config.Currency,
        categories = Config.Categories,
        localeTag = LocaleTagForIntl(),
        strings = LocalePackForNui(),
        infoText = {
            title = L('info_lsc_title'),
            subtitle = L('info_lsc_subtitle'),
        },
        stepperMeta = stepperMeta
    })
end

local function closeTuning(applied)
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Camera.stop()

    if activeVehicle and DoesEntityExist(activeVehicle) then
        if not applied then
            restoreSnapshot(activeVehicle, originalSnapshots)
        end
        FreezeEntityPosition(activeVehicle, false)
        SetVehicleEngineOn(activeVehicle, true, true, true)
    end
    activeVehicle = nil
    originalSnapshots = {}
    lastPreviewMeta = nil
    currentCategoryId = nil
end

CreateThread(function()
    createBlips()
    for _, loc in ipairs(Config.Locations) do
        lib.zones.sphere({
            coords = loc.trigger,
            radius = loc.radius or 2.0,
            debug = Config.Debug,
            inside = function()
                if isOpen then return end
                if not canAccessTuning() then
                    lib.hideTextUI()
                    return
                end
                local ped = PlayerPedId()
                if not IsPedInAnyVehicle(ped, false) then return end
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) ~= ped then return end

                lib.showTextUI(L('prompt_open'))
                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI()
                    openTuning()
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })
    end
end)

RegisterCommand('tuning', openTuning, false)

RegisterNUICallback('requestCategory', function(data, cb)
    if not activeVehicle then cb({}) return end
    currentCategoryId = data.categoryId
    local groups = Mods.buildCategory(activeVehicle, data.categoryId)
    SendNUIMessage({ action = 'setGroups', groups = groups })
    cb('ok')
end)

RegisterNUICallback('preview', function(data, cb)
    if not activeVehicle then cb('ok') return end
    Mods.applyOption(activeVehicle, data.meta)
    lastPreviewMeta = data.meta
    cb('ok')
end)

RegisterNUICallback('material', function(data, cb)
    if not activeVehicle then cb('ok') return end
    SetVehicleModKit(activeVehicle, 0)
    local r, g, b = GetVehicleColours(activeVehicle)
    local paint = data.material or 0
    SetVehicleModColor_1(activeVehicle, paint, 0, 0)
    cb('ok')
end)

RegisterNUICallback('customColor', function(data, cb)
    if not activeVehicle then cb('ok') return end
    local r, g, b = data.r or 0, data.g or 0, data.b or 0
    if data.target == 'primary' then
        SetVehicleCustomPrimaryColour(activeVehicle, r, g, b)
    else
        SetVehicleCustomSecondaryColour(activeVehicle, r, g, b)
    end
    cb('ok')
end)

RegisterNUICallback('stepperPreview', function(data, cb)
    if not activeVehicle then cb('ok') return end
    SetVehicleModKit(activeVehicle, 0)
    if data.kind == 'turbo' then
        ToggleVehicleMod(activeVehicle, 18, data.state == true or data.state == 'true' or data.level == 1)
        cb('ok') return
    end
    local mapping = { engine = 11, transmission = 13, brakes = 12, suspension = 15, armor = 16 }
    local modType = mapping[data.kind]
    if not modType then cb('ok') return end
    SetVehicleMod(activeVehicle, modType, tonumber(data.level) or -1, false)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeTuning(false)
    cb('ok')
end)

RegisterNUICallback('camRotate', function(data, cb)
    Camera.rotate(tonumber(data.dx) or 0, tonumber(data.dy) or 0)
    cb('ok')
end)

RegisterNUICallback('camZoom', function(data, cb)
    Camera.zoom(tonumber(data.delta) or 0)
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    if not activeVehicle then cb('ok') return end
    local total = tonumber(data.total) or 0
    local cart = data.cart or {}

    if total <= 0 and #cart == 0 then
        closeTuning(true)
        cb('ok')
        return
    end

    lib.callback('sp_tuning:server:pay', false, function(success, msg)
        if not success then
            notify(msg or L('err_payment_failed'), 'error')
            restoreSnapshot(activeVehicle, originalSnapshots)
            closeTuning(false)
            cb('ok')
            return
        end

        for _, item in ipairs(cart) do
            Mods.applyOption(activeVehicle, item.meta)
        end
        notify(L('success_tuning_done', Config.Currency, total), 'success')
        closeTuning(true)
        cb('ok')
    end, total)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
        if activeVehicle and DoesEntityExist(activeVehicle) then
            FreezeEntityPosition(activeVehicle, false)
            SetVehicleEngineOn(activeVehicle, true, true, true)
        end
        Camera.stop()
    end
    for _, b in ipairs(blips) do RemoveBlip(b) end
end)
