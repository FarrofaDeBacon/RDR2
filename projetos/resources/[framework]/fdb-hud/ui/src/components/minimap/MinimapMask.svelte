<script>
    import { minimap, config } from '../../stores/hudStore.js';

    export let isVisible = false;

    $: isVisible = $minimap && $minimap.visible && ($config && $config.minimapMask ? $config.minimapMask.enabled : false);
    
    $: maskSize = ($config && $config.minimapMask && $config.minimapMask.size) ? $config.minimapMask.size : 278;
    
    // Agora usamos diretamente vw/vh da config, que será perfeitamente responsivo
    $: maskLeft = ($config && $config.minimapMask && $config.minimapMask.left) ? `${$config.minimapMask.left}vw` : '8.6vw';
    $: maskBottom = ($config && $config.minimapMask && $config.minimapMask.bottom) ? `${$config.minimapMask.bottom}vh` : '13.3vh';
    
    $: maskThickness = ($config && $config.minimapMask && $config.minimapMask.thickness) ? $config.minimapMask.thickness : 24;
</script>

{#if isVisible}
<div class="radar-mask-container" style="width: {maskSize}px; height: {maskSize}px; left: {maskLeft}; bottom: {maskBottom}; border-width: {maskThickness}px;">
    <div class="radar-hole"></div>
</div>
{/if}

<style>
    .radar-mask-container {
        position: absolute;
        border-radius: 50%;
        box-sizing: content-box;
        transform: translate(-50%, 50%);
        
        /* Borda estilo couro rústico / anel que cobre as letras N, S, E, W */
        border: solid #241b12; /* A espessura vem do inline style */
        
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
