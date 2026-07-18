<script>
  // Sem lógica, puramente visual
</script>

<div class="poison-alert" role="alert">
  <span class="icon">☠</span>
  <span class="text">Envenenado</span>
</div>

<style>
  .poison-alert {
    position: absolute;
    bottom: 25vh;
    left: 5vw;
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(0, 0, 0, 0.6);
    border: 1px solid rgba(139, 92, 246, 0.4);
    padding: 6px 12px;
    border-radius: 4px;
    color: #c4b5fd;
    font-size: 0.9rem;
    font-weight: bold;
    text-transform: uppercase;
    letter-spacing: 1px;
    pointer-events: none;
    transition: opacity 0.3s ease;
  }
  .icon {
    font-size: 1.2rem;
  }
</style>
