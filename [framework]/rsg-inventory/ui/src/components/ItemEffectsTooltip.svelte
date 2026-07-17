<script>
  import { ITEM_EFFECTS } from '../lib/itemEffects.js';

  let { itemName = '' } = $props();

  let effects = $derived(ITEM_EFFECTS[itemName] || []);
</script>

{#if effects.length > 0}
  <div class="item-effects-tooltip">
    {#each effects as effect}
      <div class="effect-icon">
        <img src="assets/{effect.icon}" alt={effect.key} />
      </div>
    {/each}
  </div>
{/if}
