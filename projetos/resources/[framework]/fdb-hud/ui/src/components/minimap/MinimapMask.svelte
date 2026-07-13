<script>
  import { minimap } from '../../stores/hudStore.js'
</script>

{#if $minimap.visible}
  <div class="minimap-mask" aria-hidden="true"></div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    /* Posição física exata sobre o minimapa circular clássico */
    bottom: 22px;
    left: 22px;
    width: 268px;
    height: 268px;
    border-radius: 50%;
    
    /* Borda preta opaca para cobrir cardinais e bússola da borda do jogo */
    border: 9px solid #070403;
    
    /* Sombra interna para suavizar a borda no minimapa */
    box-shadow: 
      0 0 6px rgba(0, 0, 0, 0.95),
      inset 0 0 5px rgba(0, 0, 0, 0.95);
      
    pointer-events: none;
    z-index: 9999;
  }
</style>
