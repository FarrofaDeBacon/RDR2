export const blipCategories = [
    {
        name: "Animais & Pesca",
        blips: [
            { id: "blip_animal", label: "Animal / Caça" },
            { id: "blip_mg_fishing", label: "Peixe / Pescaria" }
        ]
    },
    {
        name: "Lojas & Serviços",
        blips: [
            { id: "blip_shop_store", label: "Armazém" },
            { id: "blip_shop_gunsmith", label: "Armeiro" },
            { id: "blip_shop_doctor", label: "Médico" },
            { id: "blip_shop_horse", label: "Estábulo" },
            { id: "blip_shop_tailor", label: "Alfaiate" },
            { id: "blip_ambient_wardrobe", label: "Guarda-Roupa" },
            { id: "blip_shop_barber", label: "Barbeiro" },
            { id: "blip_bath_house", label: "Banho" },
            { id: "blip_shop_shady_store", label: "Loja Clandestina" },
            { id: "blip_shop_saloon", label: "Saloon" },
            { id: "blip_shop_butcher", label: "Açougue" },
            { id: "blip_photo_studio", label: "Fotógrafo" },
            { id: "blip_bank", label: "Banco" }
        ]
    },
    {
        name: "Locais do Mundo",
        blips: [
            { id: "blip_shop_train", label: "Correio / Trem" },
            { id: "blip_ambient_coach", label: "Viagem Rápida" },
            { id: "blip_hotel_bed", label: "Hotel / Cama" },
            { id: "blip_ambient_law", label: "Xerife / Lei" },
            { id: "blip_ambient_camp", label: "Acampamento" },
            { id: "blip_ambient_bounty_target", label: "Alvo / Recompensa" }
        ]
    }
];

// Helper para gerar a URL local com a imagem do blip
export function getBlipImage(id) {
    const svgBlips = ['blip_bank', 'blip_bath_house', 'blip_ambient_law', 'blip_photo_studio', 'blip_hotel_bed', 'blip_ambient_wardrobe'];
    if (svgBlips.includes(id)) {
        return `./blips/${id}.svg`;
    }
    return `./blips/${id}.png`;
}