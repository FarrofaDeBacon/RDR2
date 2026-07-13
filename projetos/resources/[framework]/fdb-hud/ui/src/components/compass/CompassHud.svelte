<script>
  import { compass } from '../../stores/hudStore.js'
</script>

{#if $compass.visible}
<div class="compass-wrap" role="region" aria-label="Bússola {$compass.degrees}°">
  <!-- Aro externo / Mascara circular para esconder a argola de cima e os pinos laterais -->
  <div class="compass-mask">
    
    <!-- Mostrador giratório que utiliza a imagem real da bussola de ouro -->
    <!-- Rotaciona de forma contraria ao heading para manter o norte correto -->
    <div 
      class="compass-dial" 
      style="transform: rotate(-{$compass.degrees}deg); background-image: url('images/hud_compass.png');"
    ></div>

    <!-- Indicador de topo fixo (agulha/marcador) -->
    <div class="needle" aria-hidden="true"></div>
    
    <!-- Sombra interna / Brilho do vidro -->
    <div class="glass-reflection"></div>
  </div>

  <div class="heading-label" aria-hidden="true">
    {$compass.cardinal ?? ''} {$compass.degrees}°
  </div>
</div>
{/if}

<style>
  .compass-wrap {
    position: absolute;
    bottom: 2vh;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    pointer-events: none;
    font-family: 'Cinzel', 'Times New Roman', serif;
  }

  /* Máscara circular para extrair apenas a parte redonda da imagem */
  .compass-mask {
    position: relative;
    width: 80px;
    height: 80px;
    border-radius: 50%;
    overflow: hidden;
    /* Borda dourada em tom de latão para combinar com o estilo */
    border: 2px solid #b89047;
    box-shadow: 
      0 4px 10px rgba(0,0,0,0.8),
      inset 0 0 10px rgba(0,0,0,0.9),
      0 0 4px rgba(184, 144, 71, 0.4);
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
  }

  /* Dial giratório */
  .compass-dial {
    position: absolute;
    width: 104px; /* Ligeiramente maior para esticar a imagem e cortar os pinos externos */
    height: 104px;
    border-radius: 50%;
    background-size: contain;
    background-position: center;
    background-repeat: no-repeat;
    /* Transição de rotação linear e suave */
    transition: transform 0.15s linear;
  }

  /* Marcador fixo no Topo (Norte) */
  .needle {
    position: absolute;
    top: 2px;
    left: calc(50% - 4px);
    width: 0;
    height: 0;
    border-left: 4px solid transparent;
    border-right: 4px solid transparent;
    border-top: 7px solid #f59e0b; /* Amarelo/Laranja rustico */
    z-index: 5;
    filter: drop-shadow(0 1px 2px rgba(0,0,0,0.8));
  }

  /* Efeito de Reflexo no Vidro */
  .glass-reflection {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 60%, rgba(0,0,0,0.3) 100%);
    pointer-events: none;
    z-index: 10;
  }

  .heading-label {
    font-size: 0.65rem;
    color: #e5c185;
    font-weight: bold;
    letter-spacing: 1px;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.9);
  }
</style>
