local config = require 'config.client'
local sharedConfig = require 'config.shared'
local vehicles = require 'client.vehicles'

---@param department? BlipData
local function createBlip(department)
    if not department then return end

    local blip = AddBlipForCoord(department.coords.x, department.coords.y, department.coords.z)
    SetBlipSprite(blip, department.sprite or 60)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, department.scale or 0.8)
    SetBlipColour(blip, department.color or 29)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(department.label or locale('blip'))
    EndTextCommandSetBlipName(blip)
end

---@param job? string
---@param department? ManagementData
local function createDuty(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local location = department[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-Duty'):format(job),
                    icon = 'fa-solid fa-clipboard-user',
                    label = locale('targets.duty'),
                    serverEvent = 'QBCore:ToggleDuty',
                    groups = location.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param department? DutyData
local function createManagement(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local location = department[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-BossMenu'):format(job),
                    icon = 'fa-solid fa-people-roof',
                    label = locale('targets.boss_menu'),
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

---@param job? string
---@param armories? ArmoryData
local function createArmory(job, armories)
    if not job or not armories then return end

    for i = 1, #armories do
        local armory = armories[i]

        for ii = 1, #armory.locations do
            local location = armory.locations[ii]

            exports.ox_target:addSphereZone({
                coords = location,
                radius = armory.radius or 1.5,
                debug = config.debugPoly,
                options = {
                    {
                        name = ('%s-Armory'):format(job),
                        icon = 'fa-solid fa-person-rifle',
                        label = locale('targets.armory'),
                        canInteract = function()
                            return QBX.PlayerData.job.onduty
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('shop', { type = armory.shopType, id = ii })
                        end,
                        groups = armory.groups,
                        distance = 1.5,
                    },
                }
            })
        end
    end
end

---@param job? string
---@param stashes? PersonalStashData
local function createPersonalStash(job, stashes)
    if not job or not stashes then return end

    for i = 1, #stashes do
        local stash = stashes[i]
        local stashId = ('%s-PersonalStash'):format(job)

        exports.ox_target:addSphereZone({
            coords = stash.coords,
            radius = stash.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = stashId,
                    icon = 'fa-solid fa-box-archive',
                    label = locale('targets.personal_stash'),
                    canInteract = function()
                        return QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', stashId)
                    end,
                    groups = stash.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param department? EvidenceData
local function createEvidence(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local evidence = department[i]

        exports.ox_target:addSphereZone({
            coords = evidence.coords,
            radius = evidence.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-EvidenceDrawers'):format(job),
                    icon = 'fa-solid fa-box-archive',
                    label = locale('targets.evidence_drawers'),
                    canInteract = function()
                        return QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        exports.ox_inventory:openInventory('policeevidence')
                    end,
                    groups = evidence.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param garages? VehicleData
local function createGarage(job, garages)
    if not job or not garages then return end

    for i = 1, #garages do
        local garage = garages[i]

        lib.zones.sphere({
            coords = garage.coords,
            radius = garage.radius,
            debug = config.debugPoly,
            onEnter = function()
                local hasGroup = exports.qbx_core:HasGroup(garage.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                lib.showTextUI(cache.vehicle and locale('vehicles.store_vehicle') or locale('vehicles.open_garage'))
            end,
            inside = function()
                local hasGroup = exports.qbx_core:HasGroup(garage.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                if IsControlJustReleased(0, 38) then
                    if cache.vehicle then
                        vehicles.store(cache.vehicle)
                    else
                        vehicles.openHelipad(garage)
                    end

                    lib.hideTextUI()
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end

---@param job? string
---@param helipads? VehicleData
local function createHelipad(job, helipads)
    if not job or not helipads then return end

    for i = 1, #helipads do
        local helipad = helipads[i]

        lib.zones.sphere({
            coords = helipad.coords,
            radius = helipad.radius,
            debug = config.debugPoly,
            onEnter = function()
                local hasGroup = exports.qbx_core:HasGroup(helipad.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                lib.showTextUI(cache.vehicle and locale('vehicles.store_helicopter') or locale('vehicles.open_helipad'))
            end,
            inside = function()
                local hasGroup = exports.qbx_core:HasGroup(helipad.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                if IsControlJustReleased(0, 38) then
                    if cache.vehicle then
                        vehicles.store(cache.vehicle)
                    else
                        vehicles.openHelipad(helipad)
                    end

                    lib.hideTextUI()
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end

local function registerAliveRadial()
    lib.registerRadial({
        id = 'policeMenu',
        items = {
            {
                icon = 'magnifying-glass',
                label = locale('radial.search'),
                onSelect = function()
                    exports.ox_inventory:openNearbyInventory()
                end,
            },
            {
                icon = 'heart-crack',
                label = locale('radial.officer_down_urgent'),
                onSelect = function()
                end,
            },
            {
                icon = 'heart-pulse',
                label = locale('radial.officer_down'),
                onSelect = function()
                end,
            },
            {
                icon = 'truck-fast',
                label = locale('radial.impound'),
                onSelect = function()
                    vehicles.impound()
                end,
            },
            {
                icon = 'truck-ramp-box',
                label = locale('radial.confiscate'),
                onSelect = function()
                    vehicles.confiscate()
                end,
            },
        }
    })
end

local function registerDeadRadial()
    lib.registerRadial({
        id = 'policeMenu',
        items = {
            {
                icon = 'heart-crack',
                label = locale('radial.officer_down_urgent'),
                onSelect = function()
                end,
            },
            {
                icon = 'heart-pulse',
                label = locale('radial.officer_down'),
                onSelect = function()
                end,
            },
        }
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    lib.removeRadialItem('leo')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource or QBX.PlayerData.job.type ~= 'leo' then return end

    if QBX.PlayerData.metadata.isdead then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'leo',
        icon = 'shield-halved',
        label = locale('radial.label'),
        menu = 'policeMenu'
    })
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if QBX.PlayerData.job.type ~= 'leo' then return end

    if QBX.PlayerData.metadata.isdead then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'leo',
        icon = 'shield-halved',
        label = locale('radial.label'),
        menu = 'policeMenu'
    })
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    lib.removeRadialItem('leo')

    if job.type ~= 'leo' then return end

    if QBX.PlayerData.metadata.isdead then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'leo',
        icon = 'shield-halved',
        label = locale('radial.label'),
        menu = 'policeMenu'
    })
end)

RegisterNetEvent('qbx_core:client:onSetMetaData', function(key, oldValue, newValue)
    if QBX.PlayerData.job.type ~= 'leo' or (key ~= 'isdead' and key ~= 'inlaststand') or oldValue == newValue then return end

    lib.removeRadialItem('leo')

    if newValue then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'leo',
        icon = 'shield-halved',
        label = locale('radial.label'),
        menu = 'policeMenu'
    })
end)

CreateThread(function()
    Wait(150)

    for job, data in pairs(sharedConfig.departments) do
        createBlip(data.blip)
        createDuty(job, data.duty)
        createManagement(job, data.management)
        createArmory(job, data.armory)
        createPersonalStash(job, data.personalStash)
        createEvidence(job, data.evidence)
        createGarage(job, data.garage)
        createHelipad(job, data.helipad)
    end
end)