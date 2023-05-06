fx_version 'cerulean'
game 'gta5'

description 'QB-PoliceJob'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@qbx-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
	'@ox_lib/init.lua'
}

client_scripts {
	'client/main.lua',
	'client/camera.lua',
	'client/interactions.lua',
	'client/job.lua',
	'client/heli.lua',
	'client/anpr.lua',
	'client/evidence.lua',
	'client/objects.lua',
	'client/tracker.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
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
