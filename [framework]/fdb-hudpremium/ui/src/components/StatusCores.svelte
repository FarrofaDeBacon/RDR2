<script>
    import HUDItem from './HUDItem.svelte';
    import { coreStatus, horseStatus, survivalEngines, activeBuffs, comms } from '../store/hudStore';

    // Para facilitar, extraímos as reatividades do store
    $: health = $coreStatus.health;
    $: stamina = $coreStatus.stamina;
    $: food = $coreStatus.food;
    $: water = $coreStatus.water;
    $: stress = $coreStatus.stress;
    $: armor = $coreStatus.armor;
    $: oxygen = $coreStatus.oxygen;

    $: horseHealth = $horseStatus.horseHealth;
    $: horseStamina = $horseStatus.horseStamina;

    // Novos Survival Engines
    $: urine = $survivalEngines.urine;
    $: hygiene = $survivalEngines.hygiene;
    $: temp = $survivalEngines.temp;
    $: poison = $survivalEngines.poison;
    $: illness = $survivalEngines.illness;
    $: drunkenness = $survivalEngines.drunkenness;

    // Buffs Térmicos
    $: coldResistance = $activeBuffs.coldResistance;
    $: heatResistance = $activeBuffs.heatResistance;

    // Voice (pma-voice)
    $: voice = $comms.voice;
    $: isTalking = $comms.isTalking;

    // A cor interna dos ícones baseados no status (ex: vermelho se a vida tiver baixa)
    $: getInnerColor = (val, defaultColor = '#ffffff', dangerColor = '#ff0000', threshold = 20) => val <= threshold ? dangerColor : defaultColor;
    // Invertido para coisas que sobem (ex: estresse, bexiga, veneno)
    $: getInnerColorReverse = (val, defaultColor = '#ffffff', dangerColor = '#ff0000', threshold = 80) => val >= threshold ? dangerColor : defaultColor;
    
    // Clamp para o valor da temperatura
    $: getTempValue = (t) => Math.min(100, t < 15 ? (15 - t)*5 : (t - 35)*5);

    // Condicionais de visibilidade
    $: showArmor = armor > 0;
    $: showOxygen = oxygen < 100;
    $: showHorse = horseHealth > 0 && horseHealth <= 100;

    // Condicionais Survival Engines
    $: showUrine = urine > 50; // Mostra quando bexiga passa da metade
    $: showHygiene = hygiene < 100; // Mostra quando não está 100% limpo
    $: showTemp = temp < 15 || temp > 35; // Mostra em extremos térmicos
    $: showPoison = poison > 0;
    $: showIllness = illness > 0;
    $: showDrunkenness = drunkenness > 0;

    import DraggableModule from './DraggableModule.svelte';
</script>

<div class="status-cores-container">
    <div class="cores-group">
            <!-- Saúde -->
            <DraggableModule id="health">
            
        </DraggableModule>

            <!-- Estamina -->
            <DraggableModule id="stamina">
            
        </DraggableModule>

            <!-- Fome -->
            <DraggableModule id="food">
            
        </DraggableModule>

            <!-- Sede -->
            <DraggableModule id="water">
            
        </DraggableModule>

            <!-- Estresse -->
            <DraggableModule id="stress">
            
        </DraggableModule>

            <!-- Armadura (Condicional) -->
            {#if showArmor}
                <DraggableModule id="armor">
            
        </DraggableModule>
            {/if}

            <!-- Oxigênio (Condicional, só quando embaixo d'agua) -->
            {#if showOxygen}
                <DraggableModule id="oxygen">
            
        </DraggableModule>
            {/if}
        </div>

    <!-- Núcleos do Cavalo -->
    {#if showHorse}
        <div class="horse-group">
                <DraggableModule id="horseHealth">
            
        </DraggableModule>
                <DraggableModule id="horseStamina">
            
        </DraggableModule>
            </div>
    {/if}

    <!-- Sobrevivência Hardcore -->
    <div class="survival-group">
            {#if showUrine}
                <DraggableModule id="urine">
            
        </DraggableModule>
            {/if}

            {#if showHygiene}
                <DraggableModule id="hygiene">
            
        </DraggableModule>
            {/if}

            {#if showTemp}
                <DraggableModule id="temperature">
            
        </DraggableModule>
            {/if}

            {#if showPoison}
                <DraggableModule id="poison">
            
        </DraggableModule>
            {/if}

            {#if showIllness}
                <DraggableModule id="illness">
            
        </DraggableModule>
            {/if}

            {#if showDrunkenness}
                <DraggableModule id="drunkenness">
            
        </DraggableModule>
            {/if}
        </div>

    <!-- Buffs Ativos -->
    <div class="buffs-group">
            {#if coldResistance > 0}
                <DraggableModule id="coldResistance">
            
        </DraggableModule>
            {/if}

            {#if heatResistance > 0}
                <DraggableModule id="heatResistance">
            
        </DraggableModule>
            {/if}
        </div>

    <!-- Voz (pma-voice) -->
    <div class="voice-group">
            <DraggableModule id="voice">
            
        </DraggableModule>
        </div>
</div>

<style>
    .status-cores-container {
        display: flex;
        flex-direction: column;
        gap: 10px;
        position: absolute;
        bottom: 20px;
        left: 50%;
        transform: translateX(-50%);
        align-items: center;
    }

    .cores-group, .horse-group, .survival-group, .buffs-group, .voice-group {
        display: flex;
        flex-direction: row;
        gap: 8px;
    }

    /* O grupo do cavalo pode ficar levemente separado ou com visual distinto */
    .horse-group {
        margin-top: 5px;
    }
</style>
