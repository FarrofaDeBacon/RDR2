fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'fdb-consume'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'config.lua',
    'config/foods.lua',
    'config/drinks.lua',
    'config/medical.lua',
    'config/drugs.lua',
    'config/smokes.lua'
}

client_scripts {
    'client/editor.lua',
    'client/foods.lua',
    'client/drinks.lua',
    'client/medical.lua',
    'client/smokes.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'rsg-core'
}
