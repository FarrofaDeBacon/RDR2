<script>
  import { compass } from '../../stores/hudStore.js'

  // Gera os ticks da bússola a partir do heading atual
  function getTicks(degrees) {
    const ticks = []
    for (let i = -180; i <= 180; i += 5) {
      const angle = ((degrees + i) % 360 + 360) % 360
      ticks.push({ angle, major: angle % 45 === 0, label: angle % 90 === 0 ? cardinalLabel(angle) : null })
    }
    return ticks
  }

  function cardinalLabel(deg) {
    const map = { 0: 'N', 90: 'L', 180: 'S', 270: 'O' }
    return map[deg] ?? ''
  }
</script>

{#if $compass.visible}
<div class="compass-wrap" role="region" aria-label="Bússola {$compass.degrees}°">
  <div class="compass-bar">
    <div class="ticks">
      {#each getTicks($compass.degrees) as tick}
        <div class="tick" class:major={tick.major} class:north={tick.angle === 0}>
          {#if tick.label}<span class="tick-label">{tick.label}</span>{/if}
        </div>
      {/each}
    </div>
    <div class="center-marker" aria-hidden="true">▼</div>
  </div>

  <div class="heading-label" aria-hidden="true">
    {$compass.cardinal ?? ''} {$compass.degrees}°
  </div>
</div>
{/if}


<style>
  .compass-wrap {
    position: absolute;
    top: 2vh;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    pointer-events: none;
  }

  .compass-bar {
    position: relative;
    width: 260px;
    height: 28px;
    background: rgba(0,0,0,0.45);
    border-radius: 4px;
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.08);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .ticks {
    display: flex;
    align-items: flex-end;
    gap: 2px;
    position: absolute;
    bottom: 0;
    height: 100%;
  }

  .tick {
    width: 2px;
    height: 8px;
    background: rgba(255,255,255,0.25);
    border-radius: 1px;
    align-self: flex-end;
  }

  .tick.major {
    height: 14px;
    background: rgba(255,255,255,0.55);
    position: relative;
  }

  .tick.north { background: #f87171; }

  .tick-label {
    position: absolute;
    top: -14px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 0.55rem;
    color: #e2e8f0;
    letter-spacing: 0.5px;
    white-space: nowrap;
  }

  .center-marker {
    position: absolute;
    top: 2px;
    font-size: 0.5rem;
    color: #facc15;
    z-index: 10;
  }

  .heading-label {
    font-size: 0.6rem;
    color: #94a3b8;
    letter-spacing: 1px;
    text-transform: uppercase;
  }
</style>
