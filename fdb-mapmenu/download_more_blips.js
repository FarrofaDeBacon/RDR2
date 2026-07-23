const fs = require('fs');
const path = require('path');
const https = require('https');

const dir = path.join(__dirname, 'web', 'public', 'blips');

const blipMap = {
    'blip_ambient_law': 'sheriff.png',
    'blip_bank': 'bank.png',
    'blip_bath_house': 'bath.png',
    'blip_photo_studio': 'photo.png',
    'blip_hotel_bed': 'hotel.png',
    'blip_ambient_coach': 'fast_travel.png'
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
