fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_scrapyardjob'
author 'Supernoob Indonesia'
description 'Qbox scrapyard business and vehicle salvage resource'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/admin.lua',
    'server/main.lua',
    'server/business.lua',
    'server/illegal.lua',
    'server/rentals.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
    'Renewed-Banking'
}
