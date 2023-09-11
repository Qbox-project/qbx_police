local currentCameraIndex = 0
local createdCamera = 0
local currentScaleform = -1

local function getCurrentTime()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    if hours < 10 then
        hours = tostring(0 .. GetClockHours())
    end
    if minutes < 10 then
        minutes = tostring(0 .. GetClockMinutes())
    end
    return tostring(hours .. ":" .. minutes)
end

local function createInstructionalScaleform(scaleform)
    scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(1, 194, true))
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(Lang:t('info.close_camera'))
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

local function changeSecurityCamera(x, y, z, r)
    if createdCamera ~= 0 then
        DestroyCam(createdCamera, false)
        createdCamera = 0
    end

    if currentScaleform ~= -1 then
        SetScaleformMovieAsNoLongerNeeded(currentScaleform)
        currentScaleform = -1
    end

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, x, y, z)
    SetCamRot(cam, r.x, r.y, r.z, 2)
    RenderScriptCams(true, false, 0, true, true)
    Wait(250)
    createdCamera = cam
    currentScaleform = createInstructionalScaleform("instructional_buttons")
end

local function closeSecurityCamera()
    DestroyCam(createdCamera, false)
    RenderScriptCams(false, false, 1, true, true)
    createdCamera = 0
    SetScaleformMovieAsNoLongerNeeded(currentScaleform)
    currentScaleform = -1
    ClearTimecycleModifier()
    SetFocusEntity(cache.ped)
    if Config.SecurityCameras.hideradar then
        DisplayRadar(true)
    end
    FreezeEntityPosition(cache.ped, false)
end

-- Events
RegisterNetEvent('police:client:ActiveCamera', function(cameraId)
    if GetInvokingResource() then return end
    if Config.SecurityCameras.cameras[cameraId] then
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end
        SendNUIMessage({
            type = "enablecam",
            label = Config.SecurityCameras.cameras[cameraId].label,
            id = cameraId,
            connected = Config.SecurityCameras.cameras[cameraId].isOnline,
            time = getCurrentTime(),
        })
        local firstCamX = Config.SecurityCameras.cameras[cameraId].coords.x
        local firstCamY = Config.SecurityCameras.cameras[cameraId].coords.y
        local firstCamZ = Config.SecurityCameras.cameras[cameraId].coords.z
        local firstCamR = Config.SecurityCameras.cameras[cameraId].r
        SetFocusArea(firstCamX, firstCamY, firstCamZ, firstCamX, firstCamY, firstCamZ)
        changeSecurityCamera(firstCamX, firstCamY, firstCamZ, firstCamR)
        currentCameraIndex = cameraId
        DoScreenFadeIn(250)
    elseif cameraId == 0 then
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end
        closeSecurityCamera()
        SendNUIMessage({
            type = "disablecam",
        })
        DoScreenFadeIn(250)
    else
        QBCore.Functions.Notify(Lang:t("error.no_camera"), "error")
    end
end)

RegisterNetEvent('police:client:DisableAllCameras', function()
    if GetInvokingResource() then return end
    for k in pairs(Config.SecurityCameras.cameras) do
        Config.SecurityCameras.cameras[k].isOnline = false
    end
end)

RegisterNetEvent('police:client:EnableAllCameras', function()
    if GetInvokingResource() then return end
    for k in pairs(Config.SecurityCameras.cameras) do
        Config.SecurityCameras.cameras[k].isOnline = true
    end
end)

RegisterNetEvent('police:client:SetCamera', function(key, isOnline)
    if GetInvokingResource() then return end
    if type(key) == 'table' and table.type(key) == 'array' then
        for _, v in pairs(key) do
            Config.SecurityCameras.cameras[v].isOnline = isOnline
        end
    elseif type(key) == 'number' then
        Config.SecurityCameras.cameras[key].isOnline = isOnline
    else
        error('police:client:SetCamera did not receive the right type of key\nreceived type: ' .. type(key) .. '\nreceived value: ' .. key)
    end
end)

local function listenForCameraControls()
    DrawScaleformMovieFullscreen(currentScaleform, 255, 255, 255, 255, 0)
    SetTimecycleModifier("scanline_cam_cheap")
    SetTimecycleModifierStrength(1.0)

    if Config.SecurityCameras.hideradar then
        DisplayRadar(false)
    end

    -- CLOSE CAMERAS
    if IsControlJustPressed(1, 177) then
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end
        closeSecurityCamera()
        SendNUIMessage({
            type = "disablecam",
        })
        DoScreenFadeIn(250)
    end

    ---------------------------------------------------------------------------
    -- CAMERA ROTATION CONTROLS
    ---------------------------------------------------------------------------
    if Config.SecurityCameras.cameras[currentCameraIndex].canRotate then
        local getCameraRot = GetCamRot(createdCamera, 2)

        -- ROTATE UP
        if IsControlPressed(0, 32) then
            if getCameraRot.x <= 0.0 then
                SetCamRot(createdCamera, getCameraRot.x + 0.7, 0.0, getCameraRot.z, 2)
            end
        end

        -- ROTATE DOWN
        if IsControlPressed(0, 8) then
            if getCameraRot.x >= -50.0 then
                SetCamRot(createdCamera, getCameraRot.x - 0.7, 0.0, getCameraRot.z, 2)
            end
        end

        -- ROTATE LEFT
        if IsControlPressed(0, 34) then
            SetCamRot(createdCamera, getCameraRot.x, 0.0, getCameraRot.z + 0.7, 2)
        end

        -- ROTATE RIGHT
        if IsControlPressed(0, 9) then
            SetCamRot(createdCamera, getCameraRot.x, 0.0, getCameraRot.z - 0.7, 2)
        end
    end
end

-- Threads
CreateThread(function()
    while true do
        if createdCamera == 0 or currentScaleform == -1 then
            Wait(2000)
        else
            listenForCameraControls()
            Wait(0)
        end
    end
end)
