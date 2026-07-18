<script>
  export let health = 100;
  export let stamina = 100;
  export let hunger = 100;
  export let thirst = 100;
  export let stress = 0;
  export let bladder = 0;

  // Calculamos os graus para o conic-gradient
  $: healthDeg = (health / 100) * 360;
  $: staminaDeg = (stamina / 100) * 360;
  $: hungerDeg = (hunger / 100) * 360;
  $: thirstDeg = (thirst / 100) * 360;
  $: stressDeg = (stress / 100) * 360;
  $: bladderDeg = (bladder / 100) * 360;

  // Lógica de visibilidade dinâmica: só aparece se não estiver 100% 
  // (Para stress e bladder, aparece se maior que 0)
  $: showHealth = health < 100;
  $: showStamina = stamina < 100;
  $: showHunger = hunger < 100;
  $: showThirst = thirst < 100;
  $: showStress = stress > 0;
  $: showBladder = bladder > 0;

</script>

<div class="status-container">

  {#if showHealth}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {healthDeg}deg, transparent 0);"></div>
      <div class="core-icon">❤</div>
    </div>
  {/if}

  {#if showStamina}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {staminaDeg}deg, transparent 0);"></div>
      <div class="core-icon">⚡</div>
    </div>
  {/if}

  {#if showHunger}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {hungerDeg}deg, transparent 0);"></div>
      <div class="core-icon">🍖</div>
    </div>
  {/if}

  {#if showThirst}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {thirstDeg}deg, transparent 0);"></div>
      <div class="core-icon">💧</div>
    </div>
  {/if}

  {#if showStress}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {stressDeg}deg, transparent 0);"></div>
      <div class="core-icon">💢</div>
    </div>
  {/if}

  {#if showBladder}
    <div class="core-wrapper">
      <div class="core-bg"></div>
      <div class="core-progress" style="background: conic-gradient(#fff {bladderDeg}deg, transparent 0);"></div>
      <div class="core-icon">🚽</div>
    </div>
  {/if}

</div>

<style>
  .status-container {
    position: absolute;
    bottom: 2vh;
    left: 25vw; /* Ficar ao lado do radar/cavalo */
    display: flex;
    gap: 8px;
    pointer-events: none;
  }

  .core-wrapper {
    position: relative;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    animation: fadeIn 0.5s ease;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: scale(0.9); }
    to { opacity: 1; transform: scale(1); }
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
    transition: background 0.2s ease;
  }

  .core-icon {
    position: relative;
    z-index: 2;
    font-size: 1.4rem;
    color: #fff;
    opacity: 0.8;
  }
</style>
