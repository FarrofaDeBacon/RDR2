<script>
    import { onMount } from 'svelte';
    import Draggable from './Draggable.svelte';

    export let layoutConfig = { x: 0.05, y: 0.75 };
    export let isEditMode = false;
    export let onPositionUpdate = (x, y) => {};
</script>

<Draggable
    {isEditMode}
    initialX={layoutConfig.x}
    initialY={layoutConfig.y}
    on:dragend={(e) => onPositionUpdate(e.detail.x, e.detail.y)}
>
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <div 
        class="radar-mask-container" 
        class:edit-mode={isEditMode}
    >
        <div class="radar-hole"></div>
    </div>
</Draggable>

<style>
    .radar-mask-container {
        /* Tamanho padrão do radar do RDR2 aproximado (ajustável arrastando) */
        width: 260px;
        height: 260px;
        border-radius: 50%;
        
        /* Borda preta esfumaçada e escura que cobre as letras N, S, E, W */
        border: 25px solid rgba(0, 0, 0, 0.95);
        box-shadow: inset 0px 0px 8px rgba(0,0,0,0.8), 0px 0px 10px rgba(0,0,0,0.5);
        
        pointer-events: none; /* A máscara normal não bloqueia cliques */
        display: flex;
        align-items: center;
        justify-content: center;
        position: relative;
    }

    .radar-hole {
        width: 100%;
        height: 100%;
        border-radius: 50%;
        background-color: transparent;
    }

    .radar-mask-container.edit-mode {
        pointer-events: auto;
        border: 25px solid rgba(220, 20, 20, 0.6);
        box-shadow: 0 0 0 2px white, inset 0 0 0 2px white;
        background-color: rgba(220, 20, 20, 0.1);
        cursor: move;
    }

    .radar-mask-container.edit-mode::after {
        content: "MÁSCARA RADAR";
        position: absolute;
        top: -30px;
        left: 50%;
        transform: translateX(-50%);
        color: white;
        font-family: sans-serif;
        font-weight: bold;
        font-size: 14px;
        white-space: nowrap;
        text-shadow: 1px 1px 2px black;
    }
</style>
