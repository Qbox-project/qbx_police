local config = require 'config.client'
local sharedConfig = require 'config.shared'
local objectList = {}
local spawnedSpikes = {}
local closestSpike = nil

local function GetClosestPoliceObject()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    for id in pairs(objectList) do
        local dist2 = #(pos - objectList[id].coords)
        if current then
            if dist2 < dist then
                current = id
                dist = dist2
            end
        else
            dist = dist2
            current = id
        end
    end
    return current, dist
end

local function GetClosestSpike()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    for id in pairs(spawnedSpikes) do
        local dist2 = #(pos - spawnedSpikes[id].coords)
        if current then
            if dist2 < dist then
                current = id
            end
        else
            dist = dist2
            current = id
        end
    end
    closestSpike = current
end

---Spawn police object.
---@param item string name from `config/shared.lua`
RegisterNetEvent('police:client:spawnPObj', function(item)
    if lib.progressBar({
        duration = 2500,
        label = Lang:t('progressbar.place_object'),
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
        TriggerServerEvent('police:server:spawnObject', item)
    else
        exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
    end
end)

RegisterNetEvent('police:client:deleteObject', function()
    local objectId, dist = GetClosestPoliceObject()
    if dist < 5.0 then
        if lib.progressBar({
            duration = 2500,
            label = Lang:t('progressbar.remove_object'),
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
            TriggerServerEvent('police:server:deleteObject', objectId)
        else
            exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
        end
    end
end)

RegisterNetEvent('police:client:removeObject', function(objectId)
    NetworkRequestControlOfEntity(objectList[objectId].object)
    DeleteObject(objectList[objectId].object)
    objectList[objectId] = nil
end)

RegisterNetEvent('police:client:spawnObject', function(objectId, objectType)
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local forward = GetEntityForwardVector(cache.ped)
    local x, y, z = table.unpack(coords + forward * 0.5)
    local spawnedObj = CreateObject(sharedConfig.objects[objectType].model, x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(spawnedObj)
    SetEntityHeading(spawnedObj, heading)
    FreezeEntityPosition(spawnedObj, sharedConfig.objects[objectType].freeze)
    objectList[objectId] = {
        id = objectId,
        object = spawnedObj,
        coords = vec3(x, y, z - 0.3),
    }
end)

---Spawn a spike strip.
RegisterNetEvent('police:client:SpawnSpikeStrip', function()
    if #spawnedSpikes >= config.maxSpikes or QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then
        exports.qbx_core:Notify(Lang:t('error.no_spikestripe'), 'error')
        return
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.0)
    local spike = CreateObject(`P_ld_stinger_s`, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, true)
    local netid = NetworkGetNetworkIdFromEntity(spike)
    SetNetworkIdExistsOnAllMachines(netid, true)
    SetNetworkIdCanMigrate(netid, false)
    SetEntityHeading(spike, GetEntityHeading(cache.ped))
    PlaceObjectOnGroundProperly(spike)
    spawnedSpikes[#spawnedSpikes + 1] = {
        coords = spawnCoords,
        netid = netid,
        object = spike,
    }
    TriggerServerEvent('police:server:SyncSpikes', spawnedSpikes)
end)

RegisterNetEvent('police:client:SyncSpikes', function(table)
    spawnedSpikes = table
end)

CreateThread(function()
    while true do
        if IsLoggedIn then
            GetClosestSpike()
        end
        Wait(500)
    end
end)

AddEventHandler('ox_lib:cache:vehicle', function()
	CreateThread(function()
		while cache.vehicle do
            if closestSpike then
                local tires = {
                    {bone = 'wheel_lf', index = 0},
                    {bone = 'wheel_rf', index = 1},
                    {bone = 'wheel_lm', index = 2},
                    {bone = 'wheel_rm', index = 3},
                    {bone = 'wheel_lr', index = 4},
                    {bone = 'wheel_rr', index = 5},
                }

                for a = 1, #tires do
                    local tirePos = GetWorldPositionOfEntityBone(cache.vehicle, GetEntityBoneIndexByName(cache.vehicle, tires[a].bone))
                    local spike = GetClosestObjectOfType(tirePos.x, tirePos.y, tirePos.z, 15.0, `P_ld_stinger_s`, true, true, true)
                    local spikePos = GetEntityCoords(spike, false)
                    local distance = #(tirePos - spikePos)

                    if distance < 1.8 then
                        if not IsVehicleTyreBurst(cache.vehicle, tires[a].index, true) or IsVehicleTyreBurst(cache.vehicle, tires[a].index, false) then
                            SetVehicleTyreBurst(cache.vehicle, tires[a].index, false, 1000.0)
                        end
                    end
                end
            end
			Wait(100)
		end
	end)
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if IsLoggedIn then
            if closestSpike then
                local pos = GetEntityCoords(cache.ped)
                local dist = #(pos - spawnedSpikes[closestSpike].coords)
                if dist < 4 then
                    if not cache.vehicle then
                        if QBX.PlayerData.job.type == 'leo' and QBX.PlayerData.job.onduty then
                            sleep = 0
                            lib.showTextUI(Lang:t('info.delete_spike'))
                            if IsControlJustPressed(0, 38) then
                                NetworkRegisterEntityAsNetworked(spawnedSpikes[closestSpike].object)
                                NetworkRequestControlOfEntity(spawnedSpikes[closestSpike].object)
                                SetEntityAsMissionEntity(spawnedSpikes[closestSpike].object, false, false)
                                DeleteEntity(spawnedSpikes[closestSpike].object)
                                spawnedSpikes[closestSpike] = nil
                                closestSpike = nil
                                TriggerServerEvent('police:server:SyncSpikes', spawnedSpikes)
                                lib.hideTextUI()
                            end
                        end
                    end
                else
                    lib.hideTextUI()
                end
            end
        end
        Wait(sleep)
    end
end)
