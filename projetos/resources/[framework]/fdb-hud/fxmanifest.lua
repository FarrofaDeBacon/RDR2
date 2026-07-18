fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'fdb-hud'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/status.lua',
    'client/vehicle.lua',
    'client/nui.lua',
    'client/minimap.lua',
    'client/hidenatives.lua',
}


server_scripts {
    'server/main.lua',
    'server/status.lua',
}

ui_page 'ui/public/index.html?v=3'

files {
    'ui/public/index.html',
    'ui/public/index.js',
    'ui/public/index.css',
    'ui/public/img/*'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

lua54 'yes'

