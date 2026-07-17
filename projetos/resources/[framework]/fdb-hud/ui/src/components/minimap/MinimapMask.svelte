<script>
  import { minimap } from '../../stores/hudStore.js'
</script>

{#if $minimap.visible}
  <div class="minimap-mask" aria-hidden="true"></div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    /* Valores baseados em viewport width (vw) para escalar com a tela */
    bottom: 2vw;
    left: 2vw;
    width: 14vw;
    height: 14vw;
    
    /* Removemos a borda preta grossa antiga */
    border: none;
    
    /* Carrega a imagem da borda/mascara personalizada */
    background-image: url('img/mask.svg');
    background-size: 100% 100%;
    background-position: center;
    background-repeat: no-repeat;
      
    pointer-events: none;
    z-index: 9999;
  }
</style>
