<script>
    import { minimap, config } from '../../stores/hudStore.js';

    // The mask relies on the minimap state
    export let isVisible = false;

    // Use a reactive statement to sync visibility from the store
    $: isVisible = $minimap && $minimap.visible && ($config && $config.minimapMask ? $config.minimapMask.enabled : false);
    
    $: maskSize = ($config && $config.minimapMask && $config.minimapMask.size) ? $config.minimapMask.size : 278;
    $: maskLeft = ($config && $config.minimapMask && $config.minimapMask.left) ? $config.minimapMask.left : 34;
    $: maskBottom = ($config && $config.minimapMask && $config.minimapMask.bottom) ? $config.minimapMask.bottom : 34;
</script>

{#if isVisible}
<div class="radar-mask-container" style="width: {maskSize}px; height: {maskSize}px; left: {maskLeft}px; bottom: {maskBottom}px;">
    <div class="radar-hole"></div>
</div>
{/if}

<style>
    .radar-mask-container {
        position: absolute;
        border-radius: 50%;
        
        /* Borda estilo couro rústico / anel que cobre as letras N, S, E, W */
        border: 24px solid #241b12; /* Marrom escuro */
        
        box-shadow: 
            inset 0px 0px 8px rgba(0,0,0,0.9), /* Sombra interna para profundidade */
            inset 0px 0px 2px rgba(0,0,0,1), 
            0px 0px 10px rgba(0,0,0,0.6), /* Sombra externa */
            0px 0px 0px 2px #0a0705; /* Borda fininha externa preta */
            
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
        box-shadow: 0 0 0 1px #0a0705; /* Borda fininha interna preta */
    }
</style>
