---@param source number
---@param model string
---@param spawn vector4
lib.callback.register('s_police:server:spawnVehicle', function(source, model, spawn)
    local ped = GetPlayerPed(source)
    local netId, veh = qbx.spawnVehicle({
        spawnSource = spawn,
        model = model,
        warp = ped
    })

    local plate = ('LSPD%s'):format(math.random(1000, 9999))

    SetVehicleNumberPlateText(veh, plate)
    exports.qbx_vehiclekeys:GiveKeys(source, plate)

    return netId
end)