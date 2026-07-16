export const blipCategories = [
    {
        name: "Animais",
        blips: [
            { id: "blip_animal_buck", label: "Cervo / Buck" },
            { id: "blip_animal_bear", label: "Urso" },
            { id: "blip_animal_boar", label: "Javali" },
            { id: "blip_animal_cougar", label: "Puma / Suçuarana" },
            { id: "blip_animal_coyote", label: "Coiote" },
            { id: "blip_animal_elk", label: "Alce" },
            { id: "blip_animal_fox", label: "Raposa" },
            { id: "blip_animal_moose", label: "Alce Gigante" },
            { id: "blip_animal_wolf", label: "Lobo" },
            { id: "blip_animal_alligator", label: "Jacaré" },
            { id: "blip_fish_legendary", label: "Peixe Lendário" }
        ]
    },
    {
        name: "Comércio & Serviços",
        blips: [
            { id: "blip_shop_grocery", label: "Armazém / Provisões" },
            { id: "blip_shop_gunsmith", label: "Armeiro" },
            { id: "blip_shop_doctor", label: "Médico" },
            { id: "blip_shop_horses", label: "Estábulo" },
            { id: "blip_shop_tailor", label: "Alfaiate" },
            { id: "blip_shop_barber", label: "Barbeiro" },
            { id: "blip_shop_fence", label: "Loja Clandestina" },
            { id: "blip_shop_saloon", label: "Saloon" },
            { id: "blip_shop_butcher", label: "Açougue" },
            { id: "blip_post_office", label: "Correio" },
            { id: "blip_hotel", label: "Hotel / Dormitório" }
        ]
    },
    {
        name: "Acampamentos & Mundo",
        blips: [
            { id: "blip_ambient_camp", label: "Acampamento" },
            { id: "blip_ambient_coach", label: "Carroça" },
            { id: "blip_ambient_telegraph", label: "Telégrafo" },
            { id: "blip_ambient_train", label: "Trem" },
            { id: "blip_ambient_herb", label: "Ervas / Coleta" },
            { id: "blip_defend_coach", label: "Alvo / Destino" }
        ]
    },
    {
        name: "Profissões & Facções",
        blips: [
            { id: "blip_mp_role_bounty_hunter", label: "Caçador de Recompensa" },
            { id: "blip_mp_role_collector", label: "Colecionador / Tesouro" },
            { id: "blip_mp_role_trader", label: "Mercador" },
            { id: "blip_mp_role_moonshiner", label: "Moonshiner" },
            { id: "blip_mp_role_naturalist", label: "Naturalista" }
        ]
    }
];

// Helper para gerar a URL local com a imagem do blip
export function getBlipImage(id) {
    return `./blips/${id}.png`;
}