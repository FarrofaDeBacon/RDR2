<script>
  let { 
    contextMenuItem, 
    contextMenuPosition, 
    isTradeActive, 
    t, 
    useItem, 
    addItemToTrade, 
    addItemToTradeWithPrompt, 
    giveItem, 
    dropItem, 
    splitAndPlaceItem, 
    copySerial,
    searchBackpack,
    unequipItem,
    dropEquipmentItem
  } = $props();

  let showSubmenu = $state(null); // 'trade' | 'give' | 'drop' | 'split' | null
</script>

<ul class="context-menu" style="top: {contextMenuPosition.top}; left: {contextMenuPosition.left}">
  {#if (contextMenuItem.name.startsWith("backpack_") || contextMenuItem.name.startsWith("satchel_")) && contextMenuItem.info && (contextMenuItem.info.uid || contextMenuItem.info.stashId)}
    {#if !(contextMenuItem.inventory === 'equipment' && contextMenuItem.name.startsWith("backpack_"))}
      <!-- svelte-ignore a11y_click_events_have_key_events -->
      <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
      <li onclick={() => searchBackpack(contextMenuItem)}>{t.search_backpack || 'Vasculhar'}</li>
    {/if}
  {/if}

  {#if contextMenuItem.inventory === 'equipment'}
    {#if contextMenuItem.name.startsWith("backpack_") || contextMenuItem.name.startsWith("satchel_")}
      <!-- svelte-ignore a11y_click_events_have_key_events -->
      <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
      <li onclick={() => dropEquipmentItem(contextMenuItem)}>{t.drop_to_ground || 'Colocar no Chão'}</li>
    {/if}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li onclick={() => unequipItem(contextMenuItem)}>{t.unequip || 'Desequipar'}</li>
  {/if}

  {#if contextMenuItem.useable}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li onclick={() => useItem(contextMenuItem)}>{t.use}</li>
  {/if}

  {#if isTradeActive}
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li 
      onmouseenter={() => showSubmenu = 'trade'} 
      onmouseleave={() => showSubmenu = null}
    >
      {t.trade}
      {#if showSubmenu === 'trade'}
        <ul class="submenu">
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => addItemToTrade(contextMenuItem, 1)}>{t.single}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => addItemToTrade(contextMenuItem, Math.ceil(contextMenuItem.amount / 2))}>{t.half}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => addItemToTrade(contextMenuItem, contextMenuItem.amount)}>{t.all}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => addItemToTradeWithPrompt(contextMenuItem)}>{t.amount}</li>
        </ul>
      {/if}
    </li>
  {/if}

  {#if contextMenuItem.inventory !== 'equipment'}
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li 
      onmouseenter={() => showSubmenu = 'give'} 
      onmouseleave={() => showSubmenu = null}
    >
      {t.give}
      {#if showSubmenu === 'give'}
        <ul class="submenu">
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => giveItem(contextMenuItem, 1)}>{t.single}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => giveItem(contextMenuItem, 'half')}>{t.half}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => giveItem(contextMenuItem, 'all')}>{t.all}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => giveItem(contextMenuItem, 'enteramount')}>{t.amount}</li>
        </ul>
      {/if}
    </li>

    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li 
      onmouseenter={() => showSubmenu = 'drop'} 
      onmouseleave={() => showSubmenu = null}
    >
      {t.drop}
      {#if showSubmenu === 'drop'}
        <ul class="submenu">
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => dropItem(contextMenuItem, 1)}>{t.single}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => dropItem(contextMenuItem, 'half')}>{t.half}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => dropItem(contextMenuItem, 'all')}>{t.all}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => dropItem(contextMenuItem, 'enteramount')}>{t.amount}</li>
        </ul>
      {/if}
    </li>

    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li 
      onmouseenter={() => showSubmenu = 'split'} 
      onmouseleave={() => showSubmenu = null}
    >
      {t.split || 'Split'}
      {#if showSubmenu === 'split'}
        <ul class="submenu">
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => splitAndPlaceItem(contextMenuItem, 'player', 1)}>{t.single}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => splitAndPlaceItem(contextMenuItem, 'player', 'half')}>{t.half}</li>
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li onclick={() => splitAndPlaceItem(contextMenuItem, 'player', 'enteramount')}>{t.amount}</li>
        </ul>
      {/if}
    </li>
  {:else}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li onclick={() => giveItem(contextMenuItem, 1)}>{t.give}</li>
  {/if}

  {#if contextMenuItem.name && contextMenuItem.name.includes('weapon_')}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <li onclick={() => copySerial(contextMenuItem)}>{t.copy_serial}</li>
  {/if}
</ul>
