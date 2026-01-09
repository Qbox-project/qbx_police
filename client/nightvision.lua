local sharedConfig<const> = require 'config.shared'
if sharedConfig.disableNightvision then return end

local syncedClothes<const> = require 'config.client'.nightvisionSyncedWithClothes
local gogglesStatus = false

RegisterNetEvent('qbx_police:client:toggleNightvision', function()
  if not gogglesStatus then
    gogglesStatus = true
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "nightvision", 0.25)
    SetNightvision(true)
    if syncedClothes then
      TaskPlayAnim(cache.ped, "mp_masks@standard_car@ds@", "put_on_mask", 2.0, 2.0, 800, 51, 0, false, false, false)
      SetPedComponentVariation(cache.ped, 1, 187, 0, 0)
    end
  else
    SetNightvision(false)
    gogglesStatus = false
    if syncedClothes then
      TaskPlayAnim(cache.ped, "mp_masks@standard_car@ds@", "put_on_mask", 2.0, 2.0, 800, 51, 0, false, false, false)
      SetPedComponentVariation(cache.ped, 1, 0, 0, 0)
    end
  end
end)