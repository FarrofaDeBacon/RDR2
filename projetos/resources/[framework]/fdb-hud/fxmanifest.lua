fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'fdb-hud'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'sh/config.lua',
}

client_scripts {
    'c/main.lua',
    'c/status.lua',
    'c/vehicle.lua',
    'c/compass.lua',
    'c/nui.lua',
}

server_scripts {
    's/main.lua',
}

ui_page 'ui/public/index.html'

files {
    'ui/public/index.html',
    'ui/public/index.js',
    'ui/public/index.css',
}

dependencies {
    'rsg-core',
    'ox_lib',
}

lua54 'yes'
