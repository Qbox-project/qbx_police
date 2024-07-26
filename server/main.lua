local sharedConfig = require 'config.shared'

---@param job string
---@param personalStash table
local function registerPersonalStash(job, personalStash)
    if not job or not personalStash then return end

    for i = 1, #personalStash do
        local stash = personalStash[i]

        exports.ox_inventory:RegisterStash(('%s%sPersonalStash'):format(i, job), 'Personal Stash', stash.slots, stash.weight, true, stash.groups)
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

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for name, data in pairs(sharedConfig.departments) do
        registerPersonalStash(name, data.personalStash)
    end
end)