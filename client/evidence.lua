-- Variables
local CurrentStatusList = {}
local Casings = {}
local CurrentCasing = nil
local Blooddrops = {}
local CurrentBlooddrop = nil
local Fingerprints = {}
local CurrentFingerprint = 0
local shotAmount = 0
local StatusList = {
    ['fight'] = Lang:t('evidence.red_hands'),
    ['widepupils'] = Lang:t('evidence.wide_pupils'),
    ['redeyes'] = Lang:t('evidence.red_eyes'),
    ['weedsmell'] = Lang:t('evidence.weed_smell'),
    ['gunpowder'] = Lang:t('evidence.gunpowder'),
    ['chemicals'] = Lang:t('evidence.chemicals'),
    ['heavybreath'] = Lang:t('evidence.heavy_breathing'),
    ['sweat'] = Lang:t('evidence.sweat'),
    ['handbleed'] = Lang:t('evidence.handbleed'),
    ['confused'] = Lang:t('evidence.confused'),
    ['alcohol'] = Lang:t('evidence.alcohol'),
    ["heavyalcohol"] = Lang:t('evidence.heavy_alcohol'),
    ["agitated"] = Lang:t('evidence.agitated')
}
local closeEvidenceSleep = 5000

-- Functions
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetDrawOrigin(x,y,z, 0)

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)

    local factor = (string.len(text)) / 370

    DrawRect(0.0, 0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function WhitelistedWeapon(weapon)
    for i = 1, #Config.EvidenceWhitelistedWeapons do
        if Config.EvidenceWhitelistedWeapons[i] == weapon then
            return true
        end
    end

    return false
end

local function DropBulletCasing(weapon, ped)
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)

    TriggerServerEvent('evidence:server:CreateCasing', weapon, coords)

    Wait(300)
end

local function DnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)

    return h
end

-- Events
RegisterNetEvent('evidence:client:SetStatus', function(statusId, time)
    if time > 0 and StatusList[statusId] then
        if (not CurrentStatusList or not CurrentStatusList[statusId]) or (CurrentStatusList[statusId] and CurrentStatusList[statusId].time < 20) then
            CurrentStatusList[statusId] = {
                text = StatusList[statusId],
                time = time
            }

            lib.notify({
                description = CurrentStatusList[statusId].text,
                type = 'error'
            })
        end
    elseif StatusList[statusId] then
        CurrentStatusList[statusId] = nil
    end

    TriggerServerEvent('evidence:server:UpdateStatus', CurrentStatusList)
end)

RegisterNetEvent('evidence:client:AddBlooddrop', function(bloodId, citizenid, bloodtype, coords)
    Blooddrops[bloodId] = {
        citizenid = citizenid,
        bloodtype = bloodtype,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveBlooddrop', function(bloodId)
    Blooddrops[bloodId] = nil
    CurrentBlooddrop = 0
end)

RegisterNetEvent('evidence:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    Fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveFingerprint', function(fingerId)
    Fingerprints[fingerId] = nil
    CurrentFingerprint = 0
end)

RegisterNetEvent('evidence:client:ClearBlooddropsInArea', function()
    local pos = GetEntityCoords(cache.ped)
    local blooddropList = {}

    if lib.progressBar({
        duration = 5000,
        label = Lang:t("progressbar.blood_clear"),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true
        }
    }) then
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos - vec3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) < 10.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end

            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)

            lib.notify({
                description = Lang:t("success.blood_clear"),
                type = 'success'
            })
        end
    else
        lib.notify({
            description = Lang:t("success.blood_not_cleared"),
            type = 'error'
        })
    end
end)

RegisterNetEvent('evidence:client:AddCasing', function(casingId, weapon, coords, serie)
    Casings[casingId] = {
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveCasing', function(casingId)
    Casings[casingId] = nil
    CurrentCasing = 0
end)

RegisterNetEvent('evidence:client:ClearCasingsInArea', function()
    local pos = GetEntityCoords(cache.ped)
    local casingList = {}

    if lib.progressBar({
        duration = 5000,
        label = Lang:t("progressbar.bullet_casing"),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true
        }
    }) then
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vec3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) < 10.0 then
                    casingList[#casingList + 1] = casingId
                end
            end

            TriggerServerEvent('evidence:server:ClearCasings', casingList)

            lib.notify({
                description = Lang:t("success.bullet_casing_removed"),
                type = 'success'
            })
        end
    else
        lib.notify({
            description = Lang:t("error.bullet_casing_not_removed"),
            type = 'error'
        })
    end
end)

-- Threads
CreateThread(function()
    while true do
        Wait(10000)

        if LocalPlayer.state.isLoggedIn then
            if CurrentStatusList and next(CurrentStatusList) then
                for k, _ in pairs(CurrentStatusList) do
                    if CurrentStatusList[k].time > 0 then
                        CurrentStatusList[k].time = CurrentStatusList[k].time - 10
                    else
                        CurrentStatusList[k].time = 0
                    end
                end

                TriggerServerEvent('evidence:server:UpdateStatus', CurrentStatusList)
            end

            if shotAmount > 0 then
                shotAmount = 0
            end
        end
    end
end)

CreateThread(function() -- Gunpowder Status when shooting
    while true do
        if IsPedShooting(cache.ped) then
            local weapon = GetSelectedPedWeapon(cache.ped)

            if not WhitelistedWeapon(weapon) then
                shotAmount = shotAmount + 1

                if shotAmount > 5 and (not CurrentStatusList or not CurrentStatusList['gunpowder']) then
                    if math.random(1, 10) <= 7 then
                        TriggerEvent('evidence:client:SetStatus', 'gunpowder', 200)
                    end
                end

                DropBulletCasing(weapon, cache.ped)
            end
        end

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if CurrentCasing and CurrentCasing ~= 0 then
            local pos = GetEntityCoords(cache.ped)

            if #(pos -vec3(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z)) < 1.5 then
                DrawText3D(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z, Lang:t('info.bullet_casing', {value = Casings[CurrentCasing].type}))

                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1

                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end

                    local info = {
                        label = Lang:t('info.casing'),
                        type = 'casing',
                        street = streetLabel:gsub("%'", ""),
                        ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                        ammotype = Casings[CurrentCasing].type,
                        serie = Casings[CurrentCasing].serie
                    }

                    TriggerServerEvent('evidence:server:AddCasingToInventory', CurrentCasing, info)
                end
            end
        end

        if CurrentBlooddrop and CurrentBlooddrop ~= 0 then
            local pos = GetEntityCoords(cache.ped)

            if #(pos - vec3(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z)) < 1.5 then
                DrawText3D(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z, Lang:t('info.blood_text', {value = DnaHash(Blooddrops[CurrentBlooddrop].citizenid)}))

                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1

                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end

                    local info = {
                        label = Lang:t('info.blood'),
                        type = 'blood',
                        street = streetLabel:gsub("%'", ""),
                        dnalabel = DnaHash(Blooddrops[CurrentBlooddrop].citizenid),
                        bloodtype = Blooddrops[CurrentBlooddrop].bloodtype
                    }

                    TriggerServerEvent('evidence:server:AddBlooddropToInventory', CurrentBlooddrop, info)
                end
            end
        end

        if CurrentFingerprint and CurrentFingerprint ~= 0 then
            local pos = GetEntityCoords(cache.ped)

            if #(pos - vec3(Fingerprints[CurrentFingerprint].coords.x, Fingerprints[CurrentFingerprint].coords.y,
                Fingerprints[CurrentFingerprint].coords.z)) < 1.5 then

                DrawText3D(Fingerprints[CurrentFingerprint].coords.x, Fingerprints[CurrentFingerprint].coords.y, Fingerprints[CurrentFingerprint].coords.z, Lang:t('info.fingerprint_text'))

                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Fingerprints[CurrentFingerprint].coords.x,Fingerprints[CurrentFingerprint].coords.y, Fingerprints[CurrentFingerprint].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1

                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end

                    local info = {
                        label = Lang:t('info.fingerprint'),
                        type = 'fingerprint',
                        street = streetLabel:gsub("%'", ""),
                        fingerprint = Fingerprints[CurrentFingerprint].fingerprint
                    }

                    TriggerServerEvent('evidence:server:AddFingerprintToInventory', CurrentFingerprint, info)
                end
            end
        end

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if PlayerJob.type == 'leo' and onDuty then
                if IsPlayerFreeAiming(cache.playerId) and GetSelectedPedWeapon(cache.ped) == `WEAPON_FLASHLIGHT` then
                    closeEvidenceSleep = 10

                    if next(Casings) then
                        local pos = GetEntityCoords(cache.ped, true)

                        for k, v in pairs(Casings) do
                            local dist = #(pos - vec3(v.coords.x, v.coords.y, v.coords.z))

                            if dist < 1.5 then
                                CurrentCasing = k
                            end
                        end
                    end

                    if next(Blooddrops) then
                        local pos = GetEntityCoords(cache.ped, true)

                        for k, v in pairs(Blooddrops) do
                            local dist = #(pos - vec3(v.coords.x, v.coords.y, v.coords.z))

                            if dist < 1.5 then
                                CurrentBlooddrop = k
                            end
                        end
                    end

                    if next(Fingerprints) then
                        local pos = GetEntityCoords(cache.ped, true)

                        for k, v in pairs(Fingerprints) do
                            local dist = #(pos - vec3(v.coords.x, v.coords.y, v.coords.z))

                            if dist < 1.5 then
                                CurrentFingerprint = k
                            end
                        end
                    end
                else
                    closeEvidenceSleep = 1000
                end
            else
                closeEvidenceSleep = 5000
            end
        end

        Wait(closeEvidenceSleep)
    end
end)