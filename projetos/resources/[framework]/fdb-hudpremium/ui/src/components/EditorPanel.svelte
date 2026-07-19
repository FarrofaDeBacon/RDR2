<script>
    import { editorState } from '../store/hudStore';

    let isEditing = false;
    let scales = {};
    let colors = {};

    const unsubscribe = editorState.subscribe(state => {
        isEditing = state.isEditing;
        scales = state.scales;
        colors = state.colors;
    });

    const modules = ['PlayerCores', 'HorseCores', 'SurvivalCores', 'Buffs', 'Voice'];

    function updateScale(mod, e) {
        const val = parseFloat(e.target.value);
        editorState.update(s => ({
            ...s,
            scales: { ...s.scales, [mod]: val }
        }));
    }

    function saveSettings() {
        // Envia callback pro Lua usando GetParentResourceName()
        const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'fdb-hudpremium';
        
        // Retira a flag isEditing temporariamente para o JSON limpo
        let current;
        editorState.subscribe(s => current = s)();

        fetch(`https://${resourceName}/saveSettings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                positions: current.positions,
                scales: current.scales,
                colors: current.colors
            })
        }).catch(err => console.error('[fdb-hudpremium] NUI save erro:', err));

        // Fecha o editor (simulado via UI, geralmente o Lua fecharia o NUI focus)
        editorState.update(s => ({ ...s, isEditing: false }));
        fetch(`https://${resourceName}/closeEditor`, { method: 'POST', body: '{}' }).catch(()=>{});
    }

    function resetSettings() {
        editorState.update(s => ({ ...s, positions: {}, scales: {}, colors: {} }));
    }

    // Drag lógico do painel
    let panelX = 50;
    let panelY = 50;
    let draggingPanel = false;
    let startX, startY, initX, initY;

    function startDrag(e) {
        if (e.target.tagName.toLowerCase() === 'input' || e.target.tagName.toLowerCase() === 'button') return;
        draggingPanel = true;
        startX = e.clientX;
        startY = e.clientY;
        initX = panelX;
        initY = panelY;
        window.addEventListener('mousemove', onDrag);
        window.addEventListener('mouseup', stopDrag);
    }

    function onDrag(e) {
        if (!draggingPanel) return;
        panelX = initX + (e.clientX - startX);
        panelY = initY + (e.clientY - startY);
    }

    function stopDrag() {
        draggingPanel = false;
        window.removeEventListener('mousemove', onDrag);
        window.removeEventListener('mouseup', stopDrag);
    }
</script>

{#if isEditing}
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div 
    class="editor-panel"
    style="left: {panelX}px; top: {panelY}px;"
    on:mousedown={startDrag}
>
    <div class="header">Modo Editor (Arraste para mover)</div>
    
    <div class="content">
        {#each modules as mod}
            <div class="module-config">
                <div class="module-title">{mod}</div>
                <div class="controls">
                    <span class="small-label">Escala</span>
                    <input 
                        type="range" 
                        min="0.5" 
                        max="2.0" 
                        step="0.1" 
                        value={scales[mod] ?? 1.0} 
                        on:input={(e) => updateScale(mod, e)} 
                    />
                    <span class="val">{scales[mod] ?? 1.0}</span>
                </div>
            </div>
        {/each}
    </div>

    <div class="footer">
        <button class="btn-reset" on:click={resetSettings}>Resetar</button>
        <button class="btn-save" on:click={saveSettings}>Salvar & Fechar</button>
    </div>
</div>
{/if}

<style>
    .editor-panel {
        position: absolute;
        width: 300px;
        background: rgba(15, 15, 15, 0.95);
        border: 1px solid rgba(255,255,255,0.2);
        border-radius: 8px;
        color: #ddd;
        font-family: sans-serif;
        box-shadow: 0 10px 30px rgba(0,0,0,0.8);
        z-index: 10000;
        pointer-events: auto; /* Permite interação mesmo que o pai seja none */
    }

    .header {
        background: rgba(255, 255, 255, 0.1);
        padding: 10px;
        text-align: center;
        font-weight: bold;
        font-size: 14px;
        cursor: grab;
        border-top-left-radius: 8px;
        border-top-right-radius: 8px;
        user-select: none;
    }

    .header:active {
        cursor: grabbing;
    }

    .content {
        padding: 15px;
        display: flex;
        flex-direction: column;
        gap: 15px;
    }

    .module-config .module-title {
        display: block;
        font-size: 14px;
        font-weight: bold;
        color: #fff;
        margin-bottom: 5px;
    }

    .controls {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .small-label {
        font-size: 11px;
        color: #aaa;
    }

    input[type=range] {
        flex: 1;
        cursor: pointer;
    }

    .val {
        font-size: 12px;
        width: 25px;
        text-align: right;
    }

    .footer {
        display: flex;
        justify-content: space-between;
        padding: 15px;
        border-top: 1px solid rgba(255,255,255,0.1);
    }

    button {
        padding: 8px 12px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-weight: bold;
        transition: background 0.2s;
    }

    .btn-reset {
        background: #444;
        color: white;
    }
    .btn-reset:hover {
        background: #555;
    }

    .btn-save {
        background: #2e8b57;
        color: white;
    }
    .btn-save:hover {
        background: #3cb371;
    }
</style>
