if not Config.UseRadars then return end

local SpeedCams = {}

local function SpeedRange(speed)
	speed = math.ceil(speed)
	for k, v in pairs(Config.SpeedFines) do
		if speed < v.maxspeed then
			TriggerServerEvent('police:server:Radar', k)
			TriggerServerEvent("InteractSound_SV:PlayOnSource", 'speedcamera', 0.25)
			break
		end
	end
end

local function HandlespeedCam(speedCam, radar)
	if not cache.vehicle or cache.seat ~= -1 or GetVehicleClass(cache.vehicle) == 18 then return end
	local plate = QBCore.Functions.GetPlate(cache.vehicle)
	local speed = GetEntitySpeed(cache.vehicle) * (Config.MPH and 2.236936 or 3.6)
	local OverLimit = speed - speedCam.speed

	QBCore.Functions.TriggerCallback('police:IsPlateFlagged', function(result)
 		if not result then return end
		local s1, s2 = GetStreetNameAtCoord(speedCam.coords.x, speedCam.coords.y, speedCam.coords.z)
		local street = GetStreetNameFromHashKey(s1)
		local street2 = GetStreetNameFromHashKey(s2)
		if street2 then
			street = street .. ' | ' .. street2
		end
		TriggerServerEvent("police:server:FlaggedPlateTriggered", radar, plate, street)
	end, plate)

	if not Config.SpeedFines or OverLimit < 0 then return end
	SpeedRange(OverLimit)
end


CreateThread(function()
	for _,value in pairs(Config.Radars) do
		SpeedCams[#SpeedCams+1] = lib.points.new({
			coords = value.coords.xyz,
			distance = 20.0,
			speed = value.speedlimit,
		})
	end
	for k, v in pairs(SpeedCams) do
		function v:onEnter()
			HandlespeedCam(self, k)
		end
	end
end)
