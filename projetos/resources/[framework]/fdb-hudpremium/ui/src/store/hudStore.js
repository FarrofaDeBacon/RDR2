import { writable } from 'svelte/store';

// ============================================================================
// STORES POR DOMÍNIO
// ============================================================================

export const coreStatus = writable({
    health: 100,
    stamina: 100,
    water: 100,
    food: 100,
    stress: 0,
    armor: 0,
    oxygen: 100,
});

export const horseStatus = writable({
    horseHealth: 100,
    horseStamina: 100,
});

export const combat = writable({
    primaryAmmo: 0,
    secondaryAmmo: 0,
    weaponEquipped: false,
});

export const comms = writable({
    voice: 0, // 0 = whisper, 1 = normal, 2 = shout
    isTalking: false,
    telegram: 0, // unread messages
    population: 0, 
});

export const survivalEngines = writable({
    urine: 0, // Bladder
    temp: 20, // Body/Environment Temperature
    poison: 0, // Snake poison severity
    illness: 0, // Sickness severity (cold/flu)
    drunkenness: 0, // Alcohol level
    hygiene: 100, // Cleanliness
});

export const activeBuffs = writable({
    coldResistance: 0, // tempo restante do buff em segundos (ou valor)
    heatResistance: 0
});

export const extras = writable({
    cash: 0,
    gold: 0,
    job: 'Desempregado',
    id: 0,
    time: '12:00',
    isVisible: true,
    showTemp: false, // Temporary visibility toggle (showExtrasTemp)
});

// Editor de UI, totalmente isolado com suporte a configurações ricas e retrocompatibilidade
const defaultElements = [
    'health', 'stamina', 'food', 'water', 'urine', 'stress', 'temperature', 'voice',
    'horseHealth', 'horseStamina', 'population', 'telegram', 'primaryAmmo', 'secondaryAmmo',
    'logo', 'money', 'gold', 'job', 'id', 'time', 'pvp',
    'hygiene', 'poison', 'illness', 'drunkenness', 'armor', 'oxygen', 'coldResistance', 'heatResistance'
];

export const createDefaultConfigs = () => {
    const cfgs = {};
    defaultElements.forEach(id => {
        let outerColor = '#ffffff';
        if (id === 'stamina' || id === 'horseStamina') outerColor = '#ffd700';
        else if (id === 'food') outerColor = '#ffa500';
        else if (id === 'water') outerColor = '#00bfff';
        else if (id === 'stress') outerColor = '#ff4500';
        else if (id === 'urine') outerColor = '#ffff00';
        else if (id === 'hygiene') outerColor = '#8b4513';
        else if (id === 'poison') outerColor = '#32cd32';
        else if (id === 'illness') outerColor = '#808000';
        else if (id === 'drunkenness') outerColor = '#ff69b4';
        else if (id === 'temperature') outerColor = '#00ffff';
        else if (id === 'voice') outerColor = '#aaaaaa';
        else if (id === 'primaryAmmo') outerColor = '#ff4500';
        else if (id === 'secondaryAmmo') outerColor = '#ffa500';
        else if (id === 'armor') outerColor = '#c0c0c0';
        else if (id === 'oxygen') outerColor = '#87ceeb';
        else if (id === 'coldResistance') outerColor = '#00ffff';
        else if (id === 'heatResistance') outerColor = '#ff4500';

        cfgs[id] = {
            visible: true,
            scale: 1.0,
            outerColor: outerColor,
            outerDamageColor: '#ff0000',
            goldColor: '#ffd700',
            maxOuterColor: '#ffffff',
            innerColor: '#ffffff',
            showSegments: false,
            segmentsCount: 10,
            badge: {
                showValue: false,
                showBackground: true,
                textColor: '#ffffff',
                fontSize: 12,
                badgeScale: 1.0,
                position: 'bottom'
            }
        };
    });
    return cfgs;
};

export const editorState = writable({
    isEditing: false,
    positions: {},
    configs: createDefaultConfigs(),
});

// ============================================================================
// BATCHING / THROTTLING DE ALTA FREQUÊNCIA (RAF)
// ============================================================================
// Para evitar sobrecarga de renderização no Svelte (especialmente no updateTick),
// enfileiramos as atualizações e aplicamos em batch no próximo frame de animação.
// Isso impede que um 'updateTick' que altera fome/sede/vida dispare dezenas de
// re-renders no DOM em um único ciclo do event loop.
let pendingCoreUpdates = null;
let pendingSurvivalUpdates = null;
let pendingBuffsUpdates = null;
let rafId = null;

function applyBatchedUpdates() {
    if (pendingCoreUpdates) {
        coreStatus.update(current => ({ ...current, ...pendingCoreUpdates }));
        pendingCoreUpdates = null;
    }
    if (pendingSurvivalUpdates) {
        survivalEngines.update(current => ({ ...current, ...pendingSurvivalUpdates }));
        pendingSurvivalUpdates = null;
    }
    if (pendingBuffsUpdates) {
        activeBuffs.update(current => ({ ...current, ...pendingBuffsUpdates }));
        pendingBuffsUpdates = null;
    }
    rafId = null;
}

// ============================================================================
// NUI MESSAGE HANDLER
// ============================================================================

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    // Previne gravação de undefined em actions simples
    if (data.action !== 'updateTick' && data.action !== 'loadSettings' && data.action !== 'itemConsumed' && data.value === undefined) {
        return;
    }

    switch (data.action) {
        // --- TICK DE ALTA FREQUÊNCIA ---
        case 'updateTick':
            // data.values = { health: 90, stamina: 80, ... }
            if (data.values) {
                pendingCoreUpdates = { ...pendingCoreUpdates, ...data.values };
                if (!rafId) {
                    rafId = requestAnimationFrame(applyBatchedUpdates);
                }
            }
            break;

        // --- CORE STATUS ---
        case 'health':
        case 'stamina':
        case 'food':
        case 'water':
        case 'stress':
            pendingCoreUpdates = { ...pendingCoreUpdates, [data.action]: data.value };
            if (!rafId) {
                rafId = requestAnimationFrame(applyBatchedUpdates);
            }
            break;

        // --- HORSE STATUS ---
        case 'horseHealth':
        case 'horseStamina':
            horseStatus.update(s => ({ ...s, [data.action]: data.value }));
            break;

        // --- COMBAT ---
        case 'primaryAmmo':
        case 'secondaryAmmo':
            combat.update(s => ({ ...s, [data.action]: data.value }));
            break;

        // --- COMMS ---
        case 'voice':
        case 'telegram':
        case 'population':
            comms.update(s => ({ ...s, [data.action]: data.value }));
            break;

        // --- SURVIVAL ENGINES ---
        case 'urine':
        case 'hygiene':
        case 'temp':
        case 'poison':
        case 'illness':
        case 'drunkenness':
            pendingSurvivalUpdates = { ...pendingSurvivalUpdates, [data.action]: data.value };
            if (!rafId) {
                rafId = requestAnimationFrame(applyBatchedUpdates);
            }
            break;
        case 'coldResistance':
        case 'heatResistance':
            pendingBuffsUpdates = { ...pendingBuffsUpdates, [data.action]: data.value };
            if (!rafId) {
                rafId = requestAnimationFrame(applyBatchedUpdates);
            }
            break;

        // --- EXTRAS ---
        case 'showExtrasTemp':
            extras.update(s => ({ ...s, showTemp: data.value }));
            break;
        case 'setVisibility':
            extras.update(s => ({ ...s, isVisible: data.value }));
            break;

        // --- EDITOR (Isolado) ---
        case 'toggleEditor':
            editorState.update(s => ({ ...s, isEditing: data.value }));
            break;
        case 'loadSettings': {
            let configs = data.configs;
            if (!configs) {
                // Formato legado detectado! Fazer migração
                configs = createDefaultConfigs();
                
                // 1. Mapear as escalas legadas de grupos para os elementos individuais correspondentes
                const legacyGroupMapping = {
                    PlayerCores: ['health', 'stamina', 'food', 'water', 'stress'],
                    SurvivalCores: ['urine', 'hygiene', 'poison', 'illness', 'drunkenness', 'temperature'],
                    HorseCores: ['horseHealth', 'horseStamina'],
                    Buffs: ['coldResistance', 'heatResistance'],
                    Voice: ['voice'],
                };

                const oldScales = data.scales || {};
                for (const [group, elements] of Object.entries(legacyGroupMapping)) {
                    if (oldScales[group] !== undefined) {
                        elements.forEach(id => {
                            if (configs[id]) {
                                configs[id].scale = oldScales[group];
                            }
                        });
                    }
                }

                // 2. Se existirem cores legadas individuais salvas
                const oldColors = data.colors || {};
                for (const [id, color] of Object.entries(oldColors)) {
                    if (configs[id]) {
                        configs[id].outerColor = color;
                    }
                }
            }

            editorState.update(s => ({
                ...s,
                positions: data.positions || s.positions,
                configs: configs
            }));
            break;
        }

        // --- MISC ---
        case 'itemConsumed':
            // Logic for showing a toast or updating quick UI could go here
            break;

        default:
            console.warn(`[fdb-hudpremium] Unhandled action: ${data.action}`);
            break;
    }
});
