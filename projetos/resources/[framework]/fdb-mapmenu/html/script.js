const mapContainer = document.getElementById('map-container');
const playerMarker = document.getElementById('player-marker');

// Limites reais de coordenadas do mundo RedM/RDR2
// Esses limites mapeiam o retangulo de coordenadas da imagem do mapa
const MAP_LIMITS = {
    minX: -6000,
    maxX: 6000,
    minY: -6000,
    maxY: 6000
};

// -------------------------------------------------------
// Funções de Conversão Bidirecional
// -------------------------------------------------------

/**
 * Converte coordenadas 3D do mundo real para porcentagens X/Y na imagem do mapa
 * @param {number} worldX 
 * @param {number} worldY 
 * @returns {{x: number, y: number}} porcentagens de 0 a 100
 */
function worldToImage(worldX, worldY) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX;
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY;
    
    const pctX = ((worldX - MAP_LIMITS.minX) / rangeX) * 100;
    // Y real cresce para cima (Norte), mas a tela cresce para baixo, entao invertemos
    const pctY = (1 - (worldY - MAP_LIMITS.minY) / rangeY) * 100;
    
    return {
        x: Math.max(0, Math.min(100, pctX)),
        y: Math.max(0, Math.min(100, pctY))
    };
}

/**
 * Converte porcentagens X/Y da imagem do mapa de volta para coordenadas reais do mundo
 * @param {number} pctX porcentagem de 0 a 100
 * @param {number} pctY porcentagem de 0 a 100
 * @returns {{x: number, y: number}} coordenadas X e Y do mundo
 */
function imageToWorld(pctX, pctY) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX;
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY;
    
    const worldX = (pctX / 100) * rangeX + MAP_LIMITS.minX;
    // Inverte o Y de volta
    const worldY = (1 - (pctY / 100)) * rangeY + MAP_LIMITS.minY;
    
    return { x: worldX, y: worldY };
}

// -------------------------------------------------------
// Message Listener da NUI
// -------------------------------------------------------
window.addEventListener('message', (e) => {
    const { action, coords } = e.data ?? {};
    
    if (action === 'openMap') {
        mapContainer.style.display = 'flex';
        
        if (coords) {
            // Converte a coordenada atual do jogador
            const pos = worldToImage(coords.x, coords.y);
            
            // Posiciona o marcador na tela
            playerMarker.style.left = `${pos.x}%`;
            playerMarker.style.top = `${pos.y}%`;
        }
    } else if (action === 'closeMap') {
        mapContainer.style.display = 'none';
    }
});

// Fechamento da NUI ao clicar fora do wrapper do mapa
mapContainer.addEventListener('click', (e) => {
    if (e.target === mapContainer) {
        fetch('https://fdb-mapmenu/closeMap', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }
});
