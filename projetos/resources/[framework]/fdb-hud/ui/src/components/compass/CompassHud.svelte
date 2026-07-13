<script>
  import { compass } from '../../stores/hudStore.js'
  import compassImg from '../../assets/hud_compass.png'
</script>

{#if $compass.visible}
<div class="compass-wrap" role="region" aria-label="Bússola {$compass.degrees}°">
  <!-- Máscara circular perfeita -->
  <div class="compass-mask">
    
    <!-- Mostrador giratório com a imagem enviada pelo usuario -->
    <!-- Rotação negativa em relação ao heading para manter a direcao -->
    <div 
      class="compass-dial" 
      style="transform: rotate(-{$compass.degrees}deg); background-image: url('{compassImg}');"
    ></div>

    <!-- Indicador fixo de Norte no topo -->
    <div class="needle" aria-hidden="true"></div>
    
    <!-- Reflexo suave de vidro -->
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

  .compass-mask {
    position: relative;
    width: 80px;
    height: 80px;
    border-radius: 50%;
    overflow: hidden;
    border: 2px solid #b89047;
    box-shadow: 
      0 4px 10px rgba(0,0,0,0.85),
      inset 0 0 10px rgba(0,0,0,0.9),
      0 0 4px rgba(184, 144, 71, 0.4);
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
  }

  /* Mostrador giratório */
  .compass-dial {
    position: absolute;
    /* Zoom de 118% para ampliar a face bege central e esconder as alças de metal e argola externa da imagem */
    width: 118%;
    height: 118%;
    border-radius: 50%;
    background-size: contain;
    background-position: center;
    background-repeat: no-repeat;
    /* Rotação suave */
    transition: transform 0.15s linear;
  }

  /* Marcador fixo de topo */
  .needle {
    position: absolute;
    top: 2px;
    left: calc(50% - 4px);
    width: 0;
    height: 0;
    border-left: 4px solid transparent;
    border-right: 4px solid transparent;
    border-top: 7px solid #f59e0b;
    z-index: 5;
    filter: drop-shadow(0 1px 2px rgba(0,0,0,0.8));
  }

  .glass-reflection {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0) 60%, rgba(0,0,0,0.35) 100%);
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
