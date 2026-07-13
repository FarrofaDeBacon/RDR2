<script>
  import { minimap } from '../../stores/hudStore.js'
</script>

{#if $minimap.visible}
  <div class="minimap-mask" aria-hidden="true"></div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    /* Alinhado cirurgicamente com a borda externa do radar circular nativo do RDR2 */
    bottom: 2.1vh;
    left: 1.7vw;
    width: 14.7vw;
    height: 14.7vw;
    border-radius: 50%;
    
    /* Borda escura opaca (estilo RDR2) para cobrir fisicamente os cardinais do jogo */
    border: 9px solid #0b0705;
    
    /* Sombra interna leve para suavizar a transicao da borda preta */
    box-shadow: 
      0 0 8px rgba(0, 0, 0, 0.9),
      inset 0 0 6px rgba(0, 0, 0, 0.95);
      
    pointer-events: none;
    z-index: 100; /* Garante que fica por cima do renderizador nativo */
  }

  /* Media query para monitores Ultrawide ou Aspect Ratios customizados */
  @media (max-aspect-ratio: 21/9) {
    .minimap-mask {
      /* Pequenos ajustes de escala podem ser feitos aqui se necessario */
    }
  }
</style>
