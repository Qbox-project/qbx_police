local config = require 'config.client'
local sharedConfig = require 'config.shared'

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

CreateThread(function()
    Wait(150)

    for job, data in pairs(sharedConfig.departments) do
        createBlip(data.blip)
        createDuty(job, data.duty)
    end
end)