local lastRadar = nil
local HasAlreadyEnteredMarker = false

-- Determines if player is close enough to trigger cam
function HandlespeedCam(speedCam, hasBeenBusted)
    local playerPos = GetEntityCoords(cache.ped)
    local isInMarker  = false

    if #(playerPos - vec3(speedCam.x, speedCam.y, speedCam.z)) < 20.0 then
        isInMarker  = true
    end

    if isInMarker and not HasAlreadyEnteredMarker and not lastRadar then
        HasAlreadyEnteredMarker = true
        lastRadar = hasBeenBusted

        local vehicle = GetPlayersLastVehicle() -- gets the current vehicle the player is in.

        if cache.vehicle then
            if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
                if GetVehicleClass(vehicle) ~= 18 then
                    local plate = QBCore.Functions.GetPlate(vehicle)

                    QBCore.Functions.TriggerCallback('police:IsPlateFlagged', function(result)
                        if result then
                            local coords = GetEntityCoords(cache.ped)
                            local blipsettings = {
                                x = coords.x,
                                y = coords.y,
                                z = coords.z,
                                sprite = 488,
                                color = 1,
                                scale = 0.9,
                                text = "Speed camera #" .. hasBeenBusted .. " - Marked vehicle"
                            }
                            local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                            local street1 = GetStreetNameFromHashKey(s1)
                            local street2 = GetStreetNameFromHashKey(s2)

                            TriggerServerEvent("police:server:FlaggedPlateTriggered", hasBeenBusted, plate, street1, street2, blipsettings)
                        end
                    end, plate)
                end
            end
        end
    end

    if not isInMarker and HasAlreadyEnteredMarker and lastRadar == hasBeenBusted then
        HasAlreadyEnteredMarker = false
        lastRadar = nil
    end
end

CreateThread(function()
    while true do
        Wait(0)

        if cache.vehicle then
            for key, value in pairs(Config.Radars) do
                HandlespeedCam(value, key)
            end

            Wait(200)
        else
            Wait(2500)
        end
    end
end)