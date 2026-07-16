fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Farrofa / Antigravity'
description 'Standalone Compass UI'
version '1.0.0'

shared_scripts {
    'config.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
