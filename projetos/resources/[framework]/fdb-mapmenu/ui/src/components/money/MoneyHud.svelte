<script>
  import { money } from '../../stores/hudStore.js'

  function fmt(n) {
    return Number(n).toLocaleString('pt-BR')
  }
</script>

<div class="money-panel" role="region" aria-label="Dinheiro">
  <div class="money-row" aria-label="Dinheiro em espécie: {$money.cash}">
    <span class="icon" aria-hidden="true">$</span>
    <span class="amount">{fmt($money.cash)}</span>
  </div>
  <div class="money-row gold" aria-label="Barras de ouro: {$money.gold}">
    <span class="icon" aria-hidden="true">◈</span>
    <span class="amount">{fmt($money.gold)}</span>
  </div>
</div>

<style>
  .money-panel {
    position: absolute;
    top: 2vh;
    right: 2vw;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 2px;
    pointer-events: none;
  }

  .money-row {
    display: flex;
    align-items: center;
    gap: 4px;
    background: rgba(0,0,0,0.35);
    padding: 2px 8px;
    border-radius: 3px;
    border: 1px solid rgba(255,255,255,0.06);
  }

  .money-row.gold .icon { color: #fbbf24; }
  .money-row.gold .amount { color: #fbbf24; }

  .icon {
    font-size: 0.7rem;
    color: #4ade80;
    font-weight: 700;
  }

  .amount {
    font-size: 0.75rem;
    color: #e2e8f0;
    font-variant-numeric: tabular-nums;
    letter-spacing: 0.5px;
  }
</style>
