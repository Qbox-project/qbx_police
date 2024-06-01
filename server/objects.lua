local sharedConfig = require 'config.shared'

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
lib.callback.register('police:server:spawnSpikeStrip', function(_, coords, heading)
    if #GlobalState.spikeStrips > sharedConfig.maxSpikes then return nil, 'error.no_spikestripe' end
    local objects, netid = spawnObject(GlobalState.spikeStrips, `P_ld_stinger_s`,
                                       vector4(coords.x, coords.y, coords.z, heading), 1, true)
    GlobalState.spikeStrips = objects

    return netid
end)

---Spawns police object
---@param modelHash string
---@param coords vector3
---@param heading number
lib.callback.register('police:server:spawnObject', function(_, modelHash, coords, heading)
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
    GlobalState.spikeStrips = despawnObject(GlobalState.spikeStrips, index)
end)

RegisterNetEvent('police:server:despawnObject', function(index)
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
