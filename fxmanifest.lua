fx_version 'cerulean'
game 'gta5'

description 'QBX_PoliceJob'
repository 'https://github.com/Qbox-project/qbx_policejob'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@qbx_core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/vue.min.js',
    'html/script.js',
    'html/fingerprint.png',
    'html/main.css'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'