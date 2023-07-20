-- Variables
local currentStatusList = {}
local casings = {}
local currentCasing = nil
local bloodDrops = {}
local currentBloodDrop = nil
local fingerprints = {}
local currentFingerprint = 0
local shotAmount = 0

local statusList = {
    fight = Lang:t('evidence.red_hands'),
    widepupils = Lang:t('evidence.wide_pupils'),
    redeyes = Lang:t('evidence.red_eyes'),
    weedsmell = Lang:t('evidence.weed_smell'),
    gunpowder = Lang:t('evidence.gunpowder'),
    chemicals = Lang:t('evidence.chemicals'),
    heavybreath = Lang:t('evidence.heavy_breathing'),
    sweat = Lang:t('evidence.sweat'),
    handbleed = Lang:t('evidence.handbleed'),
    confused = Lang:t('evidence.confused'),
    alcohol = Lang:t('evidence.alcohol'),
    heavyalcohol = Lang:t('evidence.heavy_alcohol'),
    agitated = Lang:t('evidence.agitated')
}

local ignoredWeapons = {
    [`weapon_unarmed`] = true,
    [`weapon_snowball`] = true,
    [`weapon_stungun`] = true,
    [`weapon_petrolcan`] = true,
    [`weapon_hazardcan`] = true,
    [`weapon_fireextinguisher`] = true,
}

-- Functions
---@param coords vector3
---@param text string
local function drawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function dropBulletCasing(weapon, ped)
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
    local serial = exports.ox_inventory:getCurrentWeapon().metadata.serial
    TriggerServerEvent('evidence:server:CreateCasing', weapon, serial, coords)
    Wait(300)
end

local function dnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
    return h
end

-- Events
RegisterNetEvent('evidence:client:SetStatus', function(statusId, time)
    if time > 0 and statusList[statusId] then
        if not currentStatusList?[statusId] or currentStatusList[statusId].time < 20 then
            currentStatusList[statusId] = {
                text = statusList[statusId],
                time = time
            }
            QBCore.Functions.Notify(currentStatusList[statusId].text, 'error')
        end
    elseif statusList[statusId] then
        currentStatusList[statusId] = nil
    end
    TriggerServerEvent('evidence:server:UpdateStatus', currentStatusList)
end)

RegisterNetEvent('evidence:client:AddBlooddrop', function(bloodId, citizenid, bloodtype, coords)
    bloodDrops[bloodId] = {
        citizenid = citizenid,
        bloodtype = bloodtype,
        coords = vec3(coords.x, coords.y, coords.z - 0.9)
    }
end)

RegisterNetEvent('evidence:client:RemoveBlooddrop', function(bloodId)
    bloodDrops[bloodId] = nil
    currentBloodDrop = 0
end)

RegisterNetEvent('evidence:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = vec3(coords.x, coords.y, coords.z - 0.9)
    }
end)

RegisterNetEvent('evidence:client:RemoveFingerprint', function(fingerId)
    fingerprints[fingerId] = nil
    currentFingerprint = 0
end)

RegisterNetEvent('evidence:client:ClearBlooddropsInArea', function()
    local pos = GetEntityCoords(cache.ped)
    local blooddropList = {}
    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = Lang:t('progressbar.blood_clear'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = HealAnimDict,
            clip = HealAnim,
        },
    })
    then
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        if bloodDrops and next(bloodDrops) then
            for bloodId in pairs(bloodDrops) do
                if #(pos - bloodDrops[bloodId].coords) < 10.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
            lib.notify({ description = Lang:t('success.blood_clear'), type = 'success' })
        end
    else
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        lib.notify({ description = Lang:t('error.blood_not_cleared'), type = 'error' })
    end
end)

RegisterNetEvent('evidence:client:AddCasing', function(casingId, weapon, coords, serie)
    casings[casingId] = {
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = vec3(coords.x, coords.y, coords.z - 0.9)
    }
end)

RegisterNetEvent('evidence:client:RemoveCasing', function(casingId)
    casings[casingId] = nil
    currentCasing = 0
end)

RegisterNetEvent('evidence:client:ClearCasingsInArea', function()
    local pos = GetEntityCoords(cache.ped)
    local casingList = {}

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = Lang:t('progressbar.bullet_casing'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = HealAnimDict,
            clip = HealAnim,
        },
    })
    then
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        if casings and next(casings) then
            for casingId in pairs(casings) do
                if #(pos - casings[casingId].coords) < 10.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
            lib.notify({ description = Lang:t('success.bullet_casing_removed'), type = 'success' })
        end
    else
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        lib.notify({ description = Lang:t('error.bullet_casing_not_removed'), type = 'error' })
    end
end)

-- Threads

local function updateStatus()
    if not IsLoggedIn then return end
    if currentStatusList and next(currentStatusList) then
        for k in pairs(currentStatusList) do
            if currentStatusList[k].time > 0 then
                currentStatusList[k].time -= 10
            else
                currentStatusList[k].time = 0
            end
        end
        TriggerServerEvent('evidence:server:UpdateStatus', currentStatusList)
    end
    if shotAmount > 0 then
        shotAmount = 0
    end
end

CreateThread(function()
    while true do
        Wait(10000)
        updateStatus()
    end
end)

local function onPlayerShooting()
    shotAmount += 1
    if shotAmount > 5 and not currentStatusList?.gunpowder then
        if math.random(1, 10) <= 7 then
            TriggerEvent('evidence:client:SetStatus', 'gunpowder', 200)
        end
    end
    dropBulletCasing(cache.weapon, cache.ped)
end

CreateThread(function() -- Gunpowder Status when shooting
    while true do
        Wait(0)
        if IsPedShooting(cache.ped) and not ignoredWeapons[cache.weapon] then
            onPlayerShooting()
        end
    end
end)

---@param coords vector3
---@return string
local function getStreetLabel(coords)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    local streetLabel = street1
    if street2 then
        streetLabel = streetLabel .. ' | ' .. street2
    end
    local sanitized = streetLabel:gsub("%'", "")
    return sanitized
end

local function getPlayerDistanceFromCoords(coords)
    local pos = GetEntityCoords(cache.ped)
    return #(pos - coords)
end

--- draw 3D text on the ground to show evidence, if they press pickup button, set metadata and add it to their inventory.
CreateThread(function()
    while true do
        Wait(0)
        if currentCasing and currentCasing ~= 0 then
            if getPlayerDistanceFromCoords(casings[currentCasing].coords) < 1.5 then
                drawText3D(casings[currentCasing].coords, Lang:t('info.bullet_casing', {value = casings[currentCasing].type}))
                if IsControlJustReleased(0, 47) then
                    local info = {
                        type = Lang:t('info.casing'),
                        street = getStreetLabel(casings[currentCasing].coords),
                        ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[casings[currentCasing].type].ammotype],
                        ammotype = casings[currentCasing].type,
                        serie = casings[currentCasing].serie
                    }
                    TriggerServerEvent('evidence:server:AddCasingToInventory', currentCasing, info)
                end
            end
        end

        if currentBloodDrop and currentBloodDrop ~= 0 then
            if getPlayerDistanceFromCoords(bloodDrops[currentBloodDrop].coords) < 1.5 then
                drawText3D(bloodDrops[currentBloodDrop].coords, Lang:t('info.blood_text', {value = dnaHash(bloodDrops[currentBloodDrop].citizenid)}))
                if IsControlJustReleased(0, 47) then
                    local info = {
                        type = Lang:t('info.blood'),
                        street = getStreetLabel(bloodDrops[currentBloodDrop].coords),
                        dnalabel = dnaHash(bloodDrops[currentBloodDrop].citizenid),
                        bloodtype = bloodDrops[currentBloodDrop].bloodtype
                    }
                    TriggerServerEvent('evidence:server:AddBlooddropToInventory', currentBloodDrop, info)
                end
            end
        end

        if currentFingerprint and currentFingerprint ~= 0 then
            if getPlayerDistanceFromCoords(fingerprints[currentFingerprint].coords) < 1.5 then
                drawText3D(fingerprints[currentFingerprint].coords, Lang:t('info.fingerprint_text'))
                if IsControlJustReleased(0, 47) then
                    local info = {
                        type = Lang:t('info.fingerprint'),
                        street = getStreetLabel(fingerprints[currentFingerprint].coords),
                        fingerprint = fingerprints[currentFingerprint].fingerprint
                    }
                    TriggerServerEvent('evidence:server:AddFingerprintToInventory', currentFingerprint, info)
                end
            end
        end
    end
end)

local function canDiscoverEvidence()
    return IsLoggedIn
        and PlayerData.job.type == 'leo'
        and PlayerData.job.onduty
        and IsPlayerFreeAiming(cache.playerId)
        and cache.weapon == `WEAPON_FLASHLIGHT`
end

---@param evidence table<number, {coords: vector3}>
---@return number? evidenceId
local function getCloseEvidence(evidence)
    local pos = GetEntityCoords(cache.ped, true)
    for evidenceId, v in pairs(evidence) do
        local dist = #(pos - v.coords)
        if dist < 1.5 then
            return evidenceId
        end
    end
end

CreateThread(function()
    while true do
        local closeEvidenceSleep = 1000
        if canDiscoverEvidence() then
            closeEvidenceSleep = 10
            currentCasing = getCloseEvidence(casings) or currentCasing
            currentBloodDrop = getCloseEvidence(bloodDrops) or currentBloodDrop
            currentFingerprint = getCloseEvidence(fingerprints) or currentFingerprint
        end
        Wait(closeEvidenceSleep)
    end
end)
