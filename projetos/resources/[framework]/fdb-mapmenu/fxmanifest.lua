fx_version 'cerulean'
game 'rdr3'

description 'fdb-mapmenu'
version '1.0.0'

ui_page 'ui/public/index.html'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'ui/public/index.html',
    'ui/public/index.js',
    'ui/public/index.css',
    'ui/public/map.svg' -- O mapa vetorial compilado do Vite
}

dependencies {
    'rsg-core',
    'oxmysql'
}

lua54 'yes'
