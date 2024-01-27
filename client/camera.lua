local config = require 'config.client'
local InsideCam = false
local tabletProp = nil

local function updateCameraControlsText()
    local text = {
        ('------ Camera Controls ------  \n'),
        ('Rotate Left [Left Arrow]  \n'),
        ('Rotate Right [Right Arrow]  \n'),
        ('Tilt Up [Up Arrow]  \n'),
        ('Tilt Down [Down Arrow]  \n'),
        ('Zoom In [Scroll Up]  \n'),
        ('Zoom Out [Scroll Down]  \n'),
        ('Close Camera [ESC / BACKSPACE]  \n'),
    }
    lib.showTextUI(table.concat(text))
end

local function useTablet(ped)
    lib.requestModel(`prop_cs_tablet`)
    lib.requestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@base')

    if DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
    end
    
    tabletProp = CreateObject(`prop_cs_tablet`, 0.0, 0.0, 0.0, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 60309)

    SetCurrentPedWeapon(ped, `weapon_unarmed`, true)
    AttachEntityToEntity(tabletProp, ped, boneIndex, 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(`prop_cs_tablet`)
    TaskPlayAnim(ped, 'amb@code_human_in_bus_passenger_idles@female@tablet@base', 'base', 3.0, 3.0, -1, 49, 0, 0, 0, 0)
end

local function removeTablet(ped)
    ClearPedTasks(ped)
    Wait(300)
    DeleteEntity(tabletProp)
end

RegisterNetEvent('police:client:DisableAllCameras', function()
    if GetInvokingResource() then return end
    for k in pairs(config.securityCameras) do
        config.securityCameras[k].isOnline = false
    end
end)

RegisterNetEvent('police:client:EnableAllCameras', function()
    if GetInvokingResource() then return end
    for k in pairs(config.securityCameras) do
        config.securityCameras[k].isOnline = true
    end
end)

RegisterNetEvent('police:client:SetCamera', function(key, isOnline)
    if GetInvokingResource() then return end
    if type(key) == 'table' and table.type(key) == 'array' then
        for _, v in pairs(key) do
            config.securityCameras[v].isOnline = isOnline
        end
    elseif type(key) == 'number' then
        config.securityCameras[key].isOnline = isOnline
    else
        error('police:client:SetCamera did not receive the right type of key\nreceived type: ' .. type(key) .. '\nreceived value: ' .. key)
    end
end)

RegisterNetEvent('police:client:showcamera', function()
    local menu = {
        id = 'camera_menu',
        title = 'Camera List',
        options = {}
    }

    for camId, cameraData in pairs(config.securityCameras) do
        if cameraData.isOnline then
            table.insert(menu.options, {
                title = string.format('[Cam %d] %s', camId, cameraData.label),
                onSelect = function()
                    TriggerEvent('police:client:opencamera', camId)
                end,
            })
        end
    end

    lib.registerContext(menu)
    lib.showContext('camera_menu')
end)

RegisterNetEvent('police:client:opencamera', function(cameraId)
    local coords = config.securityCameras[tonumber(cameraId)].coords
    cameraId = tonumber(cameraId)

    SetTimecycleModifier('heliGunCam')
    SetTimecycleModifierStrength(1.0)

    local scaleform = RequestScaleformMovie('TRAFFIC_CAM')
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    securityCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(securityCam, coords.x, coords.y, (coords.z + 1.2))
    SetCamRot(securityCam, -15.0, 0.0, coords.w)
    SetCamFov(securityCam, 110.0)
    RenderScriptCams(true, false, 0, 1, 0)
    PushScaleformMovieFunction(scaleform, 'PLAY_CAM_MOVIE')
    SetFocusArea(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
    PopScaleformMovieFunctionVoid()

    InsideCam = true
    updateCameraControlsText()
    useTablet(cache.ped)

    while InsideCam do
        SetCamCoord(securityCam, coords.x, coords.y, (coords.z + 1.2))
        PushScaleformMovieFunction(scaleform, 'SET_ALT_FOV_HEADING')
        PushScaleformMovieFunctionParameterFloat(1.0)
        PushScaleformMovieFunctionParameterFloat(GetCamRot(securityCam, 2).z)
        PopScaleformMovieFunctionVoid()
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        local CamRot = GetCamRot(securityCam, 2)
        
        if IsControlPressed(1, 108) or IsControlPressed(1, 174) then -- DPAD LEFT
            SetCamRot(securityCam, CamRot.x, 0.0, CamRot.z + 0.7, 2)
        end

        if IsControlPressed(1, 107) or IsControlPressed(1, 175) then -- DPAD RIGHT
            SetCamRot(securityCam, CamRot.x, 0.0, CamRot.z - 0.7, 2)
        end

        if IsControlPressed(1, 61) or IsControlPressed(1, 188) then -- DPAD UP
            SetCamRot(securityCam, CamRot.x + 0.7, 0.0, CamRot.z, 2)
        end

        if IsControlPressed(1, 60) or IsControlPressed(1, 187) then -- DPAD DOWN
            SetCamRot(securityCam, CamRot.x - 0.7, 0.0, CamRot.z, 2)
        end

        local camFov = GetCamFov(securityCam)
        if IsControlPressed(1, 241) then -- SCROLL UP
            if camFov <= 20.0 then
                camFov = 20.0 
            end
            SetCamFov(securityCam, camFov - 3.0)
        end

        if IsControlPressed(1, 242) then -- SCROLL DOWN
            if camFov >= 90.0 then
                camFov = 90.0
            end
            SetCamFov(securityCam, camFov + 3.0)
        end

        if IsControlJustPressed(1, 177) then -- ESC - Backspace
            InsideCam = false
        end

        Wait(1)
    end

    lib.hideTextUI()
    removeTablet(cache.ped)
    ClearPedTasks(PlayerPedId())
    ClearTimecycleModifier()
    ClearFocus()
    RenderScriptCams(false, false, 0, 1, 0)
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    DestroyCam(securityCam, true)
end)
