local disabledControls = {
    21, -- Sprint
    24, -- Attack
    257, -- Attack 2
    25, -- Aim
    263, -- Melee Attack 1
    45, -- Reload
    22, -- Jump
    44, -- Cover
    37, -- Select Weapon
    23, -- Enter vehicle
    288, -- Disable phone
    289, -- Inventory
    170, -- Animations
    167, -- Job
    26, -- Disable looking behind
    73, -- Disable clearing animation
    199, -- Disable pause screen
    59, -- Disable steering in vehicle
    71, -- Disable driving forward in vehicle
    72, -- Disable reversing in vehicle
    36, -- Disable going stealth
    264, -- Disable melee
    257, -- Disable melee
    140, -- Disable melee
    141, -- Disable melee
    142, -- Disable melee
    143, -- Disable melee
    75 -- Disable exit vehicle
}

lib.callback.register('qbx_police:client:getHandcuffed', function()
    ClearPedTasksImmediately(cache.ped)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, true)

    local success = lib.skillCheck('medium')

    LocalPlayer.state.invBusy = true

    lib.playAnim('mp_arrest_paired', 'crook_p2_back_right', 8.0, 8.0, 3750, 48, 0.0, false, 0, false)
    Wait(3750)

    while lib.skillCheckActive() do
        Wait(0)
    end

    if success then
        lib.disableControls:Add(disabledControls)
        lib.disableRadial(true)
    else
        LocalPlayer.state.invBusy = false
    end

    FreezeEntityPosition(cache.ped, false)

    return not success
end)

RegisterNetEvent('qbx_police:client:handcuffPlayer', function()
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, true)

    lib.playAnim('mp_arrest_paired', 'cop_p2_back_right', 8.0, 8.0, 3750, 48, 0.0, false, 0, false)
    Wait(3750)

    FreezeEntityPosition(cache.ped, false)
end)

RegisterNetEvent('qbx_police:client:getUnhandcuffed', function()
    FreezeEntityPosition(cache.ped, true)

    LocalPlayer.state.invBusy = false

    lib.playAnim('mp_arresting', 'b_uncuff', 8.0, 8.0, 5500, 48, 0.0, false, 0, false)
    Wait(5500)

    lib.disableControls:Remove(disabledControls)
    lib.disableRadial(false)

    FreezeEntityPosition(cache.ped, false)
end)

RegisterNetEvent('qbx_police:client:unhandcuffPlayer', function()
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, true)

    lib.playAnim('mp_arresting', 'a_uncuff', 8.0, 8.0, 3750, 48, 0.0, false, 0, false)
    Wait(3750)

    FreezeEntityPosition(cache.ped, false)
end)

CreateThread(function()
    while LocalPlayer.state.handcuffed do
        if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
            lib.playAnim('mp_arresting', 'idle', 8.0, 8.0, -1, 48, 0.0, false, 0, false)
        end

        lib.disableControls()

        Wait(0)
    end
end)