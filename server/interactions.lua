
local function handcuff(source)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local targetId, _, _ = lib.getClosestPlayer(playerCoords, 1.0)

    if not targetId or Player(targetId).state.handcuffed then return end

    TriggerClientEvent('qbx_police:client:handcuffPlayer', source)

    local targetCuffed = lib.callback.await('qbx_police:client:getHandcuffed', targetId)

    if not targetCuffed then return end

    exports.ox_inventory:RemoveItem(source, 'handcuffs', 1)

    Player(targetId).state:set('handcuffed', true, true)
    exports.qbx_core:SetMetadata(targetId, 'handcuffed', true)
end

exports.qbx_core:CreateUseableItem('handcuffs', handcuff)

local function unhandcuff(source)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local targetId, _, _ = lib.getClosestPlayer(playerCoords, 1.0)

    if not targetId or not Player(targetId).state.handcuffed then return end

    TriggerClientEvent('qbx_police:client:unHandcuffPlayer', source)

    local targetCuffed = lib.callback.await('qbx_police:client:getHandcuffed', targetId)

    if not targetCuffed then return end

    exports.ox_inventory:AddItem(source, 'handcuffs', 1)

    Player(targetId).state:set('handcuffed', true, true)
    exports.qbx_core:SetMetadata(targetId, 'handcuffed', false)
end

exports.qbx_core:CreateUseableItem('handcuff_key', unhandcuff)