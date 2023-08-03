local QBCore = exports['qbx-core']:GetCoreObject()
local plates = {}
local playerStatus = {}
local casings = {}
local bloodDrops = {}
local fingerDrops = {}
local objects = {}
local updatingCops = false

---@param player Player
---@param minGrade? integer
---@return boolean
local function isLeoAndOnDuty(player, minGrade)
    if not player or player.PlayerData.job.type ~= "leo" or not player.PlayerData.job.onduty then
        return false
    end
    if minGrade then
        return player.PlayerData.job.grade.level >= minGrade
    end
    return true
end

---if player is not leo or not on duty, notifies them
---@param player number|Player
---@param minGrade? integer
---@return boolean
local function checkLeoAndOnDuty(player, minGrade)
    if type(player) == "number" then
        player = QBCore.Functions.GetPlayer(player)
    end
    if not isLeoAndOnDuty(player, minGrade) then
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {description = Lang:t("error.on_duty_police_only"), type = 'error'})
        return false
    end
    return true
end

-- Functions
local function updateBlips()
    local dutyPlayers = {}
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and (v.PlayerData.job.type == "leo" or v.PlayerData.job.name == "ambulance") and v.PlayerData.job.onduty then
            local coords = GetEntityCoords(GetPlayerPed(v.PlayerData.source))
            local heading = GetEntityHeading(GetPlayerPed(v.PlayerData.source))
            dutyPlayers[#dutyPlayers+1] = {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata.callsign,
                job = v.PlayerData.job.name,
                location = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    w = heading
                }
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

local function isVehicleOwned(plate)
    local count = MySQL.scalar.await('SELECT count(*) FROM player_vehicles WHERE plate = ?', {plate})
    return count > 0
end

local function dnaHash(s)
    return string.gsub(s, ".", function(c)
        return string.format("%02x", string.byte(c))
    end)
end

-- Commands
QBCore.Commands.Add("spikestrip", Lang:t("commands.place_spike"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:SpawnSpikeStrip', source)
end)

QBCore.Commands.Add("grantlicense", Lang:t("commands.license_grant"), {{name = "id", help = Lang:t('info.player_id')}, {name = "license", help = Lang:t('info.license_type')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source, Config.LicenseRank) then 
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.error_rank_license"), type = 'error'})
        return
    end
    if args[2] ~= "driver" and args[2] ~= "weapon" then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.license_type"), type = 'error'})
        return
    end
    local searchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not searchedPlayer then return end
    local licenseTable = searchedPlayer.PlayerData.metadata.licences
    if licenseTable[args[2]] then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.license_already"), type = 'error'})
        return
    end
    licenseTable[args[2]] = true
    searchedPlayer.Functions.SetMetaData("licences", licenseTable)
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("success.granted_license"), type = 'success'})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("success.grant_license"), type = 'success'})
end)

QBCore.Commands.Add("revokelicense", Lang:t("commands.license_revoke"), {{name = "id", help = Lang:t('info.player_id')}, {name = "license", help = Lang:t('info.license_type')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source, Config.LicenseRank) then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.rank_revoke"), type = "error"})
        return
    end
    if args[2] ~= "driver" and args[2] ~= "weapon" then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.error_license"), type = "error"})
        return
    end
    local searchedPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not searchedPlayer then return end
    local licenseTable = searchedPlayer.PlayerData.metadata.licences
    if not licenseTable[args[2]] then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.error_license"), type = "error"})
        return
    end
    licenseTable[args[2]] = false
    searchedPlayer.Functions.SetMetaData("licences", licenseTable)
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("error.revoked_license"), type = "error"})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("success.revoke_license"), type = "success"})
end)

QBCore.Commands.Add("pobject", Lang:t("commands.place_object"), {{name = "type",help = Lang:t("info.poobject_object")}}, true, function(source, args)
    local type = args[1]:lower()
    if not checkLeoAndOnDuty(source) then return end

    if type == 'delete' then
        TriggerClientEvent("police:client:deleteObject", source)
        return
    end

    if Config.Objects[type] then
        TriggerClientEvent("police:client:spawnPObj", source, type)
    end
end)

QBCore.Commands.Add("cuff", Lang:t("commands.cuff_player"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CuffPlayer", source)
end)

QBCore.Commands.Add("escort", Lang:t("commands.escort"), {}, false, function(source)
    TriggerClientEvent("police:client:EscortPlayer", source)
end)

QBCore.Commands.Add("callsign", Lang:t("commands.callsign"), {{name = "name", help = Lang:t('info.callsign_name')}}, false, function(source, args)
    local player = QBCore.Functions.GetPlayer(source)
    player.Functions.SetMetaData("callsign", table.concat(args, " "))
end)

QBCore.Commands.Add("clearcasings", Lang:t("commands.clear_casign"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("evidence:client:ClearCasingsInArea", source)
end)

QBCore.Commands.Add("jail", Lang:t("commands.jail_player"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:JailPlayer", source)
end)

QBCore.Commands.Add("unjail", Lang:t("commands.unjail_player"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("prison:client:UnjailPerson", tonumber(args[1]) --[[@as number]])
end)

QBCore.Commands.Add("clearblood", Lang:t("commands.clearblood"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("evidence:client:ClearBlooddropsInArea", source)
end)

QBCore.Commands.Add("seizecash", Lang:t("commands.seizecash"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:SeizeCash", source)
end)

QBCore.Commands.Add("sc", Lang:t("commands.softcuff"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CuffPlayerSoft", source)
end)

QBCore.Commands.Add("cam", Lang:t("commands.camera"), {{name = "camid", help = Lang:t('info.camera_id_help')}}, false, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ActiveCamera", source, tonumber(args[1]))
end)

QBCore.Commands.Add("flagplate", Lang:t("commands.flagplate"), {{name = "plate", help = Lang:t('info.plate_number')}, {name = "reason", help = Lang:t('info.flag_reason')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local reason = {}
    for i = 2, #args, 1 do
        reason[#reason+1] = args[i]
    end
    plates[args[1]:upper()] = {
        isflagged = true,
        reason = table.concat(reason, " ")
    }
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.vehicle_flagged", {vehicle = args[1]:upper(), reason = table.concat(reason, " ")})})
end)

QBCore.Commands.Add("unflagplate", Lang:t("commands.unflagplate"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not plates or not plates[args[1]:upper()] then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end

    if not plates[args[1]:upper()].isflagged then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end

    plates[args[1]:upper()].isflagged = false
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.unflag_vehicle", {vehicle = args[1]:upper()})})
end)

QBCore.Commands.Add("plateinfo", Lang:t("commands.plateinfo"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not plates or plates[args[1]:upper()] then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end
    if plates[args[1]:upper()].isflagged then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t('success.vehicle_flagged', {plate = args[1]:upper(), reason = plates[args[1]:upper()].reason}), type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end
end)

QBCore.Commands.Add("depot", Lang:t("commands.depot"), {{name = "price", help = Lang:t('info.impound_price')}}, false, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ImpoundVehicle", source, false, tonumber(args[1]))
end)

QBCore.Commands.Add("impound", Lang:t("commands.impound"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ImpoundVehicle", source, true)
end)

QBCore.Commands.Add("paytow", Lang:t("commands.paytow"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local playerId = tonumber(args[1])
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
    if not OtherPlayer then return end
    if OtherPlayer.PlayerData.job.name ~= "tow" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.not_towdriver"), type = 'error'})
    end

    OtherPlayer.Functions.AddMoney("bank", 500, "police-tow-paid")
    TriggerClientEvent('ox_lib:notify', OtherPlayer.PlayerData.source, {description = Lang:t("success.tow_paid"), type = 'success'})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.tow_driver_paid")})
end)

QBCore.Commands.Add("paylawyer", Lang:t("commands.paylawyer"), {{name = "id",help = Lang:t('info.player_id')}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.type ~= "leo" and Player.PlayerData.job.name ~= "judge" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.on_duty_police_only"), type = 'error'})
    end

    local playerId = tonumber(args[1])
    local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
    if not OtherPlayer then return end
    if OtherPlayer.PlayerData.job.name ~= "lawyer" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.not_lawyer"), type = "error"})
    end

    OtherPlayer.Functions.AddMoney("bank", 500, "police-lawyer-paid")
    TriggerClientEvent('ox_lib:notify', OtherPlayer.PlayerData.source, {description = Lang:t("success.tow_paid"), type = 'success'})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.paid_lawyer")})
end)

QBCore.Commands.Add("anklet", Lang:t("commands.anklet"), {}, false, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CheckDistance", source)
end)

QBCore.Commands.Add("ankletlocation", Lang:t("commands.ankletlocation"), {{name = "cid", help = Lang:t('info.citizen_id')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local citizenid = args[1]
    local Target = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Target then return end
    if not Target.PlayerData.metadata.tracker then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.no_anklet"), type = 'error'})
    end
    TriggerClientEvent("police:client:SendTrackerLocation", Target.PlayerData.source, source)
end)

QBCore.Commands.Add("takedna", Lang:t("commands.takedna"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    local player = QBCore.Functions.GetPlayer(source)
    local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))

    if not checkLeoAndOnDuty(player) then return end
    if not player.Functions.RemoveItem("empty_evidence_bag", 1) then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.have_evidence_bag"), type = "error"})
    end
    
    local info = {
        label = Lang:t('info.dna_sample'),
        type = "dna",
        dnalabel = dnaHash(OtherPlayer.PlayerData.citizenid),
        description = dnaHash(OtherPlayer.PlayerData.citizenid)
    }
    if not player.Functions.AddItem("filled_evidence_bag", 1, false, info) then return end
end)

RegisterNetEvent('police:server:SendTrackerLocation', function(coords, requestId)
    local Target = QBCore.Functions.GetPlayer(source)
    local msg = Lang:t('info.target_location', {firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname})
    local alertData = {
        title = Lang:t('info.anklet_location'),
        coords = coords,
        description = msg
    }
    TriggerClientEvent("police:client:TrackerMessage", requestId, msg, coords)
    TriggerClientEvent("qb-phone:client:addPoliceAlert", requestId, alertData)
end)

QBCore.Commands.Add('911p', Lang:t("commands.police_report"), {{name='message', help= Lang:t("commands.message_sent")}}, false, function(source, args)
    local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t("commands.civilian_call") end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if isLeoAndOnDuty(v) then
            local alertData = {title = Lang:t("commands.emergency_call"), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end)

-- Items
QBCore.Functions.CreateUseableItem("handcuffs", function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player.Functions.GetItemByName("handcuffs") then return end
    TriggerClientEvent("police:client:CuffPlayerSoft", source)
end)

QBCore.Functions.CreateUseableItem("moneybag", function(source, item)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or not player.Functions.GetItemByName("moneybag") or not item.info or item.info == "" or player.PlayerData.job.type == "leo" or not player.Functions.RemoveItem("moneybag", 1, item.slot) then return end
    player.Functions.AddMoney("cash", tonumber(item.info.cash), "used-moneybag")
end)

-- Callbacks
lib.callback.register('police:server:isPlayerDead', function(_, playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    return player.PlayerData.metadata.idead
end)

lib.callback.register('police:GetPlayerStatus', function(_, playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
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
    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE state = ?', {2})
    if result[1] then
        return result
    end
end)

lib.callback.register('qbx-policejob:server:spawnVehicle', function(source, model, coords, plate)
    local netId = QBCore.Functions.CreateVehicle(source, model, coords, true)
    if not netId or netId == 0 then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    return netId
end)

local function isPlateFlagged(plate)
    return plates and plates[plate] and plates[plate].isflagged
end

---@deprecated use qbx-police:server:isPlateFlagged
QBCore.Functions.CreateCallback('police:IsPlateFlagged', function(_, cb, plate)
    print(string.format("%s invoked deprecated callback police:IsPlateFlagged. Use police:server:IsPoliceForcePresent instead.", GetInvokingResource()))
    cb(isPlateFlagged(plate))
end)

lib.callback.register('qbx-police:server:isPlateFlagged', function(_, plate)
    return isPlateFlagged(plate)
end)

local function isPoliceForcePresent()
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == "leo" and v.PlayerData.job.grade.level >= 2 then
            return true
        end
    end
    return false
end

---@deprecated
QBCore.Functions.CreateCallback('police:server:IsPoliceForcePresent', function(_, cb)
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
    local player = QBCore.Functions.GetPlayer(source)
    if not player.Functions.RemoveMoney("bank", math.floor(price), "Radar Fine") then return end
    exports['qbx-management']:AddMoney('police', price)
    TriggerClientEvent('QBCore:Notify', source, Lang:t("info.fine_received", {fine = price}))
end)

RegisterNetEvent('police:server:policeAlert', function(text, camId, playerSource)
    local ped = GetPlayerPed(playerSource)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for k, v in pairs(players) do
        if isLeoAndOnDuty(v) then
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

    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', {0, plate})
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

    local player = QBCore.Functions.GetPlayer(src)
    local cuffedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not player or not cuffedPlayer or (not player.Functions.GetItemByName("handcuffs") and player.PlayerData.job.type ~= "leo") then return end

    TriggerClientEvent("police:client:GetCuffed", cuffedPlayer.PlayerData.source, player.PlayerData.source, isSoftcuff)
end)

RegisterNetEvent('police:server:EscortPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = QBCore.Functions.GetPlayer(source)
    local escortPlayer = QBCore.Functions.GetPlayer(playerId)
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
    local Player = QBCore.Functions.GetPlayer(source)
    local escortPlayer = QBCore.Functions.GetPlayer(playerId)
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

    local escortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead then
        TriggerClientEvent("police:client:SetOutVehicle", escortPlayer.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local escortPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead then
        TriggerClientEvent("police:client:PutInVehicle", escortPlayer.PlayerData.source)
    else
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("error.not_cuffed_dead"), type = 'error'})
    end
end)

RegisterNetEvent('police:server:BillPlayer', function(playerId, price)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = QBCore.Functions.GetPlayer(src)
    local otherPlayer = QBCore.Functions.GetPlayer(playerId)
    if not player or not otherPlayer or player.PlayerData.job.type ~= "leo" then return end

    otherPlayer.Functions.RemoveMoney("bank", price, "paid-bills")
    exports['qbx-management']:AddMoney("police", price)
    TriggerClientEvent('ox_lib:notify', otherPlayer.PlayerData.source, {description = Lang:t("info.fine_received", {fine = price})})
end)

RegisterNetEvent('police:server:JailPlayer', function(playerId, time)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = QBCore.Functions.GetPlayer(src)
    local otherPlayer = QBCore.Functions.GetPlayer(playerId)
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
    local player = QBCore.Functions.GetPlayer(source)
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
    local players = QBCore.Functions.GetQBPlayers()
    for k, v in pairs(players) do
        if v and isLeoAndOnDuty(v) then
            local alertData = {title = Lang:t('info.new_call'), coords = coords, description = Lang:t('info.plate_triggered', {plate = plate, street = street, radar = radar})}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", k, alertData)
            TriggerClientEvent('police:client:policeAlert', k, coords, Lang:t('info.plate_triggered_blip', {radar = radar}))
        end
    end
end)

RegisterNetEvent('police:server:SearchPlayer', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local searchedPlayer = QBCore.Functions.GetPlayer(playerId)
    if not QBCore.Functions.GetPlayer(src) or not searchedPlayer then return end

    TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.searched_success")})
    TriggerClientEvent('ox_lib:notify', searchedPlayer.PlayerData.source, {description = Lang:t("info.being_searched")})
end)

RegisterNetEvent('police:server:SeizeCash', function(playerId)
    local src = source
    if isTargetTooFar(src, playerId, 2.5) then return end

    local player = QBCore.Functions.GetPlayer(src)
    local searchedPlayer = QBCore.Functions.GetPlayer(playerId)
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

    local player = QBCore.Functions.GetPlayer(src)
    local searchedPlayer = QBCore.Functions.GetPlayer(playerId)
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
    if not isVehicleOwned(plate) then return end
    if not fullImpound then
        MySQL.query('UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', {0, price, body, engine, fuel, plate})
        TriggerClientEvent('ox_lib:notify', src, {description = Lang:t("info.vehicle_taken_depot", {price = price})})
    else
        MySQL.query('UPDATE player_vehicles SET state = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', {2, body, engine, fuel, plate})
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
    local player = QBCore.Functions.GetPlayer(source)
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
    local player = QBCore.Functions.GetPlayer(src)
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
    local player = QBCore.Functions.GetPlayer(src)
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
    local players = QBCore.Functions.GetQBPlayers()
    if updatingCops then return end
    updatingCops = true
    for _, v in pairs(players) do
        if isLeoAndOnDuty(v) then
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
    local player = QBCore.Functions.GetPlayer(src)
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
    local player = QBCore.Functions.GetPlayer(source)
    local fid = player.PlayerData.metadata.fingerprint
    TriggerClientEvent('police:client:showFingerprintId', sessionId, fid)
    TriggerClientEvent('police:client:showFingerprintId', source, fid)
end)

RegisterNetEvent('police:server:SetTracker', function(targetId)
    local src = source
    if isTargetTooFar(src, targetId, 2.5) then return end

    local target = QBCore.Functions.GetPlayer(targetId)
    if not QBCore.Functions.GetPlayer(src) or not target then return end

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
    for k, v in pairs(QBCore.Shared.Jobs) do
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
    for i = 1, #Config.Locations.trash do
        exports.ox_inventory:ClearInventory(('policetrash_%s'):format(i))
    end
    while true do
        Wait(1000 * 60 * 10)
        local curCops = QBCore.Functions.GetDutyCountType('leo')
        TriggerClientEvent("police:SetCopCount", -1, curCops)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        updateBlips()
    end
end)
