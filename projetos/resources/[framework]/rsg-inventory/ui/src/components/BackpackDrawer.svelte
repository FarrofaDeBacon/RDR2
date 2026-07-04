<script>
  import { slide } from 'svelte/transition';

  let {
    backpack,
    isOpen,
    toggleDrawer,
    getItemInSlot,
    handleMouseDown,
    showItemInfo,
    hideItemInfo,
    unequipBackpack,
    shouldCenter = false,
    isSatchelData = false
  } = $props();

  function handleSlotMouseDown(event, slot) {
    handleMouseDown(event, slot, 'backpack');
  }

  function handleSlotMouseEnter(item) {
    if (item) {
      showItemInfo(item, 'backpack');
    }
  }

  // isSatchelData é passado explicitamente pelo pai (App.svelte) — true se for bolsa/satchel
  let isSatchel = $derived(isSatchelData || (backpack && (backpack.model === 'p_cs_satchel01x' || backpack.model === 'p_bag01x')));
</script>

<div class="backpack-drawer-container" class:drawer-open={isOpen} class:centered-drawer={shouldCenter}>
  <!-- Clickable leather strap handle -->
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div class="backpack-strap-handle" onclick={toggleDrawer} class:active={isOpen}>
    <div class="strap-buckle"></div>
    <div class="strap-text">{isSatchel ? 'BOLSA' : 'MOCHILA'}</div>
  </div>

  {#if isOpen}
    <div class="backpack-drawer-content" transition:slide={{ axis: 'x', duration: 300 }}>
      <div class="backpack-drawer-inner-border">
        <div class="backpack-header">
          <h3>{isSatchel ? 'BOLSA' : 'MOCHILA'}</h3>
          <p class="backpack-weight">
            {((backpack.items ? Object.values(backpack.items).reduce((acc, it) => acc + (it ? (it.weight * it.amount) : 0), 0) : 0) / 1000).toFixed(1)} / {(backpack.maxweight / 1000).toFixed(1)} Kg
          </p>
        </div>
        
        <div class="item-grid backpack-grid">
          {#each Array(backpack.slots) as _, idx}
            {@const slot = idx + 1}
            {@const item = backpack.items[slot] || null}
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <div 
              id="backpack-slot-{slot}"
              class="item-slot" 
              data-slot={slot}
              onmousedown={(event) => handleSlotMouseDown(event, slot)}
              onmouseenter={() => handleSlotMouseEnter(item)}
              onmouseleave={hideItemInfo}
              ondragover={(event) => event.preventDefault()}
            >
              {#if item}
                <div class="item-slot-img">
                  <img src="images/{item.image}" alt="" />
                </div>
                <div class="item-slot-amount">
                  <p>x{item.amount}</p>
                </div>
                {#if item.info && typeof item.info === 'object' && 'quality' in item.info}
                  <div class="item-slot-durability">
                    <div 
                      class="item-slot-durability-fill"
                      style="width: {item.info.quality}%"
                      class:high={item.info.quality > 75}
                      class:medium={item.info.quality <= 75 && item.info.quality > 25}
                      class:low={item.info.quality <= 25}
                    ></div>
                  </div>
                {/if}
              {/if}
            </div>
          {/each}
        </div>
        {#if backpack.durability !== undefined}
          <div class="backpack-durability-container" style="margin: 10px 15px; text-align: left;">
            <div style="display: flex; justify-content: space-between; font-size: 11px; color: #ccc; margin-bottom: 4px;">
              <span>Integridade</span>
              <span>{backpack.durability}%</span>
            </div>
            <div style="width: 100%; height: 6px; background: rgba(255,255,255,0.1); border-radius: 3px; overflow: hidden; border: 1px solid rgba(0,0,0,0.5);">
              <div style="width: {backpack.durability}%; height: 100%; transition: width 0.3s; background: {backpack.durability > 50 ? '#55c05a' : (backpack.durability > 20 ? '#e08b1a' : '#c93c3c')};"></div>
            </div>
          </div>
        {/if}
        <button class="unequip-btn" onclick={unequipBackpack}>{isSatchel ? 'GUARDAR' : 'DESEQUIPAR'}</button>
      </div>
    </div>
  {/if}
</div>
