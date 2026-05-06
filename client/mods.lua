Mods = {}

local function priceFor(modType, index)
    local p = Config.Prices[modType]
    if type(p) == 'table' then
        return p[index] or p[#p] or Config.Prices.cosmetic
    end
    if type(p) == 'number' then return p end
    return Config.Prices.cosmetic
end

local function getModLabel(vehicle, modType, modIndex)
    if modIndex == -1 then
        return L('label_stock')
    end
    local label = GetLabelText(GetModTextLabel(vehicle, modType, modIndex)) or ''
    if label == 'NULL' or label == '' then
        return L('option_number', modIndex + 1)
    end
    return label
end

local function buildModTypeOptions(vehicle, modType, displayName)
    SetVehicleModKit(vehicle, 0)
    local num = GetNumVehicleMods(vehicle, modType)
    if num <= 0 then return nil end

    local current = GetVehicleMod(vehicle, modType)
    local options = {}
    options[#options + 1] = {
        id = modType * 1000 + 0,
        label = L('label_stock'),
        price = 0,
        current = current == -1,
        meta = { kind = 'mod', modType = modType, modIndex = -1 }
    }
    for i = 0, num - 1 do
        options[#options + 1] = {
            id = modType * 1000 + (i + 1),
            label = getModLabel(vehicle, modType, i),
            price = priceFor(modType, i + 1),
            current = current == i,
            meta = { kind = 'mod', modType = modType, modIndex = i }
        }
    end
    return {
        id = ('mod_%s'):format(modType),
        title = displayName,
        options = options
    }
end

local function buildToggleOption(vehicle, modType, displayName, priceKey)
    local isOn = IsToggleModOn(vehicle, modType)
    return {
        id = ('toggle_%s'):format(modType),
        title = displayName,
        options = {
            { id = modType * 1000 + 0, label = L('toggle_off'), price = 0, current = not isOn, meta = { kind = 'toggle', modType = modType, state = false } },
            { id = modType * 1000 + 1, label = L('toggle_on'), price = Config.Prices[priceKey] or Config.Prices.cosmetic, current = isOn, meta = { kind = 'toggle', modType = modType, state = true } },
        }
    }
end

function Mods.buildCategory(vehicle, categoryId)
    local groups = {}

    if categoryId == 'bodykit' then
        local modTypes = {
            { 0, L('body_spoiler') }, { 1, L('body_front_bumper') }, { 2, L('body_rear_bumper') },
            { 3, L('body_side_skirt') }, { 4, L('body_exhaust') }, { 5, L('body_frame') },
            { 6, L('body_grille') }, { 7, L('body_hood') }, { 8, L('body_fender') },
            { 9, L('body_right_fender') }, { 10, L('body_roof') }, { 27, L('body_livery') },
        }
        for _, entry in ipairs(modTypes) do
            local group = buildModTypeOptions(vehicle, entry[1], entry[2])
            if group then groups[#groups + 1] = group end
        end

    elseif categoryId == 'paint' then
        local currentPrimary, currentSecondary = GetVehicleColours(vehicle)
        local pearl, wheelColor = GetVehicleExtraColours(vehicle)
        local paintGroups = {
            { L('paint_primary'), 'primary', currentPrimary },
            { L('paint_secondary'), 'secondary', currentSecondary },
            { L('paint_pearl'), 'pearl', pearl },
            { L('paint_wheel'), 'wheelColor', wheelColor },
        }
        for _, pg in ipairs(paintGroups) do
            local opts = {}
            for i = 0, 159 do
                opts[#opts + 1] = {
                    id = i,
                    label = L('paint_swatch', i),
                    price = Config.Prices.paint,
                    current = pg[3] == i,
                    meta = { kind = 'paint', target = pg[2], color = i }
                }
            end
            groups[#groups + 1] = { id = 'paint_' .. pg[2], title = pg[1], options = opts }
        end

    elseif categoryId == 'wheels' then
        SetVehicleModKit(vehicle, 0)
        local currentType = GetVehicleWheelType(vehicle)
        local typeLabels = {
            [0] = 'Sport', [1] = 'Muscle', [2] = 'Lowrider', [3] = 'SUV',
            [4] = 'Offroad', [5] = 'Tuner', [6] = 'Bikes', [7] = 'High End',
            [8] = 'Benny\'s Original', [9] = 'Benny\'s Bespoke', [10] = 'Open Wheel',
            [11] = 'Street', [12] = 'Track'
        }
        local typeOpts = {}
        for wt, label in pairs(typeLabels) do
            typeOpts[#typeOpts + 1] = {
                id = wt,
                label = label,
                price = 500,
                current = wt == currentType,
                meta = { kind = 'wheelType', wheelType = wt }
            }
        end
        table.sort(typeOpts, function(a, b) return a.id < b.id end)
        groups[#groups + 1] = { id = 'wheel_type', title = L('group_wheel_type'), options = typeOpts }

        local wheelGroup = buildModTypeOptions(vehicle, 23, L('group_wheel_style'))
        if wheelGroup then groups[#groups + 1] = wheelGroup end

    elseif categoryId == 'suspension' then
        local g = buildModTypeOptions(vehicle, 15, L('perf_suspension'))
        if g then groups[#groups + 1] = g end

    elseif categoryId == 'performance' then
        local perf = {
            { 11, L('perf_engine') }, { 12, L('perf_brakes') }, { 13, L('perf_transmission') }, { 16, L('perf_armor') },
        }
        for _, e in ipairs(perf) do
            local g = buildModTypeOptions(vehicle, e[1], e[2])
            if g then groups[#groups + 1] = g end
        end
        groups[#groups + 1] = buildToggleOption(vehicle, 18, L('perf_turbo'), 18)

    elseif categoryId == 'lights' then
        groups[#groups + 1] = buildToggleOption(vehicle, 22, L('perf_xenon'), 'xenon')

        local xenonOpts = {}
        local currentXenon = GetVehicleXenonLightsColor and GetVehicleXenonLightsColor(vehicle) or -1
        for id = -1, 12 do
            local label = LPal('xenon', id) or ('#' .. tostring(id))
            xenonOpts[#xenonOpts + 1] = {
                id = id,
                label = label,
                price = Config.Prices.xenon,
                current = id == currentXenon,
                meta = { kind = 'xenonColor', color = id }
            }
        end
        table.sort(xenonOpts, function(a, b) return a.id < b.id end)
        groups[#groups + 1] = { id = 'xenon_color', title = L('group_xenon_color'), options = xenonOpts }

    elseif categoryId == 'plate' then
        local currentTint = GetVehicleWindowTint(vehicle)
        local tintOpts = {}
        for id = 0, 5 do
            local label = LPal('window_tint', id) or ('#' .. tostring(id))
            tintOpts[#tintOpts + 1] = {
                id = id,
                label = label,
                price = Config.Prices.window,
                current = id == currentTint,
                meta = { kind = 'windowTint', tint = id }
            }
        end
        table.sort(tintOpts, function(a, b) return a.id < b.id end)
        groups[#groups + 1] = { id = 'window_tint', title = L('group_window_tint'), options = tintOpts }

        local plateOpts = {}
        local currentPlate = GetVehicleNumberPlateTextIndex(vehicle)
        for i = 0, 5 do
            plateOpts[#plateOpts + 1] = {
                id = i,
                label = L('plate_style', i + 1),
                price = Config.Prices[62] or 1000,
                current = i == currentPlate,
                meta = { kind = 'plateIndex', index = i }
            }
        end
        groups[#groups + 1] = { id = 'plate_index', title = L('group_plate_index'), options = plateOpts }

    elseif categoryId == 'extras' then
        local g = buildModTypeOptions(vehicle, 14, L('group_horn'))
        if g then groups[#groups + 1] = g end
        local ts = buildModTypeOptions(vehicle, 20, L('group_tire_smoke'))
        if ts then groups[#groups + 1] = ts end

        local tsRgb = {
            { 255, 255, 255 }, { 0, 0, 0 }, { 255, 0, 0 },
            { 0, 255, 0 }, { 0, 0, 255 }, { 255, 255, 0 },
            { 255, 128, 0 }, { 255, 0, 255 },
        }
        local tsOpts = {}
        for i, c in ipairs(tsRgb) do
            tsOpts[#tsOpts + 1] = {
                id = i,
                label = LPal('tire_smoke', i) or ('Smoke ' .. tostring(i)),
                price = Config.Prices.tireSmoke,
                current = false,
                meta = { kind = 'tireSmokeColor', r = c[1], g = c[2], b = c[3] }
            }
        end
        groups[#groups + 1] = { id = 'tire_smoke_color', title = L('group_tire_smoke_color'), options = tsOpts }
    end

    return groups
end

function Mods.applyOption(vehicle, meta)
    if not meta then return end
    SetVehicleModKit(vehicle, 0)

    local kind = meta.kind
    if kind == 'mod' then
        SetVehicleMod(vehicle, meta.modType, meta.modIndex, false)
    elseif kind == 'toggle' then
        ToggleVehicleMod(vehicle, meta.modType, meta.state and true or false)
    elseif kind == 'wheelType' then
        SetVehicleWheelType(vehicle, meta.wheelType)
        SetVehicleMod(vehicle, 23, 0, false)
    elseif kind == 'paint' then
        local p, s = GetVehicleColours(vehicle)
        local pe, wc = GetVehicleExtraColours(vehicle)
        if meta.target == 'primary' then
            SetVehicleColours(vehicle, meta.color, s)
        elseif meta.target == 'secondary' then
            SetVehicleColours(vehicle, p, meta.color)
        elseif meta.target == 'pearl' then
            SetVehicleExtraColours(vehicle, meta.color, wc)
        elseif meta.target == 'wheelColor' then
            SetVehicleExtraColours(vehicle, pe, meta.color)
        end
    elseif kind == 'xenonColor' then
        if SetVehicleXenonLightsColor then
            SetVehicleXenonLightsColor(vehicle, meta.color)
        end
    elseif kind == 'windowTint' then
        SetVehicleWindowTint(vehicle, meta.tint)
    elseif kind == 'plateIndex' then
        SetVehicleNumberPlateTextIndex(vehicle, meta.index)
    elseif kind == 'tireSmokeColor' then
        SetVehicleTyreSmokeColor(vehicle, meta.r, meta.g, meta.b)
    elseif kind == 'stepperMod' then
        if meta.stepperKind == 'turbo' then
            ToggleVehicleMod(vehicle, 18, meta.state == true)
        else
            local mapping = { engine = 11, transmission = 13, brakes = 12, suspension = 15, armor = 16 }
            local modType = mapping[meta.stepperKind]
            if modType then
                SetVehicleMod(vehicle, modType, tonumber(meta.level) or -1, false)
            end
        end
    end
end

function Mods.snapshot(vehicle, meta)
    if not meta then return nil end
    SetVehicleModKit(vehicle, 0)
    if meta.kind == 'mod' then
        return { kind = 'mod', modType = meta.modType, modIndex = GetVehicleMod(vehicle, meta.modType) }
    elseif meta.kind == 'toggle' then
        return { kind = 'toggle', modType = meta.modType, state = IsToggleModOn(vehicle, meta.modType) }
    elseif meta.kind == 'wheelType' then
        return { kind = 'wheelType', wheelType = GetVehicleWheelType(vehicle) }
    elseif meta.kind == 'paint' then
        local p, s = GetVehicleColours(vehicle)
        local pe, wc = GetVehicleExtraColours(vehicle)
        local color = p
        if meta.target == 'secondary' then color = s
        elseif meta.target == 'pearl' then color = pe
        elseif meta.target == 'wheelColor' then color = wc end
        return { kind = 'paint', target = meta.target, color = color }
    elseif meta.kind == 'xenonColor' then
        return { kind = 'xenonColor', color = GetVehicleXenonLightsColor and GetVehicleXenonLightsColor(vehicle) or -1 }
    elseif meta.kind == 'windowTint' then
        return { kind = 'windowTint', tint = GetVehicleWindowTint(vehicle) }
    elseif meta.kind == 'plateIndex' then
        return { kind = 'plateIndex', index = GetVehicleNumberPlateTextIndex(vehicle) }
    elseif meta.kind == 'tireSmokeColor' then
        local r, g, b = GetVehicleTyreSmokeColor(vehicle)
        return { kind = 'tireSmokeColor', r = r, g = g, b = b }
    end
end
