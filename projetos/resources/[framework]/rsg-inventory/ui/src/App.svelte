<script>
  import { onMount, onDestroy } from 'svelte';
  import './main.css';
  import InventoryPanel from './components/InventoryPanel.svelte';
  import ContextMenu from './components/ContextMenu.svelte';
  import TradePanel from './components/TradePanel.svelte';

  // --- Svelte 5 States ---
  let isInventoryOpen = $state(false);
  let backpack = $state(null);
  let satchel = $state(null);
  let isBackpackDrawerOpen = $state(false);
  let playerInventory = $state({});
  let otherInventory = $state({});
  let maxWeight = $state(0);
  let totalSlots = $state(0);
  let playerId = $state(null);
  let playerName = $state(null);
  let cash = $state(0);
  let transferAmount = $state(null);
  let errorSlot = $state(null);
  let busy = $state(false);

  // Other inventory states
  let isOtherInventoryEmpty = $state(true);
  let otherInventoryName = $state("");
  let otherInventoryLabel = $state("Drop");
  let otherInventoryMaxWeight = $state(1000000);
  let otherInventorySlots = $state(100);
  let isShopInventory = $state(false);

  // Context menu states
  let showContextMenu = $state(false);
  let contextMenuPosition = $state({ top: "0px", left: "0px" });
  let contextMenuItem = $state(null);

  // Trade states
  let isTradeActive = $state(false);
  let tradeId = $state(null);
  let tradePartnerName = $state(null);
  let myTradeOffers = $state({});
  let theirTradeOffers = $state({});
  let myTradeAccepted = $state(false);
  let theirTradeAccepted = $state(false);

  // Hotbar states
  let showHotbar = $state(false);
  let hotbarItems = $state([]);
  let wasHotbarEnabled = $state(false);

  // Notifications states
  let showNotification = $state(false);
  let notificationText = $state("");
  let notificationImage = $state("");
  let notificationType = $state("added");
  let notificationAmount = $state(1);
  let notificationDescription = $state("");
  let notificationClass = $state("");
  let notificationTimeout = null;

  // Hover item details state
  let selectedItem = $state(null);

  // Custom drag tracking states
  let isMouseDown = $state(false);
  let mouseDownX = $state(0);
  let mouseDownY = $state(0);
  let isDragging = $state(false);
  let dragX = $state(0);
  let dragY = $state(0);
  let currentlyDraggingItem = $state(null);
  let currentlyDraggingSlot = $state(null);
  let dragStartInventoryType = $state("player");
  const dragThreshold = 5;

  // CSRF token
  let nuiToken = $state(null);

  // Translations
  let t = $state({
    title: 'RSG Inventory',
    close: 'Close',
    close_aria: 'Close inventory',
    use: 'Use',
    give: 'Give',
    single: 'Single',
    half: 'Half',
    all: 'All',
    amount: 'Amount',
    amount_placeholder: 'amount',
    drop: 'Drop',
    copy_serial: 'Copy Serial',
    sell: 'Sell',
    satchel: 'Satchel',
    weight: 'Weight',
    id: 'ID',
    cash: 'Cash',
    received: 'Received',
    used: 'Used',
    removed: 'Removed',
    trade: 'Trade',
    your_offer: 'Your Offer',
    their_offer: 'Their Offer',
    accept: 'Accept',
    waiting: 'Waiting for other player...',
    cancel: 'Cancel',
    accepted: 'Accepted',
    no_items_offered: 'No items offered'
  });

  // --- Svelte 5 Derived (Computed) Properties ---
  const playerWeight = $derived(
    Object.values(playerInventory).reduce((total, item) => {
      if (item && item.weight !== undefined && item.amount !== undefined) {
        return total + item.weight * item.amount;
      }
      return total;
    }, 0)
  );

  const otherInventoryWeight = $derived(
    Object.values(otherInventory).reduce((total, item) => {
      if (item && item.weight !== undefined && item.amount !== undefined) {
        return total + item.weight * item.amount;
      }
      return total;
    }, 0)
  );

  const playerMoney = $derived(cash * 100);
  const shouldCenterInventory = $derived(isOtherInventoryEmpty && !isTradeActive);
  // activeBackpack é o inventário ativo na gaveta — satchel tem prioridade sobre backpack
  const activeBackpack = $derived(satchel || backpack);

  // --- NUI Callback Helper ---
  async function post(event, data = {}) {
    try {
      if (nuiToken) {
        data.token = nuiToken;
      }
      const response = await fetch(`https://rsg-inventory/${event}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
      });
      return await response.json();
    } catch (error) {
      console.error(`Failed callback: ${event}`, error);
      return null;
    }
  }

  async function validateToken(csrfToken) {
    try {
      const response = await fetch("https://rsg-core/validateCSRF", {
        method: "POST",
        headers: {
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify({ clientToken: csrfToken })
      });
      const data = await response.json();
      return data.valid;
    } catch (e) {
      console.error("Error validating CSRF:", e);
      return false;
    }
  }

  // --- Core Methods ---
  function openInventory(data) {
    if (showHotbar) {
      wasHotbarEnabled = true;
      toggleHotbar(false);
    } else {
      wasHotbarEnabled = false;
    }

    isInventoryOpen = true;
    maxWeight = data.maxweight;
    totalSlots = data.slots;
    playerId = data.playerId || null;
    playerName = data.playerName || null;
    playerInventory = {};
    otherInventory = {};

    if (data.labels) {
      t = { ...t, ...data.labels };
    }

    if (data.cash !== undefined) {
      cash = data.cash;
    }

    if (data.inventory) {
      if (Array.isArray(data.inventory)) {
        data.inventory.forEach((item) => {
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        });
      } else if (typeof data.inventory === "object") {
        for (const key in data.inventory) {
          const item = data.inventory[key];
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        }
      }
    }

    if (data.other) {
      if (data.other.inventory) {
        if (Array.isArray(data.other.inventory)) {
          data.other.inventory.forEach((item) => {
            if (item && item.slot) {
              item.inventory = "other";
              otherInventory[item.slot] = item;
            }
          });
        } else if (typeof data.other.inventory === "object") {
          for (const key in data.other.inventory) {
            const item = data.other.inventory[key];
            if (item && item.slot) {
              item.inventory = "other";
              otherInventory[item.slot] = item;
            }
          }
        }
      }

      otherInventoryName = data.other.name;
      otherInventoryLabel = data.other.label || t.drop || otherInventoryLabel;
      otherInventoryMaxWeight = data.other.maxweight;
      otherInventorySlots = data.other.slots;

      isShopInventory = otherInventoryName.startsWith("shop-");
      isOtherInventoryEmpty = false;
    }

    // Backpack NUI data mapping
    if (data.backpack) {
      const itemsMap = {};
      if (Array.isArray(data.backpack.items)) {
        data.backpack.items.forEach((item) => {
          if (item && item.slot) {
            item.inventory = "backpack";
            itemsMap[item.slot] = item;
          }
        });
      } else if (typeof data.backpack.items === "object") {
        for (const key in data.backpack.items) {
          const item = data.backpack.items[key];
          if (item && item.slot) {
            item.inventory = "backpack";
            itemsMap[item.slot] = item;
          }
        }
      }
      
      backpack = {
        ...data.backpack,
        items: itemsMap
      };
    } else {
      backpack = null;
    }

    // Satchel NUI data mapping
    if (data.satchel) {
      const satchelItemsMap = {};
      if (Array.isArray(data.satchel.items)) {
        data.satchel.items.forEach((item) => {
          if (item && item.slot) {
            item.inventory = "backpack";
            satchelItemsMap[item.slot] = item;
          }
        });
      } else if (typeof data.satchel.items === "object") {
        for (const key in data.satchel.items) {
          const item = data.satchel.items[key];
          if (item && item.slot) {
            item.inventory = "backpack";
            satchelItemsMap[item.slot] = item;
          }
        }
      }
      
      satchel = {
        ...data.satchel,
        items: satchelItemsMap
      };
    } else {
      satchel = null;
    }

    // Auto open logic
    if (data.satchel && data.satchel.autoOpen) {
      isBackpackDrawerOpen = true;
    } else if (data.backpack && data.backpack.autoOpen) {
      isBackpackDrawerOpen = true;
    } else {
      isBackpackDrawerOpen = false;
    }

    if (t && t.title) {
      document.title = t.title;
    }
  }

  function updateInventory(data) {
    playerInventory = {};
    if (data.inventory) {
      if (Array.isArray(data.inventory)) {
        data.inventory.forEach((item) => {
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        });
      } else if (typeof data.inventory === "object") {
        for (const key in data.inventory) {
          const item = data.inventory[key];
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        }
      }
    }
  }

  async function closeInventory() {
    let inventoryName = otherInventoryName;
    const currentWasHotbar = wasHotbarEnabled;
    const currentWasTrade = isTradeActive;
    const currentTradeId = tradeId;
    let hotbarItemsList = [];

    if (currentWasHotbar) {
      hotbarItemsList = Array(5).fill(null).map((_, index) => {
        const item = playerInventory[index + 1];
        return item !== undefined ? item : null;
      });
    }

    if (currentWasTrade && currentTradeId) {
      post("CancelTrade", { tradeId: currentTradeId }).catch(() => {});
    }

    // Reset States
    isInventoryOpen = false;
    playerInventory = {};
    otherInventory = {};
    maxWeight = 0;
    totalSlots = 0;
    playerId = null;
    playerName = null;
    cash = 0;
    transferAmount = null;
    isOtherInventoryEmpty = true;
    otherInventoryName = "";
    isShopInventory = false;
    showContextMenu = false;
    isTradeActive = false;
    selectedItem = null;
    backpack = null;
    isBackpackDrawerOpen = false;

    try {
      await post("CloseInventory", { name: inventoryName });
      if (currentWasHotbar) {
        toggleHotbar({
          open: true,
          items: hotbarItemsList,
        });
      }
    } catch (error) {
      console.error("Error closing inventory:", error);
    }
  }

  async function unequipBackpack() {
    closeInventory();
    post("unequipBackpack").catch((error) => {
      console.error("Error unequipping backpack:", error);
    });
  }

  async function unequipSatchel() {
    closeInventory();
    post("unequipSatchel").catch((error) => {
      console.error("Error unequipping satchel:", error);
    });
  }

  function clearTransferAmount() {
    transferAmount = null;
  }

  function getItemInSlot(slot, inventoryType) {
    if (inventoryType === "player") {
      return playerInventory[slot] || null;
    } else if (inventoryType === "other") {
      return otherInventory[slot] || null;
    } else if (inventoryType === "backpack" && activeBackpack) {
      return activeBackpack.items[slot] || null;
    }
    return null;
  }

  function showItemInfo(item, type) {
    if (item) {
      if (showContextMenu || currentlyDraggingItem || isMouseDown) return;
      item.inventory = type;
      selectedItem = item;
    }
  }

  function hideItemInfo() {
    selectedItem = null;
  }

  function toggleHotbar(data) {
    if (data.open) {
      hotbarItems = data.items;
      showHotbar = true;
    } else {
      showHotbar = false;
      hotbarItems = [];
    }
  }

  function showItemNotification(itemData) {
    const item = itemData.item || {};
    const rawType = (itemData.type || '').toLowerCase();

    notificationText = item.label || "";
    notificationImage = item.image ? "images/" + item.image : "";

    const typeMap = {
      add: t.received,
      added: t.received,
      receive: t.received,
      use: t.used,
      used: t.used,
      drop: t.removed,
      remove: t.removed,
      removed: t.removed
    };

    notificationType = typeMap[rawType] || t[rawType] || (rawType ? rawType.charAt(0).toUpperCase() + rawType.slice(1) : "");

    notificationClass = (rawType === 'added') ? 'add'
      : (rawType === 'removed') ? 'remove'
      : (rawType === 'use' || rawType === 'used') ? 'use'
      : (rawType === 'drop') ? 'remove'
      : rawType;

    notificationAmount = itemData.amount || 1;
    const desc = item.info?.description || item.description || "";
    notificationDescription = typeof desc === 'string' ? desc : '';
    showNotification = true;

    if (notificationTimeout) {
      clearTimeout(notificationTimeout);
    }

    notificationTimeout = setTimeout(() => {
      showNotification = false;
      notificationDescription = "";
      notificationTimeout = null;
    }, 3000);
  }

  function inventoryError(slot) {
    const slotElement = document.getElementById(`slot-${slot}`);
    if (slotElement) {
      slotElement.style.backgroundColor = "red";
    }
    post("PlayDropFail", {}).catch((error) => {
      console.error("Error playing drop fail:", error);
    });
    setTimeout(() => {
      if (slotElement) {
        slotElement.style.backgroundColor = "";
      }
    }, 1000);
  }

  function copySerial() {
    if (!contextMenuItem) return;
    const item = contextMenuItem;
    if (item && item.info?.serie) {
      const el = document.createElement("textarea");
      el.value = item.info.serie;
      document.body.appendChild(el);
      el.select();
      document.execCommand("copy");
      document.body.removeChild(el);
    }
  }

  // --- Item Interaction Logic ---
  async function useItem(item) {
    if (!item || item.useable === false) return;
    const playerItemKey = Object.keys(playerInventory).find((key) => playerInventory[key] && playerInventory[key].slot === item.slot);
    if (playerItemKey) {
      try {
        if (item.shouldClose) {
          closeInventory();
        }
        await post("UseItem", {
          inventory: "player",
          item: item,
        });
      } catch (error) {
        console.error("Error using the item: ", error);
      }
    }
    showContextMenu = false;
  }

  async function giveItem(item, quantity) {
    if (item && item.name) {
      const playerHasItem = Object.values(playerInventory).some((invItem) => invItem && invItem.name === item.name);
      if (playerHasItem) {
        let amountToGive;
        if (typeof quantity === "string") {
          switch (quantity) {
            case "half":
              amountToGive = Math.ceil(item.amount / 2);
              break;
            case "all":
              amountToGive = item.amount;
              break;
            case "enteramount":
              const amounttt = await post("GiveItemAmount");
              amountToGive = amounttt;
              break;
            default:
              console.error("Invalid quantity specified.");
              return;
          }
        } else {
          amountToGive = quantity;
        }

        if (amountToGive > item.amount) {
          console.error("Specified quantity exceeds available amount.");
          return;
        }

        try {
          const response = await post("GiveItem", {
            item: item,
            amount: amountToGive,
            slot: item.slot,
            info: item.info,
          });
          if (!response) return;

          playerInventory[item.slot].amount -= amountToGive;
          if (playerInventory[item.slot].amount === 0) {
            delete playerInventory[item.slot];
          }
        } catch (error) {
          console.error("An error occurred while giving the item:", error);
        }
      }
    }
    showContextMenu = false;
  }

  async function dropItem(item, quantity) {
    if (item && item.name) {
      const playerItemKey = Object.keys(playerInventory).find((key) =>
        playerInventory[key] && playerInventory[key].slot === item.slot
      );

      if (playerItemKey) {
        let amountToGive;
        if (typeof quantity === "string") {
          switch (quantity) {
            case "half":
              amountToGive = Math.ceil(item.amount / 2);
              break;
            case "all":
              amountToGive = item.amount;
              break;
            case "enteramount":
              const amounttt = await post("GiveItemAmount");
              amountToGive = amounttt;
              break;
            default:
              console.error("Invalid quantity specified.");
              return;
          }
        } else if (typeof quantity === "number" && quantity > 0) {
          amountToGive = quantity;
        }

        if (amountToGive > item.amount) {
          amountToGive = item.amount;
        }

        const newItem = {
          ...item,
          amount: amountToGive,
          slot: 1,
          inventory: "other",
        };

        try {
          const response = await post("DropItem", {
            ...newItem,
            fromSlot: item.slot,
          });

          if (response) {
            const remainingAmount = playerInventory[playerItemKey].amount - amountToGive;
            if (remainingAmount <= 0) {
              delete playerInventory[playerItemKey];
            } else {
              playerInventory[playerItemKey].amount = remainingAmount;
            }

            otherInventory[1] = newItem;
            otherInventoryName = response;
            otherInventoryLabel = response;
            isOtherInventoryEmpty = false;
          }
        } catch (error) {
          inventoryError(item.slot);
        }
      }
    }
    showContextMenu = false;
  }

  async function splitAndPlaceItem(item, inventoryType, splitamount = 'half') {
    const inventoryRef = inventoryType === "player" ? playerInventory : (inventoryType === "backpack" && activeBackpack ? activeBackpack.items : otherInventory);
    let amount = 1;
    if (item && item.amount > 1) {
      if (splitamount === 'half') {
        amount = Math.ceil(item.amount / 2);
      } else if (splitamount === 'enteramount') {
        const inputAmount = await post("GiveItemAmount");
        amount = inputAmount;
        if (amount < 1) amount = 1;
        if (amount > item.amount) amount = item.amount;
      } else if (typeof splitamount === 'number') {
        amount = splitamount;
      }

      const originalSlot = Object.keys(inventoryRef).find((key) => inventoryRef[key] === item);
      if (originalSlot !== undefined) {
        const newItem = { ...item, amount: amount };
        const nextSlot = findNextAvailableSlot(inventoryRef);
        if (nextSlot !== null) {
          inventoryRef[nextSlot] = newItem;
          inventoryRef[originalSlot] = { ...item, amount: item.amount - amount };
          postInventoryData(inventoryType, inventoryType, originalSlot, nextSlot, item.amount, newItem.amount);
        }
      }
    }
    showContextMenu = false;
  }

  function findNextAvailableSlot(inventory) {
    for (let slot = 1; slot <= totalSlots; slot++) {
      if (!inventory[slot]) {
        return slot;
      }
    }
    return null;
  }

  function postInventoryData(fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount) {
    busy = true;
    let fromInventoryName = fromInventory === "other" ? otherInventoryName : (fromInventory === "backpack" && activeBackpack ? activeBackpack.uid : fromInventory);
    let toInventoryName = toInventory === "other" ? otherInventoryName : (toInventory === "backpack" && activeBackpack ? activeBackpack.uid : toInventory);

    post("SetInventoryData", {
      fromInventory: fromInventoryName,
      toInventory: toInventoryName,
      fromSlot,
      toSlot,
      fromAmount,
      toAmount,
    })
    .then(() => {
      clearDragData();
      busy = false;
    })
    .catch((error) => {
      console.error("Error posting inventory data:", error);
      busy = false;
    });
  }

  function moveItemBetweenInventories(item, sourceInventoryType) {
    if (busy) return;
    busy = true;
    const sourceInventory = sourceInventoryType === "player" ? playerInventory : otherInventory;
    const targetInventory = sourceInventoryType === "player" ? otherInventory : playerInventory;
    const amountToTransfer = transferAmount !== null ? transferAmount : 1;
    let targetSlot = null;

    const sourceItem = sourceInventory[item.slot];
    if (!sourceItem || sourceItem.amount < amountToTransfer) {
      inventoryError(item.slot);
      busy = false;
      return;
    }

    const totalWeightAfterTransfer = otherInventoryWeight + sourceItem.weight * amountToTransfer;
    if (totalWeightAfterTransfer > otherInventoryMaxWeight) {
      inventoryError(item.slot);
      busy = false;
      return;
    }

    if (playerInventory !== targetInventory) {
      if (findNextAvailableSlot(targetInventory) > otherInventorySlots) {
        inventoryError(item.slot);
        busy = false;
        return;
      }
    }

    if (item.unique) {
      targetSlot = findNextAvailableSlot(targetInventory);
      if (targetSlot === null) {
        inventoryError(item.slot);
        busy = false;
        return;
      }

      const newItem = {
        ...item,
        inventory: sourceInventoryType === "player" ? "other" : "player",
        amount: amountToTransfer,
      };
      targetInventory[targetSlot] = newItem;
      newItem.slot = targetSlot;
    } else {
      const targetItemKey = Object.keys(targetInventory).find((key) => 
        targetInventory[key] && targetInventory[key].name === item.name && targetInventory[key].info.quality === item.info.quality
      );
      const targetItem = targetInventory[targetItemKey];

      if (!targetItem) {
        const newItem = {
          ...item,
          inventory: sourceInventoryType === "player" ? "other" : "player",
          amount: amountToTransfer,
        };

        targetSlot = findNextAvailableSlot(targetInventory);
        if (targetSlot === null) {
          inventoryError(item.slot);
          busy = false;
          return;
        }

        targetInventory[targetSlot] = newItem;
        newItem.slot = targetSlot;
      } else {
        targetItem.amount += amountToTransfer;
        targetSlot = targetItem.slot;
      }
    }

    sourceItem.amount -= amountToTransfer;
    if (sourceItem.amount <= 0) {
      delete sourceInventory[item.slot];
    }

    postInventoryData(sourceInventoryType, sourceInventoryType === "player" ? "other" : "player", item.slot, targetSlot, sourceItem.amount, amountToTransfer);
  }

  // --- Drag & Drop Core Handlers ---
  function handleMouseDown(event, slot, inventory) {
    if (event.button === 1) return;
    event.preventDefault();
    const itemInSlot = getItemInSlot(slot, inventory);
    if (event.button === 0) {
      if (event.shiftKey && itemInSlot) {
        splitAndPlaceItem(itemInSlot, inventory);
      } else {
        isMouseDown = true;
        mouseDownX = event.clientX;
        mouseDownY = event.clientY;
        currentlyDraggingSlot = slot;
        dragStartInventoryType = inventory;
        currentlyDraggingItem = itemInSlot;
      }
    } else if (event.button === 2 && itemInSlot) {
      if (isShopInventory && inventory === "other") {
        handlePurchase(itemInSlot.slot, itemInSlot, 1, inventory);
        return;
      }
      if (!isOtherInventoryEmpty) {
        moveItemBetweenInventories(itemInSlot, inventory);
      } else {
        showContextMenuOptions(event, itemInSlot);
      }
    }
  }

  function handleMouseMove(event) {
    if (isMouseDown && !isDragging && currentlyDraggingItem) {
      const dx = Math.abs(event.clientX - mouseDownX);
      const dy = Math.abs(event.clientY - mouseDownY);
      if (dx >= dragThreshold || dy >= dragThreshold) {
        isDragging = true;
        hideItemInfo();
      }
    }

    if (isDragging) {
      dragX = event.clientX - 35; // centered relative offset
      dragY = event.clientY - 35;
    }
  }

  function handleMouseUp(event) {
    if (isMouseDown) {
      isMouseDown = false;
      if (isDragging && currentlyDraggingItem) {
        isDragging = false;

        const targetPlayerItemSlotElement = event.target.closest(".player-inventory .item-slot");
        if (targetPlayerItemSlotElement) {
          const targetSlot = Number(targetPlayerItemSlotElement.dataset.slot);
          if (targetSlot && !(targetSlot === currentlyDraggingSlot && dragStartInventoryType === "player")) {
            handleDropOnPlayerSlot(targetSlot);
          }
        }

        const targetOtherItemSlotElement = event.target.closest(".other-inventory .item-slot");
        if (targetOtherItemSlotElement) {
          const targetSlot = Number(targetOtherItemSlotElement.dataset.slot);
          if (targetSlot && !(targetSlot === currentlyDraggingSlot && dragStartInventoryType === "other")) {
            handleDropOnOtherSlot(targetSlot);
          }
        }

        const targetBackpackItemSlotElement = event.target.closest(".satchel-grid .item-slot");
        if (targetBackpackItemSlotElement) {
          const targetSlot = Number(targetBackpackItemSlotElement.dataset.slot);
          if (targetSlot && !(targetSlot === currentlyDraggingSlot && dragStartInventoryType === "backpack")) {
            handleItemDrop("backpack", targetSlot);
          }
        }

        const targetTradeContainer = event.target.closest(".trade-container, .trade-panel, .trade-items");
        if (targetTradeContainer && dragStartInventoryType === "player" && isTradeActive) {
          const amount = transferAmount !== null ? transferAmount : currentlyDraggingItem.amount;
          addItemToTrade(currentlyDraggingItem, amount);
        } else {
          const targetInventoryContainer = event.target.closest(".inventory-container");
          if (targetInventoryContainer && !targetPlayerItemSlotElement && !targetOtherItemSlotElement && !targetBackpackItemSlotElement) {
            handleDropOnInventoryContainer();
          }
        }
      }
      clearDragData();
    }
  }

  function handleDropOnPlayerSlot(targetSlot) {
    if (isShopInventory && dragStartInventoryType === "other") {
      const targetInventory = playerInventory;
      const targetItem = targetInventory[targetSlot];
      if ((targetItem && targetItem.name !== currentlyDraggingItem.name)
        || (targetItem && targetItem.name === currentlyDraggingItem.name && currentlyDraggingItem.unique)
        || (targetItem && targetItem.name === currentlyDraggingItem.name && targetItem.info && typeof targetItem.info === 'object' && targetItem.info.quality && targetItem.info.quality !== 100)) {
        inventoryError(currentlyDraggingSlot);
        return;
      }
      handlePurchase(currentlyDraggingSlot, currentlyDraggingItem, transferAmount, dragStartInventoryType, targetSlot);
    } else {
      handleItemDrop("player", targetSlot);
    }
  }

  function handleDropOnOtherSlot(targetSlot) {
    handleItemDrop("other", targetSlot);
  }

  async function handleDropOnInventoryContainer() {
    if (isOtherInventoryEmpty && dragStartInventoryType === "player") {
      const newItem = {
        ...currentlyDraggingItem,
        amount: currentlyDraggingItem.amount,
        slot: 1,
        inventory: "other",
      };
      const draggingItem = currentlyDraggingItem;
      try {
        const response = await post("DropItem", {
          ...newItem,
          fromSlot: currentlyDraggingSlot,
        });

        if (response) {
          otherInventory[1] = newItem;
          const draggingItemKey = Object.keys(playerInventory).find((key) => playerInventory[key] === draggingItem);
          if (draggingItemKey) {
            delete playerInventory[draggingItemKey];
          }
          otherInventoryName = response;
          otherInventoryLabel = response;
          isOtherInventoryEmpty = false;
          clearDragData();
        }
      } catch (error) {
        inventoryError(currentlyDraggingSlot);
      }
    }
    clearDragData();
  }

  function handleItemDrop(targetInventoryType, targetSlot) {
    try {
      const isShop = otherInventoryName.indexOf("shop-");
      if (dragStartInventoryType === "other" && targetInventoryType === "other" && isShop !== -1) {
        return;
      }

      const targetSlotNumber = parseInt(targetSlot, 10);
      if (isNaN(targetSlotNumber)) return;

      const sourceInventory = dragStartInventoryType === "player" ? playerInventory : (dragStartInventoryType === "backpack" && activeBackpack ? activeBackpack.items : otherInventory);
      const targetInventory = targetInventoryType === "player" ? playerInventory : (targetInventoryType === "backpack" && activeBackpack ? activeBackpack.items : otherInventory);

      const sourceItem = sourceInventory[currentlyDraggingSlot];
      if (!sourceItem) return;

      const amountToTransfer = transferAmount !== null ? transferAmount : sourceItem.amount;
      if (sourceItem.amount < amountToTransfer) return;

      if (dragStartInventoryType === "player" && targetInventoryType === "other" && isShop !== -1) {
        handlePurchase(
          currentlyDraggingSlot,
          sourceItem,
          transferAmount !== null ? transferAmount : sourceItem.amount,
          dragStartInventoryType
        );
        return;
      }

      if (targetInventoryType !== dragStartInventoryType) {
        if (targetInventoryType === "other") {
          const totalWeightAfterTransfer = otherInventoryWeight + sourceItem.weight * amountToTransfer;
          if (totalWeightAfterTransfer > otherInventoryMaxWeight) {
            throw new Error("Weight capacity exceeded");
          }
        } else if (targetInventoryType === "player") {
          const totalWeightAfterTransfer = playerWeight + sourceItem.weight * amountToTransfer;
          if (totalWeightAfterTransfer > maxWeight) {
            throw new Error("Weight capacity exceeded");
          }
        } else if (targetInventoryType === "backpack" && activeBackpack) {
          const currentBackpackWeight = Object.values(activeBackpack.items).reduce((acc, it) => acc + (it ? (it.weight * it.amount) : 0), 0);
          const totalWeightAfterTransfer = currentBackpackWeight + sourceItem.weight * amountToTransfer;
          if (totalWeightAfterTransfer > activeBackpack.maxweight) {
            throw new Error("Weight capacity exceeded");
          }
        }
      }

      const targetItem = targetInventory[targetSlotNumber];

      if (targetItem) {
        if (sourceItem.name === targetItem.name && targetItem.unique) {
          inventoryError(currentlyDraggingSlot);
          return;
        }
        const sourceQuality = (sourceItem.info && typeof sourceItem.info === 'object') ? sourceItem.info.quality : null;
        const targetQuality = (targetItem.info && typeof targetItem.info === 'object') ? targetItem.info.quality : null;
        if (sourceItem.name === targetItem.name && !targetItem.unique && sourceQuality === targetQuality) {
          targetItem.amount += amountToTransfer;
          sourceItem.amount -= amountToTransfer;
          if (sourceItem.amount <= 0) {
            delete sourceInventory[currentlyDraggingSlot];
          }
          postInventoryData(dragStartInventoryType, targetInventoryType, currentlyDraggingSlot, targetSlotNumber, sourceItem.amount, amountToTransfer);
        } else {
          sourceInventory[currentlyDraggingSlot] = targetItem;
          targetInventory[targetSlotNumber] = sourceItem;
          sourceInventory[currentlyDraggingSlot].slot = currentlyDraggingSlot;
          sourceInventory[currentlyDraggingSlot].inventory = dragStartInventoryType;
          targetInventory[targetSlotNumber].slot = targetSlotNumber;
          targetInventory[targetSlotNumber].inventory = targetInventoryType;
          postInventoryData(dragStartInventoryType, targetInventoryType, currentlyDraggingSlot, targetSlotNumber, sourceItem.amount, targetItem.amount);
        }
      } else {
        sourceItem.amount -= amountToTransfer;
        if (sourceItem.amount <= 0) {
          delete sourceInventory[currentlyDraggingSlot];
        }
        targetInventory[targetSlotNumber] = { ...sourceItem, amount: amountToTransfer, slot: targetSlotNumber, inventory: targetInventoryType };
        postInventoryData(dragStartInventoryType, targetInventoryType, currentlyDraggingSlot, targetSlotNumber, sourceItem.amount, amountToTransfer);
      }
    } catch (error) {
      console.error(error);
      inventoryError(currentlyDraggingSlot);
    } finally {
      clearDragData();
    }
  }

  async function handlePurchase(sourceSlot, sourceItem, transferAmt, sourceInventoryType, targetSlot = null) {
    if (busy) return;
    if (sourceItem.amount < 1) {
      inventoryError(sourceSlot);
      return;
    }

    busy = true;
    try {
      const response = await post("AttemptPurchase", {
        item: sourceItem,
        amount: transferAmt || 1,
        shop: otherInventoryName,
        sourceinvtype: sourceInventoryType,
        targetslot: targetSlot,
      });

      if (response) {
        if (!sourceItem.amount) {
          busy = false;
          return;
        }

        const amountToTransfer = transferAmt !== null ? transferAmt : 1;
        if (sourceInventoryType === 'player') {
          for (const key in otherInventory) {
            const item = otherInventory[key];
            if (item.name === sourceItem.name && item.amount !== undefined) {
              otherInventory[key].amount += amountToTransfer;
              break;
            }
          }
        } else {
          if (sourceItem.amount < amountToTransfer) {
            inventoryError(sourceSlot);
            busy = false;
            return;
          }
          sourceItem.amount -= amountToTransfer;
        }
      } else {
        inventoryError(sourceSlot);
      }
    } catch (error) {
      inventoryError(sourceSlot);
    } finally {
      busy = false;
    }
  }

  function clearDragData() {
    currentlyDraggingItem = null;
    currentlyDraggingSlot = null;
    isDragging = false;
  }

  // --- Trade UI Action Wrappers ---
  function openTrade(data) {
    isInventoryOpen = true;
    maxWeight = data.maxweight || 0;
    totalSlots = data.slots || 0;
    playerId = data.playerId || null;
    playerName = data.playerName || null;
    cash = data.cash || 0;
    playerInventory = {};
    otherInventory = {};
    isOtherInventoryEmpty = true;

    if (data.labels) {
      t = { ...t, ...data.labels };
    }

    if (data.inventory) {
      if (Array.isArray(data.inventory)) {
        data.inventory.forEach((item) => {
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        });
      } else if (typeof data.inventory === "object") {
        for (const key in data.inventory) {
          const item = data.inventory[key];
          if (item && item.slot) {
            item.inventory = "player";
            playerInventory[item.slot] = item;
          }
        }
      }
    }

    tradeId = data.tradeId;
    tradePartnerName = data.partnerName;
    myTradeOffers = {};
    theirTradeOffers = {};
    myTradeAccepted = false;
    theirTradeAccepted = false;
    isTradeActive = true;
  }

  function updateTrade(data) {
    const tradeData = data.tradeData;
    const myId = Number(playerId);
    const isInitiator = Number(tradeData.initiator) === myId;
    myTradeAccepted = isInitiator ? tradeData.initiatorAccepted : tradeData.targetAccepted;
    theirTradeAccepted = isInitiator ? tradeData.targetAccepted : tradeData.initiatorAccepted;
    myTradeOffers = isInitiator ? tradeData.initiatorItems : tradeData.targetItems;
    theirTradeOffers = isInitiator ? tradeData.targetItems : tradeData.initiatorItems;
  }

  function cancelTradeUI() {
    isTradeActive = false;
    tradeId = null;
    tradePartnerName = null;
    myTradeOffers = {};
    theirTradeOffers = {};
    myTradeAccepted = false;
    theirTradeAccepted = false;
  }

  function completeTradeUI() {
    cancelTradeUI();
    closeInventory();
  }

  function addItemToTrade(item, amount) {
    if (!isTradeActive || !tradeId) return;
    const amountToAdd = amount !== undefined ? amount : item.amount;
    if (amountToAdd < 1 || amountToAdd > item.amount) return;
    post("AddTradeItem", {
      tradeId: tradeId,
      item: item,
      amount: amountToAdd,
    }).catch((error) => {
      console.error("Error adding item to trade:", error);
    });
    showContextMenu = false;
  }

  async function addItemToTradeWithPrompt(item) {
    if (!isTradeActive || !tradeId) return;
    try {
      const amount = await post("GiveItemAmount");
      if (amount && amount > 0 && amount <= item.amount) {
        addItemToTrade(item, amount);
      }
    } catch (error) {
      console.error("Error getting trade amount:", error);
    }
    showContextMenu = false;
  }

  function removeItemFromTrade(tradeSlot) {
    if (!isTradeActive || !tradeId) return;
    post("RemoveTradeItem", {
      tradeId: tradeId,
      tradeSlot: tradeSlot,
    }).catch((error) => {
      console.error("Error removing item from trade:", error);
    });
  }

  function confirmTrade() {
    if (!isTradeActive || !tradeId) return;
    post("ConfirmTrade", { tradeId: tradeId }).catch((error) => {
      console.error("Error confirming trade:", error);
    });
  }

  function cancelTrade() {
    if (!isTradeActive || !tradeId) return;
    post("CancelTrade", { tradeId: tradeId }).catch((error) => {
      console.error("Error cancelling trade:", error);
    });
  }

  async function searchBackpack(item) {
    if (item && item.name.startsWith("backpack_") && item.info && item.info.uid) {
      try {
        const data = await post("GetBackpackStashData", { uid: item.info.uid, model: item.info.model || "p_ambpack02x" });
        if (data) {
          const itemsMap = {};
          if (Array.isArray(data.items)) {
            data.items.forEach((it) => {
              if (it && it.slot) {
                it.inventory = "backpack";
                itemsMap[it.slot] = it;
              }
            });
          } else if (typeof data.items === "object") {
            for (const key in data.items) {
              const it = data.items[key];
              if (it && it.slot) {
                it.inventory = "backpack";
                itemsMap[it.slot] = it;
              }
            }
          }
          backpack = {
            ...data,
            items: itemsMap
          };
          isBackpackDrawerOpen = true;
        }
      } catch (error) {
        console.error("Error searching backpack:", error);
      }
    }
    showContextMenu = false;
  }

  function showContextMenuOptions(event, item) {
    event.preventDefault();
    if (contextMenuItem && contextMenuItem.name === item.name && showContextMenu) {
      showContextMenu = false;
      contextMenuItem = null;
    } else {
      hideItemInfo();
      const menuLeft = event.clientX;
      const menuTop = event.clientY;
      showContextMenu = true;
      contextMenuPosition = {
        top: `${menuTop}px`,
        left: `${menuLeft}px`,
      };
      contextMenuItem = item;
    }
  }

  // --- NUI Message Handler ---
  const handleMessage = async (event) => {
    if (event.data.invToken) {
      nuiToken = event.data.invToken;
      window.nuiToken = event.data.invToken;
    }

    switch (event.data.action) {
      case "open":
        const valid = await validateToken(event.data.token);
        if (valid) openInventory(event.data);
        break;
      case "close":
        closeInventory();
        break;
      case "update":
        if (await validateToken(event.data.token)) {
          updateInventory(event.data);
        }
        break;
      case "toggleHotbar":
        if (await validateToken(event.data.token)) {
          toggleHotbar(event.data);
        }
        break;
      case "itemBox":
        if (event.data.labels) {
          t = { ...t, ...event.data.labels };
        }
        showItemNotification(event.data);
        break;
      case "updateHotbar":
        if (await validateToken(event.data.token)) {
          hotbarItems = event.data.items;
        }
        break;
      case "openTrade":
        if (await validateToken(event.data.token)) {
          openTrade(event.data);
        }
        break;
      case "updateTrade":
        if (await validateToken(event.data.token)) {
          updateTrade(event.data);
        }
        break;
      case "cancelTrade":
        if (await validateToken(event.data.token)) {
          cancelTradeUI();
        }
        break;
      case "completeTrade":
        if (await validateToken(event.data.token)) {
          completeTradeUI();
        }
        break;
    }
  };

  const handleKeyUp = (event) => {
    const code = event.code;
    if (code === "Escape" || code === "Tab" || code === "KeyI") {
      if (isInventoryOpen) closeInventory();
    }
  };

  onMount(() => {
    window.addEventListener("message", handleMessage);
    window.addEventListener("keyup", handleKeyUp);
  });

  onDestroy(() => {
    window.removeEventListener("message", handleMessage);
    window.removeEventListener("keyup", handleKeyUp);
  });
</script>

<svelte:window 
  onmousemove={handleMouseMove}
  onmouseup={handleMouseUp}
/>

{#if isInventoryOpen}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div class="inventory-container" onclick={() => { showContextMenu = false; hideItemInfo(); }}>
    
    <div class="inventory-main-layout">
      <!-- ======================================================== -->
      <!-- COLUNA 1 — BOLSO (Sempre Visível) -->
      <!-- ======================================================== -->
      <div class="inventory-column pocket-column">
        <!-- Seção Superior: Silhueta + Carteira e Status -->
        <div class="pocket-header-wrapper">
          <div class="character-silhouette">
            <img src="assets/silhouette.png" alt="" class="silhouette-img" />
          </div>
          
          <div class="status-and-wallet">
            <!-- Carteira em Destaque Dourado -->
            <div class="wallet-container gold-glow">
              <div class="wallet-header">CARTEIRA</div>
              <div class="wallet-balance">
                <span class="currency-symbol">$</span>
                <span class="amount">{(playerMoney / 100).toFixed(2)}</span>
              </div>
            </div>
            
            <!-- Ações rápidas de Mochila e Bolsa equipadas no cabeçalho -->
            <div class="equipment-indicators">
              {#if backpack && backpack.isEquipped && unequipBackpack}
                <div class="equip-indicator-item">
                  <div class="durability-mini">
                    <span class="indicator-label">MOCHILA</span>
                    <div class="mini-bar-bg">
                      <div class="mini-bar-fill" style="width: {backpack.durability || 100}%; background: {(backpack.durability || 100) > 50 ? '#55c05a' : ((backpack.durability || 100) > 20 ? '#e08b1a' : '#c93c3c')};"></div>
                    </div>
                  </div>
                  <button class="equipped-btn" onclick={unequipBackpack} title="Colocar Mochila no Chão">
                    <i class="fas fa-suitcase"></i>
                  </button>
                </div>
              {/if}

              {#if satchel && satchel.isEquipped && unequipSatchel}
                <div class="equip-indicator-item">
                  <div class="durability-mini">
                    <span class="indicator-label">BOLSA</span>
                    <div class="mini-bar-bg">
                      <div class="mini-bar-fill" style="width: {satchel.durability || 100}%; background: {(satchel.durability || 100) > 50 ? '#55c05a' : ((satchel.durability || 100) > 20 ? '#e08b1a' : '#c93c3c')};"></div>
                    </div>
                  </div>
                  <button class="equipped-btn" onclick={unequipSatchel} title="Guardar Bolsa nos Bolsos">
                    <i class="fas fa-briefcase"></i>
                  </button>
                </div>
              {/if}
            </div>
          </div>
        </div>

        <!-- Seção do Cinto de Munição -->
        <div class="ammo-belt-section" class:disabled={!satchel || !satchel.isEquipped}>
          <div class="section-title">CINTO DE MUNIÇÃO</div>
          <div class="ammo-calibers-grid">
            <div class="caliber-row">
              <span>PISTOLA / REVOLVER</span>
              <div class="caliber-bar-bg"><div class="caliber-bar-fill green" style="width: 85%"></div></div>
            </div>
            <div class="caliber-row">
              <span>RIFLE / REPETIDORA</span>
              <div class="caliber-bar-bg"><div class="caliber-bar-fill orange" style="width: 45%"></div></div>
            </div>
            <div class="caliber-row">
              <span>ESCOPETA (SHOTGUN)</span>
              <div class="caliber-bar-bg"><div class="caliber-bar-fill red" style="width: 15%"></div></div>
            </div>
          </div>
        </div>

        <!-- Grade de Itens do Bolso -->
        <div class="pocket-grid-wrapper">
          <div class="column-header">
            <h3>BOLSO</h3>
            <div class="header-right">
              <span class="playerNameText">{playerName || playerId || ''}</span>
              <span class="weight-text">{(playerWeight/1000).toFixed(1)}/{(maxWeight/1000).toFixed(1)} kg</span>
            </div>
          </div>
          
          <div class="item-grid-container">
            <div class="item-grid pocket-grid">
              {#each Array(totalSlots) as _, idx}
                {@const slot = idx + 1}
                {@const item = getItemInSlot(slot, 'player')}
                <!-- svelte-ignore a11y_no_static_element_interactions -->
                <div 
                  id="slot-{slot}"
                  class="item-slot" 
                  data-slot={slot} 
                  class:invalid-slot-highlight={errorSlot === slot}
                  ondblclick={() => item && useItem(item)}
                  onmousedown={(event) => handleMouseDown(event, slot, 'player')}
                  onmouseenter={() => item && showItemInfo(item, 'player')}
                  onmouseleave={hideItemInfo}
                  ondragover={(event) => event.preventDefault()}
                >
                  {#if slot <= 5}
                    <div class="item-slot-key"><p>{slot}</p></div>
                  {/if}
                  {#if item}
                    <div class="item-slot-img">
                      <img src="images/{item.image}" alt="" />
                    </div>
                    <div class="item-slot-amount"><p>x{item.amount}</p></div>
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
          </div>
        </div>

        <!-- Tooltip estático do item no bolso se selecionado -->
        {#if selectedItem && selectedItem.inventory === 'player' && !showContextMenu}
          <div class="satchel-item-details player-details">
            <ItemDetails {selectedItem} />
          </div>
        {/if}
      </div>

      <!-- ======================================================== -->
      <!-- COLUNA 2 — BOLSA (Satchel - Só Visível se Equipada) -->
      <!-- ======================================================== -->
      {#if satchel && satchel.isEquipped}
        <div class="inventory-column satchel-column">
          <div class="column-header">
            <h3>BOLSA</h3>
            <span class="weight-text">{((satchel.items ? Object.values(satchel.items).reduce((acc, it) => acc + (it ? (it.weight * it.amount) : 0), 0) : 0) / 1000).toFixed(1)} / {(satchel.maxweight / 1000).toFixed(1)} kg</span>
          </div>

          {#if satchel.durability !== undefined}
            <div class="durability-container">
              <div class="durability-header">
                <span>INTEGRIDADE DA BOLSA</span>
                <span>{satchel.durability}%</span>
              </div>
              <div class="durability-bar-bg">
                <div class="durability-fill" style="width: {satchel.durability}%; background: {satchel.durability > 50 ? '#55c05a' : (satchel.durability > 20 ? '#e08b1a' : '#c93c3c')};"></div>
              </div>
            </div>
          {/if}

          <div class="item-grid-container">
            <div class="item-grid satchel-grid">
              {#each Array(satchel.slots) as _, idx}
                {@const slot = idx + 1}
                {@const item = satchel.items[slot] || null}
                <!-- svelte-ignore a11y_no_static_element_interactions -->
                <div 
                  id="satchel-slot-{slot}"
                  class="item-slot" 
                  data-slot={slot}
                  onmousedown={(event) => handleMouseDown(event, slot, 'backpack')}
                  onmouseenter={() => item && showItemInfo(item, 'backpack')}
                  onmouseleave={hideItemInfo}
                  ondragover={(event) => event.preventDefault()}
                >
                  {#if item}
                    <div class="item-slot-img">
                      <img src="images/{item.image}" alt="" />
                    </div>
                    <div class="item-slot-amount"><p>x{item.amount}</p></div>
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
          </div>

          {#if selectedItem && selectedItem.inventory === 'backpack' && !showContextMenu}
            <div class="satchel-item-details other-details">
              <ItemDetails {selectedItem} />
            </div>
          {/if}
        </div>
      {/if}

      <!-- ======================================================== -->
      <!-- COLUNA 3 — OUTRO INVENTÁRIO (Mochila / Baú / Loja) -->
      <!-- ======================================================== -->
      {#if !isOtherInventoryEmpty && !isTradeActive}
        <div class="inventory-column other-column">
          <div class="column-header">
            <h3>{otherInventoryLabel}</h3>
            <span class="weight-text">{(otherInventoryWeight/1000).toFixed(1)}/{(otherInventoryMaxWeight/1000).toFixed(1)} kg</span>
          </div>

          <!-- Grade de Itens do Outro Inventário -->
          <div class="item-grid-container">
            <div class="item-grid other-grid">
              {#each Array(otherInventorySlots) as _, idx}
                {@const slot = idx + 1}
                {@const item = getItemInSlot(slot, 'other')}
                <!-- svelte-ignore a11y_no_static_element_interactions -->
                <div 
                  id="slot-{slot}"
                  class="item-slot" 
                  data-slot={slot} 
                  class:invalid-slot-highlight={errorSlot === slot}
                  ondblclick={() => item && useItem(item)}
                  onmousedown={(event) => handleMouseDown(event, slot, 'other')}
                  onmouseenter={() => item && showItemInfo(item, 'other')}
                  onmouseleave={hideItemInfo}
                  ondragover={(event) => event.preventDefault()}
                >
                  {#if item}
                    <div class="item-slot-img">
                      <img src="images/{item.image}" alt="" />
                    </div>
                    <div class="item-slot-amount"><p>x{item.amount}</p></div>
                    {#if isShopInventory && item.price}
                      <div class="item-price"><p>${Number(item.price).toFixed(2)}</p></div>
                    {/if}
                    {#if isShopInventory && item.buyPrice}
                      <div class="item-sell-price"><p>{t.sell}: ${Number(item.buyPrice).toFixed(2)}</p></div>
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
          </div>

          {#if selectedItem && selectedItem.inventory === 'other' && !showContextMenu}
            <div class="satchel-item-details other-details">
              <ItemDetails {selectedItem} />
            </div>
          {/if}
        </div>
      {/if}

    </div>

    <!-- Close button & Inputs (fora das colunas, centralizados debaixo do layout) -->
    <div class="controls-container">
      {#if !isOtherInventoryEmpty && !isTradeActive}
        <div class="input-container">
          <div class="input-wrapper">
            <input type="number" bind:value={transferAmount} min="1" placeholder={transferAmount === null ? t.amount_placeholder : ''} />
            <button onclick={clearTransferAmount} class="clear-button">
              <i class="fas fa-times"></i>
            </button>
          </div>
        </div>
      {/if}
      <button class="close-btn" onclick={closeInventory}>{t.close}</button>
    </div>

    <!-- Trade Panel -->
    {#if isTradeActive}
      <TradePanel
        tradePartnerName={tradePartnerName}
        myTradeOffers={myTradeOffers}
        theirTradeOffers={theirTradeOffers}
        myTradeAccepted={myTradeAccepted}
        theirTradeAccepted={theirTradeAccepted}
        t={t}
        confirmTrade={confirmTrade}
        cancelTrade={cancelTrade}
        removeItemFromTrade={removeItemFromTrade}
      />
    {/if}

    <!-- Context Menu Options (Dar, Usar, Dividir) -->
    {#if showContextMenu && contextMenuItem}
      <ContextMenu
        contextMenuItem={contextMenuItem}
        contextMenuPosition={contextMenuPosition}
        isTradeActive={isTradeActive}
        t={t}
        useItem={useItem}
        addItemToTrade={addItemToTrade}
        addItemToTradeWithPrompt={addItemToTradeWithPrompt}
        giveItem={giveItem}
        dropItem={dropItem}
        splitAndPlaceItem={splitAndPlaceItem}
        copySerial={copySerial}
        searchBackpack={searchBackpack}
      />
    {/if}
  </div>
{/if}

<!-- Hotbar HUD -->
{#if showHotbar}
  <div class="hotbar-container">
    <div class="hotbar">
      {#each Array(5) as _, idx}
        {@const slot = idx + 1}
        {@const item = hotbarItems[idx] || null}
        <div class="item-slot">
          <div class="item-slot-key">
            <p>{slot}</p>
          </div>
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
            <div class="item-slot-label">
              <p>{item.label}</p>
            </div>
          {/if}
        </div>
      {/each}
    </div>
  </div>
{/if}

<!-- Item Action Notification HUD -->
{#if showNotification}
  <div class="notification-container">
    <div class="item-box">
      <div class="item-box-icon">
        <img src={notificationImage} alt="" />
        {#if notificationAmount && notificationAmount > 1}
          <div class="item-box-amount">x{notificationAmount}</div>
        {/if}
      </div>
      <div class="item-box-content">
        <div class="item-box-type type-{(notificationClass || '').toLowerCase()}">{notificationType}</div>
        <div class="item-box-divider"></div>
        <div class="item-box-header">
          <h4>{notificationText}</h4>
        </div>
        {#if notificationDescription}
          <div class="item-box-description">
            <p>{@html notificationDescription}</p>
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}

<!-- Dragging ghost element -->
{#if isDragging && currentlyDraggingItem}
  <div 
    class="item-slot dragged-item" 
    style="position: absolute; pointer-events: none; opacity: 0.7; z-index: 1000; left: {dragX}px; top: {dragY}px; width: 4.5vw; height: 4.5vw; background: rgba(10, 10, 10, 0.9); border: 1px solid rgba(255,255,255,0.4);"
  >
    <div class="item-slot-img">
      <img src="images/{currentlyDraggingItem.image}" alt="" />
    </div>
    <div class="item-slot-amount">
      <p>x{transferAmount !== null ? transferAmount : currentlyDraggingItem.amount}</p>
    </div>
    <div class="item-slot-label">
      <p>{currentlyDraggingItem.label}</p>
    </div>
  </div>
{/if}
