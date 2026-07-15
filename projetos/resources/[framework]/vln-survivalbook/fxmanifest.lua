fx_version "cerulean"
games { 'rdr3' }

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

use_fxv2_oal "yes"
lua54        "yes"
version      "1.0"

author  "Quantum Quake Studios (Ported to RSG by Antigravity)"
description "Quantum Quake Survival Book configured for RSG-Core"

client_scripts { 
    '@ox_lib/init.lua',
    'config.lua',
    'client.lua',
    'peds.lua'
}

server_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'server.lua'
}

dependencies {
    'rsg-core',
    'ox_lib'
}
