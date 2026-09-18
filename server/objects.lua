local sharedConfig = require 'config.shared'

local function canPlaceObject(source, coords)
    local player = exports.qbx_core:GetPlayer(source)
    return IsLeoAndOnDuty(player)
        and type(coords) == 'vector3'
        and #(GetEntityCoords(GetPlayerPed(source)) - coords) <= 8.0
end

local function isAllowedObject(modelHash)
    for _, object in pairs(sharedConfig.objects) do
        if object.model == modelHash then return true end
    end
    return false
end

---Spawns object
---@param modelHash string
---@param coords vector4
---@param zOffset number
---@param isFixed boolean?
---@return table? objects
---@return number? object
local function spawnObject(objects, modelHash, coords, zOffset, isFixed)
    local object = CreateObject(modelHash, coords.x, coords.y, coords.z - zOffset, true, true, false)
    SetEntityHeading(object, coords.w)
    FreezeEntityPosition(object, true)

    local exists = lib.waitFor(function ()
        if DoesEntityExist(object) then return true end
    end, ('Failed to spawn prop %s'):format(modelHash), sharedConfig.timeout)

    if exists then
        local netid = NetworkGetNetworkIdFromEntity(object)
        objects[#objects+1] = netid
        if isFixed then
            local coordsState = GlobalState.fixedCoords
            coordsState[netid] = GetEntityCoords(object)
            GlobalState.fixedCoords = coordsState
        end

        return objects, netid
    end
end

---Spawns spike strip
---@param coords vector3
---@param heading number
lib.callback.register('police:server:spawnSpikeStrip', function(source, coords, heading)
    if not canPlaceObject(source, coords) or type(heading) ~= 'number' or heading ~= heading then return end
    if #GlobalState.spikeStrips >= sharedConfig.maxSpikes then return nil, 'error.no_spikestripe' end
    local objects, netid = spawnObject(GlobalState.spikeStrips, `P_ld_stinger_s`,
                                       vector4(coords.x, coords.y, coords.z, heading), 1, true)
    GlobalState.spikeStrips = objects

    return netid
end)

---Spawns police object
---@param modelHash string
---@param coords vector3
---@param heading number
lib.callback.register('police:server:spawnObject', function(source, modelHash, coords, heading)
    if not canPlaceObject(source, coords) or not isAllowedObject(modelHash) or type(heading) ~= 'number' or heading ~= heading then return end
    local objects, netid = spawnObject(GlobalState.policeObjects, modelHash,
                                       vector4(coords.x, coords.y, coords.z, heading), 0.3)
    GlobalState.policeObjects = objects

    return netid
end)

local function despawnObject(objects, index)
    DeleteEntity(NetworkGetEntityFromNetworkId(objects[index]))
    objects[index] = objects[#objects]
    objects[#objects] = nil
    return objects
end

RegisterNetEvent('police:server:despawnSpikeStrip', function(index)
    if not IsLeoAndOnDuty(exports.qbx_core:GetPlayer(source)) or math.type(index) ~= 'integer' or not GlobalState.spikeStrips[index] then return end
    local object = NetworkGetEntityFromNetworkId(GlobalState.spikeStrips[index])
    if not DoesEntityExist(object) or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(object)) > 8.0 then return end
    GlobalState.spikeStrips = despawnObject(GlobalState.spikeStrips, index)
end)

RegisterNetEvent('police:server:despawnObject', function(index)
    if not IsLeoAndOnDuty(exports.qbx_core:GetPlayer(source)) or math.type(index) ~= 'integer' or not GlobalState.policeObjects[index] then return end
    local object = NetworkGetEntityFromNetworkId(GlobalState.policeObjects[index])
    if not DoesEntityExist(object) or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(object)) > 8.0 then return end
    GlobalState.policeObjects = despawnObject(GlobalState.policeObjects, index)
end)

AddEventHandler('onResourceStart', function (resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    GlobalState.spikeStrips = {}
    GlobalState.policeObjects = {}
    GlobalState.fixedCoords = {}
end)

AddEventHandler('onResourceStop', function (resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    local spikeStrips = GlobalState.spikeStrips
    for i = 1, #spikeStrips do
        DeleteEntity(NetworkGetEntityFromNetworkId(spikeStrips[i]))
    end

    local policeObjects = GlobalState.policeObjects
    for i = 1, #policeObjects do
        DeleteEntity(NetworkGetEntityFromNetworkId(policeObjects[i]))
    end

    GlobalState.spikeStrips = nil
    GlobalState.policeObjects = nil
    GlobalState.fixedCoords = nil
end)
