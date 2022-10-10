-- Variables
local ObjectList = {}
local SpawnedSpikes = {}
local spikemodel = `P_ld_stinger_s`
local ClosestSpike = nil

-- Functions
local function GetClosestPoliceObject()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil

    for id, _ in pairs(ObjectList) do
        local dist2 = #(pos - ObjectList[id].coords)
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

function GetClosestSpike()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil

    for id, _ in pairs(SpawnedSpikes) do
        if current then
            if #(pos - vector3(SpawnedSpikes[id].coords.x, SpawnedSpikes[id].coords.y, SpawnedSpikes[id].coords.z)) < dist then
                current = id
            end
        else
            dist = #(pos - vector3(SpawnedSpikes[id].coords.x, SpawnedSpikes[id].coords.y, SpawnedSpikes[id].coords.z))
            current = id
        end
    end
    ClosestSpike = current
end

-- Events

---Spawn police object.
---@param item string  name from `Config.Objects`
RegisterNetEvent('police:client:spawnPObj', function(item)
    if lib.progressBar({
        duration = 2500,
        label = Lang:t("progressbar.place_object"),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = "anim@narcotics@trash",
            clip = "drop_front"
        }
    }) then
        TriggerServerEvent("police:server:spawnObject", item)
    else
        lib.notify({ description = Lang:t("error.canceled"), type = "error" })
    end
end)

RegisterNetEvent('police:client:deleteObject', function()
    local objectId, dist = GetClosestPoliceObject()
    if dist < 5.0 then
        if lib.progressBar({
            duration = 2500,
            label = Lang:t("progressbar.remove_object"),
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = {
                dict = "weapons@first_person@aim_rng@generic@projectile@thermal_charge@",
                clip = "plant_floor",
            }
        }) then
            TriggerServerEvent("police:server:deleteObject", objectId)
        else
            lib.notify({ description = Lang:t("error.canceled"), type = "error" })
        end
    end
end)

RegisterNetEvent('police:client:removeObject', function(objectId)
    NetworkRequestControlOfEntity(ObjectList[objectId].object)
    DeleteObject(ObjectList[objectId].object)
    ObjectList[objectId] = nil
end)

RegisterNetEvent('police:client:spawnObject', function(objectId, type, player)
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(player)))
    local heading = GetEntityHeading(GetPlayerPed(GetPlayerFromServerId(player)))
    local forward = GetEntityForwardVector(PlayerPedId())
    local x, y, z = table.unpack(coords + forward * 0.5)
    local spawnedObj = CreateObject(Config.Objects[type].model, x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(spawnedObj)
    SetEntityHeading(spawnedObj, heading)
    FreezeEntityPosition(spawnedObj, Config.Objects[type].freeze)
    ObjectList[objectId] = {
        id = objectId,
        object = spawnedObj,
        coords = vector3(x, y, z - 0.3),
    }
end)

---@type fun(): fun(SpawnedSpikes: table)
RegisterNetEvent('police:client:SpawnSpikeStrip', function()
    if #SpawnedSpikes >= Config.MaxSpikes or PlayerJob.name ~= "police" or not PlayerJob.onduty then
        lib.notify({ description = Lang:t("error.no_spikestripe"), type = 'error'})
        return
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 2.0, 0.0)
    local spike = CreateObject(spikemodel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 1, 1, 1)
    local netid = NetworkGetNetworkIdFromEntity(spike)
    SetNetworkIdExistsOnAllMachines(netid, true)
    SetNetworkIdCanMigrate(netid, false)
    SetEntityHeading(spike, GetEntityHeading(PlayerPedId()))
    PlaceObjectOnGroundProperly(spike)
    SpawnedSpikes[#SpawnedSpikes + 1] = {
        coords = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z),
        netid = netid,
        object = spike,
    }
    TriggerServerEvent('police:server:SyncSpikes', SpawnedSpikes)
end)

RegisterNetEvent('police:client:SyncSpikes', function(table)
    SpawnedSpikes = table
end)

-- Threads
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            GetClosestSpike()
        end
        Wait(500)
    end
end)

local spikeSleep = 1000
CreateThread(function()
    while true do
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if LocalPlayer.state.isLoggedIn and vehicle ~= 0 then
            spikeSleep = 3
            if ClosestSpike then
                local tires = {
                    { bone = "wheel_lf", index = 0 },
                    { bone = "wheel_rf", index = 1 },
                    { bone = "wheel_lm", index = 2 },
                    { bone = "wheel_rm", index = 3 },
                    { bone = "wheel_lr", index = 4 },
                    { bone = "wheel_rr", index = 5 }
                }

                for a = 1, #tires do
                    local tirePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, tires[a].bone))
                    local spike = GetClosestObjectOfType(tirePos.x, tirePos.y, tirePos.z, 15.0, spikemodel, 1, 1, 1)
                    local spikePos = GetEntityCoords(spike, false)
                    local distance = #(tirePos - spikePos)

                    if distance < 1.8 then
                        if not IsVehicleTyreBurst(vehicle, tires[a].index, true) or IsVehicleTyreBurst(vehicle, tires[a].index, false) then
                            SetVehicleTyreBurst(vehicle, tires[a].index, false, 1000.0)
                        end
                    end
                end
            end
        else
            spikeSleep = 1000
        end
        Wait(spikeSleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            if ClosestSpike then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local dist = #(pos - SpawnedSpikes[ClosestSpike].coords)
                if dist < 4 then
                    if not IsPedInAnyVehicle(PlayerPedId()) then
                        if PlayerJob.name == "police" and PlayerJob.onduty then
                            sleep = 0
                            lib.showTextUI(Lang:t('info.delete_spike'))
                            if IsControlJustPressed(0, 38) then
                                NetworkRegisterEntityAsNetworked(SpawnedSpikes[ClosestSpike].object)
                                NetworkRequestControlOfEntity(SpawnedSpikes[ClosestSpike].object)
                                SetEntityAsMissionEntity(SpawnedSpikes[ClosestSpike].object)
                                DeleteEntity(SpawnedSpikes[ClosestSpike].object)
                                SpawnedSpikes[ClosestSpike] = nil
                                ClosestSpike = nil
                                TriggerServerEvent('police:server:SyncSpikes', SpawnedSpikes)
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