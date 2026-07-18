<script>
  import StatusCores from './components/StatusCores.svelte';
  import ScreenEffects from './components/ScreenEffects.svelte';
</script>

<main>
  <ScreenEffects />
  <StatusCores />
</main>

<style>
  main {
    width: 100vw;
    height: 100vh;
    overflow: hidden;
    /* Transparent background for NUI */
    background: transparent;
  }
</style>
