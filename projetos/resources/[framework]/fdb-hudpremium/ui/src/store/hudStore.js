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

export const extras = writable({
    cash: 0,
    gold: 0,
    job: 'Desempregado',
    id: 0,
    time: '12:00',
    isVisible: true,
    showTemp: false, // Temporary visibility toggle (showExtrasTemp)
});

// Editor de UI, totalmente isolado
export const editorState = writable({
    isEditing: false,
    positions: {},
    colors: {},
    scales: {},
});

// ============================================================================
// BATCHING / THROTTLING DE ALTA FREQUÊNCIA (RAF)
// ============================================================================
// Para evitar sobrecarga de renderização no Svelte (especialmente no updateTick),
// enfileiramos as atualizações e aplicamos em batch no próximo frame de animação.
// Isso impede que um 'updateTick' que altera fome/sede/vida dispare dezenas de
// re-renders no DOM em um único ciclo do event loop.
let pendingCoreUpdates = null;
let rafId = null;

function applyBatchedUpdates() {
    if (pendingCoreUpdates) {
        coreStatus.update(current => ({ ...current, ...pendingCoreUpdates }));
        pendingCoreUpdates = null;
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

        // --- SURVIVAL ENGINES (Antigas) ---
        case 'urine':
        case 'temp':
            survivalEngines.update(s => ({ ...s, [data.action]: data.value }));
            break;

        // --- SURVIVAL ENGINES (Novas propostas) ---
        case 'poison':
        case 'illness':
        case 'drunkenness':
        case 'hygiene':
            survivalEngines.update(s => ({ ...s, [data.action]: data.value }));
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
        case 'loadSettings':
            editorState.update(s => ({
                ...s,
                positions: data.positions || s.positions,
                colors: data.colors || s.colors,
                scales: data.scales || s.scales,
            }));
            break;

        // --- MISC ---
        case 'itemConsumed':
            // Logic for showing a toast or updating quick UI could go here
            break;

        default:
            console.warn(`[fdb-hudpremium] Unhandled action: ${data.action}`);
            break;
    }
});
