const fs = require('fs');
const path = require('path');
const https = require('https');

const dir = path.join(__dirname, 'web', 'public', 'blips');
if (!fs.existsSync(dir)){
    fs.mkdirSync(dir, { recursive: true });
}

// Mapa de ícones (nossos IDs) para os arquivos PNG do JeanRopke
const blipMap = {
    'blip_animal_buck': 'animal.png',
    'blip_animal_bear': 'animal_attack.png', // Aproximação
    'blip_animal_boar': 'animal.png',
    'blip_animal_cougar': 'animal_attack.png',
    'blip_animal_coyote': 'animal.png',
    'blip_animal_elk': 'animal.png',
    'blip_animal_fox': 'animal.png',
    'blip_animal_moose': 'animal.png',
    'blip_animal_wolf': 'animal_attack.png',
    'blip_animal_alligator': 'animal_attack.png',
    'blip_fish_legendary': 'fish.png',
    
    'blip_shop_grocery': 'general_store.png',
    'blip_shop_gunsmith': 'gunsmith.png',
    'blip_shop_doctor': 'doctor.png',
    'blip_shop_horses': 'stable.png',
    'blip_shop_tailor': 'tailor.png',
    'blip_shop_barber': 'barber.png',
    'blip_shop_fence': 'fence.png',
    'blip_shop_saloon': 'saloon.png',
    'blip_shop_butcher': 'butcher.png',
    'blip_post_office': 'post_office.png',
    'blip_hotel': 'hotel.png',
    
    'blip_ambient_camp': 'camp.png',
    'blip_ambient_coach': 'fast_travel.png',
    'blip_ambient_telegraph': 'post_office.png',
    'blip_ambient_train': 'fast_travel.png',
    'blip_ambient_herb': 'plant.png',
    'blip_defend_coach': 'bounty-target.png',
    
    'blip_mp_role_bounty_hunter': 'bounty.png',
    'blip_mp_role_collector': 'madam_nazar.png',
    'blip_mp_role_trader': 'butcher.png',
    'blip_mp_role_moonshiner': 'moonshiner.png',
    'blip_mp_role_naturalist': 'animal.png'
};

function download(url, dest) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        https.get(url, {headers: {'User-Agent': 'Node.js'}}, (response) => {
            if (response.statusCode === 200) {
                response.pipe(file);
                file.on('finish', () => { file.close(); resolve(true); });
            } else {
                fs.unlink(dest, () => {});
                resolve(false); 
            }
        }).on('error', (err) => {
            fs.unlink(dest, () => {});
            resolve(false);
        });
    });
}

async function run() {
    for (const [myId, jrName] of Object.entries(blipMap)) {
        const dest = path.join(dir, `${myId}.png`);
        const url = `https://raw.githubusercontent.com/jeanropke/RDOMap/master/assets/images/icons/${jrName}`;
        
        const success = await download(url, dest);
        if (success) {
            console.log(`Baixou: ${myId}.png (de ${jrName})`);
        } else {
            console.log(`FALHOU: ${myId}.png`);
        }
    }
    console.log("Downloads finalizados.");
}

run();
