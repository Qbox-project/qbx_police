local config = require 'config.client'
local isEscorting = false
local cuffType = 1

exports('IsHandcuffed', function()
    return QBX.PlayerData.metadata.ishandcuffed
end)

local function isTargetDead(playerId)
    return lib.callback.await('police:server:isPlayerDead', false, playerId)
end

local function handCuffAnimation()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', QBX.PlayerData.metadata.ishandcuffed and 'Cuff' or 'Uncuff', 0.2)

    lib.requestAnimDict('mp_arrest_paired')
    Wait(100)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'cop_p2_back_right', 3.0, 3.0, -1, 48, 0, false, false, false)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Cuff', 0.2)
    Wait(3500)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'exit', 3.0, 3.0, -1, 48, 0, false, false, false)
    RemoveAnimDict('mp_arrest_paired')
end

local function getCuffedAnimation(playerId)
    local cuffer = GetPlayerPed(GetPlayerFromServerId(playerId))
    local heading = GetEntityHeading(cuffer)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Cuff', 0.2)
    lib.requestAnimDict('mp_arrest_paired')
    local offset = GetOffsetFromEntityInWorldCoords(cuffer, 0.0, 0.45, 0.0)
    SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)
    Wait(100)
    SetEntityHeading(cache.ped, heading)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'crook_p2_back_right', 3.0, 3.0, -1, 32, 0, false, false, false)
    Wait(2500)
    RemoveAnimDict('mp_arrest_paired')
end

local function escortActions()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
end

local function handcuffActions()
    lib.disableControls()
    DisableControlAction(27, 75, true) -- Disable exit vehicle
    EnableControlAction(0, 249, true) -- Added for talking while cuffed
    EnableControlAction(0, 46, true)  -- Added for talking while cuffed
end

local function handcuffedEscorted()
    local sleep = 1000
    local anim = {{dict = 'mp_arresting', anim = 'idle'}, {dict = 'mp_arrest_paired', anim = 'crook_p2_back_right'}}

    if not LocalPlayer.state.isLoggedIn then return sleep end
    if IsEscorted then
        sleep = 0
        escortActions()
    end
    if not QBX.PlayerData.metadata.ishandcuffed then return sleep end
    sleep = 0
    handcuffActions()
    if QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand then return sleep end
    for i = 1, #anim do
        if IsEntityPlayingAnim(cache.ped, anim[i].dict, anim[i].anim, 3) then return sleep end
    end
    lib.playAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, cuffType, 0, false, false, false)

    return sleep
end

RegisterNetEvent('police:client:SetOutVehicle', function()
    if not cache.vehicle then return end
    TaskLeaveVehicle(cache.ped, cache.vehicle, 16)
end)

RegisterNetEvent('police:client:PutInVehicle', function()
    if not QBX.PlayerData.metadata.ishandcuffed and not IsEscorted then return end

    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    for i = GetVehicleMaxNumberOfPassengers(vehicle), 0, -1 do
        if IsVehicleSeatFree(vehicle, i) then
            IsEscorted = false
            TriggerEvent('hospital:client:isEscorted', IsEscorted)
            ClearPedTasks(cache.ped)
            DetachEntity(cache.ped, true, false)
            Wait(100)
            SetPedIntoVehicle(cache.ped, vehicle, i)
            return
        end
    end
end)

---Check for closest player within distance or 2.5 units
---@param distance number?
---@return number? playerId
---@return number? playerPed
local function getClosestPlayer(distance)
    local coords = GetEntityCoords(cache.ped)
    local player, playerPed = lib.getClosestPlayer(coords, distance or 2.5)
    if not player then
        return exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
    end

    return player, playerPed
end

RegisterNetEvent('police:client:SearchPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    exports.ox_inventory:openNearbyInventory()
    TriggerServerEvent('police:server:SearchPlayer', playerId)
end)

RegisterNetEvent('police:client:SeizeCash', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    TriggerServerEvent('police:server:SeizeCash', playerId)
end)

RegisterNetEvent('police:client:RobPlayer', function()
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)

    if not (IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3)
        or isTargetDead(playerId))
    then
        return exports.qbx_core:Notify(locale('error.no_rob'), 'error')
    end

    if lib.progressCircle({
        duration = math.random(5000, 7000),
        position = 'bottom',
        label = locale('progressbar.robbing'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'random@shop_robbery',
            clip = 'robbery_action_b',
            flags = 16
        }
    })
    then
        local playerCoords = GetEntityCoords(playerPed)
        local pos = GetEntityCoords(cache.ped)
        if #(pos - playerCoords) < 2.5 then
            StopAnimTask(cache.ped, 'random@shop_robbery', 'robbery_action_b', 1.0)
            exports.ox_inventory:openNearbyInventory()
            TriggerServerEvent('police:server:RobPlayer', playerId)
        else
            exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
        end
    else
        StopAnimTask(cache.ped, 'random@shop_robbery', 'robbery_action_b', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

RegisterNetEvent('police:client:JailPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    local dialog = lib.inputDialog(locale('info.jail_time_input'), {
        {type = 'number', label = locale('info.time_months'), min = 0}
    })
    if dialog and dialog[1] > 0 then
        TriggerServerEvent('police:server:JailPlayer', playerId, dialog[1])
    else
        exports.qbx_core:Notify(locale('error.time_higher'), 'error')
    end
end)

RegisterNetEvent('police:client:BillPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    local dialog = lib.inputDialog(locale('info.bill'), {
        {type = 'number', label = locale('info.amount'), min = 0}
    })
    if dialog and dialog[1] > 0 then
        TriggerServerEvent('police:server:BillPlayer', playerId, dialog[1])
    else
        exports.qbx_core:Notify(locale('error.time_higher'), 'error')
    end
end)

local function triggerIfHandsFree(eventName)
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent(eventName, playerId)
end

RegisterNetEvent('police:client:PutPlayerInVehicle', function()
    triggerIfHandsFree('police:server:PutPlayerInVehicle')
end)

RegisterNetEvent('police:client:SetPlayerOutVehicle', function()
    triggerIfHandsFree('police:server:SetPlayerOutVehicle')
end)

RegisterNetEvent('police:client:EscortPlayer', function()
    triggerIfHandsFree('police:server:EscortPlayer')
end)

RegisterNetEvent('police:client:KidnapPlayer', function()
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)
    if IsPedInAnyVehicle(playerPed, false) or QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent('police:server:KidnapPlayer', playerId)
end)

RegisterNetEvent('police:client:CuffPlayerSoft', function()
    if IsPedRagdoll(cache.ped) then return end
    local player, playerPed = getClosestPlayer(1.5)
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)

    if IsPedInAnyVehicle(playerPed, false) or cache.vehicle then
        return exports.qbx_core:Notify(locale('error.vehicle_cuff'), 'error')
    end

    if lib.callback.await('police:server:CuffPlayer', false, playerId, true) then
        handCuffAnimation()
    end
end)

RegisterNetEvent('police:client:CuffPlayer', function()
    if IsPedRagdoll(cache.ped) then return end
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end

    if exports.ox_inventory:Search('count', config.handcuffItems) == 0 then
        return exports.qbx_core:Notify(locale('error.no_cuff'), 'error')
    end

    local playerId = GetPlayerServerId(player)

    if IsPedInAnyVehicle(playerPed, false) or cache.vehicle then
        return exports.qbx_core:Notify(locale('error.vehicle_cuff'), 'error')
    end

    if lib.callback.await('police:server:CuffPlayer', false, playerId, false) then
        handCuffAnimation()
    end
end)

RegisterNetEvent('police:client:GetEscorted', function(playerId)
    if not(QBX.PlayerData.metadata.isdead
        or QBX.PlayerData.metadata.ishandcuffed
        or QBX.PlayerData.metadata.inlaststand)
    then return end

    if not IsEscorted then
        IsEscorted = true
        local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
        local offset = GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.45, 0.0)
        SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)
        AttachEntityToEntity(cache.ped, dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    else
        IsEscorted = false
        DetachEntity(cache.ped, true, false)
    end
    TriggerEvent('hospital:client:isEscorted', IsEscorted)
end)

RegisterNetEvent('police:client:DeEscort', function()
    IsEscorted = false
    TriggerEvent('hospital:client:isEscorted', IsEscorted)
    DetachEntity(cache.ped, true, false)
end)

RegisterNetEvent('police:client:GetKidnappedTarget', function(playerId)
    if     QBX.PlayerData.metadata.isdead
        or QBX.PlayerData.metadata.ishandcuffed
        or QBX.PlayerData.metadata.inlaststand
    then
        if not IsEscorted then
            IsEscorted = true
            local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
            lib.playAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, 100000, 33, 0, false, false, false)
            AttachEntityToEntity(cache.ped, dragger, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
        else
            IsEscorted = false
            DetachEntity(cache.ped, true, false)
            ClearPedTasksImmediately(cache.ped)
        end
        TriggerEvent('hospital:client:isEscorted', IsEscorted)
    end
end)

RegisterNetEvent('police:client:GetKidnappedDragger', function()
    if not isEscorting then
        lib.playAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
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
    if not QBX.PlayerData.metadata.ishandcuffed then
        TriggerServerEvent('police:server:SetHandcuffStatus', true)
        ClearPedTasksImmediately(cache.ped)
        if cache.weapon ~= `WEAPON_UNARMED` then
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        end
        if not isSoftcuff then
            cuffType = 16
            exports.qbx_core:Notify(locale('info.cuff'), 'success')
        else
            if config.breakCuffs == true then
                local isSuccess = lib.skillCheck(config.breakCuffsDifficulty, config.breakCuffsKeys)
                if isSuccess then
                    TriggerServerEvent('police:server:SetHandcuffStatus', false)
                    ClearPedTasksImmediately(cache.ped)
                    exports.qbx_core:Notify(locale('success.escapedcuff'), 'success')
                    return
                end
            end
            cuffType = 48
            exports.qbx_core:Notify(locale('info.cuffed_walk'), 'success')
        end
        getCuffedAnimation(playerId)
    else
        IsEscorted = false
        TriggerEvent('hospital:client:isEscorted', IsEscorted)
        DetachEntity(cache.ped, true, false)
        TriggerServerEvent('police:server:SetHandcuffStatus', false)
        ClearPedTasksImmediately(cache.ped)
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Uncuff', 0.2)
        exports.qbx_core:Notify(locale('success.uncuffed'), 'success')
    end
end)

local DISABLED_CONTROLS = {
    21,  -- Sprint
    24,  -- Attack
    257, -- Attack 2
    25,  -- Aim
    263, -- Melee Attack 1
    45,  -- Reload
    22,  -- Jump
    44,  -- Cover
    37,  -- Select Weapon
    23,  -- Also 'enter'?
    288, -- Disable phone
    289, -- Inventory
    170, -- Animations
    167, -- Job
    26,  -- Disable looking behind
    73,  -- Disable clearing animation
    199, -- Disable pause screen
    59,  -- Disable steering in vehicle
    71,  -- Disable driving forward in vehicle
    72,  -- Disable reversing in vehicle
    36,  -- Disable going stealth
    264, -- Disable melee
    257, -- Disable melee
    140, -- Disable melee
    141, -- Disable melee
    142, -- Disable melee
    143, -- Disable melee
    75   -- Disable exit vehicle
}

CreateThread(function()
    local hasDisabledControls = false
    while true do
        local sleep = handcuffedEscorted()
        if sleep > 0 and hasDisabledControls then --if sleep is greater than 0, activates controls
            lib.disableControls:Remove(DISABLED_CONTROLS)
            hasDisabledControls = false
        elseif sleep == 0 and not hasDisabledControls then
            lib.disableControls:Add(DISABLED_CONTROLS)
            hasDisabledControls = true
        end
        Wait(sleep)
    end
end)
