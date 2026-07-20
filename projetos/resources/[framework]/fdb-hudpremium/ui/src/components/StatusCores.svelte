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
    <DraggableModule id="PlayerCores">
        <div class="cores-group">
            <!-- Saúde -->
            <HUDItem 
                value={health} 
                innerValue={health} 
                icon="./assets/health.svg" 
                outerColor="#ffffff"
                innerColor={getInnerColor(health, '#ffffff', '#ff0000')}
                isFlashing={health <= 15}
            />

            <!-- Estamina -->
            <HUDItem 
                value={stamina} 
                innerValue={stamina} 
                icon="./assets/stamina.svg" 
                outerColor="#ffd700" 
                innerColor={getInnerColor(stamina, '#ffffff', '#ff0000')}
                isFlashing={stamina <= 10}
            />

            <!-- Fome -->
            <HUDItem 
                value={food} 
                innerValue={food} 
                icon="./assets/food.svg" 
                outerColor="#ffa500" 
                innerColor={getInnerColor(food, '#ffffff', '#ff0000')}
                isFlashing={food <= 10}
            />

            <!-- Sede -->
            <HUDItem 
                value={water} 
                innerValue={water} 
                icon="./assets/water.svg" 
                outerColor="#00bfff" 
                innerColor={getInnerColor(water, '#ffffff', '#ff0000')}
                isFlashing={water <= 10}
            />

            <!-- Estresse -->
            <HUDItem 
                value={stress} 
                innerValue={stress} 
                icon="./assets/stress.svg" 
                outerColor="#ff4500" 
                innerColor="#ffffff"
                isFlashing={stress >= 90}
            />

            <!-- Armadura (Condicional) -->
            {#if showArmor}
                <HUDItem 
                    value={armor} 
                    innerValue={armor} 
                    icon="./assets/armor.svg" 
                    outerColor="#c0c0c0" 
                    innerColor="#ffffff"
                />
            {/if}

            <!-- Oxigênio (Condicional, só quando embaixo d'agua) -->
            {#if showOxygen}
                <HUDItem 
                    value={oxygen} 
                    innerValue={oxygen} 
                    icon="./assets/oxygen.svg" 
                    outerColor="#87ceeb" 
                    innerColor={getInnerColor(oxygen, '#ffffff', '#ff0000')}
                    isFlashing={oxygen <= 20}
                />
            {/if}
        </div>
    </DraggableModule>

    <!-- Núcleos do Cavalo -->
    {#if showHorse}
        <DraggableModule id="HorseCores">
            <div class="horse-group">
                <HUDItem 
                    value={horseHealth} 
                    innerValue={horseHealth} 
                    icon="./assets/horse_health.svg" 
                    outerColor="#ffffff"
                    innerColor={getInnerColor(horseHealth, '#ffffff', '#ff0000')}
                />
                <HUDItem 
                    value={horseStamina} 
                    innerValue={horseStamina} 
                    icon="./assets/horse_stamina.svg" 
                    outerColor="#ffd700"
                    innerColor={getInnerColor(horseStamina, '#ffffff', '#ff0000')}
                />
            </div>
        </DraggableModule>
    {/if}

    <!-- Sobrevivência Hardcore -->
    <DraggableModule id="SurvivalCores">
        <div class="survival-group">
            {#if showUrine}
                <HUDItem 
                    value={urine} 
                    innerValue={urine} 
                    icon="./assets/urine.svg" 
                    outerColor="#ffff00" 
                    innerColor={getInnerColorReverse(urine, '#ffffff', '#ff0000', 80)}
                    isFlashing={urine >= 90}
                />
            {/if}

            {#if showHygiene}
                <HUDItem 
                    value={hygiene} 
                    innerValue={hygiene} 
                    icon="./assets/hygiene.svg" 
                    outerColor="#8b4513" 
                    innerColor={getInnerColor(hygiene, '#ffffff', '#ff0000')}
                />
            {/if}

            {#if showTemp}
                <HUDItem 
                    value={getTempValue(temp)} 
                    innerValue={100} 
                    icon={temp > 35 ? "./assets/temp_hot.svg" : "./assets/temp_cold.svg"} 
                    outerColor={temp < 15 ? "#00ffff" : "#ff4500"} 
                    innerColor="#ffffff"
                    isFlashing={temp <= 0 || temp >= 45}
                />
            {/if}

            {#if showPoison}
                <HUDItem 
                    value={poison} 
                    innerValue={poison} 
                    icon="./assets/poison.svg" 
                    outerColor="#32cd32" 
                    innerColor={getInnerColorReverse(poison, '#ffffff', '#ff0000', 80)}
                    isFlashing={poison >= 80}
                />
            {/if}

            {#if showIllness}
                <HUDItem 
                    value={illness} 
                    innerValue={illness} 
                    icon="./assets/illness.svg" 
                    outerColor="#808000" 
                    innerColor="#ffffff"
                    isFlashing={illness >= 80}
                />
            {/if}

            {#if showDrunkenness}
                <HUDItem 
                    value={drunkenness} 
                    innerValue={drunkenness} 
                    icon="./assets/alcohol.svg" 
                    outerColor="#ff69b4" 
                    innerColor="#ffffff"
                />
            {/if}
        </div>
    </DraggableModule>

    <!-- Buffs Ativos -->
    <DraggableModule id="Buffs">
        <div class="buffs-group">
            {#if coldResistance > 0}
                <HUDItem 
                    value={coldResistance > 100 ? 100 : coldResistance} 
                    innerValue={100} 
                    icon="./assets/buff_cold.svg" 
                    outerColor="#00ffff" 
                    innerColor="#ffffff"
                    isFlashing={coldResistance <= 10}
                />
            {/if}

            {#if heatResistance > 0}
                <HUDItem 
                    value={heatResistance > 100 ? 100 : heatResistance} 
                    innerValue={100} 
                    icon="./assets/buff_heat.svg" 
                    outerColor="#ff4500" 
                    innerColor="#ffffff"
                    isFlashing={heatResistance <= 10}
                />
            {/if}
        </div>
    </DraggableModule>

    <!-- Voz (pma-voice) -->
    <DraggableModule id="Voice">
        <div class="voice-group">
            <HUDItem 
                value={voice === 0 ? 33 : (voice === 1 ? 66 : 100)} 
                innerValue={isTalking ? 100 : 0} 
                icon="./assets/voice.svg" 
                outerColor="#aaaaaa" 
                innerColor={isTalking ? "#ffff00" : "#ffffff"}
            />
        </div>
    </DraggableModule>
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
