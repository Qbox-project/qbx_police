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

local function isLeo(level, onduty)
    local playerJob = QBX.PlayerData.job
    return playerJob.type ~= 'leo' or playerJob.grade.level >= (level or 0) or playerJob.onduty == (onduty == nil and true or onduty)
end

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
    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, vehicle.vehicle, coords, vehicle.plate, true)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local properties = lib.callback.await('qb-garage:server:GetVehicleProperties', false, vehicle.plate)
    local veh = NetToVeh(netId)
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

    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, vehicleInfo, coords, Lang:t('info.police_plate')..tostring(math.random(1000, 9999)), true)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetToVeh(netId)
    if veh == 0 then
        exports.qbx_core:Notify('Something went wrong spawning the vehicle', 'error')
        return
    end
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

local function openGarageMenu()
    local authorizedVehicles = config.authorizedVehicles[QBX.PlayerData.job.grade.level]
    local options = {}

    for veh, label in pairs(authorizedVehicles) do
        options[#options + 1] = {
            title = label,
            onSelect = function()
                takeOutVehicle(veh)
            end,
        }
    end

    for veh, label in pairs(config.whitelistedVehicles) do
        options[#options + 1] = {
            title = label,
            onSelect = function()
                takeOutVehicle(veh)
            end,
        }
    end

    lib.registerContext({
        id = 'vehicleMenu',
        title = Lang:t('menu.garage_title'),
        options = options,
    })
    lib.showContext('vehicleMenu')
end

local function openImpoundMenu()
    local options = {}
    local result = lib.callback.await('police:GetImpoundedVehicles', false)
    if not result then
        exports.qbx_core:Notify(Lang:t('error.no_impound'), 'error')
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
        title = Lang:t('menu.impound'),
        options = options
    })
    lib.showContext('impoundMenu')
end

---TODO: global evidence lockers instead of location specific
local function openEvidenceLockerSelectInput(currentEvidence)
    local input = lib.inputDialog(Lang:t('info.evidence_stash', {value = currentEvidence}), {Lang:t('info.slot')})
    if not input then return end
    local slotNumber = tonumber(input[1])
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', Lang:t('info.current_evidence', {value = currentEvidence, value2 = slotNumber}), {
        maxweight = 4000000,
        slots = 500,
    })
    TriggerEvent('inventory:client:SetCurrentStash', Lang:t('info.current_evidence', {value = currentEvidence, value2 = slotNumber}))
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
    local netId = lib.callback.await('qbx_policejob:server:spawnVehicle', false, config.policeHelicopter, coords, 'ZULU'..tostring(math.random(1000, 9999)), true)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local heli = NetToVeh(netId)
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
        exports.qbx_core:Notify(Lang:t('error.none_nearby'), 'error')
        return
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
    lib.requestAnimDict('cellphone@')
    TaskPlayAnim(cache.ped, 'cellphone@', 'cellphone_call_listen_base', 3.0, -1, -1, 49, 0, false, false, false)
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
    if not DoesEntityExist(vehicle) then return end

    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = GetVehicleFuelLevel(vehicle)

    if #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) > 5.0 or cache.vehicle then return end

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = Lang:t('progressbar.impound'),
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
                pos = {x = 0.1, y = 0.02, z = 0.05},
                rot = {x = 10.0, y = 0.0, z = 0.0}
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = {x = 0.11, y = -0.02, z = 0.001},
                rot = {x = -120.0, y = 0.0, z = 0.0}
            }
        },
    })
    then
        local plate = qbx.getVehiclePlate(vehicle)
        TriggerServerEvent('police:server:Impound', plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)
        DeleteVehicle(vehicle)
        exports.qbx_core:Notify(Lang:t('success.impounded'), 'success')
        ClearPedTasks(cache.ped)
    else
        ClearPedTasks(cache.ped)
        exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
    end
end)

RegisterNetEvent('police:client:CheckStatus', function()
    if QBX.PlayerData.job.type ~= 'leo' then return end

    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
    if not playerId then
        exports.qbx_core:Notify(Lang:t('error.none_nearby'), 'error')
        return
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
                options = {
                    {
			distance = 1.5,
                        label = Lang:t('info.onoff_duty'),
                        icon = 'fa-solid fa-sign-in-alt',
                        onSelect = ToggleDuty,
                        groups = 'police'
                    }
                }
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
                inPrompt = true
                if not QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('info.on_duty'))
                else
                    lib.showTextUI(Lang:t('info.off_duty'))
                end
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
        local v = sharedConfig.locations.trash[i]
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                inTrash = true
                inPrompt = true
                if QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('info.trash_enter'))
                    uiPrompt('trash', i)
                end
            end,
            onExit = function()
                inTrash = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Fingerprints
    for _, v in pairs(sharedConfig.locations.fingerprint) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                inFingerprint = true
                inPrompt = true
                if QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('info.scan_fingerprint'))
                    uiPrompt('fingerprint')
                end
            end,
            onExit = function()
                inFingerprint = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Helicopter
    for _, v in pairs(sharedConfig.locations.helicopter) do
        lib.zones.box({
            coords = v,
            size = vec3(4, 4, 4),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                inHelicopter = true
                inPrompt = true
                if QBX.PlayerData.job.onduty then
                    uiPrompt('heli')
                    if cache.vehicle then
                        lib.showTextUI(Lang:t('info.store_heli'))
                    else
                        lib.showTextUI(Lang:t('info.take_heli'))
                    end
                end
            end,
            onExit = function()
                inHelicopter = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- Police Impound
    for k, v in pairs(sharedConfig.locations.impound) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                inImpound = true
                inPrompt = true
                currentGarage = k
                if QBX.PlayerData.job.onduty then
                    if cache.vehicle then
                        lib.showTextUI(Lang:t('info.impound_veh'))
                        uiPrompt('impound')
                    else
                        lib.showTextUI(Lang:t('menu.pol_impound'))
                        uiPrompt('impound')
                    end
                end
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
    for k, v in pairs(sharedConfig.locations.vehicle) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            debug = config.polyDebug,
            onEnter = function()
                if QBX.PlayerData.job.onduty and QBX.PlayerData.job.type == 'leo' then
                    inGarage = true
                    inPrompt = true
                    currentGarage = k
                    if cache.vehicle then
                        lib.showTextUI(Lang:t('info.store_veh'))
                    else
                        lib.showTextUI('[E] - Vehicle Garage')
                    end
                    uiPrompt('garage')
                end
            end,
            onExit = function()
                inGarage = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end
end)
