fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/canteen.lua',
    'config/bathing.lua'
}

client_scripts {
    'client/canteen.lua',
    'client/bathing.lua',
    'client/items.lua'
}

server_scripts {
    'server/main.lua'
}
