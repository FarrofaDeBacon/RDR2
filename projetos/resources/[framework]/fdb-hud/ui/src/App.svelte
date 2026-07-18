<script>
  import { onMount } from 'svelte';
  import MinimapMask from './components/minimap/MinimapMask.svelte';
  import StatusBars from './components/status/StatusBars.svelte';
  import HorseStatus from './components/status/HorseStatus.svelte';
  import PoisonAlert from './components/status/PoisonAlert.svelte';

  // O MinimapMask ainda usa a hudStore internamente, então precisamos importar
  import { hudStore } from './stores/hudStore.js';

  // Objeto de estado reativo
  let state = {
    health: 100,
    stamina: 100,
    hunger: 100,
    thirst: 100,
    stress: 0,
    bladder: 0,
    alcohol: 0,
    isPoisoned: false,
    isMounted: false,
    horseHealth: 100,
    horseStamina: 100,
    showHud: false
  };

  onMount(() => {
    window.addEventListener('message', (e) => {
      const { action, data } = e.data ?? {};
      
      if (action === 'showHud') {
        state = { ...state, showHud: data };
      } 
      else if (action === 'updateStatus') {
        // Merge parcial para garantir que dados incompletos não quebrem o objeto
        state = { ...state, ...data };
      }
      
      // Compatibilidade com o MinimapMask antigo e edição
      else if (action === 'updateMinimap') {
        hudStore.setMinimap(data);
      } 
      else if (action === 'setEditMode') {
        hudStore.setEditMode(data);
      }
    });

    window.addEventListener('keydown', (e) => {
      if (e.code === 'Escape') {
        fetch('https://fdb-hud/closeEditMode', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        }).catch(() => {});
      }
    });

    // Notifica o client que a UI está pronta
    fetch('https://fdb-hud/hudReady', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }).catch(() => {});
  });
</script>

{#if state.showHud}
  <main class="hud-root">
    
    <!-- Minimapa (Legado/Embutido) -->
    <MinimapMask />
    
    <!-- Novos Status -->
    <StatusBars 
      health={state.health}
      stamina={state.stamina}
      hunger={state.hunger}
      thirst={state.thirst}
      stress={state.stress}
      bladder={state.bladder}
      alcohol={state.alcohol}
    />

    <!-- Horse Status Condicional -->
    {#if state.isMounted}
      <HorseStatus 
        horseHealth={state.horseHealth}
        horseStamina={state.horseStamina}
      />
    {/if}

    <!-- Poison Alert Condicional -->
    {#if state.isPoisoned}
      <PoisonAlert />
    {/if}
    
  </main>
{/if}

<style>
  :global(*, *::before, *::after) { box-sizing: border-box; margin: 0; padding: 0; }
  :global(body) { background: transparent; overflow: hidden; font-family: 'Cinzel', serif; }

  .hud-root {
    width: 100vw;
    height: 100vh;
    position: relative;
    pointer-events: none;
  }
</style>
