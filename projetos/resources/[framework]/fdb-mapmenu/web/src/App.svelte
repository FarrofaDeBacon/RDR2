<script>
    import { onMount } from 'svelte';
    import { blipCategories, getBlipImage } from './lib/blips.js';

    let isVisible = false;
    let currentTab = 'add'; // 'add' ou 'list'
    
    // Dados de Criação/Edição
    let currentCoords = null;
    let markerIdToEdit = null; // null = Criando novo, preenchido = Editando
    let markerName = '';
    let markerIcon = 'blip_ambient_camp';
    
    // Lista de marcadores do servidor
    let markers = [];

    // Gerenciamento de eventos do LUA
    onMount(() => {
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (data.action === 'openMenu') {
                isVisible = true;
                currentCoords = data.coords;
                markerIdToEdit = null; // Garante que é criação
                markerName = '';
                markerIcon = 'blip_ambient_camp';
                currentTab = 'add';
            } else if (data.action === 'openNotebook') {
                isVisible = true;
                currentCoords = null;
                markers = data.markers || [];
                currentTab = 'list';
            }
        });

        window.addEventListener('keyup', (e) => {
            if (e.key === 'Escape' && isVisible) {
                closeUI();
            }
        });
    });

    function closeUI() {
        isVisible = false;
        fetch('https://fdb-mapmenu/closeUI', { method: 'POST', body: JSON.stringify({}) });
    }

    function switchTab(tab) {
        currentTab = tab;
        if (tab === 'list') {
            fetch('https://fdb-mapmenu/requestMarkers', { method: 'POST', body: JSON.stringify({}) })
                .then(res => res.json())
                .then(data => {
                    markers = data || [];
                });
        }
    }

    function saveMarker() {
        if (markerName.trim() === '') return;

        if (markerIdToEdit) {
            // Modo Edição
            fetch('https://fdb-mapmenu/editMarker', {
                method: 'POST',
                body: JSON.stringify({
                    id: markerIdToEdit,
                    name: markerName.trim(),
                    icon: markerIcon
                })
            });
        } else {
            // Modo Criação
            fetch('https://fdb-mapmenu/saveMarker', {
                method: 'POST',
                body: JSON.stringify({
                    name: markerName.trim(),
                    icon: markerIcon,
                    coords: currentCoords
                })
            });
        }
        closeUI();
    }

    function deleteMarker(id) {
        fetch('https://fdb-mapmenu/deleteMarker', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
        markers = markers.filter(m => m.id !== id);
    }

    function editMarker(marker) {
        markerIdToEdit = marker.id;
        markerName = marker.name;
        markerIcon = marker.icon || 'blip_ambient_camp';
        switchTab('add');
    }
</script>

{#if isVisible}
    <div class="ui-container">
        <div class="paper">
            <!-- Abas -->
            <div class="tabs">
                <button class:active={currentTab === 'add'} on:click={() => switchTab('add')}>
                    {markerIdToEdit ? 'Editar Anotação' : 'Nova Anotação'}
                </button>
                <button class:active={currentTab === 'list'} on:click={() => switchTab('list')}>Minhas Anotações</button>
            </div>

            <!-- Aba Adicionar/Editar -->
            {#if currentTab === 'add'}
                <div class="tab-content">
                    <h2>{markerIdToEdit ? 'Corrigir o Mapa' : 'Desenhar no Mapa'}</h2>
                    
                    <div class="input-group">
                        <label>O que há aqui?</label>
                        <input type="text" bind:value={markerName} placeholder="Ex: Acampamento Seguro..." autocomplete="off">
                    </div>

                    <div class="input-group">
                        <label>Escolha o Símbolo</label>
                        <div class="scrollable-categories">
                            {#each blipCategories as category}
                                <h3 class="category-title">{category.name}</h3>
                                <div class="icon-grid">
                                    {#each category.blips as blip}
                                        <!-- svelte-ignore a11y-click-events-have-key-events -->
                                        <!-- svelte-ignore a11y-no-static-element-interactions -->
                                        <div 
                                            class="icon-option" 
                                            class:selected={markerIcon === blip.id}
                                            title={blip.label}
                                            on:click={() => markerIcon = blip.id}
                                        >
                                            <img src={getBlipImage(blip.id)} alt={blip.label} />
                                        </div>
                                    {/each}
                                </div>
                            {/each}
                        </div>
                    </div>

                    <div class="actions">
                        <button class="btn btn-secondary" on:click={closeUI}>Rasgar (Cancelar)</button>
                        <button class="btn btn-primary" on:click={saveMarker}>
                            {markerIdToEdit ? 'Salvar Edição' : 'Anotar'}
                        </button>
                    </div>
                </div>
            {/if}

            <!-- Aba Lista -->
            {#if currentTab === 'list'}
                <div class="tab-content">
                    <h2>Anotações Feitas</h2>
                    <div class="marker-list-container">
                        <ul>
                            {#if markers.length === 0}
                                <li class="empty-list">Nenhuma anotação no mapa.</li>
                            {:else}
                                {#each markers as marker}
                                    <li class="marker-item">
                                        <div class="marker-info">
                                            <span>📝</span>
                                            <span>{marker.name}</span>
                                        </div>
                                        <div class="marker-actions">
                                            <button class="btn-edit" on:click={() => editMarker(marker)} title="Editar">✏️</button>
                                            <button class="btn-delete" on:click={() => deleteMarker(marker.id)} title="Deletar">❌</button>
                                        </div>
                                    </li>
                                {/each}
                            {/if}
                        </ul>
                    </div>
                    <div class="actions">
                        <button class="btn btn-secondary" on:click={closeUI}>Fechar Diário</button>
                    </div>
                </div>
            {/if}
        </div>
    </div>
{/if}

<style>
    /* O CSS do Svelte (Scoped) - Semelhante ao estilo de papel */
    @import url('https://fonts.googleapis.com/css2?family=Caveat:wght@400;700&display=swap');

    :global(body) {
        margin: 0;
        padding: 0;
        overflow: hidden;
        background: transparent !important;
        font-family: 'Caveat', cursive;
    }

    .ui-container {
        position: absolute;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        display: flex;
        justify-content: center;
        align-items: center;
        background: rgba(0, 0, 0, 0.4);
        z-index: 9999;
    }

    .paper {
        background: url('https://www.transparenttextures.com/patterns/old-paper.png'), #f4e8c1;
        background-blend-mode: multiply;
        width: 500px;
        min-height: 550px;
        border-radius: 10px;
        box-shadow: 5px 5px 20px rgba(0,0,0,0.8), inset 0 0 50px rgba(139, 69, 19, 0.2);
        padding: 30px;
        position: relative;
        border: 2px solid #8b4513;
        display: flex;
        flex-direction: column;
    }

    .tabs {
        display: flex;
        border-bottom: 2px dashed #8b4513;
        margin-bottom: 20px;
        padding-bottom: 10px;
    }

    .tabs button {
        flex: 1;
        background: none;
        border: none;
        font-size: 24px;
        color: #5c3a21;
        cursor: pointer;
        opacity: 0.6;
        transition: 0.2s;
        font-weight: bold;
        font-family: 'Caveat', cursive;
    }

    .tabs button:hover { opacity: 0.8; }
    .tabs button.active {
        opacity: 1;
        text-decoration: underline;
        color: #3e2723;
    }

    .tab-content {
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    h2 {
        text-align: center;
        color: #3e2723;
        font-size: 32px;
        margin-top: 0;
        margin-bottom: 10px;
    }

    .input-group {
        margin-bottom: 15px;
        display: flex;
        flex-direction: column;
    }

    label {
        font-size: 24px;
        color: #3e2723;
        margin-bottom: 5px;
    }

    input {
        width: 100%;
        background: rgba(255, 255, 255, 0.3);
        border: none;
        border-bottom: 2px solid #8b4513;
        padding: 10px;
        font-size: 22px;
        color: #3e2723;
        outline: none;
        font-family: 'Caveat', cursive;
        box-sizing: border-box;
    }
    
    input::placeholder { color: rgba(139, 69, 19, 0.6); }

    .scrollable-categories {
        max-height: 250px;
        overflow-y: auto;
        border: 1px dashed rgba(139, 69, 19, 0.5);
        padding: 10px;
        border-radius: 5px;
    }

    /* Scrollbar interna */
    .scrollable-categories::-webkit-scrollbar, .marker-list-container::-webkit-scrollbar { width: 8px; }
    .scrollable-categories::-webkit-scrollbar-track, .marker-list-container::-webkit-scrollbar-track { background: rgba(139, 69, 19, 0.1); border-radius: 4px; }
    .scrollable-categories::-webkit-scrollbar-thumb, .marker-list-container::-webkit-scrollbar-thumb { background: #8b4513; border-radius: 4px; }

    .category-title {
        margin: 10px 0 5px 0;
        font-size: 20px;
        color: #5c3a21;
        border-bottom: 1px dotted #8b4513;
    }

    .icon-grid {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
    }

    .icon-option {
        cursor: pointer;
        padding: 5px;
        border: 2px solid transparent;
        border-radius: 8px;
        transition: 0.2s;
        background: rgba(139, 69, 19, 0.1);
        text-align: center;
        width: 48px;
        height: 48px;
        display: flex;
        justify-content: center;
        align-items: center;
    }

    .icon-option img {
        max-width: 100%;
        max-height: 100%;
        filter: drop-shadow(1px 1px 1px rgba(0,0,0,0.5));
    }

    .icon-option:hover { background: rgba(139, 69, 19, 0.3); }
    .icon-option.selected {
        border-color: #8b4513;
        background: rgba(139, 69, 19, 0.4);
        transform: scale(1.1);
    }

    .actions {
        display: flex;
        justify-content: space-between;
        margin-top: auto;
        padding-top: 20px;
    }

    .btn {
        padding: 10px 20px;
        font-size: 24px;
        cursor: pointer;
        border: 2px solid #8b4513;
        background: transparent;
        font-family: 'Caveat', cursive;
        transition: 0.2s;
        border-radius: 5px;
        font-weight: bold;
    }

    .btn-primary { background: #8b4513; color: #f4e8c1; }
    .btn-primary:hover { background: #5c3a21; }
    .btn-secondary { color: #8b4513; }
    .btn-secondary:hover { background: rgba(139, 69, 19, 0.1); }

    .marker-list-container {
        flex: 1;
        overflow-y: auto;
        margin-bottom: 10px;
        padding-right: 10px;
    }

    ul { list-style: none; padding: 0; margin: 0; }
    
    .marker-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px;
        border-bottom: 1px dashed #8b4513;
        font-size: 22px;
        color: #3e2723;
    }

    .marker-info { display: flex; align-items: center; gap: 10px; }
    .empty-list { text-align: center; font-size: 24px; color: #8b4513; opacity: 0.8; margin-top: 20px; }
    
    .marker-actions { display: flex; gap: 10px; }
    .btn-edit, .btn-delete { background: none; border: none; font-size: 20px; cursor: pointer; }
    .btn-edit:hover { transform: scale(1.2); }
    .btn-delete { color: darkred; }
    .btn-delete:hover { transform: scale(1.2); }
</style>
