const mapContainer = document.getElementById('map-container');
const playerMarker = document.getElementById('player-marker');

// Escuta os eventos enviados pelo client
window.addEventListener('message', (e) => {
    const { action, coords } = e.data ?? {};
    
    if (action === 'openMap') {
        mapContainer.style.display = 'flex';
        
        // Posicionamento base provisório (no centro do wrapper por enquanto)
        playerMarker.style.left = '50%';
        playerMarker.style.top = '50%';
    } else if (action === 'closeMap') {
        mapContainer.style.display = 'none';
    }
});

// Fecha o mapa quando o jogador clica no fundo do container (fora do wrapper)
mapContainer.addEventListener('click', (e) => {
    if (e.target === mapContainer) {
        fetch('https://fdb-mapmenu/closeMap', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }
});
