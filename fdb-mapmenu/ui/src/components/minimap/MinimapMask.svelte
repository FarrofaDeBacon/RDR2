<script>
  import { minimap } from '../../stores/hudStore.js'
</script>

{#if $minimap.visible}
  <div class="minimap-mask" aria-hidden="true"></div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    /* Posição e dimensões em pixels para alinhar perfeitamente com o radar */
    bottom: 22px;
    left: 22px;
    width: 270px;
    height: 270px;
    border-radius: 50%;
    
    /* Borda preta bem espessa para garantir a cobertura das letras cardinais */
    border: 14px solid #0a0705;
    
    /* Brilho e sombreamento para integrar com o visual do radar */
    box-shadow: 
      0 0 10px rgba(0, 0, 0, 0.95),
      inset 0 0 8px rgba(0, 0, 0, 0.95);
      
    pointer-events: none;
    z-index: 9999;
  }
</style>
