local sharedConfig = require 'config.shared'

---@param job string
---@param personalStash PersonalStashData
local function registerPersonalStash(job, personalStash)
    if not job or not personalStash then return end

    for i = 1, #personalStash do
        local stash = personalStash[i]
        local stashName = ('%s-%s-PersonalStash'):format(i, job)

        exports.ox_inventory:RegisterStash(stashName, 'Personal Stash', stash.slots or 100, stash.weight or 100000, true, stash.groups)
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