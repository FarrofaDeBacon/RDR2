<script>
  import MapPanel from './components/map/MapPanel.svelte'
  import { visible, mapStore } from './stores/mapStore.js'

  // NUI message handler
  window.addEventListener('message', (e) => {
    const { action, coords, markers } = e.data ?? {}
    switch (action) {
      case 'openMap':
        mapStore.open(coords, markers)
        break
      case 'closeMap':
        mapStore.close()
        break
    }
  })
</script>

<main class="map-root" class:interactive={$visible}>
  <MapPanel />
</main>

<style>
  :global(*, *::before, *::after) { box-sizing: border-box; margin: 0; padding: 0; }
  :global(body) { background: transparent; overflow: hidden; font-family: 'Cinzel', serif; }

  .map-root {
    width: 100vw;
    height: 100vh;
    pointer-events: none;
  }

  .map-root.interactive {
    pointer-events: auto;
  }
</style>
