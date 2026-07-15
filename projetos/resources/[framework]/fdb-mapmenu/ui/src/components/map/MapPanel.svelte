<script>
  import { onMount, onDestroy } from 'svelte'
  import { visible, coords, markers } from '../../stores/mapStore.js'
  import L from 'leaflet'

  // Limites de coordenadas do RedM mapeando as bordas do mapa fatiado
  const MAP_LIMITS = {
    minX: -6000,
    maxX: 6000,
    minY: -6000,
    maxY: 6000
  }

  let map;
  let playerMarker;
  let markersLayer;
  let mapElement;
  let isMapInitialized = false;

  // Converte coordenadas mundo -> imagem (%)
  function worldToImage(worldX, worldY) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY
    
    const pctX = ((worldX - MAP_LIMITS.minX) / rangeX) * 100
    const pctY = (1 - (worldY - MAP_LIMITS.minY) / rangeY) * 100
    
    return {
      x: Math.max(0, Math.min(100, pctX)),
      y: Math.max(0, Math.min(100, pctY))
    }
  }

  // Converte coordenadas imagem (%) -> mundo
  function imageToWorld(pctX, pctY) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY
    
    const worldX = (pctX / 100) * rangeX + MAP_LIMITS.minX
    const worldY = (1 - (pctY / 100)) * rangeY + MAP_LIMITS.minY
    
    return { x: worldX, y: worldY }
  }

  // Notifica o client para fechar
  function closeMap() {
    fetch('https://fdb-mapmenu/closeMap', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    }).catch(() => {})
  }

  // Teclas de fechar
  function handleKeyDown(event) {
    if (event.key === 'Escape' || event.key === 'Backspace') {
      closeMap()
    }
  }

  let unsubscribeVisible;
  let unsubscribeCoords;
  let unsubscribeMarkers;

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown);

    // Subscreve às mudanças de visibilidade de forma determinística e imperativa
    unsubscribeVisible = visible.subscribe((isVisible) => {
      if (isVisible) {
        setTimeout(() => {
          if (!isMapInitialized) {
            initMap();
            // Primeiro carregamento dos marcadores customizados
            if ($markers) {
              updateCustomMarkers($markers);
            }
          } else if (map) {
            map.invalidateSize();
          }
          // Centraliza no jogador uma única vez ao abrir
          centerOnPlayer();
        }, 150);
      }
    });

    // Atualiza a posição do marcador do jogador em tempo real quando as coordenadas mudarem
    unsubscribeCoords = coords.subscribe((val) => {
      if (isMapInitialized && playerMarker && val) {
        const pct = worldToImage(val.x, val.y);
        playerMarker.setLatLng([-pct.y, pct.x]);
      }
    });

    // Atualiza os marcadores do Leaflet sempre que os marcadores da store mudarem
    unsubscribeMarkers = markers.subscribe((val) => {
      if (isMapInitialized && markersLayer && val) {
        updateCustomMarkers(val);
      }
    });
  });

  function initMap() {
    if (isMapInitialized || !mapElement) return;

    // Limites de coordenadas simples [lat, lng] correspondendo a [0, 0] a [-100, 100]
    const bounds = [[0, 0], [-100, 100]];

    // Inicializa o Leaflet com L.CRS.Simple para mapa plano
    map = L.map(mapElement, {
      crs: L.CRS.Simple,
      minZoom: 3.0,
      maxZoom: 8,
      zoomSnap: 0.1,
      zoomControl: false,
      attributionControl: false,
      dragging: true,
      scrollWheelZoom: true,
      doubleClickZoom: true,
      boxZoom: true
    });

    // Carrega os tiles locais WebP
    L.tileLayer('https://cfx-nui-fdb-mapmenu/tiles/{z}/{x}/{y}.webp', {
      minZoom: 2,
      maxZoom: 8,
      maxNativeZoom: 5,
      noWrap: true
    }).addTo(map);

    // Centro inicial do mapa (centralizado na área jogável do RDR2)
    map.setView([-58, 65], 3.0);

    // Ícone e marcador do jogador
    const playerIcon = L.divIcon({
      className: 'player-marker-leaflet',
      html: '<div class="pin"></div><div class="pulse"></div>',
      iconSize: [20, 20],
      iconAnchor: [10, 10]
    });
    playerMarker = L.marker([-50, 50], { icon: playerIcon }).addTo(map);

    // Camada para os marcadores customizados do diário
    markersLayer = L.layerGroup().addTo(map);

    // Escuta cliques no mapa para adicionar novos marcadores
    map.on('click', (e) => {
      const lat = e.latlng.lat;
      const lng = e.latlng.lng;
      
      const pctX = lng;
      const pctY = -lat;

      // Restringe cliques fora das bordas lógicas do mapa fatiado
      if (pctX < 0 || pctX > 100 || pctY < 0 || pctY > 100) return;

      const worldCoords = imageToWorld(pctX, pctY);
      
      const label = prompt("Nome do Marcador:", "Marcador");
      if (!label || label.trim() === "") return;

      fetch('https://fdb-mapmenu/addMarker', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          x: worldCoords.x,
          y: worldCoords.y,
          label: label
        })
      }).then(() => {
        markers.update(m => [...m, { x: worldCoords.x, y: worldCoords.y, label: label }]);
      }).catch(() => {});
    });

    isMapInitialized = true;
  }

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown);
    if (unsubscribeVisible) unsubscribeVisible();
    if (unsubscribeCoords) unsubscribeCoords();
    if (unsubscribeMarkers) unsubscribeMarkers();
    if (map) {
      map.remove();
    }
  });

  // Centraliza o mapa na posição do jogador com um nível de zoom fixo confortável
  function centerOnPlayer() {
    if (!isMapInitialized || !map || !$coords) return;
    const pct = worldToImage($coords.x, $coords.y);
    if (playerMarker) {
      playerMarker.setLatLng([-pct.y, pct.x]);
    }
    // Centraliza na coordenada do jogador a zoom level 3.5 ao abrir o mapa
    map.setView([-pct.y, pct.x], 3.5);
  }

  function updateCustomMarkers(markersList) {
    if (!isMapInitialized || !markersLayer || !markersList) return;
    markersLayer.clearLayers();
    markersList.forEach((marker) => {
      const pct = worldToImage(marker.x, marker.y);
      const markerIcon = L.divIcon({
        className: 'custom-marker-leaflet',
        html: '<div class="marker-pin"></div><span class="marker-label">' + marker.label + '</span>',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });
      L.marker([-pct.y, pct.x], { icon: markerIcon }).addTo(markersLayer);
    });
  }

  // Remove um marcador
  function removeMarker(index) {
    fetch('https://fdb-mapmenu/removeMarker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ index: index })
    }).then(() => {
      markers.update(m => {
        const newM = [...m]
        newM.splice(index, 1)
        return newM
      })
    }).catch(() => {})
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<div class="map-container" class:hidden={!$visible} on:click|self={closeMap}>
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <div class="map-wrapper">
    <!-- Div alvo do Leaflet -->
    <div id="leaflet-map" bind:this={mapElement}></div>
  </div>

  <!-- Caderno/Diário Lateral de Viagem (Escrita à mão) -->
  <div class="journal-sidebar">
    <h2 class="journal-title">Notas de Viagem</h2>
    <div class="markers-list">
      {#each $markers as marker, index}
        <div class="marker-item">
          <span class="marker-text">📍 {marker.label}</span>
          <button class="delete-btn" on:click={() => removeMarker(index)}>remover</button>
        </div>
      {:else}
        <p class="empty-text">Use o mapa para marcar locais importantes na sua jornada...</p>
      {/each}
    </div>
    <div class="journal-hint">
      Use o arraste para mover e o scroll para zoom.
    </div>
  </div>
  
  <!-- Dica de como fechar o mapa -->
  <div class="legend-box">
    <p>Clique no mapa para marcar | Pressione <strong>ESC</strong> para fechar</p>
  </div>
</div>

<style>
  @import url('https://fonts.googleapis.com/css2?family=Architects+Daughter&family=Cinzel:wght@400;700&display=swap');

  .map-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.82);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 99999;
  }

  .map-container.hidden {
    display: none !important;
  }

  .map-wrapper {
    position: relative;
    width: 68vw;
    height: 85vh;
    border: 5px solid #b89047;
    background: #d4c5a9;
    box-shadow: 0 10px 40px rgba(0,0,0,0.9);
    overflow: hidden;
    border-radius: 4px;
  }

  /* Camada de envelhecimento: Vinheta rústica, manchas de sujeira de época e dobras de papel simuladas */
  .map-wrapper::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none; /* Cliques passam direto para o Leaflet */
    z-index: 999; /* Acima dos tiles do mapa */
    box-shadow: inset 0 0 100px rgba(45, 28, 10, 0.75); /* Vinheta marrom/queimada nas bordas */
    background: 
      /* Dobras envelhecidas (horizontal e vertical no centro) */
      linear-gradient(to bottom, transparent 49.7%, rgba(45,28,10,0.2) 50%, rgba(255,255,255,0.08) 50.3%, transparent 51%),
      linear-gradient(to right, transparent 49.7%, rgba(45,28,10,0.2) 50%, rgba(255,255,255,0.08) 50.3%, transparent 51%),
      /* Manchas de terra e desgaste */
      radial-gradient(circle at 15% 25%, rgba(90, 60, 25, 0.22) 0%, transparent 35%),
      radial-gradient(circle at 85% 75%, rgba(90, 60, 25, 0.18) 0%, transparent 40%),
      radial-gradient(circle at 45% 85%, rgba(70, 45, 20, 0.15) 0%, transparent 30%);
    mix-blend-mode: multiply; /* Mescla as cores perfeitamente com os tiles do mapa */
  }

  #leaflet-map {
    width: 100%;
    height: 100%;
    background: #d4c5a9;
  }

  /* Remove linhas brancas de sub-pixel entre as fatias do mapa no Chrome/CEF */
  :global(.leaflet-tile) {
    margin: -0.5px;
    outline: 1px solid transparent;
  }

  /* Envelhece e melhora a tonalidade de pergaminho antigo do mapa */
  :global(.leaflet-tile-pane) {
    filter: sepia(65%) contrast(110%) brightness(90%) saturate(75%);
  }

  /* Customizando a mão do Leaflet no mapa */
  :global(.leaflet-grab) {
    cursor: grab !important;
  }
  :global(.leaflet-dragging .leaflet-grab) {
    cursor: grabbing !important;
  }

  /* Estilos do Marcador do Jogador no Leaflet */
  :global(.player-marker-leaflet) {
    position: relative;
  }
  :global(.player-marker-leaflet .pin) {
    width: 12px;
    height: 12px;
    background-color: #ef4444;
    border: 2px solid #fff;
    border-radius: 50%;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
  }
  :global(.player-marker-leaflet .pulse) {
    position: absolute;
    top: -4px;
    left: -4px;
    width: 16px;
    height: 16px;
    border: 2px solid #ef4444;
    border-radius: 50%;
    animation: marker-pulse 1.8s infinite ease-out;
    opacity: 0;
  }

  @keyframes marker-pulse {
    0% { transform: scale(0.6); opacity: 0.8; }
    100% { transform: scale(2.2); opacity: 0; }
  }

  /* Marcadores Customizados no Leaflet */
  :global(.custom-marker-leaflet) {
    position: relative;
  }
  :global(.custom-marker-leaflet .marker-pin) {
    width: 10px;
    height: 10px;
    background-color: #5c3f15;
    border: 2px solid #fff;
    border-radius: 50%;
    box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  }
  :global(.custom-marker-leaflet .marker-label) {
    position: absolute;
    top: 12px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(14, 10, 7, 0.85);
    color: #e5c185;
    font-family: 'Architects Daughter', cursive;
    font-size: 0.8rem;
    padding: 2px 6px;
    border-radius: 3px;
    border: 1px solid #b89047;
    white-space: nowrap;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    pointer-events: none;
  }

  /* Caderno/Diário de Viagem Lateral */
  .journal-sidebar {
    width: 22vw;
    height: 85vh;
    margin-left: 1.5vw;
    background: #e9dec4; /* Cor de pergaminho antigo */
    border: 3px solid #6b512c;
    border-radius: 6px;
    box-shadow: 5px 10px 30px rgba(0,0,0,0.6);
    padding: 24px;
    display: flex;
    flex-direction: column;
    font-family: 'Architects Daughter', cursive;
    color: #3b2c15;
    background-image: radial-gradient(circle, rgba(255,255,255,0.15) 0%, rgba(0,0,0,0.05) 100%);
  }

  .journal-title {
    font-size: 1.8rem;
    text-align: center;
    margin-bottom: 20px;
    border-bottom: 2px solid #8c7355;
    padding-bottom: 8px;
    text-shadow: 1px 1px 1px rgba(255,255,255,0.6);
  }

  .markers-list {
    flex: 1;
    overflow-y: auto;
    margin-bottom: 15px;
    padding-right: 5px;
  }

  /* Custom Scrollbar para o caderno */
  .markers-list::-webkit-scrollbar {
    width: 4px;
  }
  .markers-list::-webkit-scrollbar-thumb {
    background: #8c7355;
    border-radius: 2px;
  }

  .marker-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 0;
    border-bottom: 1px dashed #bda78a;
  }

  .marker-text {
    font-size: 1.15rem;
    max-width: 70%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .delete-btn {
    background: transparent;
    border: none;
    color: #8a3324;
    font-family: 'Architects Daughter', cursive;
    font-size: 1rem;
    cursor: pointer;
    text-decoration: underline;
    transition: color 0.2s;
  }

  .delete-btn:hover {
    color: #ef4444;
  }

  .empty-text {
    font-size: 1.05rem;
    color: #6b5b44;
    text-align: center;
    margin-top: 40px;
    line-height: 1.4;
  }

  .journal-hint {
    font-size: 0.85rem;
    color: #7a6850;
    border-top: 1px solid #8c7355;
    padding-top: 10px;
    text-align: center;
  }

  /* Dica de tecla */
  .legend-box {
    position: absolute;
    bottom: 3vh;
    background: rgba(14, 10, 7, 0.95);
    border: 2px solid #b89047;
    color: #e5c185;
    padding: 8px 16px;
    font-size: 0.9rem;
    border-radius: 4px;
    box-shadow: 0 4px 10px rgba(0,0,0,0.5);
    pointer-events: none;
    font-family: 'Cinzel', serif;
  }
</style>
