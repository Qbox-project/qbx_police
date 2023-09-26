---if player is not leo or not on duty, notifies them
---@param player number|Player
---@param minGrade? integer
---@return boolean
local function checkLeoAndOnDuty(player, minGrade)
    if type(player) == "number" then
        player = QBX.Functions.GetPlayer(player)
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

lib.addCommand("spikestrip", {
    help = Lang:t("commands.place_spike"),
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:SpawnSpikeStrip', source)
end)

lib.addCommand("grantlicense", {
    help = Lang:t("commands.license_grant"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        },
        {
            name = "license",
            type = "string",
            help = Lang:t('info.license_type')
        }
    },
 }, function(source, args)
    if not checkLeoAndOnDuty(source, Config.LicenseRank) then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.error_rank_license"), type = 'error'})
        return
    end
    if args[2] ~= "driver" and args[2] ~= "weapon" then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.license_type"), type = 'error'})
        return
    end
    local searchedPlayer = QBX.Functions.GetPlayer(tonumber(args[1]))
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

lib.addCommand("revokelicense",{
    help = Lang:t("commands.license_revoke"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        },
        {
            name = "license",
            type = "string",
            help = Lang:t('info.license_type')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source, Config.LicenseRank) then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.rank_revoke"), type = "error"})
        return
    end
    if args[2] ~= "driver" and args[2] ~= "weapon" then
        TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.error_license"), type = "error"})
        return
    end
    local searchedPlayer = QBX.Functions.GetPlayer(tonumber(args[1]))
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

lib.addCommand("pobject", {
    help = Lang:t("commands.place_object"),
    params = {
        {
            name = "type",
            type = "string",
            help = Lang:t("info.poobject_object")
        }
    },
 }, function(source, args)
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

lib.addCommand("cuff", {
    help = Lang:t("commands.cuff_player")
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CuffPlayer", source)
end)

lib.addCommand("escort", {
    help = Lang:t("commands.escort")
}, function(source)
    TriggerClientEvent("police:client:EscortPlayer", source)
end)

lib.addCommand("callsign", {
    help = Lang:t("commands.callsign"),
    params = {
        {
            name = "name",
            type = "string",
            help = Lang:t('info.callsign_name')
        }
    },
 }, function(source, args)
    local player = QBX.Functions.GetPlayer(source)
    player.Functions.SetMetaData("callsign", table.concat(args, " "))
end)

lib.addCommand("clearcasings", {
    help = Lang:t("commands.clear_casign")
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("evidence:client:ClearCasingsInArea", source)
end)

lib.addCommand("jail", {
    help = Lang:t("commands.jail_player")
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:JailPlayer", source)
end)

lib.addCommand("unjail", {
    help = Lang:t("commands.unjail_player"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        }
    }
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("prison:client:UnjailPerson", tonumber(args[1]) --[[@as number]])
end)

lib.addCommand("clearblood", {
    help = Lang:t("commands.clearblood"),
 }, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("evidence:client:ClearBlooddropsInArea", source)
end)

lib.addCommand("seizecash", {
    help = Lang:t("commands.seizecash")
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:SeizeCash", source)
end)

lib.addCommand("sc", {
    help = Lang:t("commands.softcuff")
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CuffPlayerSoft", source)
end)

lib.addCommand("cam", {
    help = Lang:t("commands.camera"),
    params = {
        {
            name = "camid",
            type = "number",
            help = Lang:t('info.camera_id_help')
        }
    },
 }, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ActiveCamera", source, tonumber(args[1]))
end)

lib.addCommand("flagplate", {
    help = Lang:t("commands.flagplate"),
    params = {
        {
            name = "plate",
            type = "string",
            help = Lang:t('info.plate_number')
        },
        {
            name = "reason",
            type = "string",
            help = Lang:t('info.flag_reason'),
            optional = true
        }
    },
 }, function(source, args)
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

lib.addCommand("unflagplate", {
    help = Lang:t("commands.unflagplate"),
    params = {
        {
            name = "plate",
            type = "string",
            help = Lang:t('info.plate_number')
        }
    },
}, function(source, args)
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

lib.addCommand("plateinfo", {
    help = Lang:t("commands.plateinfo"),
    params = {
        {
            name = "plate",
            type = "string",
            help = Lang:t('info.plate_number')
        }
    },
}, function(source, args)
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

lib.addCommand("depot", {
    help = Lang:t("commands.depot"),
    params = {
        {
            name = "price",
            type = "number",
            help = Lang:t('info.impound_price')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ImpoundVehicle", source, false, tonumber(args[1]))
end)

lib.addCommand("impound", {
    help = Lang:t("commands.impound"),
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:ImpoundVehicle", source, true)
end)

lib.addCommand("paytow", {
    help = Lang:t("commands.paytow"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local playerId = tonumber(args[1])
    local OtherPlayer = QBX.Functions.GetPlayer(playerId)
    if not OtherPlayer then return end
    if OtherPlayer.PlayerData.job.name ~= "tow" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.not_towdriver"), type = 'error'})
    end

    OtherPlayer.Functions.AddMoney("bank", 500, "police-tow-paid")
    TriggerClientEvent('ox_lib:notify', OtherPlayer.PlayerData.source, {description = Lang:t("success.tow_paid"), type = 'success'})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.tow_driver_paid")})
end)

lib.addCommand("paylawyer", {
    help = Lang:t("commands.paylawyer"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        }
    },
 }, function(source, args)
    local Player = QBX.Functions.GetPlayer(source)
    if Player.PlayerData.job.type ~= "leo" and Player.PlayerData.job.name ~= "judge" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.on_duty_police_only"), type = 'error'})
    end

    local playerId = tonumber(args[1])
    local OtherPlayer = QBX.Functions.GetPlayer(playerId)
    if not OtherPlayer then return end
    if OtherPlayer.PlayerData.job.name ~= "lawyer" then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.not_lawyer"), type = "error"})
    end

    OtherPlayer.Functions.AddMoney("bank", 500, "police-lawyer-paid")
    TriggerClientEvent('ox_lib:notify', OtherPlayer.PlayerData.source, {description = Lang:t("success.tow_paid"), type = 'success'})
    TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("info.paid_lawyer")})
end)

lib.addCommand("anklet", {
    help = Lang:t("commands.anklet"),
}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent("police:client:CheckDistance", source)
end)

lib.addCommand("ankletlocation", {
    help = Lang:t("commands.ankletlocation"),
    params = {
        {
            name = "cid",
            type = "string",
            help = Lang:t('info.citizen_id')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local citizenid = args[1]
    local Target = QBX.Functions.GetPlayerByCitizenId(citizenid)
    if not Target then return end
    if not Target.PlayerData.metadata.tracker then
        return TriggerClientEvent('ox_lib:notify', source, {description = Lang:t("error.no_anklet"), type = 'error'})
    end
    TriggerClientEvent("police:client:SendTrackerLocation", Target.PlayerData.source, source)
end)

lib.addCommand("takedna", {
    help = Lang:t("commands.takedna"),
    params = {
        {
            name = "id",
            type = "playerId",
            help = Lang:t('info.player_id')
        }
    },
}, function(source, args)
    local player = QBX.Functions.GetPlayer(source)
    local OtherPlayer = QBX.Functions.GetPlayer(tonumber(args[1]))

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

lib.addCommand("911p", {
    help = Lang:t("commands.police_report"),
    params = {
        {
            name="message",
            type = "string",
            help= Lang:t("commands.message_sent")
        }
    },
}, function(source, args)
    local message
	if args[1] then message = table.concat(args, " ") else message = Lang:t("commands.civilian_call") end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local players = QBX.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            local alertData = {title = Lang:t("commands.emergency_call"), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent("qb-phone:client:addPoliceAlert", v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end)