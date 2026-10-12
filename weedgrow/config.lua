Config = {}

Config.InteriorModel = 'm23_1_dlc_int_02_m23_1'

Config.Coords = {
    pot   = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
    table = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
    rack  = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
    tub   = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
    panel = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
}

Config.GrowthStages = {
    [1] = { model = 'bkr_prop_weed_01_small_01c', label = 'Small',  growTime = 300 },
    [2] = { model = 'sf_prop_sf_weed_med_01a',    label = 'Medium', growTime = 420 },
    [3] = { model = 'bkr_prop_weed_lrg_01a',      label = 'Large',  growTime = 0 },
}

Config.Times = {
    plant   = 5,
    water   = 3,
    harvest = 4,
    dry     = 8,
    pack    = 4,
}

Config.Items = {
    seed       = 'weed_ak47_seed',
    fertilizer = 'weed_nutrition',
    weedRaw    = 'weed',
    weedDried  = 'dried_weed',
    weedPack   = 'packagedweed',
    emptyBag   = 'empty_weed_bag',
    water      = 'water',
}

Config.DryPropModel = 'bkr_prop_weed_drying_01a'
Config.DryTime = 120000 -- 2 min in ms

Config.StorageName = 'weed_tub'

Config.PanelAccess = {
    job = 'janitor',
    minGrade = 1,
    allowAdmin = true,
}   