local sharedConfig<const> = require 'config.shared'
if sharedConfig.disableNightvision then return end

CreateThread(function()
  local moduleItem<const> = exports.ox_inventory:Items("nightvision")
  if moduleItem and #moduleItem > 0 then
    lib.print.warn("nightvision item not found, please follow the instructions in the README.md")
    return
  end
  exports.qbx_core.CreateUseableItem("nightvision", function(source)
    local player<const> = exports.qbx_core:GetPlayer(source)
    if player then
      TriggerClientEvent("qbx_police:client:toggleNightvision", source)
    end
  end)
end)