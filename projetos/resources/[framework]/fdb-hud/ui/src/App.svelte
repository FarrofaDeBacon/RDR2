<script>
  import StatusHud    from './components/status/StatusHud.svelte'
  import VehicleHud  from './components/vehicle/VehicleHud.svelte'
  import MoneyHud    from './components/money/MoneyHud.svelte'
  import MinimapMask from './components/minimap/MinimapMask.svelte'
  import SettingsMenu from './components/SettingsMenu.svelte'
  import { hudStore } from './stores/hudStore.js'

  let visible = false
  let settingsVisible = false

  // ── NUI message handler ─────────────────────────────────────────
  window.addEventListener('message', (e) => {
    const { action, data } = e.data ?? {}
    switch (action) {
      case 'init':
        hudStore.init(data)
        visible = true
        break
      case 'setVisible':
        visible = data
        break
      case 'updateStatus':
        hudStore.setStatus(data)
        break
      case 'updateVehicle':
        hudStore.setVehicle(data)
        break
      case 'setVehicleVisible':
        hudStore.setVehicleVisible(data)
        break

      case 'updateMinimap':
        hudStore.setMinimap(data)
        break
      case 'setEditMode':
        hudStore.setEditMode(data)
        break
      case 'openMenu':
        settingsVisible = true
        break
      case 'closeMenu':
        settingsVisible = false
        break
    }
  })

  // Notifica o client que a UI está pronta
  fetch('https://fdb-hud/hudReady', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  }).catch(() => {})
</script>

{#if visible}
  <main class="hud-root">
    <MinimapMask />
    <StatusHud  />
    <VehicleHud />
    <MoneyHud   />
    <SettingsMenu bind:visible={settingsVisible} />
  </main>
{/if}

<style>
  :global(*, *::before, *::after) { box-sizing: border-box; margin: 0; padding: 0; }
  :global(body) { background: transparent; overflow: hidden; font-family: 'Cinzel', serif; }

  .hud-root {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 100vw;
    height: 100vh;
    max-width: calc(100vh * (16 / 9));
    max-height: calc(100vw * (9 / 16));
    pointer-events: none;
  }
</style>
