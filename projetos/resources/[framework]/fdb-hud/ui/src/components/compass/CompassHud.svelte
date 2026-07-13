<script>
  import { compass } from '../../stores/hudStore.js'
  import compassImg from '../../assets/compass_hud.svg'
</script>

{#if $compass.visible}
<div class="compass-wrap" role="region" aria-label="Bússola {$compass.degrees}°">
  <!-- Máscara circular de 120px -->
  <div class="compass-mask">
    
    <!-- Mostrador giratório com tag img nativa para garantir exibição correta e sem fundo preto -->
    <div class="compass-dial" style="transform: rotate(-{$compass.degrees}deg);">
      <img src={compassImg} class="dial-image" alt="Mostrador da Bússola" />
    </div>

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
    gap: 6px;
    pointer-events: none;
    font-family: 'Cinzel', 'Times New Roman', serif;
  }

  /* Aumentado de 80px para 120px para melhor visibilidade */
  .compass-mask {
    position: relative;
    width: 120px;
    height: 120px;
    border-radius: 50%;
    overflow: hidden;
    border: 3px solid #b89047;
    box-shadow: 
      0 4px 12px rgba(0,0,0,0.85),
      inset 0 0 15px rgba(0,0,0,0.95),
      0 0 6px rgba(184, 144, 71, 0.45);
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
  }

  /* Dial giratório */
  .compass-dial {
    position: absolute;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    /* Transição de rotação linear e suave */
    transition: transform 0.15s linear;
  }

  /* Imagem do mostrador */
  .dial-image {
    width: 100%;
    height: 100%;
    object-fit: contain;
    pointer-events: none;
  }

  /* Marcador fixo de topo */
  .needle {
    position: absolute;
    top: 3px;
    left: calc(50% - 6px);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-top: 10px solid #ef4444; /* Vermelho destacado */
    z-index: 5;
    filter: drop-shadow(0 1px 3px rgba(0,0,0,0.8));
  }

  .glass-reflection {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0) 60%, rgba(0,0,0,0.4) 100%);
    pointer-events: none;
    z-index: 10;
  }

  .heading-label {
    font-size: 0.75rem;
    color: #e5c185;
    font-weight: bold;
    letter-spacing: 1.5px;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.9);
  }
</style>
