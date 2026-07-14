<script>
  import { onMount, onDestroy } from 'svelte'
  import { visible, coords, markers } from '../../stores/mapStore.js'
  import mapImg from '../../assets/map.webp'

  // Limites de coordenadas do RedM mapeando as bordas do map.svg
  const MAP_LIMITS = {
    minX: -6000,
    maxX: 6000,
    minY: -6000,
    maxY: 6000
  }

  // Controle de Zoom e Pan (Arrastar)
  let zoom = 1.0
  let panX = 0
  let panY = 0
  let isDragging = false
  let startX = 0
  let startY = 0
  let wrapperWidth = 0
  let wrapperHeight = 0

  // Converte coordenadas mundo -> imagem
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

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown)
    window.addEventListener('wheel', handleWheel, { passive: false })
  })

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown)
    window.removeEventListener('wheel', handleWheel)
  })

  // Wheel Zoom
  function handleWheel(event) {
    if (!$visible) return
    event.preventDefault()
    const zoomFactor = 0.15
    if (event.deltaY < 0) {
      zoom = Math.min(5.0, zoom + zoomFactor)
    } else {
      zoom = Math.max(1.0, zoom - zoomFactor)
      if (zoom === 1.0) {
        panX = 0
        panY = 0
      }
    }
  }

  // Início do Arraste
  function handleMouseDown(event) {
    if (event.button !== 0) return // Apenas botão esquerdo
    event.preventDefault() // Impede comportamento padrão de arrasto de imagem / seleção
    isDragging = true
    startX = event.clientX - panX
    startY = event.clientY - panY
    window.addEventListener('mousemove', handleMouseMove)
    window.addEventListener('mouseup', handleMouseUp)
  }

  // Movimento de Arraste
  function handleMouseMove(event) {
    if (!isDragging) return
    panX = event.clientX - startX
    panY = event.clientY - startY
  }

  // Fim do Arraste
  function handleMouseUp() {
    isDragging = false
    window.removeEventListener('mousemove', handleMouseMove)
    window.removeEventListener('mouseup', handleMouseUp)
  }

  // Trata clique no mapa para adicionar marcador
  function handleMapClick(event) {
    // Se arrastou o mapa mais do que 8px, cancela clique
    const dragDist = Math.sqrt(Math.pow(event.clientX - (startX + panX), 2) + Math.pow(event.clientY - (startY + panY), 2))
    if (dragDist > 8) return

    const rect = event.currentTarget.getBoundingClientRect()
    const clickX = event.clientX - rect.left
    const clickY = event.clientY - rect.top
    
    // Origem do zoom é o centro do wrapper
    const centerX = rect.width / 2
    const centerY = rect.height / 2
    
    // Inverte a transformação para saber a posição original
    const contentX = (clickX - centerX - panX) / zoom + centerX
    const contentY = (clickY - centerY - panY) / zoom + centerY
    
    const pctX = (contentX / rect.width) * 100
    const pctY = (contentY / rect.height) * 100
    
    if (pctX < 0 || pctX > 100 || pctY < 0 || pctY > 100) return
    
    const worldCoords = imageToWorld(pctX, pctY)
    
    // Solicita nome ao jogador
    const label = prompt("Nome do Marcador:", "Marcador")
    if (!label || label.trim() === "") return
    
    fetch('https://fdb-mapmenu/addMarker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        x: worldCoords.x,
        y: worldCoords.y,
        label: label
      })
    }).then(() => {
      markers.update(m => [...m, { x: worldCoords.x, y: worldCoords.y, label: label }])
    }).catch(() => {})
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

  // Evita cache persistente do CEF do RedM para arquivos grandes como o SVG do mapa
  const CACHE_BUSTER = "?v=" + Math.random().toString(36).substring(7)

  // Atributos de estilo do marcador do jogador
  let playerPos = { x: 50, y: 50 }
  
  // Reage a mudancas de coordenadas para recalcular a posicao do marcador
  $: if ($visible && $coords) {
    playerPos = worldToImage($coords.x, $coords.y)
  }
</script>

{#if $visible}
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <div class="map-container" class:dragging={isDragging} on:click|self={closeMap}>
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <div class="map-wrapper" 
         bind:clientWidth={wrapperWidth}
         bind:clientHeight={wrapperHeight}
         on:click={handleMapClick}
         on:mousedown={handleMouseDown}>
      
      <!-- Conteúdo do mapa com escala e translação aplicados -->
      <div class="map-content" style="transform: scale({zoom}) translate({panX / zoom}px, {panY / zoom}px);">
        <!-- Imagem de fundo do mapa -->
        <img src={mapImg + CACHE_BUSTER} class="map-image" alt="Mapa de Papel RDR2" draggable="false" />
        
        <!-- Marcadores personalizados -->
        {#each $markers as marker}
          {@const pos = worldToImage(marker.x, marker.y)}
          <div class="custom-marker" style:left="{pos.x}%" style:top="{pos.y}%" title={marker.label}>
            <div class="marker-pin"></div>
            <span class="marker-label">{marker.label}</span>
          </div>
        {/each}

        <!-- Marcador do Jogador ("Você está aqui") -->
        <div class="player-marker" style:left="{playerPos.x}%" style:top="{playerPos.y}%">
          <div class="pin"></div>
          <div class="pulse"></div>
        </div>
      </div>
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
        Use o scroll do mouse para Zoom e arraste para navegar.
      </div>
    </div>
    
    <!-- Dica de como fechar o mapa -->
    <div class="legend-box">
      <p>Clique no mapa para marcar | Pressione <strong>ESC</strong> para fechar</p>
    </div>
  </div>
{/if}

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

  /* Estado arrastando força cursor de mão fechada */
  .map-container.dragging {
    cursor: grabbing !important;
    user-select: none;
  }

  .map-container.dragging .map-wrapper {
    cursor: grabbing !important;
  }

  /* Novo layout retangular ocupando quase toda a tela lateralmente */
  .map-wrapper {
    position: relative;
    width: 68vw;
    height: 85vh;
    border: 5px solid #b89047;
    background: #0e0a07;
    box-shadow: 0 10px 40px rgba(0,0,0,0.9);
    overflow: hidden;
    border-radius: 4px;
    cursor: grab;
  }

  .map-content {
    width: 100%;
    height: 100%;
    position: relative;
    transform-origin: center;
    pointer-events: none;
    transition: transform 0.05s ease-out;
  }

  .map-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    opacity: 0.9;
    user-select: none;
    -webkit-user-drag: none;
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

  /* Marcadores personalizados */
  .custom-marker {
    position: absolute;
    width: 12px;
    height: 12px;
    transform: translate(-50%, -50%);
    z-index: 90;
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
    position: absolute;
    width: 16px;
    height: 16px;
    transform: translate(-50%, -50%);
    z-index: 100;
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
  }
</style>
