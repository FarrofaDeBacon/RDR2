<script>
  export let horseHealth = 100;
  export let horseStamina = 100;
  
  // Renderiza apenas se não estiver cheio, opcionalmente, 
  // mas como o HorseStatus inteiro só renderiza se montado, podemos deixar fixo ou sumir se 100%.
  // A especificação diz que a UI em si decide sumir animações complexas.
  
  // Para progress circular simples com conic-gradient
  $: healthDeg = (horseHealth / 100) * 360;
  $: staminaDeg = (horseStamina / 100) * 360;
</script>

<div class="horse-status-container">
  <!-- Core Vida -->
  <div class="core-wrapper">
    <div class="core-bg"></div>
    <div class="core-progress health" style="background: conic-gradient(#fff {healthDeg}deg, transparent 0);"></div>
    <div class="core-icon">🐎</div>
  </div>

  <!-- Core Stamina -->
  <div class="core-wrapper">
    <div class="core-bg"></div>
    <div class="core-progress stamina" style="background: conic-gradient(#fff {staminaDeg}deg, transparent 0);"></div>
    <div class="core-icon">⚡</div>
  </div>
</div>

<style>
  .horse-status-container {
    position: absolute;
    bottom: 2vh;
    left: 20vw;
    display: flex;
    gap: 12px;
    pointer-events: none;
    transition: opacity 0.3s ease;
  }

  .core-wrapper {
    position: relative;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .core-bg {
    position: absolute;
    inset: 0;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.4);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .core-progress {
    position: absolute;
    inset: 2px;
    border-radius: 50%;
    mask: radial-gradient(transparent 55%, black 56%);
    -webkit-mask: radial-gradient(transparent 55%, black 56%);
  }

  .core-progress.health {
    /* Branco/Vermelho depedendo da saude, o fundo da progress pode ser alterado no style se necessario */
  }

  .core-icon {
    position: relative;
    z-index: 2;
    font-size: 0.8rem;
    color: #fff;
    opacity: 0.8;
  }
</style>
