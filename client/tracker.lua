RegisterNetEvent('police:client:CheckDistance', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:SetTracker", playerId)
    else
        lib.notify({description = Lang:t("error.none_nearby"), type = "error"})
    end
end)

RegisterNetEvent('police:client:SetTracker', function(bool)
    local trackerClothingData = {
        outfitData = {
            accessory = { item = -1, texture = 0 },  -- Neck / Tie
        }
    }

    if bool then
        trackerClothingData.outfitData = {
            accessory = { item = 13, texture = 0 }
        }

        TriggerEvent('qb-clothing:client:loadOutfit', trackerClothingData)
    else
        TriggerEvent('qb-clothing:client:loadOutfit', trackerClothingData)
    end
end)

RegisterNetEvent('police:client:SendTrackerLocation', function(requestId)
    TriggerServerEvent('police:server:SendTrackerLocation', GetEntityCoords(cache.ped), requestId)
end)

RegisterNetEvent('police:client:TrackerMessage', function(msg, coords)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", false, 0, true)
    lib.notify({ description = msg, type = 'inform' })
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 458)
    SetBlipColour(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipAlpha(blip, transG)
    SetBlipScale(blip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Lang:t('info.ankle_location'))
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG -= 1
        SetBlipAlpha(blip, transG)
        if transG == 0 then
            SetBlipSprite(blip, 2)
            RemoveBlip(blip)
            return
        end
    end
end)
