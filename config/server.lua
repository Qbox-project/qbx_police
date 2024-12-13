return {
    consumeHandcuffs = true, -- If true, handcuffs will be consumed when putting someone in handcuffs and will be returned upon uncuffing them with a handcuff key
    giveVehicleKeys = function(src, vehicle)
        return exports.qbx_vehiclekeys:GiveKeys(src, vehicle)
    end,
}