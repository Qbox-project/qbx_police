Plates = {}
local playerStatus = {}
local casings = {}
local bloodDrops = {}
local fingerDrops = {}
local objects = {}
local updatingCops = false

---@param player Player
---@param minGrade? integer
---@return boolean
function IsLeoAndOnDuty(player, minGrade)
    if not player or player.PlayerData.job.type ~= "leo" or not player.PlayerData.job.onduty then
        return false
    end
    if minGrade then
        return player.PlayerData.job.grade.level >= minGrade
    end
    return true
end

-- Functions
local function updateBlips()
    local dutyPlayers = {}
    local players = exports.qbx_core:.GetQBPlayers()
    for _, v in pairs(players) do
        if v and (v.PlayerData.job.type == "leo" or v.PlayerData.job.name == "ambulance") and v.PlayerData.job.onduty then
            local coords = GetEntityCoords(GetPlayerPed(v.PlayerData.source))
            local heading = GetEntityHeading(GetPlayerPed(v.PlayerData.source))
            dutyPlayers[#dutyPlayers+1] = {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata.callsign,
                job = v.PlayerData.job.name,
                location = vec4(coords.x, coords.y, coords.z, heading)
            }
        end
    end
    TriggerClientEvent("police:client:UpdateBlips", -1, dutyPlayers)
end

local function generateId(table)
    local id = math.random(10000, 99999)
    if not table then return id end
    while table[id] do
        id = math.random(10000, 99999)
    end
    return id
end

RegisterNetEvent('police:server:SendTrackerLocation', function(coords, requestId)
    local Target = exports.qbx_core:.GetPlayer(source)
    local msg = Lang:t('info.target_location', {firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname})
    local alertData = {
        title = Lang:t('info.anklet_location'),
        coords = coords,
        description = msg
    }
    TriggerClientEvent("police:client:TrackerMessage", requestId, msg, coords)
    TriggerClientEvent("qb-phone:client:addPoliceAlert", requestId, alertData)
end)

-- Items
exports.qbx_core:.CreateUseableItem("handcuffs", function(source)
    local player = exports.qbx_core:.GetPlayer(source)
    if not player.Functions.GetItemByName("handcuffs") then return end
    TriggerClientEvent("police:client:CuffPlayerSoft", source)
end)

exports.qbx_core:.CreateUseableItem("moneybag", function(source, item)
    local player = exports.qbx_core:.GetPlayer(source)
    if not player or not player.Functions.GetItemByName("moneybag") or not item.info or item.info == "" or player.PlayerData.job.type == "leo" or not player.Functions.RemoveItem("moneybag", 1, item.slot) then return end
    player.Functions.AddMoney("cash", tonumber(item.info.cash), "used-moneybag")
end)

-- Callbacks
lib.callback.register('police:server:isPlayerDead', function(_, playerId)
    local player = exports.qbx_core:.GetPlayer(playerId)
    return player.PlayerData.metadata.idead
end)

lib.callback.register('police:GetPlayerStatus', function(_, playerId)
    local player = exports.qbx_core:.GetPlayer(playerId)
    if not player or not playerStatus[player.PlayerData.source] or not next(playerStatus[player.PlayerData.source]) then
        return {}
    end
    local statList = {}
    for k in pairs(playerStatus[player.PlayerData.source]) do
        statList[#statList + 1] = playerStatus[player.PlayerData.source][k].text
    end
    return statList
end)

lib.callback.register('police:GetImpoundedVehicles', function()
    return FetchImpoundedVehicles()
end)

lib.callback.register('qbx_policejob:server:spawnVehicle', function(source, model, coords, plate)
    local netId = exports.qbx_core:.CreateVehicle(source, model, coords, true)
    if not netId or netId == 0 then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    return netId
end)

local function isPlateFlagged(plate)
    return Plates and Plates[plate] and Plates[plate].isflagged
end

---@deprecated use qbx_police:server:isPlateFlagged
exports.qbx_core:.CreateCallback('police:IsPlateFlagged', function(_, cb, plate)
    print(string.format("%s invoked deprecated callback police:IsPlateFlagged. Use police:server:IsPoliceForcePresent instead.", GetInvokingResource()))
    cb(isPlateFlagged(plate))
end)

lib.callback.register('qbx_police:server:isPlateFlagged', function(_, plate)
    return isPlateFlagged(plate)
end)

local function isPoliceForcePresent()
    local players = exports.qbx_core:.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.grade.level >= 2 then
            return true
        end
    end
    return false
end

---@deprecated
exports.qbx_core:.CreateCallback('police:server:IsPoliceForcePresent', function(_, cb)
    print(string.format("%s invoked deprecated callback police:server:IsPoliceForcePresent. Use police:server:isPoliceForcePresent instead.", GetInvokingResource()))
    cb(isPoliceForcePresent())
end)

lib.callback.register('police:server:isPoliceForcePresent', function()
    return isPoliceForcePresent()
end)

-- Events
RegisterNetEvent('police:server:Radar', function(fine)
    local source = source
    local price  = Config.SpeedFines[fine].fine
    local player = exports.qbx_core:.GetPlayer(source)
    if not player.Functions.RemoveMoney("bank", math.floor(price), "Radar Fine") then return end
    exports.qbx_management:AddMoney('police', price)
    TriggerClientEvent('QBCore:Notify', source, Lang:t("info.fine_received", {fine = price}))
end)

RegisterNetEvent('police:server:policeAlert', function(text, camId, playerSource)
    local ped = GetPlayerPed(playerSource)
    local coords = GetEntityCoords(ped)
    local players = exports.qbx_core:.GetQBPlayers()
    for k, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            if camId then
                local alertData = {title = Lang:t('info.new_call'), coords = coords, description = text .. Lang:t('info.camera_id') .. camId}
                TriggerClientEvent("qb-phone:client:addPoliceAlert", k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text, camId)
            else
                local alertData = {title = Lang:t('info.new_call'), coords = coords, description = text}
                TriggerClientEvent("qb-phone:client:addPoliceAlert", k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text)
            end
        end
    end
end)

RegisterNetEvent('police:server:TakeOutImpound', function(plate, garage)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = Config.Locations.impound[garage]
    if #(playerCoords - targetCoords) > 10.0 then return DropPlayer(src, "Attempted exploit abuse") end

    Unimpound(plate)
    TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("success.impound_vehicle_removed"), type = 'success'})
end)

local function isTargetTooFar(src, targetId, maxDistance)
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > maxDistance then
        DropPlayer(src, "Attempted exploit abuse")
        return true
    end
    return false
end

RegisterNetEvent('police:server:CuffPlayer', function(playerId, isSoftcuff)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(src)
    local cuffedPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not cuffedPlayer or (not player.Functions.GetItemByName("handcuffs") and player.PlayerData.job.type ~= "leo") then return end

    TriggerClientEvent("police:client:GetCuffed", cuffedPlayer.PlayerData.source, player.PlayerData.source, isSoftcuff)
end)

RegisterNetEvent('police:server:EscortPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(source)
    local escortPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not escortPlayer then return end

    if (player.PlayerData.job.type == "leo" or player.PlayerData.job.name == "ambulance") or (escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand) then
        TriggerClientEvent("police:client:GetEscorted", escortPlayer.PlayerData.source, player.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:KidnapPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end
    local Player = exports.qbx_core:.GetPlayer(source)
    local escortPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not Player or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand then
        TriggerClientEvent("police:client:GetKidnappedTarget", escortPlayer.PlayerData.source, Player.PlayerData.source)
        TriggerClientEvent("police:client:GetKidnappedDragger", Player.PlayerData.source, escortPlayer.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:SetPlayerOutVehicle', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local escortPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not exports.qbx_core:.GetPlayer(src) or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead then
        TriggerClientEvent("police:client:SetOutVehicle", escortPlayer.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local escortPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not exports.qbx_core:.GetPlayer(src) or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead then
        TriggerClientEvent("police:client:PutInVehicle", escortPlayer.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:BillPlayer', function(playerId, price)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(src)
    local otherPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not otherPlayer or player.PlayerData.job.type ~= "leo" then return end

    otherPlayer.Functions.RemoveMoney("bank", price, "paid-bills")
    exports.qbx_management:AddMoney("police", price)
    TriggerClientEvent('ox_lib:notify', otherPlayer.PlayerData.source, {description = Lang:t("info.fine_received", {fine = price})})
end)

RegisterNetEvent('police:server:JailPlayer', function(playerId, time)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(src)
    local otherPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not otherPlayer or player.PlayerData.job.type ~= "leo" then return end

    local currentDate = os.date("*t")
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    otherPlayer.Functions.SetMetaData("injail", time)
    otherPlayer.Functions.SetMetaData("criminalrecord", {
        hasRecord = true,
        date = currentDate
    })
    TriggerClientEvent("police:client:SendToJail", otherPlayer.PlayerData.source, time)
    TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.sent_jail_for", {time = time})})
end)

RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed)
    local player = exports.qbx_core:.GetPlayer(source)
    if not player then return end
    player.Functions.SetMetaData("ishandcuffed", isHandcuffed)
end)

RegisterNetEvent('heli:spotlight', function(state)
    TriggerClientEvent('heli:spotlight', -1, source, state)
end)

RegisterNetEvent('police:server:FlaggedPlateTriggered', function(radar, plate, street)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = exports.qbx_core:.GetQBPlayers()
    for k, v in pairs(players) do
        if v and IsLeoAndOnDuty(v) then
            local alertData = {title = Lang:t('info.new_call'), coords = coords, description = Lang:t('info.plate_triggered', {plate = plate, street = street, radar = radar})}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", k, alertData)
            TriggerClientEvent('police:client:policeAlert', k, coords, Lang:t('info.plate_triggered_blip', {radar = radar}))
        end
    end
end)

RegisterNetEvent('police:server:SearchPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local searchedPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not exports.qbx_core:.GetPlayer(src) or not searchedPlayer then return end

    TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.searched_success")})
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("info.being_searched")})
end)

RegisterNetEvent('police:server:SeizeCash', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(src)
    local searchedPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not searchedPlayer then return end

    local moneyAmount = searchedPlayer.PlayerData.money.cash
    local info = { cash = moneyAmount }
    searchedPlayer.Functions.RemoveMoney("cash", moneyAmount, "police-cash-seized")
    player.Functions.AddItem("moneybag", 1, false, info)
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("info.cash_confiscated")})
end)

RegisterNetEvent('police:server:RobPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = exports.qbx_core:.GetPlayer(src)
    local searchedPlayer = exports.qbx_core:.GetPlayer(playerId)
    if not player or not searchedPlayer then return end

    local money = searchedPlayer.PlayerData.money.cash
    player.Functions.AddMoney("cash", money, "police-player-robbed")
    searchedPlayer.Functions.RemoveMoney("cash", money, "police-player-robbed")
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("info.cash_robbed", {money = money})})
    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {description = Lang:t("info.stolen_money", {stolen = money})})
end)

RegisterNetEvent('police:server:spawnObject', function(type)
    local src = source
    local objectId = generateId(objects)
    objects[objectId] = type
    TriggerClientEvent("police:client:spawnObject", src, objectId, type)
end)

RegisterNetEvent('police:server:deleteObject', function(objectId)
    TriggerClientEvent('police:client:removeObject', -1, objectId)
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    price = price or 0
    if not IsVehicleOwned(plate) then return end
    if not fullImpound then
        ImpoundWithPrice(price, body, engine, fuel, plate)
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.vehicle_taken_depot", {price = price})})
    else
        ImpoundForever(body, engine, fuel, plate)
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.vehicle_seized")})
    end
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    playerStatus[source] = data
end)

RegisterNetEvent('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
    local bloodId = generateId(bloodDrops)
    bloodDrops[bloodId] = {
        dna = citizenid,
        bloodtype = bloodtype
    }
    TriggerClientEvent("evidence:client:AddBlooddrop", -1, bloodId, citizenid, bloodtype, coords)
end)

RegisterNetEvent('evidence:server:CreateFingerDrop', function(coords)
    local player = exports.qbx_core:.GetPlayer(source)
    local fingerId = generateId(fingerDrops)
    fingerDrops[fingerId] = player.PlayerData.metadata.fingerprint
    TriggerClientEvent("evidence:client:AddFingerPrint", -1, fingerId, player.PlayerData.metadata.fingerprint, coords)
end)

RegisterNetEvent('evidence:server:ClearBlooddrops', function(blooddropList)
    if not blooddropList or not next(blooddropList) then return end
    for _, v in pairs(blooddropList) do
        TriggerClientEvent("evidence:client:RemoveBlooddrop", -1, v)
        bloodDrops[v] = nil
    end
end)

RegisterNetEvent('evidence:server:AddBlooddropToInventory', function(bloodId, bloodInfo)
    local src = source
    local player = exports.qbx_core:.GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname.." "..player.PlayerData.charinfo.lastname
    local streetName = bloodInfo.street
    local bloodType = bloodInfo.bloodtype
    local bloodDNA = bloodInfo.dnalabel
    local metadata = {}
    metadata.type = 'Blood Evidence'
    metadata.description = "DNA ID: "..bloodDNA
    metadata.description = metadata.description.."\n\nBlood Type: "..bloodType
    metadata.description = metadata.description.."\n\nCollected By: "..playerName
    metadata.description = metadata.description.."\n\nCollected At: "..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.have_evidence_bag"), type = "error"})
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent("evidence:client:RemoveBlooddrop", -1, bloodId)
        bloodDrops[bloodId] = nil
    end
end)

RegisterNetEvent('evidence:server:AddFingerprintToInventory', function(fingerId, fingerInfo)
    local src = source
    local player = exports.qbx_core:.GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname.." "..player.PlayerData.charinfo.lastname
    local streetName = fingerInfo.street
    local fingerPrint = fingerInfo.fingerprint
    local metadata = {}
    metadata.type = 'Fingerprint Evidence'
    metadata.description = "Fingerprint ID: "..fingerPrint
    metadata.description = metadata.description.."\n\nCollected By: "..playerName
    metadata.description = metadata.description.."\n\nCollected At: "..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.have_evidence_bag"), type = "error"})
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent("evidence:client:RemoveFingerprint", -1, fingerId)
        fingerDrops[fingerId] = nil
    end
end)

RegisterNetEvent('evidence:server:CreateCasing', function(weapon, serial, coords)
    local casingId = generateId(casings)
    local serieNumber = exports.ox_inventory:GetCurrentWeapon(source).metadata.serial
    if not serieNumber then
	serieNumber = serial
    end
    TriggerClientEvent("evidence:client:AddCasing", -1, casingId, weapon, coords, serieNumber)
end)

RegisterNetEvent('police:server:UpdateCurrentCops', function()
    local amount = 0
    local players = exports.qbx_core:.GetQBPlayers()
    if updatingCops then return end
    updatingCops = true
    for _, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            amount += 1
        end
    end
    TriggerClientEvent("police:SetCopCount", -1, amount)
    updatingCops = false
end)

RegisterNetEvent('evidence:server:ClearCasings', function(casingList)
    if casingList and next(casingList) then
        for _, v in pairs(casingList) do
            TriggerClientEvent("evidence:client:RemoveCasing", -1, v)
            casings[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddCasingToInventory', function(casingId, casingInfo)
    local src = source
    local player = exports.qbx_core:.GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname.." "..player.PlayerData.charinfo.lastname
    local streetName = casingInfo.street
    local ammoType = casingInfo.ammolabel
    local serialNumber = casingInfo.serie
    local metadata = {}
    metadata.type = 'Casing Evidence'
    metadata.description = "Ammo Type: "..ammoType
    metadata.description = metadata.description.."\n\nSerial #: "..serialNumber
    metadata.description = metadata.description.."\n\nCollected By: "..playerName
    metadata.description = metadata.description.."\n\nCollected At: "..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.have_evidence_bag"), type = "error"})
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent("evidence:client:RemoveCasing", -1, casingId)
        casings[casingId] = nil
    end
end)

RegisterNetEvent('police:server:showFingerprint', function(playerId)
    TriggerClientEvent('police:client:showFingerprint', playerId, source)
    TriggerClientEvent('police:client:showFingerprint', source, playerId)
end)

RegisterNetEvent('police:server:showFingerprintId', function(sessionId)
    local player = exports.qbx_core:.GetPlayer(source)
    local fid = player.PlayerData.metadata.fingerprint
    TriggerClientEvent('police:client:showFingerprintId', sessionId, fid)
    TriggerClientEvent('police:client:showFingerprintId', source, fid)
end)

RegisterNetEvent('police:server:SetTracker', function(targetId)
    local src = source
    if isTargetTooFar(src, targetId, 2.5) then return end

    local target = exports.qbx_core:.GetPlayer(targetId)
    if not exports.qbx_core:.GetPlayer(src) or not target then return end

    local trackerMeta = target.PlayerData.metadata.tracker
    if trackerMeta then
        target.Functions.SetMetaData("tracker", false)
        TriggerClientEvent('ox_lib:notify', targetId, {description = Lang:t("success.anklet_taken_off"), type = 'success'})
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("success.took_anklet_from", {firstname = target.PlayerData.charinfo.firstname, lastname = target.PlayerData.charinfo.lastname}), type = 'success'})
        TriggerClientEvent('police:client:SetTracker', targetId, false)
    else
        target.Functions.SetMetaData("tracker", true)
        TriggerClientEvent('ox_lib:notify', targetId, {description = Lang:t("success.put_anklet"), type = 'success'})
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("success.put_anklet_on", {firstname = target.PlayerData.charinfo.firstname, lastname = target.PlayerData.charinfo.lastname}), type = 'success'})
        TriggerClientEvent('police:client:SetTracker', targetId, true)
    end
end)

RegisterNetEvent('police:server:SyncSpikes', function(table)
    TriggerClientEvent('police:client:SyncSpikes', -1, table)
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= 'ox_inventory' then return end

    local jobs = {}
    for k, v in pairs(exports.qbx_core:GetJobs()) do
        if v.type == 'leo' then
            jobs[k] = 0
        end
    end

    for i = 1, #Config.Locations.trash do
        exports.ox_inventory:RegisterStash(('policetrash_%s'):format(i), 'Police Trash', 300, 4000000, nil, jobs, Config.Locations.trash[i])
    end
    exports.ox_inventory:RegisterStash('policelocker', 'Police Locker', 30, 100000, true)
end)

-- Threads
CreateThread(function()
    Wait(1000)
    for i = 1, #Config.Locations.trash do
        exports.ox_inventory:ClearInventory(('policetrash_%s'):format(i))
    end
    while true do
        Wait(1000 * 60 * 10)
        local curCops = exports.qbx_core:.GetDutyCountType('leo')
        TriggerClientEvent("police:SetCopCount", -1, curCops)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        updateBlips()
    end
end)
