<script>
  import ItemDetails from './ItemDetails.svelte';

  let {
    inventoryType = 'player',
    inventoryLabel,
    inventoryWeight,
    inventoryMaxWeight,
    inventorySlots,
    isShopInventory = false,
    shouldCenterInventory = false,
    t,
    playerName = '',
    playerId = null,
    playerMoney = 0,
    getItemInSlot,
    useItem,
    handleMouseDown,
    showItemInfo,
    hideItemInfo,
    selectedItem,
    showContextMenu,
    errorSlot,
    backpack = null,
    unequipBackpack = null,
    equipmentSlots = null
  } = $props();

  const equipmentIcons = {
    backpack: 'fa-suitcase',
    satchel: 'fa-shopping-bag',
    wallet: 'fa-wallet',
    holster: 'fa-crosshairs'
  };
</script>

<div 
  class="{inventoryType}-inventory-bg" 
  class:centered-player-inventory-bg={inventoryType === 'player' && shouldCenterInventory}
  style={['satchel', 'backpack'].includes(inventoryType) ? `height: calc(9vh + ${Math.ceil(inventorySlots / (inventoryType === 'satchel' ? 4 : 5))} * ((var(--bg-width) - (var(--bg-padding) * 2)) / 5));` : ''}
></div>

<div class="{inventoryType}-inventory-header" class:centered-inventory-header={inventoryType === 'player' && shouldCenterInventory}>
  <div class="header-main-row">
    <div class="inventory-label">
      <p>{inventoryLabel}</p>
    </div>
    <div class="current-weight">
      <img class="weight-icon" src="assets/weight.png" alt={t.weight} />
      <p>{(inventoryWeight / 1000).toFixed(1)} / {(inventoryMaxWeight / 1000).toFixed(1)}</p>
    </div>
  </div>
  {#if inventoryType === 'player'}
    <div class="header-sub-row">
      <div class="current-id">
        <img class="id-icon" src="assets/id.png" alt={t.id} />
        <p>{playerName || playerId || ''}</p>
      </div>
      <div class="current-money">
        <img class="money-icon" src="assets/cash.png" alt={t.cash} />
        <p>${(playerMoney / 100).toFixed(2)}</p>
      </div>
      {#if backpack && backpack.isEquipped && unequipBackpack}
        <div style="display: flex; align-items: center; gap: 8px; margin-left: auto;">
          <div style="display: flex; flex-direction: column; width: 70px;">
            <div style="display: flex; justify-content: space-between; font-size: 9px; color: #ebdcb9; margin-bottom: 2px; font-family: Open Sans, sans-serif; font-weight: bold; text-shadow: 1px 1px 1px black;">
              <span>{backpack.model && backpack.model.includes('satchel') ? 'Bolsa' : 'Mochila'}</span>
              <span>{backpack.durability || 100}%</span>
            </div>
            <div style="width: 100%; height: 5px; background: rgba(0,0,0,0.5); border-radius: 2px; overflow: hidden; border: 1px solid rgba(194,176,128,0.25);">
              <div style="width: {backpack.durability || 100}%; height: 100%; transition: width 0.3s; background: {(backpack.durability || 100) > 50 ? '#55c05a' : ((backpack.durability || 100) > 20 ? '#e08b1a' : '#c93c3c')};"></div>
            </div>
          </div>
          {#if backpack.model && !backpack.model.includes('satchel')}
            <button class="equipped-backpack-header-btn" onclick={unequipBackpack} title="Colocar Mochila no Chão" style="margin-left: 0;">
              <i class="fas fa-suitcase"></i>
            </button>
          {/if}
        </div>
      {/if}
    </div>
  {/if}
</div>

<div 
  class="{inventoryType}-inventory" 
  class:centered-player-inventory={inventoryType === 'player' && shouldCenterInventory}
>
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div class="item-grid">
    {#each Array(inventorySlots) as _, idx}
      {@const slot = idx + 1}
      {@const item = getItemInSlot(slot, inventoryType)}
      <!-- svelte-ignore a11y_no_static_element_interactions -->
      <div 
        id="slot-{slot}"
        class="item-slot" 
        data-slot={slot} 
        class:invalid-slot-highlight={errorSlot === slot}
        ondblclick={() => item && useItem(item)}
        onmousedown={(event) => handleMouseDown(event, slot, inventoryType)}
        onmouseenter={() => item && showItemInfo(item, inventoryType)}
        onmouseleave={hideItemInfo}
        ondragover={(event) => event.preventDefault()}
      >
        {#if inventoryType === 'player' && slot <= 5}
          <div class="item-slot-key">
            <p>{slot}</p>
          </div>
        {/if}

        {#if item}
          <div class="item-slot-img">
            <img src="images/{item.image}" alt="" />
          </div>
          <div class="item-slot-amount">
            <p>x{item.amount}</p>
          </div>
          {#if isShopInventory && item.price}
            <div class="item-price">
              <p>${Number(item.price).toFixed(2)}</p>
            </div>
          {/if}
          {#if isShopInventory && item.buyPrice}
            <div class="item-sell-price">
              <p>{t.sell}: ${Number(item.buyPrice).toFixed(2)}</p>
            </div>
          {/if}
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
  <div class="divider below-grid"></div>

  {#if inventoryType === 'player'}
    <div class="equipment-inventory">
      <div class="item-grid equipment-grid">
        {#each ['backpack', 'satchel', 'wallet', 'holster'] as equipType}
          {@const item = equipmentSlots?.[equipType] || null}
          <!-- svelte-ignore a11y_no_static_element_interactions -->
          <div 
            class="item-slot"
            data-slot={equipType}
            onmousedown={(event) => handleMouseDown(event, equipType, 'equipment')}
            onmouseenter={() => item && showItemInfo(item, 'equipment')}
            onmouseleave={hideItemInfo}
            ondragover={(event) => event.preventDefault()}
          >
            {#if item && item.image}
              <div class="item-slot-img">
                <img src="images/{item.image}" alt="" />
              </div>
              {#if equipType !== 'wallet' && item.info && typeof item.info === 'object' && 'quality' in item.info}
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
            {:else}
              <div class="equipment-placeholder">
                <i class="fas {equipmentIcons[equipType]}"></i>
              </div>
            {/if}
          </div>
        {/each}
      </div>

    </div>
  {/if}
</div>

<!-- Static Item Details in the empty lower area of the Satchel -->
{#if selectedItem && !showContextMenu}
  {#if inventoryType === 'player' && (selectedItem.inventory === 'player' || selectedItem.inventory === 'satchel' || selectedItem.inventory === 'backpack')}
    <div class="satchel-item-details player-details" class:centered-details={shouldCenterInventory}>
      <ItemDetails {selectedItem} />
    </div>
  {:else if inventoryType === 'other' && selectedItem.inventory === 'other'}
    <div class="satchel-item-details other-details">
      <ItemDetails {selectedItem} />
    </div>
  {/if}
{/if}
