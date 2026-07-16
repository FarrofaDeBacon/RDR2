const fs = require('fs');
const path = require('path');
const https = require('https');

const dir = path.join(__dirname, 'web', 'public', 'blips');
if (!fs.existsSync(dir)){
    fs.mkdirSync(dir, { recursive: true });
}

const url = "https://api.github.com/repos/femga/rdr3_discoveries/contents/useful_info_from_rpfs/textures/blips_mp?ref=a4b4bcd5a3006b0c1434b03e4095d038164932f7";

const options = {
    headers: { 'User-Agent': 'Node.js' }
};

https.get(url, options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        const files = JSON.parse(data);
        const blips = [];
        let count = 0;
        
        // Vamos pegar só uns 30 blips legais pra não baixar 500 imagens
        const wanted = ['blip_camp.png', 'blip_shop_gunsmith.png', 'blip_shop_doctor.png', 'blip_shop_grocery.png', 'blip_animal_bear.png', 'blip_animal_buck.png', 'blip_animal_cougar.png', 'blip_mp_role_bounty_hunter.png', 'blip_mp_role_collector.png', 'blip_mp_role_trader.png', 'blip_shop_horses.png', 'blip_shop_tailor.png', 'blip_shop_barber.png', 'blip_hotel.png', 'blip_ambient_train.png'];
        
        files.forEach(f => {
            if(f.name.endsWith('.png') && (wanted.includes(f.name) || count < 25)) {
                if(!wanted.includes(f.name)) count++;
                
                const filePath = path.join(dir, f.name);
                const file = fs.createWriteStream(filePath);
                https.get(f.download_url, function(response) {
                    response.pipe(file);
                });
                
                blips.push({
                    id: f.name.replace('.png', ''),
                    image: `blips/${f.name}`
                });
            }
        });
        
        fs.writeFileSync(path.join(__dirname, 'web', 'src', 'lib', 'blips.js'), `export const blipList = ${JSON.stringify(blips, null, 2)};`);
        console.log("Download completo!");
    });
});
