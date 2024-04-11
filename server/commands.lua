local config = require 'config.server'
local sharedConfig = require 'config.shared'

---if player is not leo or not on duty, notifies them
---@param player number|Player
---@param minGrade? integer
---@return boolean
local function checkLeoAndOnDuty(player, minGrade)
    if type(player) == 'number' then
        player = exports.qbx_core:GetPlayer(player)
    end
    if not IsLeoAndOnDuty(player, minGrade) then
        exports.qbx_core:Notify(player.PlayerData.source, Lang:t('error.on_duty_police_only'), 'error')
        return false
    end
    return true
end

local function dnaHash(s)
    return string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
end

lib.addCommand('spikestrip', {help = Lang:t('commands.place_spike')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:SpawnSpikeStrip', source)
end)

lib.addCommand('grantlicense', {
    help = Lang:t('commands.license_grant'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        },
        {
            name = 'license',
            type = 'string',
            help = Lang:t('info.license_type')
        }
    },
 }, function(source, args)
    if not checkLeoAndOnDuty(source, config.licenseRank) then
        exports.qbx_core:Notify(source, Lang:t('error.error_rank_license'), 'error')
        return
    end
    if not config.validLicenses[args.license] then
        exports.qbx_core:Notify(source, Lang:t('info.license_type'), 'error')
        return
    end
    local searchedPlayer = exports.qbx_core:GetPlayer(args.id)
    if not searchedPlayer then return end
    local licenseTable = searchedPlayer.PlayerData.metadata.licences
    if licenseTable[args.license] then
        exports.qbx_core:Notify(source, Lang:t('error.license_already'), 'error')
        return
    end
    licenseTable[args.license] = true
    searchedPlayer.Functions.SetMetaData('licences', licenseTable)
    exports.qbx_core:Notify(searchedPlayer.PlayerData.source, Lang:t('success.granted_license'), 'success')
    exports.qbx_core:Notify(source, Lang:t('success.grant_license'), 'success')
end)

lib.addCommand('revokelicense',{
    help = Lang:t('commands.license_revoke'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        },
        {
            name = 'license',
            type = 'string',
            help = Lang:t('info.license_type')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source, config.licenseRank) then
        exports.qbx_core:Notify(source, Lang:t('error.rank_revoke'), 'error')
        return
    end
    if not config.validLicenses[args.license] then
        exports.qbx_core:Notify(source, Lang:t('error.error_license'), 'error')
        return
    end
    local searchedPlayer = exports.qbx_core:GetPlayer(args.id)
    if not searchedPlayer then return end
    local licenseTable = searchedPlayer.PlayerData.metadata.licences
    if not licenseTable[args.license] then
        exports.qbx_core:Notify(source, Lang:t('error.error_license'), 'error')
        return
    end
    licenseTable[args.license] = false
    searchedPlayer.Functions.SetMetaData('licences', licenseTable)
    exports.qbx_core:Notify(searchedPlayer.PlayerData.source, Lang:t('error.revoked_license'), 'error')
    exports.qbx_core:Notify(source, Lang:t('success.revoke_license'), 'success')
end)

lib.addCommand('pobject', {
    help = Lang:t('commands.place_object'),
    params = {
        {
            name = 'type',
            type = 'string',
            help = Lang:t('info.poobject_object')
        }
    },
 }, function(source, args)
    local type = args.type:lower()
    if not checkLeoAndOnDuty(source) then return end

    if type == 'delete' then
        TriggerClientEvent('police:client:deleteObject', source)
        return
    end

    if sharedConfig.objects[type] then
        TriggerClientEvent('police:client:spawnPObj', source, type)
    end
end)

lib.addCommand('cuff', {help = Lang:t('commands.cuff_player')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:CuffPlayer', source)
end)

lib.addCommand('escort', {help = Lang:t('commands.escort')}, function(source)
    TriggerClientEvent('police:client:EscortPlayer', source)
end)

lib.addCommand('callsign', {
    help = Lang:t('commands.callsign'),
    params = {
        {
            name = 'name',
            type = 'string',
            help = Lang:t('info.callsign_name')
        }
    },
 }, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)
    player.Functions.SetMetaData('callsign', table.concat(args, ' '))
end)

lib.addCommand('clearcasings', {help = Lang:t('commands.clear_casign')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('evidence:client:ClearCasingsInArea', source)
end)

lib.addCommand('jail', {help = Lang:t('commands.jail_player')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:JailPlayer', source)
end)

lib.addCommand('unjail', {
    help = Lang:t('commands.unjail_player'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        }
    }
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if GetResourceState('qbx_prison') == 'started' then
        exports.qbx_prison:ReleasePlayer(args.id)
    else
        TriggerClientEvent('prison:client:UnjailPerson', args.id)
    end
end)

lib.addCommand('clearblood', {help = Lang:t('commands.clearblood')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('evidence:client:ClearBlooddropsInArea', source)
end)

lib.addCommand('seizecash', {help = Lang:t('commands.seizecash')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:SeizeCash', source)
end)

lib.addCommand('sc', {help = Lang:t('commands.softcuff')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:CuffPlayerSoft', source)
end)

lib.addCommand('cam', {
    help = Lang:t('commands.camera'),
    params = {
        {
            name = 'camid',
            type = 'number',
            help = Lang:t('info.camera_id_help')
        }
    },
 }, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:ActiveCamera', source, args.camid)
end)

lib.addCommand('flagplate', {
    help = Lang:t('commands.flagplate'),
    params = {
        {
            name = 'plate',
            type = 'string',
            help = Lang:t('info.plate_number')
        },
        {
            name = 'reason',
            type = 'string',
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
        reason = table.concat(reason, ' ')
    }
    exports.qbx_core:Notify(source, Lang:t('info.vehicle_flagged', {vehicle = args[1]:upper(), reason = table.concat(reason, ' ')}), 'inform')
end)

lib.addCommand('unflagplate', {
    help = Lang:t('commands.unflagplate'),
    params = {
        {
            name = 'plate',
            type = 'string',
            help = Lang:t('info.plate_number')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not Plates or not Plates[args.plate:upper()] then
        return exports.qbx_core:Notify(source, Lang:t('error.vehicle_not_flag'), 'error')
    end

    if not Plates[args.plate:upper()].isflagged then
        return exports.qbx_core:Notify(source, Lang:t('error.vehicle_not_flag'), 'error')
    end

    Plates[args.plate:upper()].isflagged = false
    exports.qbx_core:Notify(source, Lang:t('info.unflag_vehicle', {vehicle = args.plate:upper()}), 'inform')
end)

lib.addCommand('plateinfo', {
    help = Lang:t('commands.plateinfo'),
    params = {
        {
            name = 'plate',
            type = 'string',
            help = Lang:t('info.plate_number')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    if not Plates or Plates[args.plate:upper()] then
        return exports.qbx_core:Notify(source, Lang:t('error.vehicle_not_flag'), 'error')
    end
    if Plates[args.plate:upper()].isflagged then
        exports.qbx_core:Notify(source, Lang:t('success.vehicle_flagged', {plate = args.plate:upper(), reason = Plates[args.plate:upper()].reason}), 'success')
    else
        exports.qbx_core:Notify(source, Lang:t('error.vehicle_not_flag'), 'error')
    end
end)

lib.addCommand('depot', {
    help = Lang:t('commands.depot'),
    params = {
        {
            name = 'price',
            type = 'number',
            help = Lang:t('info.impound_price')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:ImpoundVehicle', source, false, args.price)
end)

lib.addCommand('impound', {help = Lang:t('commands.impound')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:ImpoundVehicle', source, true)
end)

lib.addCommand('paytow', {
    help = Lang:t('commands.paytow'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local otherPlayer = exports.qbx_core:GetPlayer(args.id)
    if not otherPlayer then return end
    if not config.towJobs[otherPlayer.PlayerData.job.name] then
        return exports.qbx_core:Notify(source, Lang:t('error.not_towdriver'), 'error')
    end

    otherPlayer.Functions.AddMoney('bank', config.towPay, 'police-tow-paid')
    exports.qbx_core:Notify(otherPlayer.PlayerData.source, Lang:t('success.tow_paid'), 'success')
    exports.qbx_core:Notify(source, Lang:t('info.tow_driver_paid'), 'inform')
end)

lib.addCommand('paylawyer', {
    help = Lang:t('commands.paylawyer'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        }
    },
 }, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)
    if player.PlayerData.job.type ~= 'leo' and player.PlayerData.job.name ~= 'judge' then
        return exports.qbx_core:Notify(source, Lang:t('error.on_duty_police_only'), 'error')
    end

    local otherPlayer = exports.qbx_core:GetPlayer(args.id)
    if not otherPlayer then return end
    if not config.lawyerJobs[otherPlayer.PlayerData.job.name] then
        return exports.qbx_core:Notify(source, Lang:t('error.not_lawyer'), 'error')
    end

    otherPlayer.Functions.AddMoney('bank', config.lawyerPay, 'police-lawyer-paid')
    exports.qbx_core:Notify(otherPlayer.PlayerData.source, Lang:t('success.tow_paid'), 'success')
    exports.qbx_core:Notify(source, Lang:t('info.paid_lawyer'), 'inform')
end)

lib.addCommand('anklet', {help = Lang:t('commands.anklet')}, function(source)
    if not checkLeoAndOnDuty(source) then return end
    TriggerClientEvent('police:client:CheckDistance', source)
end)

lib.addCommand('ankletlocation', {
    help = Lang:t('commands.ankletlocation'),
    params = {
        {
            name = 'cid',
            type = 'string',
            help = Lang:t('info.citizen_id')
        }
    },
}, function(source, args)
    if not checkLeoAndOnDuty(source) then return end
    local target = exports.qbx_core:GetPlayerByCitizenId(args.cid)
    if not target then return end
    if not target.PlayerData.metadata.tracker then
        return exports.qbx_core:Notify(source, Lang:t('error.no_anklet'), 'error')
    end
    TriggerClientEvent('police:client:SendTrackerLocation', target.PlayerData.source, source)
end)

lib.addCommand('takedna', {
    help = Lang:t('commands.takedna'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = Lang:t('info.player_id')
        }
    },
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)
    local otherPlayer = exports.qbx_core:GetPlayer(args.id)

    if not checkLeoAndOnDuty(player) then return end
    if not player.Functions.RemoveItem('empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(source, Lang:t('error.have_evidence_bag'), 'error')
    end

    local info = {
        label = Lang:t('info.dna_sample'),
        type = 'dna',
        dnalabel = dnaHash(otherPlayer.PlayerData.citizenId),
        description = dnaHash(otherPlayer.PlayerData.citizenId)
    }
    if not player.Functions.AddItem('filled_evidence_bag', 1, false, info) then return end
end)

lib.addCommand('911p', {
    help = Lang:t('commands.police_report'),
    params = {
        {
            name = 'message',
            type = 'string',
            help = Lang:t('commands.message_sent')
        }
    },
}, function(source, args)
    local message
	if args.message then message = table.concat(args, ' ') else message = Lang:t('commands.civilian_call') end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local players = exports.qbx_core:GetQBPlayers()
    for _, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            local alertData = {title = Lang:t('commands.emergency_call'), coords = {x = coords.x, y = coords.y, z = coords.z}, description = message}
            TriggerClientEvent('qb-phone:client:addPoliceAlert', v.PlayerData.source, alertData)
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end)
