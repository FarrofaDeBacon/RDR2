<script>
  import { vehicle, vehicleVisible } from '../../stores/hudStore.js'
</script>

{#if $vehicleVisible}
  <div class="vehicle-panel" role="region" aria-label="HUD de veículo">
    <div class="speed-display">
      <span class="speed-value">{$vehicle.speed}</span>
      <span class="speed-unit">{$vehicle.unit}</span>
    </div>

    <div class="gear-display" aria-label="Marcha {$vehicle.gear}">
      {$vehicle.gear}
    </div>

    <!-- RPM bar -->
    <div class="rpm-track" role="progressbar" aria-valuenow={$vehicle.rpm} aria-valuemin="0" aria-valuemax="100">
      <div class="rpm-fill" style:width="{$vehicle.rpm}%"
        class:rpm-red={$vehicle.rpm > 85}
        class:rpm-yellow={$vehicle.rpm > 65 && $vehicle.rpm <= 85}>
      </div>
    </div>
  </div>
{/if}

<style>
  .vehicle-panel {
    position: absolute;
    bottom: 8vh;
    right: 2vw;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 4px;
    pointer-events: none;
  }

  .speed-display {
    display: flex;
    align-items: baseline;
    gap: 4px;
  }

  .speed-value {
    font-size: 2.2rem;
    font-weight: 700;
    color: #f1f5f9;
    line-height: 1;
    text-shadow: 0 0 12px rgba(0,0,0,0.8);
    font-variant-numeric: tabular-nums;
  }

  .speed-unit {
    font-size: 0.65rem;
    color: #94a3b8;
    text-transform: uppercase;
    letter-spacing: 1px;
    align-self: flex-end;
    padding-bottom: 4px;
  }

  .gear-display {
    font-size: 1.1rem;
    font-weight: 600;
    color: #e2e8f0;
    text-shadow: 0 0 8px rgba(0,0,0,0.9);
  }

  .rpm-track {
    width: 120px;
    height: 4px;
    background: rgba(0,0,0,0.4);
    border-radius: 3px;
    overflow: hidden;
  }

  .rpm-fill {
    height: 100%;
    background: #60a5fa;
    border-radius: 3px;
    transition: width 0.15s ease, background 0.2s ease;
  }

  .rpm-fill.rpm-yellow { background: #facc15; }
  .rpm-fill.rpm-red    { background: #f87171; }
</style>
