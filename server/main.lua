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

---@param job string
---@param personalStash table
local function registerPersonalStash(job, personalStash)
    if not job or not personalStash then return end

    for i = 1, #personalStash do
        local stash = personalStash[i]
        local stashName = ('%s-%s-PersonalStash'):format(i, job)

        exports.ox_inventory:RegisterStash(stashName, 'Personal Stash', stash.slots, stash.weight, true, stash.groups)
    end
end

---@param source number
---@param model string
---@param spawn vector4
lib.callback.register('qbx_police:server:spawnVehicle', function(source, model, spawn)
    local ped = GetPlayerPed(source)
    local plate = ('LSPD%s'):format(math.random(1000, 9999))
    local netId, _ = qbx.spawnVehicle({
        spawnSource = spawn,
        model = model,
        warp = ped,
        props = {
            plate = plate
        }
    })

    exports.qbx_vehiclekeys:GiveKeys(source, plate)

    return netId
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for job, data in pairs(sharedConfig.departments) do
        registerPersonalStash(job, data.personalStash)
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