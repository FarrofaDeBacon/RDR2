<script>
    import HUDItem from './HUDItem.svelte';
    import { coreStatus, horseStatus, survivalEngines } from '../store/hudStore';

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

    // A cor interna dos ícones baseados no status (ex: vermelho se a vida tiver baixa)
    $: getInnerColor = (val, defaultColor = '#ffffff', dangerColor = '#ff0000', threshold = 20) => val <= threshold ? dangerColor : defaultColor;

    // Condicionais de visibilidade
    $: showArmor = armor > 0;
    $: showOxygen = oxygen < 100;
    $: showHorse = horseHealth > 0 && horseHealth <= 100; // assumindo que o horse status atualize pra 0 quando não montado
</script>

<div class="status-cores-container">
    <div class="cores-group">
        <!-- Saúde -->
        <HUDItem 
            value={health} 
            innerValue={health} 
            icon="/assets/health.png" 
            outerColor="#ffffff"
            innerColor={getInnerColor(health, '#ffffff', '#ff0000')}
            isFlashing={health <= 15}
        />

        <!-- Estamina -->
        <HUDItem 
            value={stamina} 
            innerValue={stamina} 
            icon="/assets/stamina.png" 
            outerColor="#ffd700" 
            innerColor={getInnerColor(stamina, '#ffffff', '#ff0000')}
            isFlashing={stamina <= 10}
        />

        <!-- Fome -->
        <HUDItem 
            value={food} 
            innerValue={food} 
            icon="/assets/food.png" 
            outerColor="#ffa500" 
            innerColor={getInnerColor(food, '#ffffff', '#ff0000')}
            isFlashing={food <= 10}
        />

        <!-- Sede -->
        <HUDItem 
            value={water} 
            innerValue={water} 
            icon="/assets/water.png" 
            outerColor="#00bfff" 
            innerColor={getInnerColor(water, '#ffffff', '#ff0000')}
            isFlashing={water <= 10}
        />

        <!-- Estresse -->
        <HUDItem 
            value={stress} 
            innerValue={stress} 
            icon="/assets/stress.png" 
            outerColor="#ff4500" 
            innerColor="#ffffff"
            isFlashing={stress >= 90}
        />

        <!-- Armadura (Condicional) -->
        {#if showArmor}
            <HUDItem 
                value={armor} 
                innerValue={armor} 
                icon="/assets/armor.png" 
                outerColor="#c0c0c0" 
                innerColor="#ffffff"
            />
        {/if}

        <!-- Oxigênio (Condicional, só quando embaixo d'agua) -->
        {#if showOxygen}
            <HUDItem 
                value={oxygen} 
                innerValue={oxygen} 
                icon="/assets/oxygen.png" 
                outerColor="#87ceeb" 
                innerColor={getInnerColor(oxygen, '#ffffff', '#ff0000')}
                isFlashing={oxygen <= 20}
            />
        {/if}
    </div>

    <!-- Núcleos do Cavalo -->
    {#if showHorse}
        <div class="horse-group">
            <HUDItem 
                value={horseHealth} 
                innerValue={horseHealth} 
                icon="/assets/horse_health.png" 
                outerColor="#ffffff"
                innerColor={getInnerColor(horseHealth, '#ffffff', '#ff0000')}
            />
            <HUDItem 
                value={horseStamina} 
                innerValue={horseStamina} 
                icon="/assets/horse_stamina.png" 
                outerColor="#ffd700"
                innerColor={getInnerColor(horseStamina, '#ffffff', '#ff0000')}
            />
        </div>
    {/if}
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

    .cores-group, .horse-group {
        display: flex;
        flex-direction: row;
        gap: 8px;
    }

    /* O grupo do cavalo pode ficar levemente separado ou com visual distinto */
    .horse-group {
        margin-top: 5px;
    }
</style>
