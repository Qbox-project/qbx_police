return {
    refreshRate = 1000, -- Time in ms between the refreshing of officer blips

    giveVehicleKeys = function(source, vehicle)
        return exports.qbx_vehiclekeys:GiveKeys(source, vehicle)
    end,
}