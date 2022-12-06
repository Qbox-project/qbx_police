local lastRadar = nil
local HasAlreadyEnteredMarker = false

-- Determines if player is close enough to trigger cam
local function HandleSpeedCam(speedCam, radar)
	local playerPos = GetEntityCoords(cache.ped)
	local isInMarker  = false
	if #(playerPos - speedCam.xyz) < 20.0 then
		isInMarker = true
	end

	if isInMarker and not HasAlreadyEnteredMarker and not lastRadar then
		HasAlreadyEnteredMarker = true
		lastRadar = radar

		if cache.vehicle and cache.seat == -1 and GetVehicleClass(cache.vehicle) ~= 18 then
			local plate = QBCore.Functions.GetPlate(cache.vehicle)
			QBCore.Functions.TriggerCallback('police:IsPlateFlagged', function(result)
				if not result then return end

				local s1, s2 = GetStreetNameAtCoord(playerPos.x, playerPos.y, playerPos.z)
				local street1 = GetStreetNameFromHashKey(s1)
				local street2 = GetStreetNameFromHashKey(s2)
				local street = street1
				if street2 then
					street = street .. ' | ' .. street2
				end
				TriggerServerEvent("police:server:FlaggedPlateTriggered", radar, plate, street)
			end, plate)
		end
	end

	if not isInMarker and HasAlreadyEnteredMarker and lastRadar == radar then
		HasAlreadyEnteredMarker = false
		lastRadar = nil
	end
end

CreateThread(function()
	local sleep
	while true do
		sleep = 1000
		if cache.vehicle then
			sleep = 200
			for key, value in pairs(Config.Radars) do
				HandleSpeedCam(value, key)
			end
		end
		Wait(sleep)
	end
end)
