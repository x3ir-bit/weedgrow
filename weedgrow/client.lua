local QBCore = exports['qb-core']:GetCoreObject()

local props = {}
local dryProps = {}
local busy = false

-- ============================================================
-- UTILS
-- ============================================================

RegisterCommand('tpweed', function()
    local interiorID = 291329
    LoadInterior(interiorID)
    while not IsInteriorReady(interiorID) do
        Wait(0)
    end
    SetEntityCoords(PlayerPedId(), 1200.0, -3250.0, -50.0, false, false, false, true)
end, false)   

local function spawnProp(model, coords, heading)
    local hash = type(model) == 'string' and joaat(model) or model
    lib.requestModel(hash)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityHeading(obj, heading or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetEntityCollision(obj, true, true)
    return obj
end   

local function deleteProp(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function addPotTarget(entity)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'weed_pot',
            icon = 'fa-solid fa-seedling',
            label = 'Weed Pot',
            distance = 2.5,
            canInteract = function()
                return not busy
            end,
            onSelect = function(data)
                openPotMenu(data.entity)
            end,
        },
    })
end

-- ============================================================
-- SPAWN INITIAL PROPS
-- ============================================================

local function spawnAllProps()
    -- Pot
    local c = Config.Coords.pot
    local potEntity = spawnProp('bkr_prop_weed_plantpot_stack_01b', c, c.heading)
    props.pot = { entity = potEntity, model = 'bkr_prop_weed_plantpot_stack_01b', stage = 0, watered = false, coords = c, heading = c.heading }
    addPotTarget(potEntity)

    -- Table
    local tc = Config.Coords.table
    local tableEntity = spawnProp('bkr_prop_weed_table_01a', tc, tc.heading)
    exports.ox_target:addLocalEntity(tableEntity, {
        {
            name = 'weed_table',
            icon = 'fa-solid fa-box',
            label = 'Pack Weed',
            distance = 2.5,
            canInteract = function()
                return not busy
            end,
            onSelect = function()
                startPacking()
            end,
        },
    })

    -- Rack
    local rc = Config.Coords.rack
    local rackEntity = spawnProp('bkr_prop_weed_drying_01a', rc, rc.heading)
    exports.ox_target:addLocalEntity(rackEntity, {
        {
            name = 'weed_rack',
            icon = 'fa-solid fa-wind',
            label = 'Dry Weed',
            distance = 2.5,
            canInteract = function()
                return not busy
            end,
            onSelect = function()
                startDrying()
            end,
        },
        {
            name = 'weed_rack_collect',
            icon = 'fa-solid fa-hand',
            label = 'Collect Dried Weed',
            distance = 2.5,
            canInteract = function()
                for _, dp in ipairs(dryProps) do
                    if dp.ready then return true end
                end
                return false
            end,
            onSelect = function()
                collectDried()
            end,
        },
    })

    -- Storage tub
    local stc = Config.Coords.tub
    local tubEntity = spawnProp('prop_weed_tub_01', stc, stc.heading)
    exports.ox_target:addLocalEntity(tubEntity, {
        {
            name = 'weed_tub',
            icon = 'fa-solid fa-box-open',
            label = 'Open Storage',
            distance = 2.5,
            onSelect = function()
                exports.ox_inventory:openInventory('stash', Config.StorageName)
            end,
        },
    })

    -- Security panel
    local pc = Config.Coords.panel
    local panelEntity = spawnProp('hei_prop_hei_securitypanel', pc, pc.heading)
    exports.ox_target:addLocalEntity(panelEntity, {
        {
            name = 'weed_panel',
            icon = 'fa-solid fa-sliders',
            label = 'Control Panel',
            distance = 2.5,
            canInteract = function()
                local player = QBCore.Functions.GetPlayerData()
                if Config.PanelAccess.allowAdmin and player.job and player.job.name == 'admin' then return true end
                return player.job and player.job.name == Config.PanelAccess.job and player.job.grade >= Config.PanelAccess.minGrade
            end,
            onSelect = function()
                openPanelUI()
            end,
        },
    })
end

-- ============================================================
-- POT MENU
-- ============================================================

local function getPotByEntity(entity)
    for _, p in pairs(props) do
        if p.entity == entity then return p end
    end
    return nil
end

local function openPotMenu(entity)
    local pot = getPotByEntity(entity)
    if not pot then return end

    local options = {}

    if pot.stage == 0 then
        table.insert(options, {
            title = 'Plant Seed',
            icon = 'fa-solid fa-seedling',
            onSelect = function()
                plantSeed(pot)
            end,
        })
    elseif pot.stage > 0 and pot.stage < #Config.GrowthStages then
        if not pot.watered then
            table.insert(options, {
                title = 'Water Plant',
                icon = 'fa-solid fa-droplet',
                onSelect = function()
                    waterPlant(pot)
                end,
            })
        else
            table.insert(options, {
                title = ('Growing... (%s stage)'):format(Config.GrowthStages[pot.stage].label),
                icon = 'fa-solid fa-clock',
            })
        end
    elseif pot.stage == #Config.GrowthStages then
        table.insert(options, {
            title = 'Harvest Weed',
            icon = 'fa-solid fa-hand',
            onSelect = function()
                harvestWeed(pot)
            end,
        })
    end

    lib.showContext('weed_pot_menu', options)
end

-- ============================================================
-- PLANT SEED
-- ============================================================

local function plantSeed(pot)
    local hasSeed = exports.ox_inventory:Search('count', Config.Items.seed) >= 1
    local hasFert = exports.ox_inventory:Search('count', Config.Items.fertilizer) >= 1

    if not hasFert then
        lib.notify({ title = 'Weed', description = 'You need fertilizer!', type = 'error' })
        return
    end
    if not hasSeed then
        lib.notify({ title = 'Weed', description = 'You need a seed!', type = 'error' })
        return
    end

    busy = true
    lib.progressBar({
        duration = Config.Times.plant * 1000,
        label = 'Planting seed...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        onCompleted = function()
            busy = false
            exports.ox_inventory:RemoveItem(Config.Items.seed, 1)
            exports.ox_inventory:RemoveItem(Config.Items.fertilizer, 1)

            exports.ox_target:removeLocalEntity(pot.entity)
            deleteProp(pot.entity)

            local stage1 = Config.GrowthStages[1]
            local newEntity = spawnProp(stage1.model, pot.coords, pot.heading)
            pot.entity = newEntity
            pot.model = stage1.model
            pot.stage = 1
            pot.watered = false

            addPotTarget(newEntity)
            lib.notify({ title = 'Weed', description = 'Seed planted!', type = 'success' })
        end,
        onCancel = function()
            busy = false
            lib.notify({ title = 'Weed', description = 'Cancelled', type = 'error' })
        end,
    })
end

-- ============================================================
-- WATER PLANT
-- ============================================================

local function waterPlant(pot)
    local hasWater = exports.ox_inventory:Search('count', Config.Items.water) >= 1
    if not hasWater then
        lib.notify({ title = 'Weed', description = 'You need water!', type = 'error' })
        return
    end

    busy = true
    lib.progressBar({
        duration = Config.Times.water * 1000,
        label = 'Watering plant...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        onCompleted = function()
            busy = false
            exports.ox_inventory:RemoveItem(Config.Items.water, 1)
            pot.watered = true

            local growTime = Config.GrowthStages[pot.stage].growTime
            if growTime > 0 then
                TriggerServerEvent('weedgrow:server:startGrowth', pot.stage, growTime)
                lib.notify({ title = 'Weed', description = ('Watered! Next stage in %d min'):format(math.ceil(growTime / 60)), type = 'success' })
            end
        end,
        onCancel = function()
            busy = false
        end,
    })
end

-- ============================================================
-- GROWTH STAGE UP (from server)
-- ============================================================

RegisterNetEvent('weedgrow:client:stageUp')
AddEventHandler('weedgrow:client:stageUp', function(newStage)
    local pot = nil
    for _, p in pairs(props) do
        if p.stage > 0 and p.stage < #Config.GrowthStages then
            pot = p
            break
        end
    end
    if not pot then return end

    local oldEntity = pot.entity
    exports.ox_target:removeLocalEntity(oldEntity)
    deleteProp(oldEntity)

    local stageData = Config.GrowthStages[newStage]
    local newEntity = spawnProp(stageData.model, pot.coords, pot.heading)
    pot.entity = newEntity
    pot.model = stageData.model
    pot.stage = newStage
    pot.watered = false

    addPotTarget(newEntity)
    lib.notify({ title = 'Weed', description = ('Plant grew to %s!'):format(stageData.label), type = 'success' })
end)

-- ============================================================
-- HARVEST
-- ============================================================

local function harvestWeed(pot)
    busy = true
    lib.progressBar({
        duration = Config.Times.harvest * 1000,
        label = 'Harvesting weed...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        onCompleted = function()
            busy = false
            exports.ox_target:removeLocalEntity(pot.entity)
            deleteProp(pot.entity)

            local newEntity = spawnProp('bkr_prop_weed_plantpot_stack_01b', pot.coords, pot.heading)
            pot.entity = newEntity
            pot.model = 'bkr_prop_weed_plantpot_stack_01b'
            pot.stage = 0
            pot.watered = false

            addPotTarget(newEntity)
            TriggerServerEvent('weedgrow:server:giveWeed')
            lib.notify({ title = 'Weed', description = 'Harvested raw weed!', type = 'success' })
        end,
        onCancel = function()
            busy = false
        end,
    })
end

-- ============================================================
-- DRYING
-- ============================================================

local function startDrying()
    local hasWeed = exports.ox_inventory:Search('count', Config.Items.weedRaw) >= 1
    if not hasWeed then
        lib.notify({ title = 'Weed', description = 'You have no raw weed to dry!', type = 'error' })
        return
    end

    busy = true
    lib.progressBar({
        duration = Config.Times.dry * 1000,
        label = 'Placing weed to dry...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        onCompleted = function()
            busy = false
            exports.ox_inventory:RemoveItem(Config.Items.weedRaw, 1)

            local rc = Config.Coords.rack
            local offset = { x = rc.x + 0.5, y = rc.y + 0.5, z = rc.z + 0.5 }
            local dryEntity = spawnProp(Config.DryPropModel, offset, rc.heading)
            dryProps[#dryProps + 1] = { entity = dryEntity, ready = false, timer = GetGameTimer() + Config.DryTime }

            lib.notify({ title = 'Weed', description = 'Weed is drying (2 min).', type = 'success' })
        end,
        onCancel = function()
            busy = false
        end,
    })
end

CreateThread(function()
    while true do
        Wait(10000)
        local now = GetGameTimer()
        for _, dp in ipairs(dryProps) do
            if not dp.ready and now >= dp.timer then
                dp.ready = true
            end
        end
    end
end)

local function collectDried()
    local readyIdx = nil
    for i, dp in ipairs(dryProps) do
        if dp.ready then
            readyIdx = i
            break
        end
    end

    if not readyIdx then
        lib.notify({ title = 'Weed', description = 'Nothing ready yet!', type = 'error' })
        return
    end

    local dp = dryProps[readyIdx]
    table.remove(dryProps, readyIdx)
    deleteProp(dp.entity)
    TriggerServerEvent('weedgrow:server:giveDriedWeed')
    lib.notify({ title = 'Weed', description = 'Collected dried weed!', type = 'success' })
end

-- ============================================================
-- PACKING
-- ============================================================

local function startPacking()
    local hasDried = exports.ox_inventory:Search('count', Config.Items.weedDried) >= 1
    local hasBag = exports.ox_inventory:Search('count', Config.Items.emptyBag) >= 1

    if not hasDried then
        lib.notify({ title = 'Weed', description = 'No dried weed to pack!', type = 'error' })
        return
    end
    if not hasBag then
        lib.notify({ title = 'Weed', description = 'You need an empty bag!', type = 'error' })
        return
    end

    busy = true
    lib.progressBar({
        duration = Config.Times.pack * 1000,
        label = 'Packing weed into bag...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        onCompleted = function()
            busy = false
            exports.ox_inventory:RemoveItem(Config.Items.weedDried, 1)
            exports.ox_inventory:RemoveItem(Config.Items.emptyBag, 1)
            TriggerServerEvent('weedgrow:server:givePackagedWeed')
            lib.notify({ title = 'Weed', description = 'Packed! You got a bag of weed.', type = 'success' })
        end,
        onCancel = function()
            busy = false
        end,
    })
end

-- ============================================================
-- UI PANEL
-- ============================================================

local function openPanelUI()
    SetNuiFocus(true, true)
    local list = {}
    for id, p in pairs(props) do
        local c = GetEntityCoords(p.entity)
        table.insert(list, {
            id = id,
            label = p.model,
            stage = p.stage,
            coords = { x = c.x, y = c.y, z = c.z },
            heading = GetEntityHeading(p.entity),
        })
    end
    SendNUIMessage({
        action = 'openPanel',
        props = list,
    })
end

RegisterNUICallback('closePanel', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('setStage', function(data, cb)
    local pot = props[data.id]
    if pot then
        exports.ox_target:removeLocalEntity(pot.entity)
        deleteProp(pot.entity)

        local stageData = Config.GrowthStages[data.stage]
        if stageData then
            local newEntity = spawnProp(stageData.model, pot.coords, pot.heading)
            pot.entity = newEntity
            pot.model = stageData.model
            pot.stage = data.stage
            pot.watered = false
            addPotTarget(newEntity)
        else
            local newEntity = spawnProp('bkr_prop_weed_plantpot_stack_01b', pot.coords, pot.heading)
            pot.entity = newEntity
            pot.model = 'bkr_prop_weed_plantpot_stack_01b'
            pot.stage = 0
            pot.watered = false
            addPotTarget(newEntity)
        end
    end
    cb('ok')
end)

RegisterNUICallback('moveProp', function(data, cb)
    local pot = props[data.id]
    if pot then
        exports.ox_target:removeLocalEntity(pot.entity)
        deleteProp(pot.entity)

        pot.coords = { x = data.x, y = data.y, z = data.z }
        pot.heading = data.heading
        local newEntity = spawnProp(pot.model, pot.coords, pot.heading)
        pot.entity = newEntity
        addPotTarget(newEntity)
    end
    cb('ok')
end)

RegisterNUICallback('deleteProp', function(data, cb)
    local pot = props[data.id]
    if pot then
        exports.ox_target:removeLocalEntity(pot.entity)
        deleteProp(pot.entity)
        props[data.id] = nil
    end
    cb('ok')
end)

-- ============================================================
-- INIT
-- ============================================================

CreateThread(function()
    Wait(2000)
    spawnAllProps()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in pairs(props) do
        if p.entity and DoesEntityExist(p.entity) then
            deleteProp(p.entity)
        end
    end
    for _, dp in pairs(dryProps) do
        if dp.entity and DoesEntityExist(dp.entity) then
            deleteProp(dp.entity)
        end
    end
end)   