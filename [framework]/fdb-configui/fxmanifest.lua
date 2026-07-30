fx_version 'cerulean'
game 'redm'

author 'Antigravity'
description 'Painel Svelte generico para editar runtime config'

ui_page 'web/dist/index.html'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
    'web/dist/assets/*.svg',
    'web/dist/assets/*.png',
    'web/dist/assets/*.webp'
}
