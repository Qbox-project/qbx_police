local VEHICLES = exports.qbx_core:GetVehiclesByName()

---@param vehicle integer
local function store(vehicle)
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

return {
    openGarage = openGarage,
    openHelipad = openHelipad,
    store = store
}