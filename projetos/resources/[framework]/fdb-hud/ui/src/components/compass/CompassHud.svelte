<script>
  import { compass } from '../../stores/hudStore.js'
</script>

{#if $compass.visible}
<div class="compass-wrap" role="region" aria-label="Bússola {$compass.degrees}°">
  <!-- Caixa externa / Aro de latão envelhecido -->
  <div class="compass-ring">
    
    <!-- Face interna da bússola que rotaciona de acordo com os graus -->
    <!-- Rotação negativa do heading para manter o norte fixo no topo -->
    <div class="compass-dial" style="transform: rotate(-{$compass.degrees}deg);">
      <div class="cardinal n">N</div>
      <div class="cardinal l">L</div>
      <div class="cardinal s">S</div>
      <div class="cardinal o">O</div>
      
      <!-- Linhas de ticks auxiliares -->
      <div class="tick-line t-45"></div>
      <div class="tick-line t-135"></div>
      <div class="tick-line t-225"></div>
      <div class="tick-line t-315"></div>
    </div>
    
    <!-- Vidro / Sombra interna -->
    <div class="glass-reflection"></div>
    
    <!-- Ponteiro central fixo (aponta sempre para o Norte) -->
    <div class="needle" aria-hidden="true"></div>
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

  .compass-ring {
    position: relative;
    width: 90px;
    height: 90px;
    border-radius: 50%;
    /* Aro de Latão Envelhecido */
    background: radial-gradient(circle, #2d2013 40%, #150e08 80%);
    border: 3px solid #b89047;
    box-shadow: 
      inset 0 0 12px rgba(0,0,0,0.8),
      0 4px 10px rgba(0,0,0,0.7),
      0 0 2px 1px rgba(184, 144, 71, 0.4);
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }

  .compass-dial {
    position: absolute;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    /* Rotação linear suave */
    transition: transform 0.15s linear;
  }

  /* Letras Cardinais */
  .cardinal {
    position: absolute;
    font-size: 0.85rem;
    font-weight: 700;
    color: #e5c185; /* Bege/Dourado desbotado */
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.9);
    width: 20px;
    text-align: center;
  }

  .n { top: 4px; left: calc(50% - 10px); color: #ef4444; } /* Norte vermelho rustico */
  .s { bottom: 4px; left: calc(50% - 10px); }
  .l { right: 4px; top: calc(50% - 8px); }
  .o { left: 4px; top: calc(50% - 8px); }

  /* Ticks diagonais (NE, SE, SO, NO) */
  .tick-line {
    position: absolute;
    width: 2px;
    height: 6px;
    background: #8b6e3c;
    left: calc(50% - 1px);
    top: 2px;
    transform-origin: 1px 45px;
  }

  .t-45  { transform: rotate(45deg); }
  .t-135 { transform: rotate(135deg); }
  .t-225 { transform: rotate(225deg); }
  .t-315 { transform: rotate(315deg); }

  /* Ponteiro/Marcador do Topo (Norte) */
  .needle {
    position: absolute;
    top: 4px;
    width: 0;
    height: 0;
    border-left: 5px solid transparent;
    border-right: 5px solid transparent;
    border-top: 8px solid #f59e0b; /* Indicador fixo dourado */
    z-index: 5;
    filter: drop-shadow(0 1px 2px rgba(0,0,0,0.6));
  }

  /* Efeito de Reflexo no Vidro */
  .glass-reflection {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 50%, rgba(0,0,0,0.2) 100%);
    pointer-events: none;
    z-index: 10;
  }

  .heading-label {
    font-size: 0.7rem;
    color: #e5c185;
    letter-spacing: 1px;
    text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.9);
  }
</style>
