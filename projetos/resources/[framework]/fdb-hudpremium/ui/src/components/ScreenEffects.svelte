<script>
    import { coreStatus, survivalEngines } from '../store/hudStore';

    $: stress = $coreStatus.stress;
    $: poison = $survivalEngines.poison;
    $: drunkenness = $survivalEngines.drunkenness;

    // Calcular valores de efeitos
    $: blurAmount = poison > 0 ? (poison / 100) * 10 : 0; // Até 10px de blur
    $: tiltDeg = drunkenness > 0 ? (drunkenness / 100) * 5 : 0; // Até 5 graus de inclinação
    $: isStressed = stress > 80;
    $: isDrunk = drunkenness > 0;
</script>

<div 
    class="screen-effects"
    class:shaking={isStressed}
    class:drunk={isDrunk}
    style="
        --blur-amt: {blurAmount}px;
        --sepia-amt: {drunkenness/100};
        --tilt-deg: {tiltDeg}deg;
        --tilt-deg-neg: -{tiltDeg}deg;
        backdrop-filter: blur(var(--blur-amt)) sepia(var(--sepia-amt)); 
        -webkit-backdrop-filter: blur(var(--blur-amt)) sepia(var(--sepia-amt));
    "
>
    <!-- Sobreposição visual para embriaguez -->
    {#if drunkenness > 0}
        <div class="drunk-overlay" style="opacity: {drunkenness / 200}"></div>
    {/if}

    <!-- Sobreposição pulsante vermelha para estresse extremo -->
    {#if isStressed}
        <div class="stress-overlay"></div>
    {/if}
</div>

<style>
    .screen-effects {
        position: fixed;
        top: -10%;
        left: -10%;
        width: 120%;
        height: 120%;
        pointer-events: none;
        z-index: 9999; /* Fica acima de tudo, ou abaixo da HUD se preferir */
        /* Transição suave para mudanças (exceto a rotação que a gente faria via CSS keyframes para animar contínuo) */
        transition: backdrop-filter 0.5s ease;
    }

    /* Animação CSS para a bebedeira (tilt lento) */
    @keyframes drunkSway {
        0% { transform: rotate(var(--tilt-deg-neg)) scale(1.05); }
        50% { transform: rotate(var(--tilt-deg)) scale(1.05); }
        100% { transform: rotate(var(--tilt-deg-neg)) scale(1.05); }
    }

    /* Aplica keyframes se estiver bebado (sobrescrevendo o style transform para rodar infinito) */
    :global(.screen-effects.drunk) {
        animation: drunkSway 4s infinite ease-in-out;
    }

    /* Animação de tremor de estresse */
    @keyframes stressShake {
        0% { transform: translate(0, 0) scale(1.02); }
        25% { transform: translate(3px, -3px) scale(1.02); }
        50% { transform: translate(-3px, 3px) scale(1.02); }
        75% { transform: translate(-3px, -3px) scale(1.02); }
        100% { transform: translate(3px, 3px) scale(1.02); }
    }

    .shaking {
        animation: stressShake 0.1s infinite cubic-bezier(.36,.07,.19,.97);
    }

    .drunk-overlay {
        position: absolute;
        inset: 0;
        background: radial-gradient(circle, transparent 40%, rgba(200, 100, 0, 0.4) 100%);
        mix-blend-mode: overlay;
    }

    .stress-overlay {
        position: absolute;
        inset: 0;
        background: radial-gradient(circle, transparent 60%, rgba(255, 0, 0, 0.15) 100%);
        animation: pulseStress 1s infinite alternate ease-in-out;
    }

    @keyframes pulseStress {
        from { opacity: 0.5; }
        to { opacity: 1; }
    }
</style>
