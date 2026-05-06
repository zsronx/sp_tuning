Config = {}

Config.Debug = false

Config.Locale = 'en'

Config.Currency = '$'

Config.TuningAccess = {
    enabled = true,
    jobs = { 'mechanic' },
    requireOnDuty = true,
}

Config.BossMenu = {
    enabled = true,
    job = 'mechanic',
    societyAccount = 'mechanic',
    societyCut = 1.0,
    withdrawTo = 'bank',
    openCommand = 'werkstattchef',
    bossLocation = vec3(-347.3362, -133.4024, 39.0097),
    bossRadius = 2.0,
}
Config.PaymentAccount = 'bank'

Config.Locations = {
    {
        label = 'LS Customs - Innenstadt',
        blip = { enabled = true, sprite = 72, color = 17, scale = 0.8 },
        trigger = vec3(-362.14, -131.79, 38.69),
        radius = 2.0,
        vehicleSpot = vec4(-339.18, -137.06, 38.69, 180.0),
        cameraAnchor = vec3(-339.18, -137.06, 39.4)
    },
    {
        label = 'LS Customs - Airport',
        blip = { enabled = true, sprite = 72, color = 17, scale = 0.8 },
        trigger = vec3(-336.8965, -136.8862, 38.5984),
        radius = 2.0,
        vehicleSpot = vec4(-336.8965, -136.8862, 38.5984, 269.1090),
        cameraAnchor = vec3(-336.8965, -136.8862, 39.4)
    },
    {
        label = 'LS Customs - Sandy Shores',
        blip = { enabled = true, sprite = 72, color = 17, scale = 0.8 },
        trigger = vec3(1181.46, 2640.23, 37.82),
        radius = 2.0,
        vehicleSpot = vec4(1181.46, 2640.23, 37.82, 0.0),
        cameraAnchor = vec3(1181.46, 2640.23, 38.5)
    }
}

Config.Camera = {
    minDist = 3.0,
    maxDist = 9.0,
    defaultDist = 5.5,
    defaultHeight = 0.6,
    rotateSpeed = 0.4,
    zoomSpeed = 0.5,
    autoRotateSpeed = 0.15
}

Config.Categories = {
    { id = 'bodykit',     label = 'Body Kit' },
    { id = 'paint',       label = 'Paint' },
    { id = 'wheels',      label = 'Wheels' },
    { id = 'suspension',  label = 'Suspension' },
    { id = 'performance', label = 'Performance' },
    { id = 'lights',      label = 'Lights' },
    { id = 'plate',       label = 'Plate' },
    { id = 'extras',      label = 'Extras' }
}

Config.Prices = {
    [1] = 2500,
    [2] = 4500,
    [3] = 4500,
    [4] = 3500,
    [5] = 4000,
    [6] = 3500,
    [7] = 2500,
    [8] = 5000,
    [9] = 2500,
    [10] = 2500,
    [27] = 3500,
    [28] = 1000,
    [14] = 4500,
    [22] = 2000,
    [23] = 3000,
    [24] = 3000,
    [25] = 1500,
    [26] = 1500,
    [34] = 1500,
    [35] = 1500,
    [37] = 1500,
    [38] = 1500,
    [39] = 1500,
    [40] = 1500,
    [41] = 1500,
    [42] = 1500,
    [43] = 1500,
    [44] = 1500,
    [45] = 1500,
    [46] = 1500,
    [47] = 1500,
    [48] = 5000,
    [49] = 2000,
    [50] = 2000,
    [51] = 2000,
    [52] = 2000,
    [53] = 2000,
    [54] = 2000,
    [55] = 2000,

    [11] = 12000,
    [12] = 5000,
    [13] = 8000,
    [15] = 4500,
    [16] = 7500,
    [18] = 10000,
    [20] = 1500,
    [62] = 1000,
}

Config.Prices.cosmetic = 1500
Config.Prices.paint = 1000
Config.Prices.neon = 2000
Config.Prices.tireSmoke = 1500
Config.Prices.window = 750
Config.Prices.xenon = 2500

Config.StepperPrices = {
    engine       = { 12000, 22000, 38000, 60000 },
    transmission = {  8000, 16000, 28000 },
    brakes       = {  5000, 10000, 18000 },
    suspension   = {  4000,  8000, 14000, 22000, 32000 },
    armor        = {  4500,  9000, 15000, 22000, 32000 },
    turbo        = 18000,
}
