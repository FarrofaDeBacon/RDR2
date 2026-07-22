<script>
    import HUDItem from './HUDItem.svelte';
    import DraggableModule from './DraggableModule.svelte';
    import { coreStatus, horseStatus, survivalEngines, activeBuffs, comms, editorState } from '../store/hudStore';

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

    $: isEditing = $editorState.isEditing;

    // Condicionais de visibilidade (sempre visíveis se estiver editando)
    $: showArmor = isEditing || armor > 0;
    $: showOxygen = isEditing || oxygen < 100;
    $: showHorse = isEditing || (horseHealth > 0 && horseHealth <= 100);

    // Condicionais Survival Engines
    $: showUrine = isEditing || urine > 50;
    $: showHygiene = isEditing || hygiene < 100;
    $: showTemp = isEditing || temp < 15 || temp > 35;
    $: showPoison = isEditing || poison > 0;
    $: showIllness = isEditing || illness > 0;
    $: showDrunkenness = isEditing || drunkenness > 0;

    // Buffs
    $: showColdResistance = isEditing || coldResistance > 0;
    $: showHeatResistance = isEditing || heatResistance > 0;
</script>

<div class="status-cores-container">
    <!-- Saúde -->
    <DraggableModule id="health" defaultX={-240} defaultY={0}>
        <HUDItem 
            itemId="health"
            value={health} 
            innerValue={health} 
            icon="./assets/health.svg" 
            outerColor="#ffffff"
            innerColor={getInnerColor(health, '#ffffff', '#ff0000')}
            isFlashing={health <= 15}
        />
    </DraggableModule>

    <!-- Estamina -->
    <DraggableModule id="stamina" defaultX={-180} defaultY={0}>
        <HUDItem 
            itemId="stamina"
            value={stamina} 
            innerValue={stamina} 
            icon="./assets/stamina.svg" 
            outerColor="#ffd700" 
            innerColor={getInnerColor(stamina, '#ffffff', '#ff0000')}
            isFlashing={stamina <= 10}
        />
    </DraggableModule>

    <!-- Fome -->
    <DraggableModule id="food" defaultX={-120} defaultY={0}>
        <HUDItem 
            itemId="food"
            value={food} 
            innerValue={food} 
            icon="./assets/food.svg" 
            outerColor="#ffa500" 
            innerColor={getInnerColor(food, '#ffffff', '#ff0000')}
            isFlashing={food <= 10}
        />
    </DraggableModule>

    <!-- Sede -->
    <DraggableModule id="water" defaultX={-60} defaultY={0}>
        <HUDItem 
            itemId="water"
            value={water} 
            innerValue={water} 
            icon="./assets/water.svg" 
            outerColor="#00bfff" 
            innerColor={getInnerColor(water, '#ffffff', '#ff0000')}
            isFlashing={water <= 10}
        />
    </DraggableModule>

    <!-- Estresse -->
    <DraggableModule id="stress" defaultX={0} defaultY={0}>
        <HUDItem 
            itemId="stress"
            value={stress} 
            innerValue={stress} 
            icon="./assets/stress.svg" 
            outerColor="#ff4500" 
            innerColor="#ffffff"
            isFlashing={stress >= 90}
        />
    </DraggableModule>

    <!-- Armadura (Condicional) -->
    {#if showArmor}
        <DraggableModule id="armor" defaultX={60} defaultY={0}>
            <HUDItem 
                itemId="armor"
                value={armor} 
                innerValue={armor} 
                icon="./assets/armor.svg" 
                outerColor="#c0c0c0" 
                innerColor="#ffffff"
            />
        </DraggableModule>
    {/if}

    <!-- Oxigênio (Condicional) -->
    {#if showOxygen}
        <DraggableModule id="oxygen" defaultX={120} defaultY={0}>
            <HUDItem 
                itemId="oxygen"
                value={oxygen} 
                innerValue={oxygen} 
                icon="./assets/oxygen.svg" 
                outerColor="#87ceeb" 
                innerColor={getInnerColor(oxygen, '#ffffff', '#ff0000')}
                isFlashing={oxygen <= 20}
            />
        </DraggableModule>
    {/if}

    <!-- Núcleos do Cavalo -->
    {#if showHorse}
        <DraggableModule id="horseHealth" defaultX={-180} defaultY={-60}>
            <HUDItem 
                itemId="horseHealth"
                value={horseHealth} 
                innerValue={horseHealth} 
                icon="./assets/horse_health.svg" 
                outerColor="#ffffff"
                innerColor={getInnerColor(horseHealth, '#ffffff', '#ff0000')}
            />
        </DraggableModule>
        <DraggableModule id="horseStamina" defaultX={-120} defaultY={-60}>
            <HUDItem 
                itemId="horseStamina"
                value={horseStamina} 
                innerValue={horseStamina} 
                icon="./assets/horse_stamina.svg" 
                outerColor="#ffd700"
                innerColor={getInnerColor(horseStamina, '#ffffff', '#ff0000')}
            />
        </DraggableModule>
    {/if}

    <!-- Sobrevivência Hardcore -->
    {#if showUrine}
        <DraggableModule id="urine" defaultX={-60} defaultY={-60}>
            <HUDItem 
                itemId="urine"
                value={urine} 
                innerValue={urine} 
                icon="./assets/urine.svg" 
                outerColor="#ffff00" 
                innerColor={getInnerColorReverse(urine, '#ffffff', '#ff0000', 80)}
                isFlashing={urine >= 90}
            />
        </DraggableModule>
    {/if}

    {#if showHygiene}
        <DraggableModule id="hygiene" defaultX={0} defaultY={-60}>
            <HUDItem 
                itemId="hygiene"
                value={hygiene} 
                innerValue={hygiene} 
                icon="./assets/hygiene.svg" 
                outerColor="#8b4513" 
                innerColor={getInnerColor(hygiene, '#ffffff', '#ff0000')}
            />
        </DraggableModule>
    {/if}

    {#if showTemp}
        <DraggableModule id="temperature" defaultX={60} defaultY={-60}>
            <HUDItem 
                itemId="temperature"
                value={getTempValue(temp)} 
                innerValue={100} 
                icon={temp > 35 ? "./assets/temp_hot.svg" : "./assets/temp_cold.svg"} 
                outerColor={temp < 15 ? "#00ffff" : "#ff4500"} 
                innerColor="#ffffff"
                isFlashing={temp <= 0 || temp >= 45}
            />
        </DraggableModule>
    {/if}

    {#if showPoison}
        <DraggableModule id="poison" defaultX={120} defaultY={-60}>
            <HUDItem 
                itemId="poison"
                value={poison} 
                innerValue={poison} 
                icon="./assets/poison.svg" 
                outerColor="#32cd32" 
                innerColor={getInnerColorReverse(poison, '#ffffff', '#ff0000', 80)}
                isFlashing={poison >= 80}
            />
        </DraggableModule>
    {/if}

    {#if showIllness}
        <DraggableModule id="illness" defaultX={180} defaultY={-60}>
            <HUDItem 
                itemId="illness"
                value={illness} 
                innerValue={illness} 
                icon="./assets/illness.svg" 
                outerColor="#808000" 
                innerColor="#ffffff"
                isFlashing={illness >= 80}
            />
        </DraggableModule>
    {/if}

    {#if showDrunkenness}
        <DraggableModule id="drunkenness" defaultX={240} defaultY={-60}>
            <HUDItem 
                itemId="drunkenness"
                value={drunkenness} 
                innerValue={drunkenness} 
                icon="./assets/alcohol.svg" 
                outerColor="#ff69b4" 
                innerColor="#ffffff"
            />
        </DraggableModule>
    {/if}

    <!-- Buffs Ativos -->
    {#if showColdResistance}
        <DraggableModule id="coldResistance" defaultX={0} defaultY={-120}>
            <HUDItem 
                itemId="coldResistance"
                value={coldResistance > 100 ? 100 : coldResistance} 
                innerValue={100} 
                icon="./assets/buff_cold.svg" 
                outerColor="#00ffff" 
                innerColor="#ffffff"
                isFlashing={coldResistance <= 10}
            />
        </DraggableModule>
    {/if}

    {#if showHeatResistance}
        <DraggableModule id="heatResistance" defaultX={60} defaultY={-120}>
            <HUDItem 
                itemId="heatResistance"
                value={heatResistance > 100 ? 100 : heatResistance} 
                innerValue={100} 
                icon="./assets/buff_heat.svg" 
                outerColor="#ff4500" 
                innerColor="#ffffff"
                isFlashing={heatResistance <= 10}
            />
        </DraggableModule>
    {/if}

    <!-- Voz (pma-voice) -->
    <DraggableModule id="voice" defaultX={120} defaultY={-120}>
        <HUDItem 
            itemId="voice"
            value={voice === 0 ? 33 : (voice === 1 ? 66 : 100)} 
            innerValue={isTalking ? 100 : 0} 
            icon="./assets/voice.svg" 
            outerColor="#aaaaaa" 
            innerColor={isTalking ? "#ffff00" : "#ffffff"}
        />
    </DraggableModule>
</div>

<style>
    .status-cores-container {
        position: absolute;
        bottom: 50px;
        left: 50%;
        /* O container atua apenas como um ponto de ancoragem no centro-inferior. */
        /* Todos os filhos usarão coordenadas absolutas a partir deste ponto. */
        width: 0;
        height: 0;
        overflow: visible;
    }
</style>
