fx_version 'cerulean'
game 'gta5'

description 'qbx_policejob'
repository 'https://github.com/Qbox-project/qbx_policejob'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'config/client.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@qbx_vehiclekeys/server/functions.lua',
    'config/server.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/vue.min.js',
    'html/script.js',
    'html/fingerprint.png',
    'html/main.css',
    'config/shared.lua',
    'locales/*.json'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'