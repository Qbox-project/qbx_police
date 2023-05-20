-- Variables
local isEscorting = false

-- Functions
exports('IsHandcuffed', function()
    return PlayerData.metadata.ishandcuffed
end)

local function IsTargetDead(playerId)
    local p = promise.new()
    QBCore.Functions.TriggerCallback('police:server:isPlayerDead', function(result)
        p:resolve(result)
    end, playerId)
    return Citizen.Await(p)
end

local function HandCuffAnimation()
    if PlayerData.metadata.ishandcuffed then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Cuff", 0.2)
    else
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Uncuff", 0.2)
    end

    lib.requestAnimDict("mp_arrest_paired")
    Wait(100)
    TaskPlayAnim(cache.ped, "mp_arrest_paired", "cop_p2_back_right", 3.0, 3.0, -1, 48, 0, false, false, false)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "Cuff", 0.2)
    Wait(3500)
    TaskPlayAnim(cache.ped, "mp_arrest_paired", "exit", 3.0, 3.0, -1, 48, 0, false, false, false)
end

local function GetCuffedAnimation(playerId)
    local cuffer = GetPlayerPed(GetPlayerFromServerId(playerId))
    local heading = GetEntityHeading(cuffer)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "Cuff", 0.2)
    lib.requestAnimDict("mp_arrest_paired")
    local offset = GetOffsetFromEntityInWorldCoords(cuffer, 0.0, 0.45, 0.0)
    SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)
    Wait(100)
    SetEntityHeading(cache.ped, heading)
    TaskPlayAnim(cache.ped, "mp_arrest_paired", "crook_p2_back_right", 3.0, 3.0, -1, 32, 0, false, false, false)
    Wait(2500)
end

local function EscortActions()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
end

local function HandcuffActions()
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 257, true) -- Attack 2
    DisableControlAction(0, 25, true) -- Aim
    DisableControlAction(0, 263, true) -- Melee Attack 1

    DisableControlAction(0, 45, true) -- Reload
    DisableControlAction(0, 22, true) -- Jump
    DisableControlAction(0, 44, true) -- Cover
    DisableControlAction(0, 37, true) -- Select Weapon
    DisableControlAction(0, 23, true) -- Also 'enter'?

    DisableControlAction(0, 288, true) -- Disable phone
    DisableControlAction(0, 289, true) -- Inventory
    DisableControlAction(0, 170, true) -- Animations
    DisableControlAction(0, 167, true) -- Job

    DisableControlAction(0, 26, true) -- Disable looking behind
    DisableControlAction(0, 73, true) -- Disable clearing animation
    DisableControlAction(2, 199, true) -- Disable pause screen

    DisableControlAction(0, 59, true) -- Disable steering in vehicle
    DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
    DisableControlAction(0, 72, true) -- Disable reversing in vehicle

    DisableControlAction(2, 36, true) -- Disable going stealth

    DisableControlAction(0, 264, true) -- Disable melee
    DisableControlAction(0, 257, true) -- Disable melee
    DisableControlAction(0, 140, true) -- Disable melee
    DisableControlAction(0, 141, true) -- Disable melee
    DisableControlAction(0, 142, true) -- Disable melee
    DisableControlAction(0, 143, true) -- Disable melee
    DisableControlAction(0, 75, true)  -- Disable exit vehicle
    DisableControlAction(27, 75, true) -- Disable exit vehicle
    EnableControlAction(0, 249, true) -- Added for talking while cuffed
    EnableControlAction(0, 46, true)  -- Added for talking while cuffed
end

local function HandcuffedEscorted()
    local sleep = 1000
    local anim = {{dict = "mp_arresting", anim = "idle"}, {dict = "mp_arrest_paired", anim = "crook_p2_back_right"}}
    
    if not IsLoggedIn then return sleep end
    if isEscorted then
        sleep = 0
        EscortActions()
    end
    if not PlayerData.metadata.ishandcuffed then return sleep end
    sleep = 0
    HandcuffActions()
    if PlayerData.metadata.isdead then return sleep end
    for i = 1, #anim do
        if IsEntityPlayingAnim(cache.ped, anim[i].dict, anim[i].anim, 3) then return sleep end
    end
    lib.requestAnimDict("mp_arresting")
    TaskPlayAnim(cache.ped, "mp_arresting", "idle", 8.0, -8, -1, cuffType, 0, false, false, false)

    return sleep
end

-- Events
RegisterNetEvent('police:client:SetOutVehicle', function()
    if not cache.vehicle then return end

    TaskLeaveVehicle(cache.ped, cache.vehicle, 16)
end)

RegisterNetEvent('police:client:PutInVehicle', function()
    if not PlayerData.metadata.ishandcuffed and not isEscorted then return end

    local vehicle = QBCore.Functions.GetClosestVehicle()
    if not DoesEntityExist(vehicle) then return end

    for i = GetVehicleMaxNumberOfPassengers(vehicle), 0, -1 do
        if IsVehicleSeatFree(vehicle, i) then
            isEscorted = false
            TriggerEvent('hospital:client:isEscorted', isEscorted)
            ClearPedTasks(cache.ped)
            DetachEntity(cache.ped, true, false)
            Wait(100)
            SetPedIntoVehicle(cache.ped, vehicle, i)
            return
        end
    end
end)

RegisterNetEvent('police:client:SearchPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        exports.ox_inventory:openNearbyInventory()
        TriggerServerEvent("police:server:SearchPlayer", playerId)
    else
        lib.notify({
            description = Lang:t("error.none_nearby"),
            type = 'error'
        })
    end
end)

RegisterNetEvent('police:client:SeizeCash', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:SeizeCash", playerId)
    else
        lib.notify({
            description = Lang:t("error.none_nearby"),
            type = 'error'
        })
    end
end)

RegisterNetEvent('police:client:RobPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerPed = GetPlayerPed(player)
        local playerId = GetPlayerServerId(player)
        if IsEntityPlayingAnim(playerPed, "missminuteman_1ig_2", "handsup_base", 3) or IsEntityPlayingAnim(playerPed, "mp_arresting", "idle", 3) or IsTargetDead(playerId) then
            
            if lib.progressCircle({
                duration = math.random(5000, 7000),
                position = 'bottom',
                label = Lang:t("progressbar.robbing"),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                    mouse = false,
                },
                anim = {
                    dict = "random@shop_robbery",
                    clip = 'robbery_action_b',
                    flags = 16,
                },
            })
            then
                TriggerEvent('animations:client:EmoteCommandStart', { "c" })
                local plyCoords = GetEntityCoords(playerPed)
                local pos = GetEntityCoords(cache.ped)
                if #(pos - plyCoords) < 2.5 then
                    StopAnimTask(cache.ped, "random@shop_robbery", "robbery_action_b", 1.0)
                    exports.ox_inventory:openNearbyInventory()
                    TriggerServerEvent("inventory:server:RobPlayer", playerId)
                else
                    lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
                end
            else
                TriggerEvent('animations:client:EmoteCommandStart', { "c" })
                StopAnimTask(cache.ped, "random@shop_robbery", "robbery_action_b", 1.0)
                lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
            end
        end return lib.notify({ description = Lang:t("error.no_rob"), type = 'error' })
    else
        lib.notify({
            description = Lang:t("error.none_nearby"),
            type = 'error'
        })
    end
end)

RegisterNetEvent('police:client:JailPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        local dialog = lib.inputDialog(Lang:t('info.jail_time_input'), {
            type = "number",
            label = Lang:t('info.time_months'),
            default = 1
        })
        if dialog and dialog[1] > 0 then
            TriggerServerEvent("police:server:JailPlayer", playerId, dialog[1])
        else
            lib.notify({ description = Lang:t("error.time_higher"), type = 'error' })
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:BillPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        local dialog = lib.inputDialog(Lang:t('info.bill'), {
            type = "number",
            label = Lang:t('info.amount'),
            default = 1
        })
        if dialog and dialog[1] > 0 then
            TriggerServerEvent("police:server:BillPlayer", playerId, dialog[1])
        else
            lib.notify({ description = Lang:t("error.time_higher"), type = 'error' })
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:PutPlayerInVehicle', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if not PlayerData.metadata.ishandcuffed and not isEscorted then
            TriggerServerEvent("police:server:PutPlayerInVehicle", playerId)
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:SetPlayerOutVehicle', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if not PlayerData.metadata.ishandcuffed and not isEscorted then
            TriggerServerEvent("police:server:SetPlayerOutVehicle", playerId)
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:EscortPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if not PlayerData.metadata.ishandcuffed and not isEscorted then
            TriggerServerEvent("police:server:EscortPlayer", playerId)
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:KidnapPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if not IsPedInAnyVehicle(GetPlayerPed(player), false) and not PlayerData.metadata.ishandcuffed and not isEscorted then
            TriggerServerEvent("police:server:KidnapPlayer", playerId)
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:CuffPlayerSoft', function()
    if IsPedRagdoll(cache.ped) then return end

    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 1.5 then
        local playerId = GetPlayerServerId(player)
        if not IsPedInAnyVehicle(GetPlayerPed(player), false) and not cache.vehicle then
            TriggerServerEvent("police:server:CuffPlayer", playerId, true)
            HandCuffAnimation()
        else
            lib.notify({ description = Lang:t("error.vehicle_cuff"), type = 'error' })
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:CuffPlayer', function()
    if IsPedRagdoll(cache.ped) then return end

    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 1.5 then
        if QBCore.Functions.HasItem(Config.HandCuffItem) then
            local playerId = GetPlayerServerId(player)
            if not IsPedInAnyVehicle(GetPlayerPed(player), false) and not cache.vehicle then
                TriggerServerEvent("police:server:CuffPlayer", playerId, false)
                HandCuffAnimation()
            else
                lib.notify({ description = Lang:t("error.vehicle_cuff"), type = 'error' })
            end
        else
            lib.notify({ description = Lang:t("error.no_cuff"), type = 'error' })
        end
    else
        lib.notify({ description = Lang:t("error.none_nearby"), type = 'error' })
    end
end)

RegisterNetEvent('police:client:GetEscorted', function(playerId)
    if not PlayerData.metadata.isdead and not PlayerData.metadata.ishandcuffed and not PlayerData.metadata.inlaststand then return end

    if not isEscorted then
        isEscorted = true
        local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
        local offset = GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.45, 0.0)
        SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)
        AttachEntityToEntity(cache.ped, dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    else
        isEscorted = false
        DetachEntity(cache.ped, true, false)
    end
    TriggerEvent('hospital:client:isEscorted', isEscorted)
end)

RegisterNetEvent('police:client:DeEscort', function()
    isEscorted = false
    TriggerEvent('hospital:client:isEscorted', isEscorted)
    DetachEntity(cache.ped, true, false)
end)

RegisterNetEvent('police:client:GetKidnappedTarget', function(playerId)
    if PlayerData.metadata.idead or PlayerData.metadata.inlaststand or PlayerData.metadata.ishandcuffed then
        if not isEscorted then
            isEscorted = true
            local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
            lib.requestAnimDict("nm")
            AttachEntityToEntity(cache.ped, dragger, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
            TaskPlayAnim(cache.ped, "nm", "firemans_carry", 8.0, -8.0, 100000, 33, 0, false, false, false)
        else
            isEscorted = false
            DetachEntity(cache.ped, true, false)
            ClearPedTasksImmediately(cache.ped)
        end
        TriggerEvent('hospital:client:isEscorted', isEscorted)
    end
end)

RegisterNetEvent('police:client:GetKidnappedDragger', function()
    if not isEscorting then
        lib.requestAnimDict("missfinale_c2mcs_1")
        TaskPlayAnim(cache.ped, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, 100000, 49, 0, false, false, false)
        isEscorting = true
    else
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasksImmediately(cache.ped)
        isEscorting = false
    end
    TriggerEvent('hospital:client:SetEscortingState', isEscorting)
    TriggerEvent('qb-kidnapping:client:SetKidnapping', isEscorting)
end)

RegisterNetEvent('police:client:GetCuffed', function(playerId, isSoftcuff)
    if not PlayerData.metadata.ishandcuffed then
        TriggerServerEvent("police:server:SetHandcuffStatus", true)
        ClearPedTasksImmediately(cache.ped)
        if cache.weapon ~= `WEAPON_UNARMED` then
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        end
        if not isSoftcuff then
            cuffType = 16
            GetCuffedAnimation(playerId)
            lib.notify({ description = Lang:t("info.cuff"), type = 'success' })
        else
            cuffType = 49
            GetCuffedAnimation(playerId)
            lib.notify({ description = Lang:t("info.cuffed_walk"), type = 'success' })
        end
    else
        isEscorted = false
        TriggerEvent('hospital:client:isEscorted', isEscorted)
        DetachEntity(cache.ped, true, false)
        TriggerServerEvent("police:server:SetHandcuffStatus", false)
        ClearPedTasksImmediately(cache.ped)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Uncuff", 0.2)
        lib.notify({ description = Lang:t("success.uncuffed"), type = 'success' })
    end
end)

-- Threads
CreateThread(function()
    while true do
        Wait(HandcuffedEscorted())
    end
end)
