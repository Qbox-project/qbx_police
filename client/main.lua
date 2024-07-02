local config = require 'config.client'
local sharedConfig = require 'config.shared'
local vehicles = require 'client.vehicles'

---@param station table
local function createBlip(station)
    if not station then return end

    local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
    SetBlipSprite(blip, station.sprite or 60)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, station.scale or 0.8)
    SetBlipColour(blip, station.color or 29)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(station.label or 'Police Station')
    EndTextCommandSetBlipName(blip)
end

---@param job string
---@param station table
local function createDuty(job, station)
    if not job or not station then return end

    for i = 1, #station do
        local location = station[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%sDuty'):format(job),
                    icon = 'fa-solid fa-clipboard-user',
                    label = 'Clock In/Out',
                    serverEvent = 'QBCore:ToggleDuty',
                    groups = location.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job string
---@param station table
local function createManagement(job, station)
    if not job or not station then return end

    for i = 1, #station do
        local location = station[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%sBossMenu'):format(job),
                    icon = 'fa-solid fa-people-roof',
                    label = 'Open Job Management',
                    canInteract = function()
                        return QBX.PlayerData.job.isboss and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        exports.qbx_management:OpenBossMenu('job')
                    end,
                    groups = location.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job string
---@param station table
local function createGarage(job, station)
    if not job or not station then return end

    for i = 1, #station do
        local garage = station[i]

        exports.ox_target:addSphereZone({
            coords = garage.coords,
            radius = garage.radius,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%sGarage'):format(job),
                    icon = 'fa-solid fa-warehouse',
                    label = 'Open Garage',
                    canInteract = function()
                        return not cache.vehicle and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        vehicles.openGarage(garage)
                    end,
                    groups = garage.groups,
                    distance = 1.5,
                },
                {
                    name = ('%sGarageStore'):format(job),
                    icon = 'fa-solid fa-square-parking',
                    label = 'Store Vehicle',
                    canInteract = function()
                        return cache.vehicle and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        vehicles.store(cache.vehicle)
                    end,
                    groups = garage.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job string
---@param station table
local function createHelipad(job, station)
    if not job or not station then return end

    for i = 1, #station do
        local helipad = station[i]

        exports.ox_target:addSphereZone({
            coords = helipad.coords,
            radius = helipad.radius,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%sHelipad'):format(job),
                    icon = 'fa-solid fa-helicopter-symbol',
                    label = 'Open Helipad',
                    canInteract = function()
                        return not cache.vehicle and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        vehicles.openHelipad(helipad)
                    end,
                    groups = helipad.groups,
                    distance = 1.5,
                },
                {
                    name = ('%sHelipadStore'):format(job),
                    icon = 'fa-solid fa-square-parking',
                    label = 'Store Helicopter',
                    canInteract = function()
                        return cache.vehicle and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        vehicles.store(cache.vehicle)
                    end,
                    groups = helipad.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

CreateThread(function()
    Wait(150)

    for job, data in pairs(sharedConfig.departments) do
        createBlip(data.blip)
        createManagement(job, data.management)
        createDuty(job, data.duty)
        createGarage(job, data.garage)
        createHelipad(job, data.helipad)
    end
end)