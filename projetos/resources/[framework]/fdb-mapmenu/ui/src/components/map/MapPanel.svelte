<script>
  import { onMount, onDestroy } from 'svelte'
  import { visible, coords, markers } from '../../stores/mapStore.js'
  import L from 'leaflet'
  import 'leaflet/dist/leaflet.css'

  // Limites de coordenadas do RedM (RDR2 World Limits)
  const MAP_LIMITS = {
    minX: -6000,
    maxX: 6000,
    minY: -6000,
    maxY: 6000
  }

  // Definição dos limites em pixels no Leaflet CRS.Simple (zoom 0 = 256x256)
  const bounds = [[-256, 0], [0, 256]]

  let mapContainer
  let leafletMap
  let playerMarker
  let leafletCustomMarkers = []

  // Converte coordenadas do RedM (Vector3) para LatLng do Leaflet
  function gameToLatLng(x, y) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY
    
    // Eixo X (Longitude) -> Mapeia [-6000, 6000] para [0, 256]
    const lng = ((x - MAP_LIMITS.minX) / rangeX) * 256
    
    // Eixo Y (Latitude) -> Mapeia [-6000, 6000] para [-256, 0] (Invertido)
    const lat = ((y - MAP_LIMITS.maxY) / rangeY) * -256
    
    return L.latLng(lat, lng)
  }

  // Converte LatLng do Leaflet de volta para coordenadas do RedM
  function latLngToGame(latlng) {
    const rangeX = MAP_LIMITS.maxX - MAP_LIMITS.minX
    const rangeY = MAP_LIMITS.maxY - MAP_LIMITS.minY
    
    const x = (latlng.lng / 256) * rangeX + MAP_LIMITS.minX
    const y = (latlng.lat / -256) * rangeY + MAP_LIMITS.maxY
    
    return { x: x, y: y }
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

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown)

    // Inicializa o mapa com Leaflet
    leafletMap = L.map(mapContainer, {
      crs: L.CRS.Simple,
      minZoom: 0,
      maxZoom: 5,
      zoomControl: true,
      attributionControl: false,
      maxBounds: bounds,
      maxBoundsViscosity: 1.0
    })

    // Adiciona o tileset local de WebP
    L.tileLayer('../../tiles/{z}/{x}/{y}.webp', {
      tileSize: 256,
      noWrap: true,
      bounds: bounds
    }).addTo(leafletMap)

    // Evento de clique para adicionar marcador personalizado
    leafletMap.on('click', (e) => {
      const worldCoords = latLngToGame(e.latlng)
      
      const label = prompt("Nome do Marcador:", "Marcador")
      if (!label || label.trim() === "") return
      
      fetch('https://fdb-mapmenu/addMarker', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          x: worldCoords.x,
          y: worldCoords.y,
          label: label.trim()
        })
      }).then(() => {
        markers.update(m => [...m, { x: worldCoords.x, y: worldCoords.y, label: label.trim() }])
      }).catch(() => {})
    })
  })

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown)
    if (leafletMap) {
      leafletMap.remove()
    }
  })

  // Reage à mudança de visibilidade para recalcular tamanho e focar
  $: if ($visible && leafletMap) {
    setTimeout(() => {
      leafletMap.invalidateSize()
      if ($coords) {
        leafletMap.setView(gameToLatLng($coords.x, $coords.y), 3)
      } else {
        leafletMap.setView([-128, 128], 1)
      }
    }, 50)
  }

  // Sincroniza o marcador do jogador
  $: if (leafletMap && $coords) {
    const latlng = gameToLatLng($coords.x, $coords.y)
    if (!playerMarker) {
      const playerIcon = L.divIcon({
        className: 'custom-player-icon',
        html: '<div class="player-marker"><div class="pin"></div><div class="pulse"></div></div>',
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      })
      playerMarker = L.marker(latlng, { icon: playerIcon }).addTo(leafletMap)
    } else {
      playerMarker.setLatLng(latlng)
    }
  }

  // Sincroniza os marcadores salvos
  $: if (leafletMap && $markers) {
    // Limpa os blips anteriores
    leafletCustomMarkers.forEach(m => m.remove())
    leafletCustomMarkers = []

    // Adiciona os blips ativos
    $markers.forEach((marker, index) => {
      const latlng = gameToLatLng(marker.x, marker.y)
      const customIcon = L.divIcon({
        className: 'custom-pin-icon',
        html: `<div class="custom-marker"><div class="marker-pin"></div><span class="marker-label">${marker.label}</span></div>`,
        iconSize: [12, 12],
        iconAnchor: [6, 6]
      })
      const mapMarker = L.marker(latlng, { icon: customIcon }).addTo(leafletMap)
      leafletCustomMarkers.push(mapMarker)
    })
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

  // Foca a câmera do mapa em um marcador específico
  function focusMarker(marker) {
    if (leafletMap) {
      leafletMap.setView(gameToLatLng(marker.x, marker.y), 4)
    }
  }
</script>

<div class="map-container" class:visible={$visible} on:click|self={closeMap}>
  <div class="map-wrapper" bind:this={mapContainer}></div>

  <!-- Caderno/Diário Lateral de Viagem (Escrita à mão) -->
  <div class="journal-sidebar">
    <h2 class="journal-title">Notas de Viagem</h2>
    <div class="markers-list">
      {#each $markers as marker, index}
        <div class="marker-item">
          <!-- svelte-ignore a11y-click-events-have-key-events -->
          <span class="marker-text" on:click={() => focusMarker(marker)}>📍 {marker.label}</span>
          <button class="delete-btn" on:click={() => removeMarker(index)}>remover</button>
        </div>
      {:else}
        <p class="empty-text">Use o mapa para marcar locais importantes na sua jornada...</p>
      {/each}
    </div>
    <div class="journal-hint">
      Use o scroll do mouse para Zoom e arraste para navegar.
    </div>
  </div>
  
  <!-- Dica de como fechar o mapa -->
  <div class="legend-box">
    <p>Clique no mapa para marcar | Pressione <strong>ESC</strong> para fechar</p>
  </div>
</div>

<style>
  @import url('https://fonts.googleapis.com/css2?family=Architects+Daughter&family=Cinzel:wght@400;700&display=swap');

  /* Leaflet reset and containers */
  :global(.leaflet-container) {
    background: #0e0a07 !important;
    outline: 0;
  }

  /* Sobrescreve botões de zoom do Leaflet para combinarem com o tema vintage */
  :global(.leaflet-bar) {
    border: 2px solid #b89047 !important;
    box-shadow: 0 4px 10px rgba(0,0,0,0.5) !important;
  }
  :global(.leaflet-bar a) {
    background-color: #1a120b !important;
    color: #e5c185 !important;
    border-bottom: 1px solid #6b512c !important;
    transition: background 0.2s;
  }
  :global(.leaflet-bar a:hover) {
    background-color: #2c1e12 !important;
    color: #fff !important;
  }

  .map-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.82);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 99999;
  }

  .map-container.visible {
    display: flex;
  }

  /* Novo layout retangular ocupando quase toda a tela lateralmente */
  .map-wrapper {
    position: relative;
    width: 68vw;
    height: 85vh;
    border: 5px solid #b89047;
    background: #0e0a07;
    box-shadow: 0 10px 40px rgba(0,0,0,0.9);
    border-radius: 4px;
    z-index: 10;
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
    z-index: 20;
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
    cursor: pointer;
    transition: color 0.15s;
  }
  .marker-text:hover {
    color: #8c7355;
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

  /* Marcadores personalizados */
  .custom-marker {
    position: relative;
    width: 12px;
    height: 12px;
  }

  .marker-pin {
    width: 8px;
    height: 8px;
    background: #5c3f15;
    border: 2px solid #fff;
    border-radius: 50%;
    box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  }

  .marker-label {
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
    white-space: nowrap;
    border: 1px solid #b89047;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
  }

  /* Marcador do jogador */
  .player-marker {
    position: relative;
    width: 16px;
    height: 16px;
  }

  .pin {
    width: 10px;
    height: 10px;
    background: #ef4444;
    border: 2px solid #fff;
    border-radius: 50%;
    box-shadow: 0 2px 4px rgba(0,0,0,0.5);
  }

  .pulse {
    position: absolute;
    top: -4px;
    left: -4px;
    width: 18px;
    height: 18px;
    border: 2px solid #ef4444;
    border-radius: 50%;
    animation: pulse 1.8s infinite ease-out;
    opacity: 0;
  }

  @keyframes pulse {
    0% { transform: scale(0.6); opacity: 0.8; }
    100% { transform: scale(2.2); opacity: 0; }
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
    z-index: 30;
  }
</style>
