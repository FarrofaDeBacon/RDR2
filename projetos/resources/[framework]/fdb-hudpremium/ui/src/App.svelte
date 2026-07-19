<script>
  import StatusCores from './components/StatusCores.svelte';
  import ScreenEffects from './components/ScreenEffects.svelte';
  import EditorPanel from './components/EditorPanel.svelte';
</script>

<main>
  <ScreenEffects />
  <StatusCores />
  <EditorPanel />
</main>

<style>
  main {
    width: 100vw;
    height: 100vh;
    overflow: hidden;
    /* Transparent background for NUI */
    background: transparent;
    pointer-events: none; /* App em si não deve bloquear mouse */
  }

  /* Para permitir clicar no painel sem bloquear o jogo todo */
  :global(.editor-panel) {
    pointer-events: auto;
  }
</style>
