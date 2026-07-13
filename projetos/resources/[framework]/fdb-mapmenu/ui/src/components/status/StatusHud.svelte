<script>
  import { status } from '../../stores/hudStore.js'

  // Converte 0.0–1.0 em % para a barra SVG
  function pct(val) { return Math.max(0, Math.min(100, Math.round(val * 100))) }

  // Cores dinâmicas baseadas no valor
  function healthColor(v) {
    if (v > 0.5) return '#4ade80'   // verde
    if (v > 0.25) return '#facc15'  // amarelo
    return '#f87171'                // vermelho
  }
</script>

{#if !$status.dead}
  <div class="status-panel" role="region" aria-label="Status do personagem">
    <!-- Saúde -->
    <div class="stat-row">
      <span class="stat-icon" aria-hidden="true">❤</span>
      <div class="bar-track" role="progressbar" aria-valuenow={pct($status.health)} aria-valuemin="0" aria-valuemax="100">
        <div class="bar-fill" style:width="{pct($status.health)}%" style:background={healthColor($status.health)}></div>
      </div>
    </div>

    <!-- Stamina -->
    <div class="stat-row">
      <span class="stat-icon" aria-hidden="true">⚡</span>
      <div class="bar-track" role="progressbar" aria-valuenow={pct($status.stamina)} aria-valuemin="0" aria-valuemax="100">
        <div class="bar-fill stamina" style:width="{pct($status.stamina)}%"></div>
      </div>
    </div>
  </div>
{:else}
  <div class="dead-overlay" role="alert" aria-live="assertive">
    <span>✝ MORTO</span>
  </div>
{/if}

<style>
  .status-panel {
    position: absolute;
    bottom: 8vh;
    left: 2vw;
    display: flex;
    flex-direction: column;
    gap: 6px;
    pointer-events: none;
  }

  .stat-row {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .stat-icon {
    font-size: 0.8rem;
    opacity: 0.85;
    color: #fff;
    width: 16px;
    text-align: center;
  }

  .bar-track {
    width: 140px;
    height: 6px;
    background: rgba(0,0,0,0.45);
    border-radius: 4px;
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.08);
  }

  .bar-fill {
    height: 100%;
    border-radius: 4px;
    transition: width 0.3s ease, background 0.3s ease;
  }

  .bar-fill.stamina { background: #60a5fa; }

  .dead-overlay {
    position: absolute;
    bottom: 8vh;
    left: 2vw;
    color: #f87171;
    font-size: 0.9rem;
    font-weight: bold;
    letter-spacing: 2px;
    opacity: 0.9;
  }
</style>
