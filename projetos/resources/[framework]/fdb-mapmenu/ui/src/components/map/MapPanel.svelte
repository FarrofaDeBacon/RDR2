<script>
  import { onMount, onDestroy } from 'svelte'
  import { visible, coords } from '../../stores/mapStore.js'
  import mapImg from '../../assets/map.svg'

  // Limites de coordenadas do RedM mapeando as bordas do map.svg
  const MAP_LIMITS = {
    minX: -6000,
    maxX: 6000,
    minY: -6000,
    maxY: 6000
  }

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

  // Notifica o client para fechar
  function closeMap() {
    fetch('https://fdb-mapmenu/closeMap', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    }).catch(() => {})
  }

  // Atributos de estilo do marcador do jogador
  let playerPos = { x: 50, y: 50 }
  
  // Reage a mudancas de coordenadas para recalcular a posicao do marcador
  $: if ($visible && $coords) {
    playerPos = worldToImage($coords.x, $coords.y)
  }
</script>

{#if $visible}
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <div class="map-container" on:click|self={closeMap}>
    <div class="map-wrapper">
      <!-- Imagem de fundo do mapa -->
      <img src={mapImg} class="map-image" alt="Mapa de Papel RDR2" />
      
      <!-- Marcador do Jogador ("Você está aqui") -->
      <div class="player-marker" style:left="{playerPos.x}%" style:top="{playerPos.y}%">
        <div class="pin"></div>
        <div class="pulse"></div>
      </div>
    </div>
    
    <!-- Dica de como fechar o mapa -->
    <div class="legend-box">
      <p>Pressione <strong>ESC</strong> ou clique fora para fechar</p>
    </div>
  </div>
{/if}

<style>
  .map-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.75);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 99999;
  }

  .map-wrapper {
    position: relative;
    width: 85vh;
    height: 85vh;
    border: 5px solid #b89047;
    background: #0e0a07;
    box-shadow: 0 10px 30px rgba(0,0,0,0.85);
    overflow: hidden;
    border-radius: 4px;
  }

  .map-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    opacity: 0.85;
    pointer-events: none;
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
    bottom: 4vh;
    background: rgba(14, 10, 7, 0.9);
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
