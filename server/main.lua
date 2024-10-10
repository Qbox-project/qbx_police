local config = require 'config.server'
local sharedConfig = require 'config.shared'
local activeOfficers = {}

---@param name string
---@param data any
local function triggerOfficerEvent(name, data)
    for playerId in pairs(activeOfficers) do
        TriggerClientEvent(name, playerId, data)
    end
end

---@param playerId number
local function getOfficer(playerId)
    return activeOfficers[playerId]
end

---@param playerId number
local function removeOfficer(playerId)
    triggerOfficerEvent('qbx_police:client:removeOfficer', playerId)

    activeOfficers[playerId] = nil
end

---@param playerId number
local function addOfficer(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)

    if not player or player.PlayerData.job.type ~= 'leo' then return end

    activeOfficers[playerId] = {
        firstName = player.PlayerData.charinfo.firstname,
        lastName = player.PlayerData.charinfo.lastname,
        callsign = player.PlayerData.metadata.callsign,
        playerId = playerId,
        group = player.PlayerData.job.name,
        grade = player.PlayerData.job.grade.label,
        position = {},
    }
end

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

    vehicle.mods.plate = vehicle.mods.plate or ('LSPD%s'):format(math.random(1000, 9999))

    local netId, veh = qbx.spawnVehicle({
        spawnSource = spawn,
        model = vehicle.name,
        warp = ped,
        props = vehicle.mods or {}
    })

    config.giveVehicleKeys(source, veh)

    return netId
end)

---@param netId number
---@return integer
lib.callback.register('qbx_police:server:canImpound', function(_, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local plate = GetVehicleNumberPlateText(entity)

    return Entity(entity).state.vehicleid or exports.qbx_vehicles:DoesPlayerVehiclePlateExist(plate)
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

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    addOfficer(source)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local officer = getOfficer(source)

    if officer then
        if officer.group == job.name then
            activeOfficers[source].grade = job.grade.label
            return
        else
            local playerJob = exports.qbx_core:GetJob(job.name)

            if playerJob.type ~= 'leo' then
                removeOfficer(source)
                return
            end

            activeOfficers[source].group = job.name
            activeOfficers[source].grade = job.grade.label
            return
        end
    end

    addOfficer(source)
end)

AddEventHandler('QBCore:Server:SetDuty', function(source, onDuty)
    local player = exports.qbx_core:GetPlayer(source)

    if player?.PlayerData.job.type ~= 'leo' then return end

    if not onDuty then
        removeOfficer(source)
        return
    end

    addOfficer(source)
end)

SetInterval(function()
    local officersArray = {}

    for playerId, officer in pairs(activeOfficers) do
        local coords = GetEntityCoords(GetPlayerPed(officer.playerId))

        officer.position = coords

        officersArray[playerId] = officer
    end

    triggerOfficerEvent('qbx_police:client:updatePositions', officersArray)
    table.wipe(officersArray)
end, config.refreshRate)