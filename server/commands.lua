---if player is not leo or not on duty, notifies them
---@param player number|Player
---@param minGrade? integer
---@return boolean
local function checkLeoAndOnDuty(player, minGrade)
    if type(player) == "number" then
        player = QBCore.Functions.GetPlayer(player)
    end
    if not IsLeoAndOnDuty(player, minGrade) then
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {description = Lang:t("error.on_duty_police_only"), type = 'error'})
        return false
    end
    return true
end

local function dnaHash(s)
    return string.gsub(s, ".", function(c)
        return string.format("%02x", string.byte(c))
    end)
end

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
    Plates[args[1]:upper()] = {
        isflagged = true,
        reason = table.concat(reason, " ")
    }
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.vehicle_flagged", {vehicle = args[1]:upper(), reason = table.concat(reason, " ")})})
end)

QBCore.Commands.Add("unflagplate", Lang:t("commands.unflagplate"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not Plates or not Plates[args[1]:upper()] then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end

    if not Plates[args[1]:upper()].isflagged then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end

    Plates[args[1]:upper()].isflagged = false
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.unflag_vehicle", {vehicle = args[1]:upper()})})
end)

QBCore.Commands.Add("plateinfo", Lang:t("commands.plateinfo"), {{name = "plate", help = Lang:t('info.plate_number')}}, true, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not Plates or Plates[args[1]:upper()] then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.vehicle_not_flag"), type = 'error'})
    end
    if Plates[args[1]:upper()].isflagged then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t('success.vehicle_flagged', {plate = args[1]:upper(), reason = Plates[args[1]:upper()].reason}), type = 'success'})
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

QBCore.Commands.Add('911p', Lang:t("commands.police_report"), {{name='message', help= Lang:t("commands.message_sent")}}, false, function(source, args)
    local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t("commands.civilian_call") end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            local alertData = {title = Lang:t("commands.emergency_call"), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end)