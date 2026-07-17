<script>
    import { minimap } from '../../stores/hudStore.js';

    // The mask relies on the minimap state
    export let isVisible = false;

    // Use a reactive statement to sync visibility from the store
    $: isVisible = $minimap && $minimap.visible;
</script>

{#if isVisible}
<div class="radar-mask-container">
    <div class="radar-hole"></div>
</div>
{/if}

<style>
    .radar-mask-container {
        position: absolute;
        bottom: 25px; /* Ajuste fino para encaixar no radar */
        left: 25px;
        width: 260px;
        height: 260px;
        border-radius: 50%;
        
        /* Borda preta esfumaçada e escura que cobre as letras N, S, E, W */
        border: 22px solid rgba(0, 0, 0, 0.95);
        box-shadow: inset 0px 0px 8px rgba(0,0,0,0.8), 0px 0px 10px rgba(0,0,0,0.5);
        
        pointer-events: none; /* A máscara normal não bloqueia cliques */
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 9999;
    }

    .radar-hole {
        width: 100%;
        height: 100%;
        border-radius: 50%;
        background-color: transparent;
    }
</style>
