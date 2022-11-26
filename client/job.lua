-- Variables
local currentGarage = 0
local inFingerprint = false
local FingerPrintSessionId = nil
local inStash = false
local inTrash = false
local inAmoury = false
local inHelicopter = false
local inImpound = false
local inGarage = false
local hasOxInventory = GetResourceState('ox_inventory') ~= 'missing'

local function GetClosestPlayer() -- interactions, job, tracker
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(cache.ped)

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= cache.playerId then
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
    inFingerprint = true
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

function TakeOutImpound(vehicle)
    local coords = Config.Locations["impound"][currentGarage]

    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)

            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)

                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetVehicleFuelLevel(veh, vehicle.fuel)

                doCarDamage(veh, vehicle)

                TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)

                lib.hideContext()

                TaskWarpPedIntoVehicle(cache.ped, veh, -1)

                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

                SetVehicleEngineOn(veh, true, true, false)
            end, vehicle.plate)
        end, vehicle.vehicle, coords, true)
    end
end

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]

    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)

            SetCarItemsInfo()

            SetVehicleNumberPlateText(veh, Lang:t('info.police_plate') .. tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            SetVehicleFuelLevel(veh, 100.0)

            lib.hideContext()

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

local function SetWeaponSeries()
    for k in pairs(Config.Items.items) do
        if k < 6 then
            Config.Items.items[k].info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
        end
    end
end

function MenuGarage(currentSelection)
    local vehicleMenu = {}
    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]

    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            title = label,
            event = "police:client:TakeOutVehicle",
            args = {vehicle = veh, currentSelection = currentSelection}
        }
    end

    if IsArmoryWhitelist() then
        for veh, label in pairs(Config.WhitelistedVehicles) do
            vehicleMenu[#vehicleMenu + 1] = {
                title = label,
                event = "police:client:TakeOutVehicle",
                args = {vehicle = veh, currentSelection = currentSelection}
            }
        end
    end

    vehicleMenu[#vehicleMenu + 1] = {
        title = Lang:t('menu.close'),
        onSelect = function(args)
            lib.hideContext()
        end
    }

    lib.registerContext({
        id = 'open_policeGarage',
        title = Lang:t('menu.garage_title'),
        options = vehicleMenu
    })
    lib.showContext('open_policeGarage')
end

function MenuImpound(currentSelection)
    local impoundMenu = {}

    QBCore.Functions.TriggerCallback("police:GetImpoundedVehicles", function(result)
        local shouldContinue = false

        if result == nil then
            QBCore.Functions.Notify(Lang:t("error.no_impound"), "error", 5000)
        else
            shouldContinue = true

            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu + 1] = {
                    title = vname.." ["..v.plate.."]",
                    description =  Lang:t('info.vehicle_info', {value = enginePercent, value2 = currentFuel}),
                    event = "police:client:TakeOutImpound",
                    args = {vehicle = v, currentSelection = currentSelection}
                }
            end
        end


        if shouldContinue then
            impoundMenu[#impoundMenu + 1] = {
                title = Lang:t('menu.close'),
                onSelect = function(args)
                    lib.hideContext()
                end
            }

            lib.registerContext({
                id = 'open_policeImpound',
                title = Lang:t('menu.impound'),
                options = impoundMenu
            })
            lib.showContext('open_policeImpound')
        end
    end)
end

-- NUI Callbacks
RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)

    inFingerprint = false

    cb('ok')
end)

-- Events
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

    lib.requestAnimDict("cellphone@")
    
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
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = GetVehicleFuelLevel(vehicle)

    if vehicle ~= 0 and vehicle then
        local pos = GetEntityCoords(cache.ped)
        local vehpos = GetEntityCoords(vehicle)

        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(cache.ped, false) then
            QBCore.Functions.Progressbar('impound', Lang:t('progressbar.impound'), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, {
                animDict = 'missheistdockssetup1clipboard@base',
                anim = 'base',
                flags = 1
            }, {
                model = 'prop_notepad_01',
                bone = 18905,
                coords = { x = 0.1, y = 0.02, z = 0.05 },
                rotation = { x = 10.0, y = 0.0, z = 0.0 }
            },{
                model = 'prop_pencil_01',
                bone = 58866,
                coords = { x = 0.11, y = -0.02, z = 0.001 },
                rotation = { x = -120.0, y = 0.0, z = 0.0 }
            }, function() -- Play When Done
                local plate = QBCore.Functions.GetPlate(vehicle)

                TriggerServerEvent("police:server:Impound", plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)

                QBCore.Functions.DeleteVehicle(vehicle)

                TriggerEvent('QBCore:Notify', Lang:t('success.impounded'), 'success')

                ClearPedTasks(cache.ped)
            end, function() -- Play When Cancel
                ClearPedTasks(cache.ped)

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

RegisterNetEvent("police:client:VehicleMenuHeader", function (data)
    MenuGarage(data.currentSelection)

    currentGarage = data.currentSelection
end)

RegisterNetEvent("police:client:ImpoundMenuHeader", function (data)
    MenuImpound(data.currentSelection)

    currentGarage = data.currentSelection
end)

RegisterNetEvent('police:client:TakeOutImpound', function(data)
    if not inImpound then
        return
    end

    TakeOutImpound(data.vehicle)
end)

RegisterNetEvent('police:client:TakeOutVehicle', function(data)
    if not inGarage then return end

    TakeOutVehicle(data.vehicle)
end)

RegisterNetEvent('police:client:EvidenceStashDrawer', function(data)
    local currentEvidence = data.currentEvidence
    local pos = GetEntityCoords(cache.ped)
    local takeLoc = Config.Locations["evidence"][currentEvidence]

    if not takeLoc then
        return
    end

    if #(pos - takeLoc) <= 1.0 then
        local drawer = lib.inputDialog(Lang:t('info.evidence_stash', {value = currentEvidence}), {
            { type = "number", label = Lang:t('info.slot') }
        })

        if not drawer then
            return
        end

        local drawerSlot = tonumber(drawer[1])

        TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawerSlot}), {
            maxweight = 4000000,
            slots = 500
        })
    else
        lib.hideContext()
    end
end)

-- Toggle Duty in an event.
RegisterNetEvent('qb-policejob:ToggleDuty', function()
    onDuty = not onDuty

    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateCurrentCops")
end)

RegisterNetEvent('qb-police:client:scanFingerPrint', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:showFingerprint", playerId)
    else
        QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
    end
end)

RegisterNetEvent('qb-police:client:openArmoury', function()
    local authorizedItems = {
        label = Lang:t('menu.pol_armory'),
        slots = 30,
        items = {}
    }
    local index = 1

    for _, armoryItem in pairs(Config.Items.items) do
        for i=1, #armoryItem.authorizedJobGrades do
            if armoryItem.authorizedJobGrades[i] == PlayerJob.grade.level then
                authorizedItems.items[index] = armoryItem
                authorizedItems.items[index].slot = index
                index += 1
            end
        end
    end

    SetWeaponSeries()

    TriggerServerEvent("inventory:server:OpenInventory", "shop", "police", authorizedItems)
end)

RegisterNetEvent('qb-police:client:spawnHelicopter', function(k)
    if IsPedInAnyVehicle(cache.ped, false) then
        QBCore.Functions.DeleteVehicle(cache.vehicle)
    else
        local coords = Config.Locations["helicopter"][k]

        if not coords then
            local plyCoords = GetEntityCoords(cache.ped)
            local plyHeading = GetEntityHeading(cache.ped)

            coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, plyHeading)
        end

        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)

            SetVehicleLivery(veh , 0)
            SetVehicleMod(veh, 0, 48, false)
            SetVehicleNumberPlateText(veh, "ZULU"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            SetVehicleFuelLevel(veh, 100.0)

            closeMenuFull()

            TaskWarpPedIntoVehicle(cache.ped, veh, -1)

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
            exports['qb-target']:AddBoxZone("box_zone_police_duty_"..k, vec3(v.x, v.y, v.z), 1, 1, {
                name = "box_zone_police_duty_"..k,
                heading = 11,
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
    local dutylisten = false
    function dutylistener()
        if PlayerJob.type ~= "leo" then return end
        dutylisten = true
        CreateThread(function()
            while dutylisten do
                if PlayerJob.type == "leo" then
                    if IsControlJustReleased(0, 38) then
                        onDuty = not onDuty
                        TriggerServerEvent("police:server:UpdateCurrentCops")
                        TriggerServerEvent("QBCore:ToggleDuty")
                        dutylisten = false
                        break
                    end
                else
                    break
                end
                Wait(0)
            end
        end)
    end

    -- Toggle Duty
    local dutyZones = {}

    for k, v in pairs(Config.Locations["duty"]) do
        dutyZones[#dutyZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 1.75, 1, {
            name = "box_zone_police_duty" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local dutyCombo = ComboZone:Create(dutyZones, {
        name = "dutyCombo"
    })
    dutyCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            dutylisten = true

            if not onDuty then
                lib.showTextUI(Lang:t('info.on_duty'))

                dutylistener()
            else
                lib.showTextUI(Lang:t('info.off_duty'))

                dutylistener()
            end
        else
            inDuty = false

            lib.hideTextUI()
        end
    end)
end

CreateThread(function()
    -- Evidence Storage
    local evidenceZones = {}

    for k, v in pairs(Config.Locations["evidence"]) do
        evidenceZones[#evidenceZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 2, 1, {
            name = "box_zone_police_evidence_" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local evidenceCombo = ComboZone:Create(evidenceZones, {
        name = "evidenceCombo"
    })
    evidenceCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            if PlayerJob.type == "leo" and onDuty then
                local currentEvidence = 0
                local pos = GetEntityCoords(cache.ped)

                for k, v in pairs(Config.Locations["evidence"]) do
                    if #(pos - v) < 2 then
                        currentEvidence = k
                    end
                end

                lib.registerContext({
                    id = 'open_policeEvidenceHeader',
                    title = "Evidence",
                    options = {
                        {
                            title = Lang:t('info.evidence_stash', {value = currentEvidence}),
                            event = 'police:client:EvidenceStashDrawer',
                            args = {currentEvidence = currentEvidence}
                        }
                    }
                })
                lib.showContext('open_policeEvidenceHeader')
            end
        else
            lib.hideContext()
        end
    end)

    -- Personal Stash
    local stashZones = {}

    for k, v in pairs(Config.Locations["stash"]) do
        stashZones[#stashZones + 1] = BoxZone:Create( vec3(v.x, v.y, v.z), 1.5, 1.5, {
            name="box_zone_police_stash_" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local stashCombo = ComboZone:Create(stashZones, {
        name = "stashCombo"
    })
    stashCombo:onPlayerInOut(function(isPointInside, _, _)
        if isPointInside then
            inStash = true
            lib.showTextUI(Lang:t('info.stash_enter'))
            stash()
        else
            lib.hideTextUI()
            inStash = false
        end
    end)

    -- Police Trash
    for i = 1, #Config.Locations.trash do
        local v = Config.Locations.trash[i]
        local trashZone = BoxZone:Create(
            vec3(v.x, v.y, v.z), 1, 1.75, {
            name="box_zone_police_trash_"..i,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
        trashZone:onPlayerInOut(function(isPointInside)
            inTrash = isPointInside
            if isPointInside then
                if onDuty then
                    lib.showTextUI(Lang:t('info.trash_enter'))
                    trash(i)
                end
            else
                lib.hideTextUI()
            end
        end)
    end

    -- Fingerprints
    local fingerprintZones = {}

    for k, v in pairs(Config.Locations["fingerprint"]) do
        fingerprintZones[#fingerprintZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 2, 1, {
            name = "box_zone_police_fingerprint_" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local fingerprintCombo = ComboZone:Create(fingerprintZones, {
        name = "fingerprintCombo"
    })
    fingerprintCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inFingerprint = true
            if onDuty then
                lib.showTextUI(Lang:t('info.scan_fingerprint'))
                fingerprint()
            end
        else
            inFingerprint = false
            lib.hideTextUI()
        end
    end)

    -- Armoury
    local armouryZones = {}

    for k, v in pairs(Config.Locations["armory"]) do
        armouryZones[#armouryZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 5, 1, {
            name = "box_zone_police_armory_" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local armouryCombo = ComboZone:Create(armouryZones, {
        name = "armouryCombo"
    })
    armouryCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inAmoury = true

            if onDuty then
                lib.showTextUI(Lang:t('info.enter_armory'))

                armoury()
            end
        else
            inAmoury = false

            lib.hideTextUI()
        end
    end)

    -- Helicopter
    local helicopterZones = {}

    for k, v in pairs(Config.Locations["helicopter"]) do
        helicopterZones[#helicopterZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 10, 10, {
            name="box_zone_police_helicopter_" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local helicopterCombo = ComboZone:Create(helicopterZones, {
        name = "helicopterCombo"
    })
    helicopterCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inHelicopter = true
            if onDuty then
                heli()
                if IsPedInAnyVehicle(cache.ped, false) then
                    lib.hideTextUI()
                    lib.showTextUI(Lang:t('info.store_heli'))
                else
                    lib.showTextUI(Lang:t('info.take_heli'))
                end
            end
        else
            inHelicopter = false
            lib.hideTextUI()
        end
    end)

    -- Police Impound
    local impoundZones = {}

    for k, v in pairs(Config.Locations["impound"]) do
        impoundZones[#impoundZones + 1] = BoxZone:Create(vec3(v.x, v.y, v.z), 1, 1, {
            name = "box_zone_police_impound" .. k,
            minZ = v.z - 1,
            maxZ = v.z + 1,
            heading = 180
        })
    end

    local impoundCombo = ComboZone:Create(impoundZones, {
        name = "impoundCombo"
    })
    impoundCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inImpound = true
            
            if onDuty then
                if IsPedInAnyVehicle(cache.ped, false) then
                    lib.showTextUI(Lang:t('info.impound_veh'))

                    impound()
                else
                    local currentSelection = 0

                    for k, v in pairs(Config.Locations["impound"]) do
                        if #(point - vec3(v.x, v.y, v.z)) < 4 then
                            currentSelection = k
                        end
                    end

                    lib.registerContext({
                        id = 'open_policeImpoundHeader',
                        title = "Impound",
                        options = {
                            {
                                title = Lang:t('menu.pol_impound'),
                                event = 'police:client:ImpoundMenuHeader',
                                args = {currentSelection = currentSelection}
                            }
                        }
                    })
                    lib.showContext('open_policeImpoundHeader')
                end
            end
        else
            inImpound = false

            lib.hideContext()
            lib.hideTextUI()
        end
    end)

    -- Police Garage
    local garageZones = {}

    for k, v in pairs(Config.Locations["vehicle"]) do
        garageZones[#garageZones + 1] = BoxZone:Create(
            vec3(v.x, v.y, v.z), 3, 3, {
            name="box_zone_police_vehicle_"..k,
            minZ = v.z - 1,
            maxZ = v.z + 1
        })
    end

    local garageCombo = ComboZone:Create(garageZones, {
        name = "garageCombo"
    })
    garageCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inGarage = true

            if onDuty and PlayerJob.type == 'leo' then
                if IsPedInAnyVehicle(cache.ped, false) then
                    lib.showTextUI(Lang:t('info.store_veh'))
                    garage()
                else
                    local currentSelection = 0

                    for k, v in pairs(Config.Locations["vehicle"]) do
                        if #(point - vec3(v.x, v.y, v.z)) < 4 then
                            currentSelection = k
                        end
                    end

                    lib.registerContext({
                        id = 'open_policeGarageHeader',
                        title = "Police garage",
                        options = {
                            {
                                title = Lang:t('menu.pol_garage'),
                                event = 'police:client:VehicleMenuHeader',
                                args = {currentSelection = currentSelection}
                            }
                        }
                    })
                    lib.showContext('open_policeGarageHeader')
                end
            end
        else
            inGarage = false

            lib.hideContext()
            lib.hideTextUI()
        end
    end)
end)

-- Personal Stash Thread
function stash()
    if not inStash or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)

            if inStash and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    break
                end
            else
                break
            end
        end
    end)
end

-- Police Trash Thread
function trash(id)
    if not inTrash or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)

            if inTrash and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    if hasOxInventory then
                        exports.ox_inventory:openInventory('stash', ('policetrash_%s'):format(id))
                    else
                        TriggerServerEvent("inventory:server:OpenInventory", "stash", ('policetrash_%s'):format(id), {
                            maxweight = 4000000,
                            slots = 300
                        })
                    end
                    break
                end
            else
                break
            end
        end
    end)
end

-- Fingerprint Thread
function fingerprint()
    if not inFingerprint or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)
            if inFingerprint and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:scanFingerPrint")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Armoury Thread
function armoury()
    if not inAmoury or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)
            if inAmoury and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:openArmoury")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Helicopter Thread
function heli()
    if not inHelicopter or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)
            if inHelicopter and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:spawnHelicopter")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Police Impound Thread
function impound()
    if not inImpound or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)

            if inImpound and PlayerJob.type == "leo" then
                if IsPedInAnyVehicle(cache.ped, false) then
                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.DeleteVehicle(cache.vehicle)
                        break
                    end
                end
            else
                break
            end
        end
    end)
end

-- Police Garage Thread
function garage()
    if not inGarage or PlayerJob.type ~= "leo" then return end

    CreateThread(function()
        while true do
            Wait(0)

            if inGarage and PlayerJob.type == "leo" then
                if IsPedInAnyVehicle(cache.ped, false) then
                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.DeleteVehicle(cache.vehicle)
                        break
                    end
                end
            else
                break
            end
        end
    end)
end
