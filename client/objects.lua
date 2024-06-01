local sharedConfig = require 'config.shared'

local function checkIsSpikeObject(spikeStrips, fixedCoords, position, maxDistance)
    if #spikeStrips == 0 then return end
    for i = 1, #spikeStrips do
        local coords = fixedCoords[spikeStrips[i]]

        local distance = #(position - coords)
        if distance < maxDistance then
            return true
        end
    end
end

local function getClosestObject(objects, position, maxDistance, isFixed)
    if #objects == 0 then return end
    local minDistance, currentIndex

    for i = 1, #objects do
        local coords
        if isFixed then
            coords = GlobalState.fixedCoords[objects[i]]
        else
            local object = NetworkGetEntityFromNetworkId(objects[i])
            coords = GetEntityCoords(object)
        end

        local distance = #(position - coords)
        if distance < maxDistance then
            if not minDistance or distance < minDistance then
                minDistance = distance
                currentIndex = i
            end
        end
    end

    return currentIndex
end

---Spawn police object.
---@param item string name from `config/shared.lua`
RegisterNetEvent('police:client:spawnPObj', function(item)
    if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end

    if cache.vehicle then return exports.qbx_core:Notify(locale('error.in_vehicle'), 'error') end

    if lib.progressBar({
        duration = 2500,
        label = locale('progressbar.place_object'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front'
        }
    }) then
        local objectConfig = sharedConfig.objects[item]
        local forward = GetEntityForwardVector(cache.ped)
        local spawnCoords = GetEntityCoords(cache.ped) + forward * 0.5
        local netid, error = lib.callback.await('police:server:spawnObject', false,
                                                objectConfig.model, spawnCoords, GetEntityHeading(cache.ped))

        if not netid then return exports.qbx_core:Notify(locale(error), 'error') end

        local object = NetworkGetEntityFromNetworkId(netid)
        PlaceObjectOnGroundProperly(object)
        FreezeEntityPosition(object, objectConfig.freeze)
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

RegisterNetEvent('police:client:deleteObject', function()
    local objectId = getClosestObject(GlobalState.policeObjects, GetEntityCoords(cache.ped) , 5.0)
    if not objectId then return end
    if lib.progressBar({
        duration = 2500,
        label = locale('progressbar.remove_object'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@',
            clip = 'plant_floor'
        }
    }) then
        TriggerServerEvent('police:server:despawnObject', objectId)
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

---Spawn a spike strip.
RegisterNetEvent('police:client:SpawnSpikeStrip', function()
    if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
    if #GlobalState.spikeStrips >= sharedConfig.maxSpikes then
        return exports.qbx_core:Notify(locale('error.no_spikestripe'), 'error')
    end

    if cache.vehicle then return exports.qbx_core:Notify(locale('error.in_vehicle'), 'error') end

    if lib.progressBar({
        duration = 2500,
        label = locale('progressbar.place_object'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'amb@medic@standing@kneel@enter',
            clip = 'enter'
        }
    }) then
        local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0)
        local netid, error = lib.callback.await('police:server:spawnSpikeStrip', false,
                                                spawnCoords, GetEntityHeading(cache.ped))

        if not netid then
            return exports.qbx_core:Notify(locale(error), 'error')
        end

        lib.requestAnimDict('p_ld_stinger_s')
        local spike = NetworkGetEntityFromNetworkId(netid)
        PlayEntityAnim(spike, 'p_stinger_s_deploy', 'p_ld_stinger_s', 1000.0, false, false, false, 0.0, 0)
        PlaceObjectOnGroundProperly(spike)
        RemoveAnimDict('p_ld_stinger_s')
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end

    RemoveAnimDict('amb@medic@standing@kneel@enter')
end)

local WHEEL_NAMES = {
    'wheel_lf',
    'wheel_rf',
    'wheel_lm',
    'wheel_rm',
    'wheel_lr',
    'wheel_rr',
}

local isSpike
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            isSpike = checkIsSpikeObject(GlobalState.spikeStrips, GlobalState.fixedCoords, GetEntityCoords(cache.ped), 30)
        end
        Wait(500)
    end
end)

local isWatchInVehicleBusy
local function burstTyreOnSpikeCollision(vehicle)
    CreateThread(function ()
        if isWatchInVehicleBusy then return end
        isWatchInVehicleBusy = true
        local wheels = {}
        for i = 1, #WHEEL_NAMES do
            local w = GetEntityBoneIndexByName(vehicle, WHEEL_NAMES[i])
            if w ~= -1 then
                wheels[#wheels + 1] = { wheel = w, index = i - 1 }
            end
        end

        pcall(lib.waitFor(function() return cache.value end, nil, sharedConfig.timeout))

        while cache.vehicle do
            local spikeStrips = GlobalState.spikeStrips
            local fixedCoords = GlobalState.fixedCoords
            if isSpike then
                for i = 1, #wheels do
                    if wheels[i].wheel then
                        local wheelPosition = GetWorldPositionOfEntityBone(cache.vehicle, wheels[i].wheel)

                        if checkIsSpikeObject(spikeStrips, fixedCoords, wheelPosition, 1.8) then
                            local index = wheels[i].index
                            if not IsVehicleTyreBurst(cache.vehicle, index, true)
                                or IsVehicleTyreBurst(cache.vehicle, index, false)
                            then
                                SetVehicleTyreBurst(cache.vehicle, index, false, 1000.0)
                            end
                        end
                    end
                end
                Wait(0)
            else
                Wait(250)
            end
        end
        isWatchInVehicleBusy = nil
    end)
end

local function displayInfoCloseToSpike()
    CreateThread(function ()
        pcall(lib.waitFor(function() return cache.value and nil or false end, nil, sharedConfig.timeout))

        while not cache.vehicle and LocalPlayer.state.isLoggedIn and QBX.PlayerData.job.type == 'leo' and QBX.PlayerData.job.onduty do
            local isOpen, text = lib.isTextUIOpen()

            if isSpike and checkIsSpikeObject(GlobalState.spikeStrips, GlobalState.fixedCoords, GetEntityCoords(cache.ped), 3) then
                if not isOpen or text ~= locale('info.delete_spike') then
                    lib.showTextUI(locale('info.delete_spike'))
                end
            else
                if isOpen and text == locale('info.delete_spike') then
                    lib.hideTextUI()
                end
            end

            Wait(500)
        end

        local isOpen, text = lib.isTextUIOpen()
        if isOpen and text == locale('info.delete_spike') then
            lib.hideTextUI()
        end
    end)
end

local keybind

local function onPressed()
    if cache.vehicle then return end
    keybind:disable(true)
    local spike = getClosestObject(GlobalState.spikeStrips, GetEntityCoords(cache.ped), 4, true)
    if spike ~= nil then
        if lib.progressBar({
            duration = 2500,
            label = locale('progressbar.remove_object'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false
            },
            anim = {
                dict = 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@',
                clip = 'plant_floor'
            }
        }) then
            TriggerServerEvent('police:server:despawnSpikeStrip', spike)
            lib.hideTextUI()
        else
            exports.qbx_core:Notify(locale('error.canceled'), 'error')
        end
    end
    keybind:disable(false)
end

keybind = lib.addKeybind({
    name = 'despawnSpikeStrip',
    description = locale('info.delete_spike'),
    defaultKey = 'E',
    secondaryMapper = 'PAD_DIGITALBUTTONANY',
    secondaryKey = 'LRIGHT_INDEX',
    onPressed = onPressed
})

local function toggleJobFunctions(isWorkingLeo)
    if isWorkingLeo then
        keybind:disable(false)

        if not cache.vehicle then
            displayInfoCloseToSpike()
        end
    else
        keybind:disable(true)
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    toggleJobFunctions(LocalPlayer.state.isLoggedIn and job.type == 'leo' and job.onduty)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    local job = QBX.PlayerData.job
    toggleJobFunctions(LocalPlayer.state.isLoggedIn and job and job.type == 'leo' and onDuty)
end)

AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_, _, isLoggedIn)
    local job = QBX.PlayerData.job
    toggleJobFunctions(isLoggedIn and job and job.type == 'leo' and job.onduty)

    if cache.vehicle then
        burstTyreOnSpikeCollision(cache.vehicle)
    end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        burstTyreOnSpikeCollision(vehicle)
    else
        displayInfoCloseToSpike()
    end
end)

AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end
    local isOpen, text = lib.isTextUIOpen()
    if isOpen and text == locale('info.delete_spike') then
        lib.hideTextUI()
    end
end)
