lib.addCommand('callsign', {
    help = 'Give yourself a callsign',
    params = {
        {
            name = 'callsign',
            type = 'number',
            help = locale('info.callsign_name')
        }
    },
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)

    if not player then return end

    player.Functions.SetMetaData('callsign', args.callsign)
end)

lib.addCommand('fine', {
    help = 'Fine somebody',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID of the Individual'
        },
        {
            name = 'amount',
            type = 'number',
            help = 'Amount you wish to fine',
        },
    }
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'leo' then return end

    local target = exports.qbx_core:GetPlayer(args.target)

    if not target then
        exports.qbx_core:Notify(source, 'It does not look like that person is around right now...', 'error')
        return
    end

    target.Functions.RemoveMoney('bank', args.amount, 'Fined by the City of Los Santos')

    exports.qbx_core:Notify(source, 'Fine issued', 'success')
    exports.qbx_core:Notify(target, 'You have been fined $' .. args.amount, 'error')
end)