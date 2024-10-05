local config = require 'config.server'
local sharedConfig = require 'config.shared'

---@param department? ArmoryData
local function registerArmory(department)
    if not department then return end

    for i = 1, #department do
        local armory = department[i]

        exports.ox_inventory:RegisterShop(armory.shopType, armory)
    end
end

---@param job? string
---@param department? PersonalStashData
local function registerPersonalStash(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local stash = department[i]
        local stashId = ('%s-PersonalStash'):format(job)

        exports.ox_inventory:RegisterStash(stashId, stash.label, stash.slots or 100, stash.weight or 100000, true, stash.groups, stash.coords)
    end
end

---@param impound? table
local function registerImpound(impound)
    if not impound then return end

    exports.qbx_garages:RegisterGarage(impound.name, impound.lot)
end

---@param source number
---@param vehicle table
---@param spawn vector4
lib.callback.register('qbx_police:server:spawnVehicle', function(source, vehicle, spawn)
    local ped = GetPlayerPed(source)
    local plate = ('LSPD%s'):format(math.random(1000, 9999))
    local netId, _ = qbx.spawnVehicle({
        spawnSource = spawn,
        model = vehicle.name,
        warp = ped,
        props = {
            plate = plate,
            modLivery = vehicle.livery or 0
        }
    })

    config.giveVehicleKeys(source, plate)

    return netId
end)

---@param netId number
---@return integer
lib.callback.register('qbx_police:server:canImpound', function(_, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local plate = GetVehicleNumberPlateText(entity)

    return exports.qbx_vehicles:DoesPlayerVehiclePlateExist(plate)
end)

---@param netId integer
---@return boolean
lib.callback.register('qbx_police:server:impoundVehicle', function(_, netId)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'police' then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)

    exports.qbx_vehicles:SaveVehicle(entity, {
        garage = 'impoundlot',
        state = 2, -- Impounded
    })

    exports.qbx_core:DeleteVehicle(entity)

    return true
end)

---@param source number
---@param netId integer
---@return boolean
lib.callback.register('qbx_police:server:confiscateVehicle', function(source, netId)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'police' then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    local impound = sharedConfig.departments[player.PlayerData.job.name].impound

    exports.qbx_vehicles:SaveVehicle(entity, {
        garage = impound.name,
        state = 1, -- Garaged
    })

    exports.qbx_core:DeleteVehicle(entity)

    return true
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for job, data in pairs(sharedConfig.departments) do
        registerArmory(data.armory)
        registerPersonalStash(job, data.personalStash)
        registerImpound(data.impound)
    end
end)