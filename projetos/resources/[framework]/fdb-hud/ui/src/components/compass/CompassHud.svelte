<script>
  import { onMount, onDestroy } from 'svelte'
  import { compass } from '../../stores/hudStore.js'
  import roseImg from '../../assets/rose.svg'

  // Referência do elemento DOM da imagem para atualizar diretamente o transform (60 FPS)
  let roseEl = null
  
  // Estado local para o texto do heading
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

  // Ouve atualizacoes da store do compass
  const unsubscribe = compass.subscribe(($c) => {
    if ($c && $c.degrees !== undefined) {
      targetHeading = $c.degrees
    }
  })

  onMount(() => {
    // Inicializa variaveis
    currentHeading = targetHeading
    
    // Inicia loop requestAnimationFrame
    animationFrameId = requestAnimationFrame(updateLoop)
  })

  onDestroy(() => {
    // Limpa a store e o frame de animacao ao destruir o componente
    unsubscribe()
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId)
    }
  })
</script>

{#if $compass.visible}
<div class="compass-container">
  <div class="compass">
    <!-- Imagem da rosa dos ventos que rotaciona via requestAnimationFrame -->
    <img 
      bind:this={roseEl} 
      src={roseImg} 
      class="rose" 
      alt="Rose"
    />
    
    <!-- Ponteiro de topo fixo (Triângulo vermelho) -->
    <div class="pointer"></div>
  </div>

  <!-- Texto com direcao cardinal e graus logo abaixo -->
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

  /* Estrutura HTML solicitada */
  .compass {
    position: relative;
    width: 130px;
    height: 130px;
    border-radius: 50%;
    overflow: hidden;
    /* Aro sutil e sombra projetada */
    border: 3px solid #b89047;
    box-shadow: 
      0 4px 15px rgba(0,0,0,0.85),
      inset 0 0 15px rgba(0,0,0,0.95);
    background: #0d0905;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* Rosa dos ventos (will-change ativo para aceleracao por GPU) */
  .rose {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transform-origin: center center;
    will-change: transform;
    pointer-events: none;
    /* Transicoes desativadas para a animacao rodar exclusivamente pelo RAF */
    transition: none !important;
  }

  /* Ponteiro do topo fixo (Triangulo Vermelho) */
  .pointer {
    position: absolute;
    top: 4px;
    left: calc(50% - 6px);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-top: 10px solid #ef4444; /* Vermelho RDR2 */
    z-index: 10;
    filter: drop-shadow(0 1px 2px rgba(0,0,0,0.8));
    pointer-events: none;
  }

  /* Texto com cardinal e graus */
  .heading {
    font-size: 0.85rem;
    font-weight: 700;
    color: #e5c185; /* Latão envelhecido */
    letter-spacing: 1px;
    text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.95);
  }
</style>
