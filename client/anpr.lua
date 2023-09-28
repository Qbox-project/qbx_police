if not Config.UseRadars then return end

local speedCams = {}

local function speedRange(speed)
	speed = math.ceil(speed)
	for k, v in pairs(Config.SpeedFines) do
		if speed < v.maxspeed then
			TriggerServerEvent('police:server:Radar', k)
			TriggerServerEvent("InteractSound_SV:PlayOnSource", 'speedcamera', 0.25)
			break
		end
	end
end

local function handleSpeedCam(speedCam, radar)
	if not cache.vehicle or cache.seat ~= -1 or GetVehicleClass(cache.vehicle) == 18 then return end
	local plate = GetPlate(cache.vehicle)
	local speed = GetEntitySpeed(cache.vehicle) * (Config.MPH and 2.236936 or 3.6)
	local overlimit = speed - speedCam.speed

	lib.callback('police:server:isPlateFlagged', false, function(result)
		if not result then return end
		local s1, s2 = GetStreetNameAtCoord(speedCam.coords.x, speedCam.coords.y, speedCam.coords.z)
		local street = GetStreetNameFromHashKey(s1)
		local street2 = GetStreetNameFromHashKey(s2)
		if street2 then
			street = street .. ' | ' .. street2
		end
		TriggerServerEvent("police:server:FlaggedPlateTriggered", radar, plate, street)
	end, plate)

	if not Config.SpeedFines or overlimit < 0 then return end
	speedRange(overlimit)
end

CreateThread(function()
	for _,value in pairs(Config.Radars) do
		speedCams[#speedCams+1] = lib.points.new({
			coords = value.coords.xyz,
			distance = 20.0,
			speed = value.speedlimit,
		})
	end
	for k, v in pairs(speedCams) do
		function v:onEnter()
			handleSpeedCam(self, k)
		end
	end
end)
