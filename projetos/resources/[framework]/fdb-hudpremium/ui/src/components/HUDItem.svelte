<script>
    export let value = 100; // Outer ring value (0-100)
    export let innerValue = 100; // Inner core fill value (0-100)
    export let icon = ''; // Image path for the core icon
    export let outerColor = '#ffffff'; // Color of the outer ring
    export let innerColor = '#ffffff'; // Color of the inner core icon fill
    export let isFlashing = false; // For critical states
    
    // SVG circle properties for the outer ring
    const radius = 22;
    const circumference = 2 * Math.PI * radius;
    $: strokeDashoffset = circumference - (value / 100) * circumference;
</script>

<div class="hud-item" class:flashing={isFlashing}>
    <!-- Fundo metálico (Borda RDR2) -->
    <div class="hud-bg"></div>
    
    <!-- Outer Ring (SVG Progress) -->
    <svg class="outer-ring" width="56" height="56" viewBox="0 0 56 56">
        <circle 
            class="ring-track" 
            cx="28" cy="28" r="{radius}" 
            stroke-width="4" 
            fill="none" 
        />
        <circle 
            class="ring-fill" 
            cx="28" cy="28" r="{radius}" 
            stroke-width="4" 
            fill="none" 
            stroke="{outerColor}" 
            stroke-dasharray="{circumference}"
            stroke-dashoffset="{strokeDashoffset}"
        />
    </svg>

    <!-- Inner Core Icon (Mask / Clip) -->
    <div class="inner-core" style="--icon-url: url('{icon}'); --inner-color: {innerColor}; --fill-percent: {innerValue}%;">
        <!-- Camada base semi-transparente -->
        <div class="core-base"></div>
        <!-- Camada preenchida (cresce de baixo pra cima) -->
        <div class="core-fill"></div>
    </div>
</div>

<style>
    .hud-item {
        position: relative;
        width: 56px;
        height: 56px;
        display: flex;
        justify-content: center;
        align-items: center;
        margin: 4px;
        transition: transform 0.2s ease-out;
    }

    .hud-bg {
        position: absolute;
        width: 100%;
        height: 100%;
        background-image: url('./assets/border_single-CaVJ0brv.png');
        background-size: cover;
        background-position: center;
        z-index: 1;
        opacity: 0.9;
    }

    .outer-ring {
        position: absolute;
        top: 0;
        left: 0;
        z-index: 2;
        transform: rotate(-90deg); /* Começa do topo */
    }

    .ring-track {
        stroke: rgba(0, 0, 0, 0.5);
    }

    .ring-fill {
        transition: stroke-dashoffset 0.3s ease-out, stroke 0.3s ease-out;
        stroke-linecap: round;
    }

    .inner-core {
        position: absolute;
        width: 32px;
        height: 32px;
        z-index: 3;
    }

    .core-base {
        position: absolute;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.4);
        mask-image: var(--icon-url);
        mask-size: contain;
        mask-repeat: no-repeat;
        mask-position: center;
        -webkit-mask-image: var(--icon-url);
        -webkit-mask-size: contain;
        -webkit-mask-repeat: no-repeat;
        -webkit-mask-position: center;
    }

    .core-fill {
        position: absolute;
        bottom: 0;
        width: 100%;
        height: var(--fill-percent);
        background-color: var(--inner-color);
        mask-image: var(--icon-url);
        mask-size: contain;
        mask-repeat: no-repeat;
        mask-position: bottom;
        -webkit-mask-image: var(--icon-url);
        -webkit-mask-size: contain;
        -webkit-mask-repeat: no-repeat;
        -webkit-mask-position: bottom;
        transition: height 0.3s ease-out, background-color 0.3s ease-out;
    }

    /* Flashing effect para quando a barra zera / veneno */
    @keyframes flash {
        0% { transform: scale(1); filter: brightness(1); }
        50% { transform: scale(1.1); filter: brightness(1.5); }
        100% { transform: scale(1); filter: brightness(1); }
    }

    .flashing {
        animation: flash 1s infinite ease-in-out;
    }
</style>
