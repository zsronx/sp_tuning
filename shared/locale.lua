local function activeLocaleCode()
    if Config and Config.Locale then
        return tostring(Config.Locale)
    end
    return 'en'
end

local function activePack()
    local code = activeLocaleCode()
    local pack = Locales and Locales[code]
    if pack then return pack end
    return Locales and Locales['en']
end

function L(key, ...)
    local pack = activePack()
    local fmtStr = pack and pack[key]
    if fmtStr == nil and Locales and Locales['en'] then
        fmtStr = Locales['en'][key]
    end
    if fmtStr == nil then
        return key
    end
    if select('#', ...) > 0 and type(fmtStr) == 'string' then
        return string.format(fmtStr, ...)
    end
    return fmtStr
end

function LPal(name, idx)
    local pack = activePack()
    local pals = pack and pack.Palettes
    if not pals or not pals[name] then return nil end
    local tbl = pals[name]
    if type(tbl) ~= 'table' then return nil end
    return tbl[idx]
end

function LocalePackForNui()
    local pack = activePack()
    if pack and pack.Nui then return pack.Nui end
    if Locales and Locales['en'] and Locales['en'].Nui then return Locales['en'].Nui end
    return {}
end

function LocaleTagForIntl()
    if activeLocaleCode() == 'de' then return 'de-DE' end
    return 'en-US'
end
