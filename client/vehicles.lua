local VEHICLES = exports.qbx_core:GetVehiclesByName()

---@param vehicle integer
local function kickOutOfVehicle(vehicle)
    local seats = GetVehicleMaxNumberOfPassengers(vehicle)

    for i = -1, seats do
        local ped = GetPedInVehicleSeat(vehicle, i)

        if ped then
            TaskLeaveVehicle(ped, vehicle, 0)
        end
    end
end

---@param veicle integer
---@return boolean
local function checkSeats(veicle)
    local seats = GetVehicleMaxNumberOfPassengers(veicle)

    for i = -1, seats do
        local ped = GetPedInVehicleSeat(veicle, i)

        if ped then
            return false
        end
    end

    return true
end

---@param vehicle integer
local function store(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    kickOutOfVehicle(vehicle)
    Wait(1500)
    DeleteVehicle(vehicle)
end

---@param vehicle CatalogueItem
---@param spawn vector4
local function takeOut(vehicle, spawn)
    if cache.vehicle then
        exports.qbx_core:Notify(locale('notify.in_vehicle'), 'error')
        return
    end

    local netId = lib.callback.await('qbx_police:server:spawnVehicle', false, vehicle, spawn)

    lib.waitFor(function()
        return NetworkDoesEntityExistWithNetworkId(netId)
    end, locale('vehicles.something_wrong'))
end

---@param garage table
local function openGarage(garage)
    local options = {}

    for i = 1, #garage.catalogue do
        local vehicle = garage.catalogue[i]

        if vehicle.grade <= QBX.PlayerData.job.grade.level then
            local title = ('%s %s'):format(VEHICLES[vehicle.name].brand, VEHICLES[vehicle.name].name)

            options[#options + 1] = {
                title = title,
                arrow = true,
                onSelect = function()
                    takeOut(vehicle, garage.spawn)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'garageMenu',
        title = locale('vehicles.garage_title'),
        options = options
    })

    lib.showContext('garageMenu')
end

---@param helipad table
local function openHelipad(helipad)
    local options = {}

    for i = 1, #helipad.catalogue do
        local helicopter = helipad.catalogue[i]

        if helicopter.grade <= QBX.PlayerData.job.grade.level then
            local title = ('%s %s'):format(VEHICLES[helicopter.name].brand, VEHICLES[helicopter.name].name)

            options[#options + 1] = {
                title = title,
                arrow = true,
                onSelect = function()
                    takeOut(helicopter, helipad.spawn)
                end,
            }
        end
    end

    if #options == 0 then
        exports.qbx_core:Notify(locale('vehicles.not_helipad_grade'), 'error')
        return
    end

    lib.registerContext({
        id = 'helipadMenu',
        title = locale('vehicles.helipad_title'),
        options = options
    })

    lib.showContext('helipadMenu')
end

local function impound()
    if not cache.vehicle then
        exports.qbx_core:Notify(locale('notify.not_in_vehicle'), 'error')
        return
    end

    if lib.progressBar({
        duration = 5000,
        label = locale('progress.impound'),
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = false,
            mouse = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        },
    }) then
        local netId = NetworkGetNetworkIdFromEntity(cache.vehicle)
        local canBeImpounded = lib.callback.await('qbx_police:server:canImpound', false, netId)

        if not canBeImpounded then
            store(cache.vehicle)
            return
        end

        local isVehicleEmpty = checkSeats(cache.vehicle)

        if not isVehicleEmpty then
            exports.qbx_core:Notify(locale('notify.still_occupied'), 'error')
            return
        end

        local impounded = lib.callback.await('qbx_police:server:impoundVehicle', false, netId)

        if impounded then
            exports.qbx_core:Notify(locale('notify.impounded'), 'success')
        else
            exports.qbx_core:Notify(locale('notify.failed_impound'), 'error')
        end
    else
        exports.qbx_core:Notify(locale('notify.canceled'), 'error')
    end
end

local function confiscate()
    if not cache.vehicle then
        exports.qbx_core:Notify(locale('notify.not_in_vehicle'), 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(cache.vehicle)
    local canBeConfiscated = lib.callback.await('qbx_police:server:canImpound', false, netId)

    if not canBeConfiscated then
        exports.qbx_core:Notify(locale('notify.cannot_confiscate'), 'error')
        return
    end

    if lib.progressBar({
        duration = 5000,
        label = locale('progress.confiscate'),
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = false,
            mouse = false,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        },
    }) then
        local isVehicleEmpty = checkSeats(cache.vehicle)

        if not isVehicleEmpty then
            exports.qbx_core:Notify(locale('notify.still_occupied'), 'error')
            return
        end

        local confiscated = lib.callback.await('qbx_police:server:confiscateVehicle', false, netId)

        if confiscated then
            exports.qbx_core:Notify(locale('notify.confiscated'), 'success')
        else
            exports.qbx_core:Notify(locale('notify.failed_confiscate'), 'error')
        end
    else
        exports.qbx_core:Notify(locale('notify.canceled'), 'error')
    end
end

return {
    openGarage = openGarage,
    openHelipad = openHelipad,
    store = store,
    impound = impound,
    confiscate = confiscate
}