fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Antigravity'
description 'Survival Engine'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/cleanliness.lua',
    'client/bladder.lua',
    'client/temperature.lua',
    'client/health.lua',
    'client/exports.lua'
}

server_scripts {
    'server/main.lua'
}
