let currentCoords = null;

// Escuta as mensagens do Client (Lua)
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === "openMenu") {
        $("#ui-container").removeClass("hidden");
        currentCoords = data.coords; // Coordenadas que vieram do duplo clique
        
        // Abre na aba de adicionar
        switchTab('add');
        
        // Limpa o input
        $("#marker-name").val('');
        $("#marker-icon").prop('selectedIndex', 0);
        $("#marker-name").focus();
    } else if (data.action === "openNotebook") {
        $("#ui-container").removeClass("hidden");
        currentCoords = null; // Não estamos criando nada novo
        
        // Abre na aba da lista
        switchTab('list');
        updateMarkerList(data.markers);
    }
});

// Troca de Abas
$(".tab-btn").click(function() {
    const tabId = $(this).attr("id").replace("tab-", "");
    switchTab(tabId);
    
    // Se clicou na lista, pede pro cliente as anotações
    if (tabId === 'list') {
        $.post('https://fdb-mapmenu/requestMarkers', JSON.stringify({}), function(markers) {
            updateMarkerList(markers);
        });
    }
});

function switchTab(tabId) {
    $(".tab-btn").removeClass("active");
    $(".tab-content").removeClass("active");
    
    $("#tab-" + tabId).addClass("active");
    $("#content-" + tabId).addClass("active");
}

// Fechar UI (Botão Rasgar ou Esc)
function closeUI() {
    $("#ui-container").addClass("hidden");
    $.post('https://fdb-mapmenu/closeUI', JSON.stringify({}));
}

$("#btn-cancel").click(closeUI);
$("#btn-close-list").click(closeUI);

$(document).keyup(function(e) {
    if (e.key === "Escape") {
        closeUI();
    }
});

// Salvar Anotação
$("#btn-save").click(function() {
    const name = $("#marker-name").val().trim();
    const icon = $("#marker-icon").val();
    
    if (name.length === 0) {
        return; // Não deixa salvar sem nome
    }
    
    $.post('https://fdb-mapmenu/saveMarker', JSON.stringify({
        name: name,
        icon: icon,
        coords: currentCoords
    }));
    
    closeUI();
});

// Atualizar Lista
function updateMarkerList(markers) {
    const list = $("#marker-list");
    list.empty();
    
    if (!markers || markers.length === 0) {
        list.append('<li class="marker-item">Nenhuma anotação no mapa.</li>');
        return;
    }
    
    markers.forEach(function(marker) {
        const li = $(`
            <li class="marker-item">
                <div class="marker-info">
                    <span>📝</span>
                    <span>${marker.name}</span>
                </div>
                <button class="btn-delete" data-id="${marker.id}">❌</button>
            </li>
        `);
        
        list.append(li);
    });
    
    // Deletar
    $(".btn-delete").click(function() {
        const id = $(this).data("id");
        $.post('https://fdb-mapmenu/deleteMarker', JSON.stringify({ id: id }));
        $(this).closest('li').remove();
    });
}
