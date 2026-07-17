<script>
  import { minimap } from "../../stores/hudStore.js";
</script>

{#if $minimap.visible}
  <div class="minimap-mask" aria-hidden="true"></div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    /* Usando Viewport Height (vh) para ancorar na mesma proporção do minimapa em qualquer resolução (Ultrawide etc) */
    bottom: 2.2vh;
    left: 2.2vh;
    width: 27.0vh;
    height: 27.0vh;

    /* Removemos a borda preta grossa antiga */
    border: none;

    /* Carrega a imagem da borda/mascara personalizada */
    background-image: url("img/mask.svg");
    background-size: 100% 100%;
    background-position: center;
    background-repeat: no-repeat;

    pointer-events: none;
    z-index: 9999;
  }
</style>
