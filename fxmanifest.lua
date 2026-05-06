fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sp_tuning'
description 'SP tuning' 
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'locales/en.lua',
    'locales/de.lua',
    'shared/locale.lua'
}

client_scripts {
    'client/main.lua',
    'client/camera.lua',
    'client/mods.lua',
    'client/boss.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/boss.js',
    'html/logo-r.png'
}

dependencies {
    'ox_lib'
}
