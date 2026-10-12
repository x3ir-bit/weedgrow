local QBCore = exports['qb-core']:GetCoreObject()

local growthTimers = {}

RegisterNetEvent('weedgrow:server:startGrowth', function(stage, growTime)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if growthTimers[src] then return end

    local targetTime = GetGameTimer() + (growTime * 1000)
    growthTimers[src] = targetTime

    local newStage = stage + 1
    if newStage > #Config.GrowthStages then return end

    CreateThread(function()
        while GetGameTimer() < targetTime do
            Wait(10000)
        end
        if growthTimers[src] == targetTime then
            growthTimers[src] = nil
            TriggerClientEvent('weedgrow:client:stageUp', src, newStage)
        end
    end)
end)

RegisterNetEvent('weedgrow:server:giveWeed')
AddEventHandler('weedgrow:server:giveWeed', function()
    local src = source
    if not exports.ox_inventory:CanCarryItem(src, Config.Items.weedRaw, 1) then
        TriggerClientEvent('ox_inventory:notify', src, { title = 'Weed', description = 'Inventory full!', type = 'error' })
        return
    end
    exports.ox_inventory:AddItem(src, Config.Items.weedRaw, 1)
end)

RegisterNetEvent('weedgrow:server:giveDriedWeed')
AddEventHandler('weedgrow:server:giveDriedWeed', function()
    local src = source
    if not exports.ox_inventory:CanCarryItem(src, Config.Items.weedDried, 1) then
        TriggerClientEvent('ox_inventory:notify', src, { title = 'Weed', description = 'Inventory full!', type = 'error' })
        return
    end
    exports.ox_inventory:AddItem(src, Config.Items.weedDried, 1)
end)

RegisterNetEvent('weedgrow:server:givePackagedWeed')
AddEventHandler('weedgrow:server:givePackagedWeed', function()
    local src = source
    if not exports.ox_inventory:CanCarryItem(src, Config.Items.weedPack, 1) then
        TriggerClientEvent('ox_inventory:notify', src, { title = 'Weed', description = 'Inventory full!', type = 'error' })
        return
    end
    exports.ox_inventory:AddItem(src, Config.Items.weedPack, 1)
end)

CreateThread(function()
    AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
        exports.ox_inventory:RegisterStash(Config.StorageName, 'Weed Storage', 30, 100000, false)
    end
end)