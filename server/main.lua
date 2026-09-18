local sharedConfig = require 'config.shared'
local clientConfig = require 'config.client'
local playerStatus = {}
local casings = {}
local bloodDrops = {}
local fingerDrops = {}
local updatingCops = false
local vehiclesSpawning = {}
local lastPoliceAlert = {}
local pendingUnimpounds = {}
local fingerprintSessions = {}
local lastEvidenceDrop = {}
Plates = {}
IsUsingXTPrison = GetResourceState('xt-prison'):find('start')

---@param player Player
---@param minGrade? integer
---@return boolean?
function IsLeoAndOnDuty(player, minGrade)
    if not player then return false end
    local job = player.PlayerData.job
    if job and job.type == 'leo' and job.onduty then
        return job.grade.level >= (minGrade or 0)
    end
end

local function normalizePlate(plate)
    if type(plate) ~= 'string' or #plate > 16 then return end
    return plate:match('^%s*(.-)%s*$')
end

local function getNearbyVehicle(source, plate, maxDistance)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for _, vehicle in ipairs(GetAllVehicles()) do
        if #(playerCoords - GetEntityCoords(vehicle)) <= (maxDistance or 8.0)
            and normalizePlate(GetVehicleNumberPlateText(vehicle)) == plate
        then
            return vehicle
        end
    end
end

---@param value any
---@param min number
---@param max number
---@return boolean
local function isValidInteger(value, min, max)
    return math.type(value) == 'integer' and value >= min and value <= max
end

---@param target Player
---@return boolean
local function isRestrained(target)
    local metadata = target.PlayerData.metadata
    return metadata.ishandcuffed or metadata.isdead or metadata.inlaststand
end

local function isTargetTooFar(src, targetSrc, maxDistance)
    if math.type(targetSrc) ~= 'integer' or targetSrc == src
        or not exports.qbx_core:GetPlayer(src) or not exports.qbx_core:GetPlayer(targetSrc)
    then
        return true
    end
    maxDistance = maxDistance or 2.5
    return #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetSrc))) > maxDistance
end

-- Functions
local function updateBlips()
    local dutyPlayers = {}
    local players = exports.qbx_core:GetQBPlayers()
    for _, player in pairs(players) do
        local playerData = player.PlayerData
        local job = playerData.job
        if (job.type == 'leo' or job.type == 'ems') and job.onduty then
            local source = playerData.source
            local ped = GetPlayerPed(source)
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            dutyPlayers[#dutyPlayers + 1] = {
                job = job.name,
                source = source,
                label = playerData.metadata.callsign,
                location = vec4(coords.x, coords.y, coords.z, heading)
            }
        end
    end

    TriggerClientEvent('police:client:UpdateBlips', -1, dutyPlayers)
end

local function generateId(table)
    local id = lib.string.random('11111')
    if not table then return id end
    while table[id] do
        id = lib.string.random('11111')
    end
    return id
end

RegisterNetEvent('police:server:SendTrackerLocation', function(coords, requestId)
    local target = exports.qbx_core:GetPlayer(source)
    local msg = locale('info.target_location', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)
    local alertData = {
        title = locale('info.anklet_location'),
        coords = coords,
        description = msg
    }
    TriggerClientEvent('police:client:TrackerMessage', requestId, msg, coords)
    TriggerClientEvent('qb-phone:client:addPoliceAlert', requestId, alertData)
end)

-- Items
exports.qbx_core:CreateUseableItem('handcuffs', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player.Functions.GetItemByName('handcuffs') then return end
    TriggerClientEvent('police:client:CuffPlayerSoft', source)
end)

exports.qbx_core:CreateUseableItem('moneybag', function(source, item)
    if not item.info or item.info == '' then return end
    local player = exports.qbx_core:GetPlayer(source)
    if not player
        or player.PlayerData.job.type == 'leo'
        or not player.Functions.GetItemByName('moneybag')
        or type(item.info.cash) ~= 'number' or item.info.cash ~= item.info.cash or item.info.cash <= 0 or item.info.cash > 1000000000
        or not player.Functions.RemoveItem('moneybag', 1, item.slot)
    then
        return
    end
    player.Functions.AddMoney('cash', tonumber(item.info.cash), 'used-moneybag')
end)

-- Callbacks
lib.callback.register('police:server:isPlayerDead', function(source, playerId)
    if isTargetTooFar(source, playerId) then return false end
    local player = exports.qbx_core:GetPlayer(playerId)
    return player and player.PlayerData.metadata.isdead or false
end)

lib.callback.register('police:GetPlayerStatus', function(source, targetSrc)
    if isTargetTooFar(source, targetSrc) then return {} end
    local requester = exports.qbx_core:GetPlayer(source)
    if not IsLeoAndOnDuty(requester) then return {} end
    local player = exports.qbx_core:GetPlayer(targetSrc)
    if not player or not next(playerStatus[targetSrc]) then return {} end
    local status = playerStatus[targetSrc]

    local statList = {}
    for _, statusData in pairs(status) do
        statList[#statList + 1] = statusData.text
    end

    return statList
end)

lib.callback.register('police:GetImpoundedVehicles', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not IsLeoAndOnDuty(player) then return end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local nearImpound = false
    for i = 1, #sharedConfig.locations.impound do
        if #(coords - sharedConfig.locations.impound[i]) <= 10.0 then nearImpound = true break end
    end
    if not nearImpound then return end
    return FetchImpoundedVehicles()
end)

lib.callback.register('qbx_policejob:server:spawnVehicle', function(source, model, coords, plate, giveKeys, vehId)
    local player = exports.qbx_core:GetPlayer(source)
    if not IsLeoAndOnDuty(player) or vehiclesSpawning[source] or type(model) ~= 'string' or type(coords) ~= 'vector4' or type(plate) ~= 'string' or #plate > 16 then return end

    local gradeVehicles = clientConfig.authorizedVehicles[player.PlayerData.job.grade.level] or {}
    local allowedModel = gradeVehicles[model] or clientConfig.whitelistedVehicles[model] or model == clientConfig.policeHelicopter
    local validSpawn
    for _, locationList in ipairs({sharedConfig.locations.vehicle, sharedConfig.locations.helicopter}) do
        for i = 1, #locationList do
            if #(coords.xyz - locationList[i].xyz) <= 3.0 then validSpawn = locationList[i] break end
        end
        if validSpawn then break end
    end

    local impoundedVehicle
    local impoundGarage
    if not validSpawn then
        for i = 1, #sharedConfig.locations.impound do
            if #(coords.xyz - sharedConfig.locations.impound[i]) <= 3.0 then
                impoundedVehicle = MySQL.single.await('SELECT id, vehicle FROM player_vehicles WHERE plate = ? AND state = 2', {plate})
                if impoundedVehicle and impoundedVehicle.vehicle == model then
                    validSpawn = vec4(sharedConfig.locations.impound[i].xyz, coords.w)
                    impoundGarage = i
                end
                break
            end
        end
    end

    if not validSpawn or (not allowedModel and not impoundedVehicle) or #(GetEntityCoords(GetPlayerPed(source)) - validSpawn.xyz) > 10.0 then return end
    if not impoundedVehicle then
        local pattern = ('1'):rep(8 - #sharedConfig.policePlatePrefix)
        plate = sharedConfig.policePlatePrefix .. lib.string.random(pattern):upper()
    end
    vehiclesSpawning[source] = true
    local netId, veh = qbx.spawnVehicle({
        model = model,
        spawnSource = validSpawn,
        warp = GetPlayerPed(source)
    })
    vehiclesSpawning[source] = nil

    if not netId or netId == 0 or not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, plate)
    if giveKeys == true then exports.qbx_vehiclekeys:GiveKeys(source, veh) end

    local vehicleId = impoundedVehicle?.id or vehId
    if vehicleId then Entity(veh).state.vehicleid = vehicleId end
    if impoundedVehicle then
        pendingUnimpounds[source] = { plate = plate, garage = impoundGarage, expires = os.time() + 30 }
    end
    return netId
end)

local function isPlateFlagged(plate)
    return Plates and Plates[plate] and Plates[plate].isflagged
end


lib.callback.register('police:server:isPlateFlagged', function(_, plate)
    return isPlateFlagged(plate)
end)

local function isPoliceForcePresent()
    local players = exports.qbx_core:GetQBPlayers()
    for i = 1, #players do
        local job = players[i].PlayerData.job
        if job.type == 'leo' and job.grade.level >= 2 then
            return true
        end
    end
end

lib.callback.register('qbx_police:server:isPoliceForcePresent', isPoliceForcePresent)

if GetConvar('qbx:enablebridge', 'true') == 'true' then
    local QBCore = exports['qb-core']:GetCoreObject()
    ---@deprecated use police:server:isPlateFlagged
    QBCore.Functions.CreateCallback('police:IsPlateFlagged', function(_, cb, plate)
        lib.print.warn(GetInvokingResource(),
            'invoked deprecated callback police:IsPlateFlagged. Use police:server:isPlateFlagged instead.')
        cb(isPlateFlagged(plate))
    end)

    ---@deprecated
    QBCore.Functions.CreateCallback('police:server:IsPoliceForcePresent', function(_, cb)
        lib.print.warn(GetInvokingResource(),
            'invoked deprecated callback police:server:IsPoliceForcePresent. Use lib callback qbx_police:server:isPoliceForcePresent instead')
        cb(isPoliceForcePresent())
    end)
end

-- Events
RegisterNetEvent('police:server:Radar', function(fine)
    local src    = source
    local fineData = isValidInteger(fine, 1, #sharedConfig.radars.speedFines) and sharedConfig.radars.speedFines[fine]
    if not fineData then return end
    local price  = fineData.fine
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if not player.Functions.RemoveMoney('bank', math.floor(price), 'Radar Fine') then return end
    exports['Renewed-Banking']:addAccountMoney('police', price)
    exports.qbx_core:Notify(src, locale('info.fine_received', price), 'inform')
end)

RegisterNetEvent('police:server:policeAlert', function(text, camId, playerSource)
    if type(text) ~= 'string' or #text < 1 or #text > 200 then return end
    if source > 0 then
        playerSource = source
        local now = os.time()
        if lastPoliceAlert[source] and now - lastPoliceAlert[source] < 5 then return end
        lastPoliceAlert[source] = now
    elseif math.type(playerSource) ~= 'integer' then
        return
    end
    if not exports.qbx_core:GetPlayer(playerSource) then return end
    local ped = GetPlayerPed(playerSource)
    local coords = GetEntityCoords(ped)
    local players = exports.qbx_core:GetQBPlayers()
    for k, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            if camId then
                local alertData = {
                    title = locale('info.new_call'),
                    coords = coords,
                    description = text ..
                        locale('info.camera_id') .. camId
                }
                TriggerClientEvent('qb-phone:client:addPoliceAlert', k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text, camId)
            else
                local alertData = { title = locale('info.new_call'), coords = coords, description = text }
                TriggerClientEvent('qb-phone:client:addPoliceAlert', k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text)
            end
        end
    end
end)

RegisterNetEvent('police:server:TakeOutImpound', function(plate, garage)
    local src = tonumber(source)
    local player = src and exports.qbx_core:GetPlayer(src)
    if not src or not IsLeoAndOnDuty(player) or math.type(garage) ~= 'integer' or not sharedConfig.locations.impound[garage] or type(plate) ~= 'string' then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - sharedConfig.locations.impound[garage]) > 10.0 then return end
    local pending = pendingUnimpounds[src]
    if not pending or pending.plate ~= plate or pending.garage ~= garage or pending.expires < os.time() then return end
    pendingUnimpounds[src] = nil

    Unimpound(plate)
    exports.qbx_core:Notify(src, locale('success.impound_vehicle_removed'), 'success')
end)

lib.callback.register('police:server:CuffPlayer', function(src, cuffedSrc, isSoftcuff)
    if isTargetTooFar(src, cuffedSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cuffedPlayer = exports.qbx_core:GetPlayer(cuffedSrc)
    if not cuffedPlayer or not player.Functions.GetItemByName('handcuffs') then return end

    TriggerClientEvent('police:client:GetCuffed', cuffedPlayer.PlayerData.source, player.PlayerData.source, isSoftcuff)

    return true
end)

RegisterNetEvent('police:server:EscortPlayer', function(escortSrc)
    local src = source
    if isTargetTooFar(src, escortSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local escortPlayer = exports.qbx_core:GetPlayer(escortSrc)
    if not escortPlayer then return end

    if (player.PlayerData.job.type == 'leo' or player.PlayerData.job.type == 'ems') or (escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand) then
        TriggerClientEvent('police:client:GetEscorted', escortPlayer.PlayerData.source, player.PlayerData.source)
    else
        exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end
end)

RegisterNetEvent('police:server:KidnapPlayer', function(kidnapedSrc)
    local src = source
    if isTargetTooFar(src, kidnapedSrc) then return end
    local player = exports.qbx_core:GetPlayer(source)
    local escortPlayer = exports.qbx_core:GetPlayer(kidnapedSrc)
    if not player or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand then
        TriggerClientEvent('police:client:GetKidnappedTarget', escortPlayer.PlayerData.source, player.PlayerData.source)
        TriggerClientEvent('police:client:GetKidnappedDragger', player.PlayerData.source, escortPlayer.PlayerData.source)
    else
        exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end
end)

RegisterNetEvent('police:server:SetPlayerOutVehicle', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local escortPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not escortPlayer then return end
    local metadata = escortPlayer.PlayerData.metadata
    if not (metadata.ishandcuffed or metadata.isdead or metadata.inlaststand) then
        return exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end

    TriggerClientEvent('police:client:SetOutVehicle', escortPlayer.PlayerData.source)
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local escortPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not escortPlayer then return end
    local metadata = escortPlayer.PlayerData.metadata

    if not (metadata.ishandcuffed or metadata.isdead or metadata.inlaststand) then
        return exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end

    TriggerClientEvent('police:client:PutInVehicle', escortPlayer.PlayerData.source)
end)

RegisterNetEvent('police:server:BillPlayer', function(targetSrc, price)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not IsLeoAndOnDuty(player) or not isValidInteger(price, 1, 100000) then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    if not targetPlayer.Functions.RemoveMoney('bank', price, 'paid-bills') then return end
    exports['Renewed-Banking']:addAccountMoney('police', price)
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.fine_received', price), 'inform')
end)

if not IsUsingXTPrison then
    RegisterNetEvent('police:server:JailPlayer', function(targetSrc, time)
        local src = source
        if isTargetTooFar(src, targetSrc) then return end

        local player = exports.qbx_core:GetPlayer(src)
        if not IsLeoAndOnDuty(player) or not isValidInteger(time, 1, 10000) then return end
        local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
        if not targetPlayer then return end

        local currentDate = os.date('*t')
        if currentDate.day == 31 then
            currentDate.day = 30
        end

        targetPlayer.Functions.SetMetaData('injail', time)
        targetPlayer.Functions.SetMetaData('criminalrecord', {
            hasRecord = true,
            date = currentDate
        })
        if GetResourceState('qbx_prison') == 'started' then
            exports.qbx_prison:JailPlayer(targetPlayer.PlayerData.source, time)
        else
            TriggerClientEvent('police:client:SendToJail', targetPlayer.PlayerData.source, time)
        end
        exports.qbx_core:Notify(src, locale('info.sent_jail_for', time), 'inform')
    end)
end

RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(isHandcuffed) ~= 'boolean' then return end
    player.Functions.SetMetaData('ishandcuffed', isHandcuffed)
    Player(source).state.invBusy = isHandcuffed
end)

RegisterNetEvent('heli:spotlight', function(state)
    TriggerClientEvent('heli:spotlight', -1, source, state)
end)

RegisterNetEvent('police:server:FlaggedPlateTriggered', function(radar, plate, street)
    local src = tonumber(source)
    if not src then return end
    local coords = GetEntityCoords(GetPlayerPed(src))
    local players = exports.qbx_core:GetQBPlayers()
    for i = 1, #players do
        if IsLeoAndOnDuty(players[i]) then
            local alertData = {
                title = locale('info.new_call'),
                coords = coords,
                description = locale(
                    'info.plate_triggered', plate, street, radar)
            }
            TriggerClientEvent('qb-phone:client:addPoliceAlert', i, alertData)
            TriggerClientEvent('police:client:policeAlert', i, coords, locale('info.plate_triggered_blip', radar))
        end
    end
end)

RegisterNetEvent('police:server:SearchPlayer', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    local player = exports.qbx_core:GetPlayer(src)
    if not targetPlayer or not IsLeoAndOnDuty(player) then return end

    exports.qbx_core:Notify(src, locale('info.searched_success'), 'inform')
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.being_searched'), 'inform')
end)

RegisterNetEvent('police:server:SeizeCash', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not IsLeoAndOnDuty(player) then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer or not isRestrained(targetPlayer) then return end

    local moneyAmount = targetPlayer.PlayerData.money.cash
    if moneyAmount <= 0 or not exports.ox_inventory:CanCarryItem(src, 'moneybag', 1) then return end
    if not targetPlayer.Functions.RemoveMoney('cash', moneyAmount, 'police-cash-seized') then return end
    if not player.Functions.AddItem('moneybag', 1, false, { cash = moneyAmount }) then
        targetPlayer.Functions.AddMoney('cash', moneyAmount, 'police-cash-seizure-refund')
        return
    end
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.cash_confiscated'), 'inform')
end)

RegisterNetEvent('police:server:RobPlayer', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not player or not targetPlayer then return end
    if not isRestrained(targetPlayer) then return end

    local money = targetPlayer.PlayerData.money.cash
    if targetPlayer.Functions.RemoveMoney('cash', money, 'police-player-robbed') then
        player.Functions.AddMoney('cash', money, 'police-player-robbed')
    end

    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.cash_robbed', money), 'inform')
    exports.qbx_core:Notify(player.PlayerData.source, locale('info.stolen_money', money), 'inform')
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    price = price or 0
    local player = exports.qbx_core:GetPlayer(src)
    plate = normalizePlate(plate)
    if not IsLeoAndOnDuty(player) or not plate or type(fullImpound) ~= 'boolean'
        or not isValidInteger(price, 0, 1000000)
        or type(body) ~= 'number' or body ~= body or body < 0 or body > 1000
        or type(engine) ~= 'number' or engine ~= engine or engine < 0 or engine > 1000
        or type(fuel) ~= 'number' or fuel ~= fuel or fuel < 0 or fuel > 100
        or not IsVehicleOwned(plate)
    then
        return
    end
    if not getNearbyVehicle(src, plate, 8.0) then return end
    if not fullImpound then
        ImpoundWithPrice(price, body, engine, fuel, plate)
        exports.qbx_core:Notify(src, locale('info.vehicle_taken_depot', price), 'inform')
    else
        ImpoundForever(body, engine, fuel, plate)
        exports.qbx_core:Notify(src, locale('info.vehicle_seized'), 'inform')
    end
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    if type(data) ~= 'table' then return end
    local sanitized = {}
    local count = 0
    for key, status in pairs(data) do
        if count >= 16 then break end
        if type(key) == 'string' and #key <= 32 and type(status) == 'table'
            and type(status.text) == 'string' and #status.text <= 100
            and isValidInteger(status.time, 0, 3600)
        then
            sanitized[key] = { text = status.text, time = status.time }
            count += 1
        end
    end
    playerStatus[source] = sanitized
end)

RegisterNetEvent('evidence:server:CreateBloodDrop', function(_, _, coords)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(coords) ~= 'vector3' or #(GetEntityCoords(GetPlayerPed(source)) - coords) > 5.0 then return end
    local now = GetGameTimer()
    if lastEvidenceDrop[source] and now - lastEvidenceDrop[source] < 1000 then return end
    lastEvidenceDrop[source] = now
    local citizenid = player.PlayerData.citizenid
    local bloodtype = player.PlayerData.metadata.bloodtype
    local bloodId = generateId(bloodDrops)
    bloodDrops[bloodId] = {
        dna = citizenid,
        bloodtype = bloodtype,
        coords = coords
    }
    TriggerClientEvent('evidence:client:AddBlooddrop', -1, bloodId, citizenid, bloodtype, coords)
end)

RegisterNetEvent('evidence:server:CreateFingerDrop', function(coords)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(coords) ~= 'vector3' or #(GetEntityCoords(GetPlayerPed(source)) - coords) > 5.0 then return end
    local now = GetGameTimer()
    if lastEvidenceDrop[source] and now - lastEvidenceDrop[source] < 1000 then return end
    lastEvidenceDrop[source] = now
    local fingerId = generateId(fingerDrops)
    fingerDrops[fingerId] = { fingerprint = player.PlayerData.metadata.fingerprint, coords = coords }
    TriggerClientEvent('evidence:client:AddFingerPrint', -1, fingerId, player.PlayerData.metadata.fingerprint, coords)
end)

RegisterNetEvent('evidence:server:ClearBlooddrops', function(bloodDropList)
    local player = exports.qbx_core:GetPlayer(source)
    if not IsLeoAndOnDuty(player) or type(bloodDropList) ~= 'table' or not next(bloodDropList) then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for _, v in pairs(bloodDropList) do
        local evidence = bloodDrops[v]
        if evidence and #(playerCoords - evidence.coords) <= 10.0 then
            TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, v)
            bloodDrops[v] = nil
        end
    end
end)

local function dnaHash(value)
    return value:gsub('.', function(character)
        return ('%02x'):format(character:byte())
    end)
end

local function sanitizeEvidenceLabel(value)
    if type(value) ~= 'string' then return 'Unknown' end
    return value:gsub('[\r\n]', ' '):sub(1, 100)
end

RegisterNetEvent('evidence:server:AddBlooddropToInventory', function(bloodId, bloodInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local evidence = bloodDrops[bloodId]
    if not IsLeoAndOnDuty(player) or not evidence or type(bloodInfo) ~= 'table'
        or #(GetEntityCoords(GetPlayerPed(src)) - evidence.coords) > 2.0
    then
        return
    end
    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local streetName = sanitizeEvidenceLabel(bloodInfo.street)
    local bloodType = sanitizeEvidenceLabel(evidence.bloodtype)
    local bloodDNA = dnaHash(evidence.dna)
    local metadata = {}
    metadata.type = 'Blood Evidence'
    metadata.description = 'DNA ID: ' .. bloodDNA
    metadata.description = metadata.description .. '\n\nBlood Type: ' .. bloodType
    metadata.description = metadata.description .. '\n\nCollected By: ' .. playerName
    metadata.description = metadata.description .. '\n\nCollected At: ' .. streetName
    if not exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then return end
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, bloodId)
        bloodDrops[bloodId] = nil
    end
end)

RegisterNetEvent('evidence:server:AddFingerprintToInventory', function(fingerId, fingerInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local evidence = fingerDrops[fingerId]
    if not IsLeoAndOnDuty(player) or not evidence or type(fingerInfo) ~= 'table'
        or #(GetEntityCoords(GetPlayerPed(src)) - evidence.coords) > 2.0
    then
        return
    end
    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local streetName = sanitizeEvidenceLabel(fingerInfo.street)
    local fingerprint = sanitizeEvidenceLabel(evidence.fingerprint)
    local metadata = {}
    metadata.type = 'Fingerprint Evidence'
    metadata.description = 'Fingerprint ID: ' .. fingerprint
    metadata.description = metadata.description .. '\n\nCollected By: ' .. playerName
    metadata.description = metadata.description .. '\n\nCollected At: ' .. streetName
    if not exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then return end
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveFingerprint', -1, fingerId)
        fingerDrops[fingerId] = nil
    end
end)

RegisterNetEvent('evidence:server:CreateCasing', function(weapon, serial, coords)
    if type(weapon) ~= 'number' or type(coords) ~= 'vector3' or #(GetEntityCoords(GetPlayerPed(source)) - coords) > 5.0 then return end
    local currentWeapon = exports.ox_inventory:GetCurrentWeapon(source)
    if not currentWeapon then return end
    local now = GetGameTimer()
    if lastEvidenceDrop[source] and now - lastEvidenceDrop[source] < 200 then return end
    lastEvidenceDrop[source] = now
    local casingId = generateId(casings)
    local serieNumber = currentWeapon.metadata?.serial or sanitizeEvidenceLabel(serial)
    casings[casingId] = { weapon = weapon, serial = serieNumber, coords = coords }
    TriggerClientEvent('evidence:client:AddCasing', -1, casingId, weapon, coords, serieNumber)
end)

RegisterNetEvent('police:server:UpdateCurrentCops', function()
    local amount = 0
    local players = exports.qbx_core:GetQBPlayers()
    if updatingCops then return end
    updatingCops = true
    for i = 1, #players do
        if IsLeoAndOnDuty(players[i]) then
            amount += 1
        end
    end
    TriggerClientEvent('police:SetCopCount', -1, amount)
    updatingCops = false
end)

RegisterNetEvent('evidence:server:ClearCasings', function(casingList)
    local player = exports.qbx_core:GetPlayer(source)
    if IsLeoAndOnDuty(player) and type(casingList) == 'table' and next(casingList) then
        local playerCoords = GetEntityCoords(GetPlayerPed(source))
        for _, v in pairs(casingList) do
            local evidence = casings[v]
            if evidence and #(playerCoords - evidence.coords) <= 10.0 then
                TriggerClientEvent('evidence:client:RemoveCasing', -1, v)
                casings[v] = nil
            end
        end
    end
end)

RegisterNetEvent('evidence:server:AddCasingToInventory', function(casingId, casingInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local evidence = casings[casingId]
    if not IsLeoAndOnDuty(player) or not evidence or type(casingInfo) ~= 'table'
        or #(GetEntityCoords(GetPlayerPed(src)) - evidence.coords) > 2.0
    then
        return
    end
    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local streetName = sanitizeEvidenceLabel(casingInfo.street)
    local ammoType = sanitizeEvidenceLabel(casingInfo.ammolabel or tostring(evidence.weapon))
    local serialNumber = sanitizeEvidenceLabel(evidence.serial)
    local metadata = {}
    metadata.type = 'Casing Evidence'
    metadata.description = 'Ammo Type: ' .. ammoType
    metadata.description = metadata.description .. '\n\nSerial #: ' .. serialNumber
    metadata.description = metadata.description .. '\n\nCollected By: ' .. playerName
    metadata.description = metadata.description .. '\n\nCollected At: ' .. streetName
    if not exports.ox_inventory:CanCarryItem(src, 'filled_evidence_bag', 1) then return end
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveCasing', -1, casingId)
        casings[casingId] = nil
    end
end)

RegisterNetEvent('police:server:showFingerprint', function(playerId)
    if isTargetTooFar(source, playerId) or not IsLeoAndOnDuty(exports.qbx_core:GetPlayer(source)) then return end
    local nearScanner = false
    local coords = GetEntityCoords(GetPlayerPed(source))
    for i = 1, #sharedConfig.locations.fingerprint do
        if #(coords - sharedConfig.locations.fingerprint[i]) <= 3.0 then nearScanner = true break end
    end
    if not nearScanner then return end
    fingerprintSessions[source] = playerId
    fingerprintSessions[playerId] = source
    TriggerClientEvent('police:client:showFingerprint', playerId, source)
    TriggerClientEvent('police:client:showFingerprint', source, playerId)
end)

RegisterNetEvent('police:server:showFingerprintId', function(sessionId)
    if math.type(sessionId) ~= 'integer' or fingerprintSessions[source] ~= sessionId or isTargetTooFar(source, sessionId) then return end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local fid = player.PlayerData.metadata.fingerprint
    TriggerClientEvent('police:client:showFingerprintId', sessionId, fid)
    TriggerClientEvent('police:client:showFingerprintId', source, fid)
end)

RegisterNetEvent('police:server:SetTracker', function(targetId)
    local src = source
    if isTargetTooFar(src, targetId) then return end

    local target = exports.qbx_core:GetPlayer(targetId)
    if not IsLeoAndOnDuty(exports.qbx_core:GetPlayer(src)) or not target then return end

    local trackerMeta = target.PlayerData.metadata.tracker
    if trackerMeta then
        target.Functions.SetMetaData('tracker', false)
        exports.qbx_core:Notify(targetId, locale('success.anklet_taken_off'), 'success')
        exports.qbx_core:Notify(src,
            locale('success.took_anklet_from', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname),
            'success')
        TriggerClientEvent('police:client:SetTracker', targetId, false)
    else
        target.Functions.SetMetaData('tracker', true)
        exports.qbx_core:Notify(targetId, locale('success.put_anklet'), 'success')
        exports.qbx_core:Notify(src,
            locale('success.put_anklet_on', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname),
            'success')
        TriggerClientEvent('police:client:SetTracker', targetId, true)
    end
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= 'ox_inventory' then return end

    local jobs = {}
    for k, v in pairs(exports.qbx_core:GetJobs()) do
        if v.type == 'leo' then
            jobs[k] = 0
        end
    end

    for i = 1, #sharedConfig.locations.trash do
        exports.ox_inventory:RegisterStash(('policetrash_%s'):format(i), 'Police Trash', 300, 4000000, nil, jobs,
            sharedConfig.locations.trash[i])
    end
    exports.ox_inventory:RegisterStash('policelocker', 'Police Locker', 30, 100000, true)
end)

AddEventHandler('playerDropped', function()
    playerStatus[source] = nil
    vehiclesSpawning[source] = nil
    lastPoliceAlert[source] = nil
    pendingUnimpounds[source] = nil
    lastEvidenceDrop[source] = nil
    local sessionId = fingerprintSessions[source]
    fingerprintSessions[source] = nil
    if sessionId then fingerprintSessions[sessionId] = nil end
end)

-- Threads
CreateThread(function()
    Wait(1000)
    for i = 1, #sharedConfig.locations.trash do
        exports.ox_inventory:ClearInventory(('policetrash_%s'):format(i))
    end
    while true do
        Wait(1000 * 60 * 10)
        local curCops = exports.qbx_core:GetDutyCountType('leo')
        TriggerClientEvent('police:SetCopCount', -1, curCops)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        updateBlips()
    end
end)
