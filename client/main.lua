local config = require 'config.client'
local sharedConfig = require 'config.shared'
local vehicles = require 'client.vehicles'

---@param department BlipData
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

---@param job string
---@param department ManagementData
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

---@param job string
---@param department DutyData
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

---@param job string
---@param department ArmoryData
local function createArmory(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local armory = department[i]

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
                            exports.ox_inventory:openInventory('shop', { type = department.shopType, id = ii })
                        end,
                        groups = armory.groups,
                        distance = 1.5,
                    },
                }
            })
        end
    end
end

---@param job string
---@param department PersonalStashData
local function createPersonalStash(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local stash = department[i]
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

---@param job string
---@param department EvidenceData
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

---@param job string
---@param department VehicleData
local function createGarage(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local garage = department[i]

        exports.ox_target:addSphereZone({
            coords = garage.coords,
            radius = garage.radius,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-Garage'):format(job),
                    icon = 'fa-solid fa-warehouse',
                    label = locale('targets.garage'),
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
                    name = ('%s-GarageStore'):format(job),
                    icon = 'fa-solid fa-square-parking',
                    label = locale('targets.store_vehicle'),
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
---@param department VehicleData
local function createHelipad(job, department)
    if not job or not department then return end

    for i = 1, #department do
        local helipad = department[i]

        exports.ox_target:addSphereZone({
            coords = helipad.coords,
            radius = helipad.radius,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-Helipad'):format(job),
                    icon = 'fa-solid fa-helicopter-symbol',
                    label = locale('targets.helipad'),
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
                    name = ('%s-HelipadStore'):format(job),
                    icon = 'fa-solid fa-square-parking',
                    label = locale('targets.store_helicopter'),
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

local function registerAliveRadial()
    lib.registerRadial({
        id = 'policeMenu',
        items = {
            {
                icon = 'lock',
                label = locale('radial.cuff'),
                onSelect = function()
                end,
            },
            {
                icon = 'lock-open',
                label = locale('radial.uncuff'),
                onSelect = function()
                end,
            },
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
                end,
            },
            {
                icon = 'truck-ramp-box',
                label = locale('radial.confiscate'),
                onSelect = function()
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

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    lib.removeRadialItem('leo')

    if QBX.PlayerData.job.type ~= 'leo' then return end

    lib.addRadialItem({
        id = 'leo',
        icon = 'shield-halved',
        label = locale('radial.label'),
        menu = 'policeMenu'
    })
end)

AddStateBagChangeHandler('DEATH_STATE_STATE_BAG', nil, function(bagName, _, dead)
    local player = GetPlayerFromStateBagName(bagName)

    if player ~= cache.playerId or QBX.PlayerData?.job?.type ~= 'leo' then return end

    lib.removeRadialItem('leo')

    if dead then
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