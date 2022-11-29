-- Variables
local currentGarage = 0
local inFingerprint = false
local FingerPrintSessionId = nil
local inStash = false
local inTrash = false
local inHelicopter = false
local inImpound = false
local inGarage = false

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

function TakeOutImpound(vehicle)
    local coords = Config.Locations["impound"][currentGarage]

    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)

            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)

                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetVehicleFuelLevel(veh, vehicle.fuel)

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

            SetVehicleNumberPlateText(veh, Lang:t('info.police_plate') .. tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            SetVehicleFuelLevel(veh, 100.0)

            lib.hideContext()

            if Config.VehicleSettings[vehicleInfo] then
                if Config.VehicleSettings[vehicleInfo].extras then
                    QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
                end

                if Config.VehicleSettings[vehicleInfo].livery then
                    SetVehicleLivery(veh, Config.VehicleSettings[vehicleInfo].livery)
                end
            end

            TaskWarpPedIntoVehicle(cache.ped, veh, -1)

            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

            SetVehicleEngineOn(veh, true, true, false)
        end, vehicleInfo, coords, true)
    end
end

local function IsVehicleWhitelist()
    local retval = false

    if QBCore.Functions.GetPlayerData().job.type == 'leo' then
        retval = true
    end

    return retval
end

function MenuGarage(currentSelection)
    local vehicleMenu = {}
    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]

    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            title = label,
            event = "police:client:TakeOutVehicle",
            args = {
                vehicle = veh,
                currentSelection = currentSelection
            }
        }
    end

    if IsVehicleWhitelist() then
        for veh, label in pairs(Config.WhitelistedVehicles) do
            vehicleMenu[#vehicleMenu + 1] = {
                title = label,
                event = "police:client:TakeOutVehicle",
                args = {
                    vehicle = veh,
                    currentSelection = currentSelection
                }
            }
        end
    end

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

        if not result then
            lib.notify({
                description = Lang:t("error.no_impound"),
                duration = 5000,
                type = 'error'
            })
        else
            shouldContinue = true

            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu + 1] = {
                    title = vname .. " [" .. v.plate .. "]",
                    description =  Lang:t('info.vehicle_info', {
                        value = enginePercent,
                        value2 = currentFuel
                    }),
                    event = "police:client:TakeOutImpound",
                    args = {
                        vehicle = v,
                        currentSelection = currentSelection
                    }
                }
            end
        end


        if shouldContinue then
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
    RemoveAnimDict('cellphone@')

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
            if lib.progressBar({
                duration = 2000,
                label = 'Drinking water',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true
                },
                anim = {
                    dict = 'missheistdockssetup1clipboard@base',
                    clip = 'base',
                    flag = 1
                },
                prop = {
                    {
                        model = `prop_notepad_01`,
                        bone = 18905,
                        pos = vec3(0.1, 0.02, 0.05),
                        rot = vec3(10.0, 0.0, 0.0)
                    },
                    {
                        model = `prop_pencil_01`,
                        bone = 58866,
                        pos = vec3(0.11, -0.02, 0.001),
                        rot = vec3(-120.0, 0.0, 0.0)
                    }
                }
            }) then
                local plate = QBCore.Functions.GetPlate(vehicle)

                TriggerServerEvent("police:server:Impound", plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)

                QBCore.Functions.DeleteVehicle(vehicle)

                TriggerEvent('QBCore:Notify', Lang:t('success.impounded'), 'success')

                ClearPedTasks(cache.ped)
            else
                ClearPedTasks(cache.ped)

                TriggerEvent('QBCore:Notify', Lang:t('error.canceled'), 'error')
            end
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
                            lib.notify({
                                description = v
                            })
                        end
                    end
                end, playerId)
            else
                lib.notify({
                    description = Lang:t("error.none_nearby"),
                    type = 'error'
                })
            end
        end
    end)
end)

RegisterNetEvent("police:client:VehicleMenuHeader", function(data)
    MenuGarage(data.currentSelection)

    currentGarage = data.currentSelection
end)

RegisterNetEvent("police:client:ImpoundMenuHeader", function(data)
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
    if not inGarage then
        return
    end

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
        local drawer = lib.inputDialog(Lang:t('info.evidence_stash', {
            value = currentEvidence
        }), {
            {
                type = "number",
                label = Lang:t('info.slot')
            }
        })

        if not drawer then
            return
        end

        local drawerSlot = tonumber(drawer[1])

        TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {
            value = currentEvidence,
            value2 = drawerSlot
        }), {
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
        lib.notify({
            description = Lang:t("error.none_nearby"),
            type = 'error'
        })
    end
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
            SetVehicleNumberPlateText(veh, "ZULU" .. tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            SetVehicleFuelLevel(veh, 100.0)

            lib.hideContext()

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
        for _, v in pairs(Config.Locations["duty"]) do
            exports.ox_target:addBoxZone({
                coords = v,
                size = vec3(2, 2, 2),
                rotation = 11,
                options = {
                    {
                        name = 'qb-policejob:duty',
                        event = "qb-policejob:ToggleDuty",
                        icon = "fas fa-sign-in-alt",
                        label = "Sign In",
                        distance = 1.5,
                        canInteract = function(_, _, _, _)
                            return PlayerJob.name == "police"
                        end
                    }
                }
            })
        end
    end)
else
    local dutylisten = false

    function dutylistener()
        if PlayerJob.type ~= "leo" then
            return
        end

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
    for _, v in pairs(Config.Locations["duty"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                dutylisten = true

                if not onDuty then
                    lib.showTextUI(Lang:t('info.on_duty'))

                    dutylistener()
                else
                    lib.showTextUI(Lang:t('info.off_duty'))

                    dutylistener()
                end
            end,
            onExit = function(_)
                dutylisten = false

                lib.hideTextUI()
            end
        })
    end
end

CreateThread(function()
    -- Evidence Storage
    for k, v in pairs(Config.Locations["evidence"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                if PlayerJob.type == "leo" and onDuty then
                    lib.registerContext({
                        id = 'open_policeEvidenceHeader',
                        title = "Evidence",
                        options = {
                            {
                                title = Lang:t('info.evidence_stash', {
                                    value = k
                                }),
                                icon = "fa-solid fa-paperclip",
                                event = 'police:client:EvidenceStashDrawer',
                                args = {
                                    currentEvidence = k
                                }
                            }
                        }
                    })
                    lib.showContext('open_policeEvidenceHeader')
                end
            end,
            onExit = function(_)
                lib.hideContext()
            end
        })
    end

    -- Personal Stash
    for _, v in pairs(Config.Locations["stash"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                inStash = true

                lib.showTextUI(Lang:t('info.stash_enter'))

                stash()
            end,
            onExit = function(_)
                lib.hideTextUI()

                inStash = false
            end
        })
    end

    -- Police Trash
    for k, v in pairs(Config.Locations["trash"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                inTrash = true

                if onDuty then
                    lib.showTextUI(Lang:t('info.trash_enter'))

                    trash(k)
                end
            end,
            onExit = function(_)
                inTrash = false

                lib.hideTextUI()
            end
        })
    end

    -- Fingerprints
    for _, v in pairs(Config.Locations["fingerprint"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                inFingerprint = true

                if onDuty then
                    lib.showTextUI(Lang:t('info.scan_fingerprint'))

                    fingerprint()
                end
            end,
            onExit = function(_)
                inFingerprint = false

                lib.hideTextUI()
            end
        })
    end

    -- Helicopter
    for _, v in pairs(Config.Locations["helicopter"]) do
        lib.zones.box({
            coords = v,
            size = vec3(4, 4, 4),
            rotation = 0.0,
            onEnter = function(_)
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
            end,
            onExit = function(_)
                inHelicopter = false

                lib.hideTextUI()
            end
        })
    end

    -- Police Impound
    for k, v in pairs(Config.Locations["impound"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                inImpound = true

                if onDuty then
                    if IsPedInAnyVehicle(cache.ped, false) then
                        lib.showTextUI(Lang:t('info.impound_veh'))

                        impound()
                    else
                        lib.registerContext({
                            id = 'open_policeImpoundHeader',
                            title = "Impound",
                            options = {
                                {
                                    title = Lang:t('menu.pol_impound'),
                                    icon = "fa-solid fa-warehouse",
                                    event = 'police:client:ImpoundMenuHeader',
                                    args = {
                                        currentSelection = k
                                    }
                                }
                            }
                        })
                        lib.showContext('open_policeImpoundHeader')
                    end
                end
            end,
            onExit = function(_)
                inImpound = false

                lib.hideContext()
                lib.hideTextUI()
            end
        })
    end

    -- Police Garage
    for k, v in pairs(Config.Locations["vehicle"]) do
        lib.zones.box({
            coords = v,
            size = vec3(2, 2, 2),
            rotation = 0.0,
            onEnter = function(_)
                inGarage = true

                if onDuty and PlayerJob.type == 'leo' then
                    if IsPedInAnyVehicle(cache.ped, false) then
                        lib.showTextUI(Lang:t('info.store_veh'))

                        garage()
                    else
                        lib.registerContext({
                            id = 'open_policeGarageHeader',
                            title = "Police garage",
                            options = {
                                {
                                    title = Lang:t('menu.pol_garage'),
                                    icon = "fa-solid fa-warehouse",
                                    event = 'police:client:VehicleMenuHeader',
                                    args = {
                                        currentSelection = k
                                    }
                                }
                            }
                        })
                        lib.showContext('open_policeGarageHeader')
                    end
                end
            end,
            onExit = function(_)
                inGarage = false

                lib.hideContext()
                lib.hideTextUI()
            end
        })
    end
end)

-- Personal Stash Thread
function stash()
    if not inStash or PlayerJob.type ~= "leo" then
        return
    end

    CreateThread(function()
        while true do

            if inStash and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_" .. QBCore.Functions.GetPlayerData().citizenid)
                    break
                end
            else
                break
            end

            Wait(0)
        end
    end)
end

-- Police Trash Thread
function trash(id)
    if not inTrash or PlayerJob.type ~= "leo" then
        return
    end

    CreateThread(function()
        while true do

            if inTrash and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    exports.ox_inventory:openInventory('stash', ('policetrash_%s'):format(id))
                    break
                end
            else
                break
            end

            Wait(0)
        end
    end)
end

-- Fingerprint Thread
function fingerprint()
    if not inFingerprint or PlayerJob.type ~= "leo" then
        return
    end

    CreateThread(function()
        while true do
            if inFingerprint and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:scanFingerPrint")
                    break
                end
            else
                break
            end

            Wait(0)
        end
    end)
end

-- Helicopter Thread
function heli()
    if not inHelicopter or PlayerJob.type ~= "leo" then
        return
    end

    CreateThread(function()
        while true do
            if inHelicopter and PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:spawnHelicopter")
                    break
                end
            else
                break
            end

            Wait(0)
        end
    end)
end

-- Police Impound Thread
function impound()
    if not inImpound or PlayerJob.type ~= "leo" then
        return
    end

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
    if not inGarage or PlayerJob.type ~= "leo" then
        return
    end

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