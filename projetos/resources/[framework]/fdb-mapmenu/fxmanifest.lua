fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'fdb-mapmenu'
version '1.0.0'

ui_page 'ui/public/index.html'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'ui/public/index.html',
    'ui/public/assets/index-BVCStlFN.js',
    'ui/public/assets/index-9RJ1eD72.css',
    -- Declaração explícita por nível de zoom para garantir empacotamento completo de subpastas profundas no RedM
    'tiles/0/**/*.webp',
    'tiles/1/**/*.webp',
    'tiles/2/**/*.webp',
    'tiles/3/**/*.webp',
    'tiles/4/**/*.webp',
    'tiles/5/**/*.webp'
}

dependencies {
    'rsg-core',
    'oxmysql',
    'ox_lib'
}

lua54 'yes'
