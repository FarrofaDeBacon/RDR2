<script>
    import alcohol from '../../public/assets/alcohol.svg?raw';
    import armor from '../../public/assets/armor.svg?raw';
    import buff_cold from '../../public/assets/buff_cold.svg?raw';
    import buff_heat from '../../public/assets/buff_heat.svg?raw';
    import food from '../../public/assets/food.svg?raw';
    import health from '../../public/assets/health.svg?raw';
    import horse_health from '../../public/assets/horse_health.svg?raw';
    import horse_stamina from '../../public/assets/horse_stamina.svg?raw';
    import hygiene from '../../public/assets/hygiene.svg?raw';
    import illness from '../../public/assets/illness.svg?raw';
    import oxygen from '../../public/assets/oxygen.svg?raw';
    import poison from '../../public/assets/poison.svg?raw';
    import stamina from '../../public/assets/stamina.svg?raw';
    import stress from '../../public/assets/stress.svg?raw';
    import temp_cold from '../../public/assets/temp_cold.svg?raw';
    import temp_hot from '../../public/assets/temp_hot.svg?raw';
    import urine from '../../public/assets/urine.svg?raw';
    import voice from '../../public/assets/voice.svg?raw';
    import water from '../../public/assets/water.svg?raw';

    const svgMap = {
        './assets/alcohol.svg': alcohol,
        './assets/armor.svg': armor,
        './assets/buff_cold.svg': buff_cold,
        './assets/buff_heat.svg': buff_heat,
        './assets/food.svg': food,
        './assets/health.svg': health,
        './assets/horse_health.svg': horse_health,
        './assets/horse_stamina.svg': horse_stamina,
        './assets/hygiene.svg': hygiene,
        './assets/illness.svg': illness,
        './assets/oxygen.svg': oxygen,
        './assets/poison.svg': poison,
        './assets/stamina.svg': stamina,
        './assets/stress.svg': stress,
        './assets/temp_cold.svg': temp_cold,
        './assets/temp_hot.svg': temp_hot,
        './assets/urine.svg': urine,
        './assets/voice.svg': voice,
        './assets/water.svg': water,
    };

    export let value = 100;      // Outer ring value (0-100)
    export let innerValue = 100; // Inner core fill value (0-100)
    export let icon = '';        // Image path for the core icon
    export let outerColor = '#ffffff';
    export let innerColor = '#ffffff';
    export let isFlashing = false;

    const radius = 22;
    const circumference = 2 * Math.PI * radius;
    $: strokeDashoffset = circumference - (value / 100) * circumference;

    $: clipHeight = Math.max(0, Math.min(100, innerValue));
    $: svgMarkup = svgMap[icon] || '';
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

    <!-- Inner Core Icon — inline SVG + clip-path fill overlay -->
    {#if svgMarkup}
    <div class="inner-core">
        <div class="icon-wrapper" style="--fill-h: {clipHeight}%">
            <!-- Ghost background icon (semi-transparent) -->
            <div class="icon-ghost" style="color: {innerColor}">
                {@html svgMarkup}
            </div>
            <!-- Filled portion of icon, clipped from bottom -->
            <div class="icon-fill-clip" style="height: {clipHeight}%">
                <div class="icon-filled" style="color: {innerColor}">
                    {@html svgMarkup}
                </div>
            </div>
        </div>
    </div>
    {/if}
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
        transform: rotate(-90deg);
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
        width: 30px;
        height: 30px;
        z-index: 3;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .icon-wrapper {
        position: relative;
        width: 100%;
        height: 100%;
    }

    /* Force all SVGs inside wrapper to fit and respect currentColor */
    .icon-wrapper :global(svg) {
        width: 100%;
        height: 100%;
        display: block;
    }
    
    .icon-wrapper :global(svg path),
    .icon-wrapper :global(svg circle),
    .icon-wrapper :global(svg rect),
    .icon-wrapper :global(svg polygon),
    .icon-wrapper :global(svg ellipse) {
        fill: currentColor !important;
    }

    /* Ghost (dark background icon) */
    .icon-ghost {
        position: absolute;
        top: 0; left: 0;
        width: 100%;
        height: 100%;
        opacity: 0.25;
    }

    /* Clip wrapper: grows from bottom based on fill % */
    .icon-fill-clip {
        position: absolute;
        bottom: 0;
        left: 0;
        width: 100%;
        overflow: hidden;
        transition: height 0.3s ease-out;
    }

    /* Filled icon — anchored to bottom inside clip */
    .icon-filled {
        position: absolute;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 30px; /* fixed height = same as .inner-core */
    }

    @keyframes flash {
        0%   { transform: scale(1);   filter: brightness(1); }
        50%  { transform: scale(1.1); filter: brightness(1.8); }
        100% { transform: scale(1);   filter: brightness(1); }
    }

    .flashing {
        animation: flash 1s infinite ease-in-out;
    }
</style>
