local config = require 'config.client'
local sharedConfig = require 'config.shared'
local currentGarage = 0
local inFingerprint = false
local fingerprintSessionId = nil
local inStash = false
local inTrash = false
local inHelicopter = false
local inImpound = false
local inGarage = false
local inPrompt = false

local function openFingerprintUi()
    SendNUIMessage({
        type = 'fingerprintOpen'
    })
    SetNuiFocus(true, true)
end

local function setCarItemsInfo()
    local items = {}
    for _, item in pairs(config.carItems) do
        local itemInfo = exports.ox_inventory:Items()[item.name:lower()]
        items[item.slot] = {
            name = itemInfo.name,
            amount = tonumber(item.amount),
            info = item.info,
            label = itemInfo.label,
            description = itemInfo.description or '',
            weight = itemInfo.weight,
            type = itemInfo.type,
            unique = itemInfo.unique,
            useable = itemInfo.useable,
            image = itemInfo.image,
            slot = item.slot
        }
    end
    config.carItems = items
end

local function doCarDamage(currentVehicle, veh)
    local smash = false
    local damageOutside = false
    local popTires = false
    local engine = veh.engine + 0.0
    local body = veh.body + 0.0

    if engine < 200.0 then engine = 200.0 end
    if engine > 1000.0 then engine = 950.0 end
    if body < 150.0 then body = 150.0 end
    if body < 950.0 then smash = true end
    if body < 920.0 then damageOutside = true end
    if body < 920.0 then popTires = true end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)

    if smash then
        for i = 0, 4 do
            SmashVehicleWindow(currentVehicle, i)
        end
    end

    if damageOutside then
        SetVehicleDoorBroken(currentVehicle, 1, true)
        SetVehicleDoorBroken(currentVehicle, 6, true)
        SetVehicleDoorBroken(currentVehicle, 4, true)
    end

    if popTires then
        for i = 1, 4 do
            SetVehicleTyreBurst(currentVehicle, i, false, 990.0)
        end
    end

    if body < 1000 then
        SetVehicleBodyHealth(currentVehicle, 985.1)
    end
end

local function takeOutImpound(vehicle)
    if not inImpound then return end
    local coords = sharedConfig.locations.impound[currentGarage]
    if not coords then return end

    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, vehicle.vehicle, coords, vehicle.plate, vehicle.id)

    local veh = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)

    local properties = lib.callback.await('qb-garage:server:GetVehicleProperties', false, vehicle.plate)
    lib.setVehicleProperties(veh, properties)
    SetVehicleFuelLevel(veh, vehicle.fuel)
    doCarDamage(veh, vehicle)
    TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)
    SetVehicleEngineOn(veh, true, true, false)
end

local function takeOutVehicle(vehicleInfo)
    if not inGarage then return end
    local coords = sharedConfig.locations.vehicle[currentGarage]
    if not coords then return end
    local pattern = ''
    for _ = 1, 8 - #sharedConfig.policePlatePrefix do
        pattern = pattern..'1'
    end
    local plate = sharedConfig.policePlatePrefix..lib.string.random(pattern):upper()
    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, vehicleInfo, coords, plate, true)

    local veh = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end, nil, sharedConfig.timeout)

    assert(veh ~= 0, 'Something went wrong spawning the vehicle')

    setCarItemsInfo()
    SetEntityHeading(veh, coords.w)
    SetVehicleFuelLevel(veh, 100.0)
    if config.vehicleSettings[vehicleInfo] then
        if config.vehicleSettings[vehicleInfo].extras then
            qbx.setVehicleExtras(veh, config.vehicleSettings[vehicleInfo].extras)
        end
        if config.vehicleSettings[vehicleInfo].livery then
            SetVehicleLivery(veh, config.vehicleSettings[vehicleInfo].livery)
        end
    end
    SetVehicleEngineOn(veh, true, true, false)
end

local function addGarageMenuItems(destinationOptions, sourceOptions)
    for veh, label in pairs(sourceOptions) do
        destinationOptions[#destinationOptions + 1] = {
            title = label,
            onSelect = function()
                takeOutVehicle(veh)
            end,
        }
    end

    return destinationOptions
end

local function openGarageMenu()
    local authorizedVehicles = config.authorizedVehicles[QBX.PlayerData.job.grade.level]
    local options = {}

    options = addGarageMenuItems(options, authorizedVehicles)
    options = addGarageMenuItems(options, config.whitelistedVehicles)

    lib.registerContext({
        id = 'vehicleMenu',
        title = locale('menu.garage_title'),
        options = options,
    })
    lib.showContext('vehicleMenu')
end

local function openImpoundMenu()
    local options = {}
    local result = lib.callback.await('police:GetImpoundedVehicles', false)
    if not result then
        exports.qbx_core:Notify(locale('error.no_impound'), 'error')
    else
        local vehicles = exports.qbx_core:GetVehiclesByName()
        for _, v in pairs(result) do
            local enginePercent = qbx.math.round(v.engine / 10, 0)
            local currentFuel = v.fuel
            local vName = vehicles[v.vehicle].name

            options[#options + 1] = {
                title = vName..' ['..v.plate..']',
                onSelect = function()
                    takeOutImpound(v)
                end,
                metadata = {
                    {label = 'Engine', value = enginePercent .. ' %'},
                    {label = 'Fuel', value = currentFuel .. ' %'}
                },
            }
        end
    end

    lib.registerContext({
        id = 'impoundMenu',
        title = locale('menu.impound'),
        options = options
    })
    lib.showContext('impoundMenu')
end

---TODO: global evidence lockers instead of location specific
local function openEvidenceLockerSelectInput(currentEvidence)
    local input = lib.inputDialog(locale('info.evidence_stash', currentEvidence), {locale('info.slot')})
    if not input then return end
    local slotNumber = tonumber(input[1])
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', locale('info.current_evidence', currentEvidence, slotNumber), {
        maxweight = 4000000,
        slots = 500,
    })
    TriggerEvent('inventory:client:SetCurrentStash', locale('info.current_evidence', currentEvidence, slotNumber))
end

local function openEvidenceMenu()
    local pos = GetEntityCoords(cache.ped)
    for k, v in pairs(sharedConfig.locations.evidence) do
        if #(pos - v) < 1 then
            openEvidenceLockerSelectInput(k)
            return
        end
    end
end

local function spawnHelicopter()
    if not inHelicopter then return end
    local plyCoords = GetEntityCoords(cache.ped)
    local coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, GetEntityHeading(cache.ped))
    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, config.policeHelicopter, coords, 'ZULU'..lib.string.random('1111'), true)
    local heli = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end, nil, sharedConfig.timeout)
    SetVehicleLivery(heli , 0)
    SetVehicleMod(heli, 0, 48, false)
    SetEntityHeading(heli, coords.w)
    SetVehicleFuelLevel(heli, 100.0)
    SetVehicleEngineOn(heli, true, true, false)
end

local function scanFingerprint()
    if not inFingerprint then return end
    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.5, false)
    if not playerId then
        return exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
    end
    TriggerServerEvent('police:server:showFingerprint', GetPlayerServerId(playerId))
end

local function uiPrompt(promptType, id)
    if QBX.PlayerData.job.type ~= 'leo' then return end
    CreateThread(function()
        while inPrompt do
            Wait(0)
            if IsControlJustReleased(0, 38) then
                if promptType == 'duty' then
                    ToggleDuty()
                    lib.hideTextUI()
                    break
                elseif promptType == 'garage' then
                    if not inGarage then return end
                    if cache.vehicle then
                        DeleteVehicle(cache.vehicle)
                        lib.hideTextUI()
                        break
                    else
                        openGarageMenu()
                        lib.hideTextUI()
                        break
                    end
                elseif promptType == 'evidence' then
                    openEvidenceMenu()
                    lib.hideTextUI()
                    break
                elseif promptType == 'impound' then
                    if not inImpound then return end
                    if cache.vehicle then
                        DeleteVehicle(cache.vehicle)
                        lib.hideTextUI()
                        break
                    else
                        openImpoundMenu()
                        lib.hideTextUI()
                        break
                    end
                elseif promptType == 'heli' then
                    if not inHelicopter then return end
                    if cache.vehicle then
                        DeleteVehicle(cache.vehicle)
                        lib.hideTextUI()
                        break
                    else
                        spawnHelicopter()
                        lib.hideTextUI()
                        break
                    end
                elseif promptType == 'fingerprint' then
                    scanFingerprint()
                    lib.hideTextUI()
                    break
                elseif promptType == 'trash' then
                    if not inTrash then return end
                    exports.ox_inventory:openInventory('stash', ('policetrash_%s'):format(id))
                    break
                elseif promptType == 'stash' then
                    if not inStash then return end
                    exports.ox_inventory:openInventory('stash', {id = 'policelocker'})
                    break
                end
            end
        end
    end)
end

RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('police:client:showFingerprint', function(playerId)
    openFingerprintUi()
    fingerprintSessionId = playerId
end)

RegisterNetEvent('police:client:showFingerprintId', function(fid)
    SendNUIMessage({
        type = 'updateFingerprintId',
        fingerprintId = fid
    })
    PlaySound(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', false, 0, true)
end)

RegisterNUICallback('doFingerScan', function(_, cb)
    TriggerServerEvent('police:server:showFingerprintId', fingerprintSessionId)
    cb('ok')
end)

RegisterNetEvent('police:client:SendEmergencyMessage', function(coords, message)
    TriggerServerEvent('police:server:SendEmergencyMessage', coords, message)
    TriggerEvent('police:client:CallAnim')
end)

RegisterNetEvent('police:client:EmergencySound', function()
    PlaySound(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', false, 0, true)
end)

RegisterNetEvent('police:client:CallAnim', function()
    local isCalling = true
    local callCount = 5
    lib.playAnim(cache.ped, 'cellphone@', 'cellphone_call_listen_base', 3.0, -1, -1, 49, 0, false, false, false)
    Wait(1000)
    CreateThread(function()
        while isCalling do
            Wait(1000)
            callCount -= 1
            if callCount <= 0 then
                isCalling = false
                StopAnimTask(cache.ped, 'cellphone@', 'cellphone_call_listen_base', 1.0)
            end
        end
    end)
end)

RegisterNetEvent('police:client:ImpoundVehicle', function(fullImpound, price)
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = GetVehicleFuelLevel(vehicle)

    if cache.vehicle or #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) > 5.0 then return end

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = locale('progressbar.impound'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base',
            flags = 1
        },
        prop = {
            {
                model = `prop_notepad_01`,
                bone = 18905,
                pos = vec3(0.1, 0.02, 0.05),
                rot = vec3(10.0, 0.0, 0.0)
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec3(0.11, -0.02, 0.001),
                rot = vec3(-120.0, 0.0, 0.0)
            }
        },
    })
    then
        local plate = qbx.getVehiclePlate(vehicle)
        TriggerServerEvent('police:server:Impound', plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)
        DeleteVehicle(vehicle)
        exports.qbx_core:Notify(locale('success.impounded'), 'success')
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end

    ClearPedTasks(cache.ped)
end)

RegisterNetEvent('police:client:CheckStatus', function()
    if QBX.PlayerData.job.type ~= 'leo' then return end

    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
    if not playerId then
        return exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
    end
    local result = lib.callback.await('police:GetPlayerStatus', false, playerId)
    if not result then return end
    for _, v in pairs(result) do
        exports.qbx_core:Notify(v, 'success')
    end
end)

function ToggleDuty()
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateCurrentCops')
end

if config.useTarget then
    CreateThread(function()
        for i = 1, #sharedConfig.locations.duty do
            exports.ox_target:addBoxZone({
                coords = sharedConfig.locations.duty[i],
                size = vec3(1,1,3),
                debug = config.polyDebug,
                options = {{
                    distance = 1.5,
                    label = locale('info.onoff_duty'),
                    icon = 'fa-solid fa-sign-in-alt',
                    onSelect = ToggleDuty,
                    groups = 'police'
                }}
            })
        end
    end)
else
    for i = 1, #sharedConfig.locations.duty do
        lib.zones.box({
            coords = sharedConfig.locations.duty[i],
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' then return end
                inPrompt = true
                lib.showTextUI(locale(QBX.PlayerData.job.onduty and 'info.off_duty' or 'info.on_duty'))
                uiPrompt('duty')
            end,
            onExit = function()
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end
end

CreateThread(function()
    -- Police Trash
    for i = 1, #sharedConfig.locations.trash do
        lib.zones.box({
            coords = sharedConfig.locations.trash[i],
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
                inTrash = true
                inPrompt = true
                lib.showTextUI(locale('info.trash_enter'))
                uiPrompt('trash', i)
            end,
            onExit = function()
                inTrash = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Fingerprints
    for i = 1, #sharedConfig.locations.fingerprint do
        lib.zones.box({
            coords = sharedConfig.locations.fingerprint[i],
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
                inFingerprint = true
                inPrompt = true
                lib.showTextUI(locale('info.scan_fingerprint'))
                uiPrompt('fingerprint')
            end,
            onExit = function()
                inFingerprint = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Helicopter
    for i = 1, #sharedConfig.locations.helicopter do
        lib.zones.box({
            coords = sharedConfig.locations.helicopter[i],
            size = vec3(4, 4, 4),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
                inHelicopter = true
                inPrompt = true
                uiPrompt('heli')
                lib.showTextUI(locale(cache.vehicle and 'info.store_heli' or 'info.take_heli'))
            end,
            onExit = function()
                inHelicopter = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Police Impound
    for i = 1, #sharedConfig.locations.impound do
        lib.zones.box({
            coords = sharedConfig.locations.impound[i],
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
                inImpound = true
                inPrompt = true
                currentGarage = i
                lib.showTextUI(locale(cache.vehicle and 'info.impound_veh' or 'menu.pol_impound'))
                uiPrompt('impound')
            end,
            onExit = function()
                inImpound = false
                inPrompt = false
                lib.hideTextUI()
                currentGarage = 0
            end
        })
    end

    -- Police Garage
    for i = 1, #sharedConfig.locations.vehicle do
        lib.zones.box({
            coords = sharedConfig.locations.vehicle[i],
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
                inGarage = true
                inPrompt = true
                currentGarage = i
                lib.showTextUI(locale(cache.vehicle and 'info.store_veh' or 'info.grab_veh'))
                uiPrompt('garage')
            end,
            onExit = function()
                inGarage = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end
end)
