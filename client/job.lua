-- Variables
local currentGarage = 0
local FingerPrintSessionId = nil

local inPrompt = false
local hasOxInventory = GetResourceState('ox_inventory') ~= 'missing'

local function loadAnimDict(dict) -- interactions, job,
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

local function GetClosestPlayer() -- interactions, job, tracker
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

local function openFingerprintUI()
    SendNUIMessage({
        type = "fingerprintOpen"
    })
    SetNuiFocus(true, true)
end

local function SetCarItemsInfo()
	local items = {}
	for _, item in pairs(Config.CarItems) do
		local itemInfo = QBCore.Shared.Items[item.name:lower()]
		items[item.slot] = {
			name = itemInfo["name"],
			amount = tonumber(item.amount),
			info = item.info,
			label = itemInfo["label"],
			description = itemInfo["description"] and itemInfo["description"] or "",
			weight = itemInfo["weight"],
			type = itemInfo["type"],
			unique = itemInfo["unique"],
			useable = itemInfo["useable"],
			image = itemInfo["image"],
			slot = item.slot,
		}
	end
	Config.CarItems = items
end

local function doCarDamage(currentVehicle, veh)
	local smash = false
	local damageOutside = false
	local damageOutside2 = false
	local engine = veh.engine + 0.0
	local body = veh.body + 0.0

	if engine < 200.0 then engine = 200.0 end
    if engine  > 1000.0 then engine = 950.0 end
	if body < 150.0 then body = 150.0 end
	if body < 950.0 then smash = true end
	if body < 920.0 then damageOutside = true end
	if body < 920.0 then damageOutside2 = true end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)

	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end

	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end

	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end

	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end

local function TakeOutImpound(vehicle)
    local coords = Config.Locations["impound"][currentGarage]
    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                SetVehicleNumberPlateText(veh, vehicle.plate)
                exports['LegacyFuel']:SetFuel(veh, vehicle.fuel)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetVehicleEngineOn(veh, true, true, false)
            end, vehicle.plate)
        end, vehicle.vehicle, coords, true)
    end
end

local function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetCarItemsInfo()
            SetVehicleNumberPlateText(veh, Lang:t('info.police_plate')..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
            if Config.VehicleSettings[vehicleInfo] ~= nil then
                if Config.VehicleSettings[vehicleInfo].extras ~= nil then
                    QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
                end
                if Config.VehicleSettings[vehicleInfo].livery ~= nil then
                    SetVehicleLivery(veh, Config.VehicleSettings[vehicleInfo].livery)
                end
            end
            TaskWarpPedIntoVehicle(cache.ped, veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            TriggerServerEvent("inventory:server:addTrunkItems", QBCore.Functions.GetPlate(veh), Config.CarItems)
            SetVehicleEngineOn(veh, true, true, false)
        end, vehicleInfo, coords, true)
    end
end

local function IsArmoryWhitelist() -- being removed
    local retval = false

    if QBCore.Functions.GetPlayerData().job.type == 'leo' then
        retval = true
    end
    return retval
end

function MenuGarage()
    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    local registeredMenu = {
        id = 'policejob_vehicles_menu',
        title = Lang:t('menu.garage_title'),
        options = {}
    }
    local options = {}

    for veh, label in pairs(authorizedVehicles) do
        options[#options+1] = {
            title = label,
            description = '',
            event = 'police:client:TakeOutVehicle',
            args = {vehicle = veh}
        }
    end

    if IsArmoryWhitelist() then
        for veh, label in pairs(Config.WhitelistedVehicles) do
            options[#options+1] = {
                title = label,
                description = '',
                event = 'police:client:TakeOutVehicle',
                args = {vehicle = veh}
            }
        end
    end

    registeredMenu["options"] = options
    lib.registerContext(registeredMenu)
    lib.showContext('policejob_vehicles_menu')
end

function MenuImpound()
    local registeredMenu = {
        id = 'policejob_impound_menu',
        title = Lang:t('menu.impound'),
        options = {}
    }
    local options = {}

    QBCore.Functions.TriggerCallback("police:GetImpoundedVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify(Lang:t("error.no_impound"), "error", 5000)
        else
            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                options[#options+1] = {
                    title = vname.." ["..v.plate.."]",
                    description = '',
                    event = 'police:client:TakeOutImpound',
                    args = {vehicle = v},
                    metadata = {
                        {label = 'Engine', value = enginePercent .. ' %'},
                        {label = 'Fuel', value = currentFuel .. ' %'},
                    },
                }
            end
        end

        registeredMenu["options"] = options
        lib.registerContext(registeredMenu)
        lib.showContext('policejob_impound_menu')
    end)
end

function MenuEvidence()
    local currentEvidence = 0
    local pos = GetEntityCoords(PlayerPedId())

    for k, v in pairs(Config.Locations["evidence"]) do
        if #(pos - v) < 2 then
            currentEvidence = k
        end
    end
    lib.registerContext({
        id = 'policejob_evidence_menu',
        title = Lang:t('info.evidence_stash', {value = currentEvidence}),
        options = {
            {
                title = 'Police Evidence Stash '..currentEvidence,
                description = 'Open evidence stash',
                event = 'police:client:EvidenceStashDrawer',
                args = {currentEvidence = currentEvidence}
            }
        },
    })
    lib.showContext('policejob_evidence_menu')
end

--NUI Callbacks
RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

--Events
RegisterNetEvent('police:client:showFingerprint', function(playerId)
    openFingerprintUI()
    FingerPrintSessionId = playerId
end)

RegisterNetEvent('police:client:showFingerprintId', function(fid)
    SendNUIMessage({
        type = "updateFingerprintId",
        fingerprintId = fid
    })
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", false, 0, true)
end)

RegisterNUICallback('doFingerScan', function(_, cb)
    TriggerServerEvent('police:server:showFingerprintId', FingerPrintSessionId)
    cb("ok")
end)

RegisterNetEvent('police:client:SendEmergencyMessage', function(coords, message)
    TriggerServerEvent("police:server:SendEmergencyMessage", coords, message)
    TriggerEvent("police:client:CallAnim")
end)

RegisterNetEvent('police:client:EmergencySound', function()
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", false, 0, true)
end)

RegisterNetEvent('police:client:CallAnim', function()
    local isCalling = true
    local callCount = 5
    loadAnimDict("cellphone@")
    TaskPlayAnim(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 3.0, -1, -1, 49, 0, false, false, false)
    Wait(1000)
    CreateThread(function()
        while isCalling do
            Wait(1000)
            callCount -= 1
            if callCount <= 0 then
                isCalling = false
                StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 1.0)
            end
        end
    end)
end)

RegisterNetEvent('police:client:ImpoundVehicle', function(fullImpound, price)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = exports['LegacyFuel']:GetFuel(vehicle)
    if vehicle ~= 0 and vehicle then
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped, false) then
            QBCore.Functions.Progressbar('impound', Lang:t('progressbar.impound'), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'missheistdockssetup1clipboard@base',
                anim = 'base',
                flags = 1,
            }, {
                model = 'prop_notepad_01',
                bone = 18905,
                coords = { x = 0.1, y = 0.02, z = 0.05 },
                rotation = { x = 10.0, y = 0.0, z = 0.0 },
            },{
                model = 'prop_pencil_01',
                bone = 58866,
                coords = { x = 0.11, y = -0.02, z = 0.001 },
                rotation = { x = -120.0, y = 0.0, z = 0.0 },
            }, function() -- Play When Done
                local plate = QBCore.Functions.GetPlate(vehicle)
                TriggerServerEvent("police:server:Impound", plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)
                QBCore.Functions.DeleteVehicle(vehicle)
                TriggerEvent('QBCore:Notify', Lang:t('success.impounded'), 'success')
                ClearPedTasks(ped)
            end, function() -- Play When Cancel
                ClearPedTasks(ped)
                TriggerEvent('QBCore:Notify', Lang:t('error.canceled'), 'error')
            end)
        end
    end
end)

RegisterNetEvent('police:client:CheckStatus', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                QBCore.Functions.TriggerCallback('police:GetPlayerStatus', function(result)
                    if result then
                        for _, v in pairs(result) do
                            QBCore.Functions.Notify(''..v..'')
                        end
                    end
                end, playerId)
            else
                QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
            end
        end
    end)
end)

RegisterNetEvent('police:client:TakeOutImpound', function(data)
    if not inPrompt then return end

    TakeOutImpound(data.vehicle)
end)

RegisterNetEvent('police:client:TakeOutVehicle', function(data)
    if not inPrompt then return end

    TakeOutVehicle(data.vehicle)
end)

RegisterNetEvent('police:client:EvidenceStashDrawer', function(data)
    local currentEvidence = data.currentEvidence
    local pos = GetEntityCoords(PlayerPedId())
    local takeLoc = Config.Locations["evidence"][currentEvidence]

    if not takeLoc then return end

    if #(pos - takeLoc) <= 1.0 then
        local input = lib.inputDialog(Lang:t('info.evidence_stash', {value = currentEvidence}), {Lang:t('info.slot')})

        if not input then return end
        local slotNumber = tonumber(input[1])
        TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = slotNumber}), {
            maxweight = 4000000,
            slots = 500,
        })
        TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = slotNumber}))
    end
end)

-- Toggle Duty in an event.
RegisterNetEvent('qb-policejob:ToggleDuty', function()
    onDuty = not onDuty
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateCurrentCops")
    TriggerServerEvent("police:server:UpdateBlips")
end)

RegisterNetEvent('qb-police:client:scanFingerPrint', function()
    if not inPrompt then return end
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:showFingerprint", playerId)
    else
        QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
    end
end)

RegisterNetEvent('qb-police:client:spawnHelicopter', function(k)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped, false))
    else
        local coords = Config.Locations["helicopter"][k]
        if not coords then
            local plyCoords = GetEntityCoords(ped)
            local plyHeading = GetEntityHeading(ped)
            coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, plyHeading)
        end
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleLivery(veh , 0)
            SetVehicleMod(veh, 0, 48, false)
            SetVehicleNumberPlateText(veh, "ZULU"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true, false)
        end, Config.PoliceHelicopter, coords, true)
    end
end)

-- Threads

if Config.UseTarget then
    CreateThread(function()
        -- Toggle Duty
        for k, v in pairs(Config.Locations["duty"]) do
            exports['qb-target']:AddBoxZone("box_zone_police_duty_"..k, vector3(v.x, v.y, v.z), 1, 1, {
                name = "box_zone_police_duty_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "qb-policejob:ToggleDuty",
                        icon = "fas fa-sign-in-alt",
                        label = "Sign In",
                        job = "police",
                    },
                },
                distance = 1.5
            })
        end
    end)
else
    -- Toggle Duty
    local dutyZones = {}
    for k, v in pairs(Config.Locations["duty"]) do
        dutyZones[#dutyZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 1.75, 1, {
            name="box_zone_police_duty"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local dutyCombo = ComboZone:Create(dutyZones, {name = "dutyCombo", debugPoly = false})
    dutyCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inPrompt = true
            if not onDuty then
                lib.showTextUI(Lang:t('info.on_duty'))
                uiPrompt('duty')
            else
                lib.showTextUI(Lang:t('info.off_duty'))
                uiPrompt('duty')
            end
        else
            inPrompt = false
            lib.hideTextUI()
        end
    end)
end

CreateThread(function()
    -- Evidence Storage
    local evidenceZones = {}
    for k, v in pairs(Config.Locations["evidence"]) do
        evidenceZones[#evidenceZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 2, 1, {
            name="box_zone_police_evidence_"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local evidenceCombo = ComboZone:Create(evidenceZones, {name = "evidenceCombo", debugPoly = false})
    evidenceCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            if PlayerJob.type == "leo" and onDuty then
                inPrompt = true
                lib.showTextUI('[E] - Evidence')
                uiPrompt('evidence')
            end
        else
            lib.hideTextUI()
            inPrompt = false
        end
    end)

    -- Personal Stash
    local stashZones = {}
    for k, v in pairs(Config.Locations["stash"]) do
        stashZones[#stashZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 1.5, 1.5, {
            name="box_zone_police_stash_"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local stashCombo = ComboZone:Create(stashZones, {name = "stashCombo", debugPoly = false})
    stashCombo:onPlayerInOut(function(isPointInside, _, _)
        if isPointInside then
            inPrompt = true
            lib.showTextUI(Lang:t('info.stash_enter'))
            uiPrompt('stash')
        else
            lib.hideTextUI()
            inPrompt = false
        end
    end)

    -- Police Trash
    for i = 1, #Config.Locations.trash do
        local v = Config.Locations.trash[i]
        local trashZone = BoxZone:Create(
            vector3(v.x, v.y, v.z), 1, 1.75, {
            name="box_zone_police_trash_"..i,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
        trashZone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                inPrompt = true
                if onDuty then
                    lib.showTextUI(Lang:t('info.trash_enter'))
                    uiPrompt('trash', i)
                end
            else
                inPrompt = false
                lib.hideTextUI()
            end
        end)
    end

    -- Fingerprints
    local fingerprintZones = {}
    for k, v in pairs(Config.Locations["fingerprint"]) do
        fingerprintZones[#fingerprintZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 2, 1, {
            name="box_zone_police_fingerprint_"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local fingerprintCombo = ComboZone:Create(fingerprintZones, {name = "fingerprintCombo", debugPoly = false})
    fingerprintCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inPrompt = true
            if onDuty then
                lib.showTextUI(Lang:t('info.scan_fingerprint'))
                uiPrompt('fingerprint')
            end
        else
            inPrompt = false
            lib.hideTextUI()
        end
    end)

    -- Helicopter
    local helicopterZones = {}
    for k, v in pairs(Config.Locations["helicopter"]) do
        helicopterZones[#helicopterZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 10, 10, {
            name="box_zone_police_helicopter_"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local helicopterCombo = ComboZone:Create(helicopterZones, {name = "helicopterCombo", debugPoly = false})
    helicopterCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inPrompt = true
            if onDuty then
                uiPrompt('heli')
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    lib.showTextUI(Lang:t('info.store_heli'))
                else
                    lib.showTextUI(Lang:t('info.take_heli'))
                end
            end
        else
            inPrompt = false
            lib.hideTextUI()
        end
    end)

    -- Police Impound
    local impoundZones = {}
    for k, v in pairs(Config.Locations["impound"]) do
        impoundZones[#impoundZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 1, 1, {
            name="box_zone_police_impound"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
            heading = 180,
        })
    end

    local impoundCombo = ComboZone:Create(impoundZones, {name = "impoundCombo", debugPoly = false})
    impoundCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inPrompt = true
            if onDuty then
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    lib.showTextUI(Lang:t('info.impound_veh'))
                    uiPrompt('impound')
                else
                    for k, v in pairs(Config.Locations["impound"]) do
                        if #(point - vector3(v.x, v.y, v.z)) < 4 then
                            currentGarage = k
                        end
                    end
                    lib.showTextUI('[E] - Police Impound')
                    uiPrompt('impound')
                end
            end
        else
            inPrompt = false
            lib.hideTextUI()
            currentGarage = 0
        end
    end)

    -- Police Garage
    local garageZones = {}
    for k, v in pairs(Config.Locations["vehicle"]) do
        garageZones[#garageZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 3, 3, {
            name="box_zone_police_vehicle_"..k,
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local garageCombo = ComboZone:Create(garageZones, {name = "garageCombo", debugPoly = false})
    garageCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inPrompt = true
            if onDuty and PlayerJob.type == 'leo' then
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    lib.showTextUI(Lang:t('info.store_veh'))
                    uiPrompt('garage')
                else
                    for k, v in pairs(Config.Locations["vehicle"]) do
                        if #(point - vector3(v.x, v.y, v.z)) < 4 then
                            currentGarage = k
                            break
                        end
                    end
                    lib.showTextUI('[E] - Vehicle Garage')
                    uiPrompt('garage')
                end
            end
        else
            inPrompt = false
            currentGarage = 0
            lib.hideTextUI()
        end
    end)
end)

function uiPrompt(promptType, id)
    if PlayerJob.type ~= "leo" then return end
    CreateThread(function()
        while inPrompt do
            Wait(0)
            if IsControlJustReleased(0, 38) then
                if promptType == 'duty' then
                    onDuty = not onDuty
                    TriggerServerEvent("police:server:UpdateCurrentCops")
                    TriggerServerEvent("QBCore:ToggleDuty")
                    TriggerServerEvent("police:server:UpdateBlips")
                    lib.hideTextUI()
                    break
                elseif promptType == 'garage' then
                    if IsPedInAnyVehicle(cache.ped, false) then
                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(cache.ped, false))
                        lib.hideTextUI()
                        break
                    else
                        MenuGarage()
                        lib.hideTextUI()
                        break
                    end
                elseif promptType == 'evidence' then
                    MenuEvidence()
                    lib.hideTextUI()
                    break
                elseif promptType == 'impound' then
                    if IsPedInAnyVehicle(cache.ped, false) then
                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(cache.ped, false))
                        lib.hideTextUI()
                        break
                    else
                        MenuImpound()
                        lib.hideTextUI()
                        break
                    end
                elseif promptType == 'heli' then
                    TriggerEvent("qb-police:client:spawnHelicopter")
                    lib.hideTextUI()
                    break
                elseif promptType == 'fingerprint' then
                    TriggerEvent("qb-police:client:scanFingerPrint")
                    lib.hideTextUI()
                    break
                elseif promptType == 'trash' then
                    if hasOxInventory then
                        exports.ox_inventory:openInventory('stash', ('policetrash_%s'):format(id))
                    else
                        TriggerServerEvent("inventory:server:OpenInventory", "stash", ('policetrash_%s'):format(id), {
                            maxweight = 4000000,
                            slots = 300,
                        })
                        TriggerEvent("inventory:client:SetCurrentStash", ('policetrash_%s'):format(id))
                    end
                    break
                elseif promptType == 'stash' then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    break
                end
            end
        end
    end)
end