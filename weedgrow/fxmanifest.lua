fx_version 'cerulean'
game 'gta5'

name 'weedgrow'
author 'you'
description 'Weed growing system'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qb-core',
}   