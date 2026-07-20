<script>
    export let value = 100;      // Outer ring value (0-100)
    export let innerValue = 100; // Inner core fill value (0-100)
    export let icon = '';        // Image path for the core icon
    export let outerColor = '#ffffff';
    export let innerColor = '#ffffff';
    export let isFlashing = false;

    const radius = 22;
    const circumference = 2 * Math.PI * radius;
    $: strokeDashoffset = circumference - (value / 100) * circumference;

    // Convert hex/named color to CSS filter to colorize a white SVG
    // We render the SVG white and use CSS filter + mix-blend-mode to tint it
    // This is more compatible with embedded Chromium (RedM NUI)
    $: clipHeight = Math.max(0, Math.min(100, innerValue));
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

    <!-- Inner Core Icon — plain <img> + clip-path fill overlay -->
    {#if icon}
    <div class="inner-core">
        <!-- Icon layer: drawn in innerColor using CSS filter chain -->
        <div class="icon-wrapper" style="--fill-h: {clipHeight}%">
            <!-- Dark ghost of icon -->
            <img class="icon-ghost" src={icon} alt="" />
            <!-- Filled portion of icon, clipped from bottom -->
            <div class="icon-fill-clip" style="height: {clipHeight}%">
                <img class="icon-filled" src={icon} alt="" style="color: {innerColor}" />
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

    /* Ghost (dark background icon) */
    .icon-ghost {
        position: absolute;
        top: 0; left: 0;
        width: 100%;
        height: 100%;
        object-fit: contain;
        opacity: 0.25;
        filter: brightness(0) invert(1); /* renders pure white then fades */
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
        object-fit: contain;
        object-position: bottom;
        filter: brightness(0) invert(1); /* makes it white, then tint via mix-blend */
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
