lib.addCommand('callsign', {
    help = locale('commands.callsign.help'),
    params = {
        {
            name = 'callsign',
            type = 'string',
            help = locale('commands.callsign.params.callsign'),
        }
    },
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'leo'  or player.PlayerData.job.type ~= 'ems' then return end

    player.Functions.SetMetaData('callsign', args.callsign)
end)

lib.addCommand('fine', {
    help = locale('commands.fine.help'),
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = locale('commands.fine.params.target'),
        },
        {
            name = 'amount',
            type = 'number',
            help = locale('commands.fine.params.amount'),
        },
    }
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'leo' then return end

    local target = exports.qbx_core:GetPlayer(args.target)

    if not target then
        exports.qbx_core:Notify(source, locale('notify.not_around'), 'error')
        return
    end

    target.Functions.RemoveMoney('bank', args.amount, locale('commands.fine.issuer'))

    exports.qbx_core:Notify(source, locale('commands.fine.issued'), 'success')
    exports.qbx_core:Notify(target, locale('commands.fine.fined', args.amount), 'error')
end)