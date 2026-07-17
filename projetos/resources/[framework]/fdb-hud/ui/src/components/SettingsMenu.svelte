<script>
    import { hudStore, config, minimap } from '../stores/hudStore.js';
    
    export let visible = false;

    // Valores temporários ligados aos sliders
    let maskSize = 278;
    let maskLeft = 34;
    let maskBottom = 34;
    let maskThickness = 24;

    let wasVisible = false;

    // Sincroniza os sliders APENAS quando o menu abre
    $: if (visible && !wasVisible) {
        if ($config && $config.minimapMask) {
            maskSize = $config.minimapMask.size ?? 278;
            maskLeft = $config.minimapMask.left ?? 34;
            maskBottom = $config.minimapMask.bottom ?? 34;
            maskThickness = $config.minimapMask.thickness ?? 24;
        }
        wasVisible = true;
    } else if (!visible && wasVisible) {
        wasVisible = false;
    }

    // Atualiza a loja em tempo real enquanto move o slider
    function updateConfig() {
        if (!$config) return;
        const newConfig = { ...$config };
        if (!newConfig.minimapMask) newConfig.minimapMask = {};
        
        newConfig.minimapMask.size = parseInt(maskSize);
        newConfig.minimapMask.left = parseFloat(maskLeft);
        newConfig.minimapMask.bottom = parseFloat(maskBottom);
        newConfig.minimapMask.thickness = parseInt(maskThickness);
        
        hudStore.init({ config: newConfig });
    }

    // Salva as configurações permanentemente no servidor
    function saveSettings() {
        fetch('https://fdb-hud/saveMaskSettings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                size: maskSize,
                left: maskLeft,
                bottom: maskBottom,
                thickness: maskThickness
            })
        }).catch(() => {});
        closeMenu();
    }

    function closeMenu() {
        fetch('https://fdb-hud/closeMenu', { method: 'POST', body: '{}' }).catch(()=>{});
        visible = false;
    }
</script>

{#if visible}
<div class="settings-overlay">
    <div class="settings-panel">
        <h2>Ajustar Minimapa</h2>
        
        <div class="setting-row">
            <label>Tamanho do Aro ({maskSize}px)</label>
            <input type="range" min="150" max="400" bind:value={maskSize} on:input={updateConfig}>
        </div>

        <div class="setting-row">
            <label>Espessura do Couro ({maskThickness}px)</label>
            <input type="range" min="0" max="80" bind:value={maskThickness} on:input={updateConfig}>
        </div>

        <div class="setting-row">
            <label>Posição Horizontal - X ({maskLeft}%)</label>
            <input type="range" min="0" max="50" step="0.1" bind:value={maskLeft} on:input={updateConfig}>
        </div>

        <div class="setting-row">
            <label>Posição Vertical - Y ({maskBottom}%)</label>
            <input type="range" min="0" max="50" step="0.1" bind:value={maskBottom} on:input={updateConfig}>
        </div>

        <div class="actions">
            <button class="btn-cancel" on:click={closeMenu}>Cancelar</button>
            <button class="btn-save" on:click={saveSettings}>Salvar Alterações</button>
        </div>
    </div>
</div>
{/if}

<style>
    .settings-overlay {
        position: absolute;
        top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(0,0,0,0.4);
        display: flex;
        align-items: center;
        justify-content: center;
        pointer-events: auto;
        z-index: 10000;
        font-family: 'Cinzel', serif;
    }

    .settings-panel {
        background: #1a1614;
        border: 2px solid #3c2a18;
        padding: 20px 30px;
        border-radius: 8px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.8), inset 0 0 20px rgba(0,0,0,0.5);
        color: #e5d3b3;
        width: 350px;
    }

    h2 {
        text-align: center;
        margin-bottom: 20px;
        font-size: 1.2rem;
        border-bottom: 1px solid #3c2a18;
        padding-bottom: 10px;
    }

    .setting-row {
        margin-bottom: 15px;
        display: flex;
        flex-direction: column;
    }

    label {
        font-size: 0.9rem;
        margin-bottom: 5px;
        color: #b09e82;
    }

    .auto-pos {
        margin-top: 10px;
        background: #110d0a;
        padding: 10px;
        border-radius: 4px;
        border-left: 3px solid #3a7c39;
        text-align: center;
    }

    .auto-badge {
        color: #4CAF50;
        font-weight: bold;
        font-size: 0.95rem;
        display: block;
        margin-bottom: 5px;
    }

    .auto-pos small {
        color: #8c6a3f;
        font-size: 0.8rem;
    }

    input[type=range] {
        width: 100%;
        accent-color: #8c6a3f;
    }

    .actions {
        display: flex;
        justify-content: space-between;
        margin-top: 25px;
    }

    button {
        padding: 8px 15px;
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-family: 'Cinzel', serif;
        font-weight: bold;
        transition: 0.2s;
    }

    .btn-cancel {
        background: #33261f;
        color: #e5d3b3;
        border: 1px solid #4a3628;
    }
    .btn-cancel:hover { background: #4a3628; }

    .btn-save {
        background: #2b5c2a;
        color: white;
        border: 1px solid #3a7c39;
    }
    .btn-save:hover { background: #3a7c39; }
</style>
