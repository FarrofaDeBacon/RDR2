<script>
  import { minimap, editMode } from "../../stores/hudStore.js";

  // Valores iniciais (em vh) ajustados pelo jogador
  let maskWidth = 41.6;
  let maskHeight = 41.6;
  let maskLeft = -3.4;
  let maskBottom = 3.2;
</script>

{#if $minimap.visible}
  <div 
    class="minimap-mask" 
    aria-hidden="true"
    style="width: {maskWidth}vh; height: {maskHeight}vh; left: {maskLeft}vh; bottom: {maskBottom}vh;"
  ></div>
{/if}

{#if $editMode}
  <div class="editor-panel">
    <h3>Ajuste do Minimapa</h3>
    <label>Tamanho (vh): {maskWidth}
      <input type="range" min="10" max="60" step="0.1" bind:value={maskWidth} />
      <input type="range" min="10" max="60" step="0.1" bind:value={maskHeight} />
    </label>
    <label>Esquerda (vh): {maskLeft}
      <input type="range" min="-10" max="50" step="0.1" bind:value={maskLeft} />
    </label>
    <label>Baixo (vh): {maskBottom}
      <input type="range" min="-10" max="50" step="0.1" bind:value={maskBottom} />
    </label>
    <p>Passe esses números para o dev!</p>
  </div>
{/if}

<style>
  .minimap-mask {
    position: absolute;
    border: none;
    background-image: url("img/mask.svg");
    background-size: 100% 100%;
    background-position: center;
    background-repeat: no-repeat;
    pointer-events: none;
    z-index: 9999;
    
    /* Sombra projetada aumentada a pedido do jogador (mais escura e com maior espalhamento) */
    filter: drop-shadow(0 6px 10px rgba(0,0,0,0.9)) drop-shadow(0 0 20px rgba(0,0,0,0.7));
  }

  .editor-panel {
    position: absolute;
    top: 20px;
    right: 20px;
    background: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 20px;
    border-radius: 8px;
    z-index: 10000;
    pointer-events: auto;
    font-family: sans-serif;
  }
  .editor-panel label {
    display: block;
    margin-bottom: 10px;
  }
  .editor-panel input[type="range"] {
    width: 100%;
  }
</style>
