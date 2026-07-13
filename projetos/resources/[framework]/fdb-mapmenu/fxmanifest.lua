fx_version 'cerulean'
game 'rdr3'

description 'fdb-mapmenu'
version '1.0.0'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/rose.png' -- O mapa vetorial que sera exibido
}

dependencies {
    'rsg-core',
    'oxmysql'
}

lua54 'yes'
