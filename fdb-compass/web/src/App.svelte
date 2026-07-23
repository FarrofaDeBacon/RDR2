<script>
  import { onMount, onDestroy } from 'svelte'
  import roseImg from './assets/rose.svg'

  // Referência do elemento DOM da imagem para atualizar diretamente o transform (60 FPS)
  let roseEl = null
  
  let visible = false
  let displayHeading = 0
  let displayCardinal = 'N'

  // Variaveis de controle da interpolacao
  let currentHeading = 0
  let targetHeading = 0
  let animationFrameId

  // Direções cardinais nativas do RDR2
  const CARDINAL_NAMES = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
  
  function getCardinalDirection(degrees) {
    const index = Math.floor((degrees + 22.5) / 45) % 8
    return CARDINAL_NAMES[index]
  }

  // Loop de animacao a 60 FPS com requestAnimationFrame
  function updateLoop() {
    // Calcula a menor distancia angular (considera wrap de 360 graus)
    let diff = targetHeading - currentHeading
    diff = ((diff + 180) % 360 + 360) % 360 - 180

    // Interpola suavemente (fator 0.12 para transicao suave e sem saltos)
    if (Math.abs(diff) > 0.01) {
      currentHeading = currentHeading + diff * 0.12
      // Mantem 0-359
      currentHeading = (currentHeading % 360 + 360) % 360
    } else {
      currentHeading = targetHeading
    }

    // Atualiza diretamente o transform no DOM (otimizacao maxima de performance)
    if (roseEl) {
      roseEl.style.transform = `rotate(${-currentHeading}deg)`
    }

    // Atualiza estados reativos apenas quando o valor mudar (reduz re-renderizacoes)
    const rounded = Math.floor(currentHeading)
    if (rounded !== displayHeading) {
      displayHeading = rounded
      displayCardinal = getCardinalDirection(rounded)
    }

    animationFrameId = requestAnimationFrame(updateLoop)
  }

  const handleMessage = (event) => {
    const data = event.data
    if (data.action === 'updateCompass') {
      targetHeading = data.degrees
      visible = data.visible
    }
  }

  onMount(() => {
    window.addEventListener('message', handleMessage)
    currentHeading = targetHeading
    animationFrameId = requestAnimationFrame(updateLoop)
  })

  onDestroy(() => {
    window.removeEventListener('message', handleMessage)
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId)
    }
  })
</script>

{#if visible}
<div class="compass-container">
  <div class="compass">
    <img 
      bind:this={roseEl} 
      src={roseImg} 
      class="rose" 
      alt="Rose"
    />
    <div class="pointer"></div>
  </div>
  <div class="heading">
    {displayCardinal} {displayHeading}°
  </div>
</div>
{/if}

<style>
  .compass-container {
    position: absolute;
    bottom: 2vh;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    pointer-events: none;
    font-family: 'Cinzel', 'Times New Roman', serif;
  }

  .compass {
    position: relative;
    width: 130px;
    height: 130px;
    border-radius: 50%;
    overflow: hidden;
    border: 3px solid #b89047;
    box-shadow: 
      0 4px 15px rgba(0,0,0,0.85),
      inset 0 0 15px rgba(0,0,0,0.95);
    background: #0d0905;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .rose {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transform-origin: center center;
    will-change: transform;
    pointer-events: none;
    transition: none !important;
  }

  .pointer {
    position: absolute;
    top: 4px;
    left: calc(50% - 6px);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-top: 10px solid #ef4444;
    z-index: 10;
    filter: drop-shadow(0 1px 2px rgba(0,0,0,0.8));
    pointer-events: none;
  }

  .heading {
    font-size: 0.85rem;
    font-weight: 700;
    color: #e5c185;
    letter-spacing: 1px;
    text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.95);
  }
</style>
