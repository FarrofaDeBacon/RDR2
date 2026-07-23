const fs = require('fs');
const path = require('path');
const http = require('http'); // Femga usa http aparentemente, ou https. Vamos tentar http que está no link.

const dir = path.join(__dirname, 'web', 'public', 'blips');
if (!fs.existsSync(dir)){
    fs.mkdirSync(dir, { recursive: true });
}

// Lista dos blips que a gente usou no código
const wantedBlips = [
    'blip_animal_buck', 'blip_animal_bear', 'blip_animal_boar', 'blip_animal_cougar', 'blip_animal_coyote', 
    'blip_animal_elk', 'blip_animal_fox', 'blip_animal_moose', 'blip_animal_wolf', 'blip_animal_alligator', 'blip_fish_legendary',
    'blip_shop_grocery', 'blip_shop_gunsmith', 'blip_shop_doctor', 'blip_shop_horses', 'blip_shop_tailor', 'blip_shop_barber', 
    'blip_shop_fence', 'blip_shop_saloon', 'blip_shop_butcher', 'blip_post_office', 'blip_hotel',
    'blip_ambient_camp', 'blip_ambient_coach', 'blip_ambient_telegraph', 'blip_ambient_train', 'blip_ambient_herb', 'blip_defend_coach',
    'blip_mp_role_bounty_hunter', 'blip_mp_role_collector', 'blip_mp_role_trader', 'blip_mp_role_moonshiner', 'blip_mp_role_naturalist'
];

function download(url, dest) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        http.get(url, (response) => {
            if (response.statusCode === 200) {
                response.pipe(file);
                file.on('finish', () => { file.close(); resolve(); });
            } else {
                fs.unlink(dest, () => {});
                resolve(false); // Ignora 404 pra tentar no outro diretório
            }
        }).on('error', (err) => {
            fs.unlink(dest, () => {});
            resolve(false);
        });
    });
}

async function run() {
    for (const blip of wantedBlips) {
        const dest = path.join(dir, `${blip}.png`);
        
        // Tenta baixar da pasta blips_mp primeiro
        let url1 = `http://femga.com/images/samples/ui_textures_no_bg/blips_mp/${blip}.png`;
        let success = await download(url1, dest);
        
        if (!success) {
            // Se falhar, tenta na pasta blips normal (singleplayer)
            let url2 = `http://femga.com/images/samples/ui_textures_no_bg/blips/${blip}.png`;
            success = await download(url2, dest);
        }
        
        if (success) {
            console.log(`Baixou: ${blip}`);
        } else {
            console.log(`FALHOU: ${blip}`);
        }
    }
    console.log("Downloads finalizados.");
}

run();
