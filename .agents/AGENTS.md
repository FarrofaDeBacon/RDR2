# RedM Server - FDB Custom Architecture & Rules

This document outlines the custom architecture, design patterns, and specific systems implemented in this RSGCore-based RedM server. Always refer to these guidelines when making modifications to avoid breaking existing features.

## 1. HUD Architecture (`fdb-hud`)
- **Technology Stack:** Svelte + Vite for the UI.
- **Role:** It is the primary client interface. It displays Health, Stamina, Hunger, Thirst, Stress, Bladder (🚽), Alcohol (🍻), and Horse stats.
- **State Syncing:** The script constantly polls `PlayerData.metadata` and syncs the visual UI. It also acts as a bridge for legacy scripts by pushing custom metadata (`bladder`, `alcohol`) into the local `StateBag` (`LocalPlayer.state:set(..., false)`).
- **Edit Mode:** Players can move elements around using `/edithud`. The layout is saved to the server via `fdb-hud:server:saveLayout` and persists per `citizenid`.
- **UI Builds:** If you modify `.svelte` or `.css` files in `fdb-hud/ui`, you **must** build the project using `npm run build` inside the `ui` directory.

## 2. Consumables System (`fdb-consume`)
- **Server-Authoritative:** We DO NOT use the default `rsg-consume` because it allows clients to exploit status gains (e.g. telling the server they gained 100 hunger without an item). We replaced it with `fdb-consume`.
- **How it works:**
  1. The server reads `config.lua` and registers usable items.
  2. Upon use, the **Server** removes the item.
  3. The **Server** calculates the new metadata (clamping logic) and calls `SetMetaData`.
  4. The **Server** instructs the client to play the corresponding animation (`fdb-consume:client:playAnim`).
- **Alcohol Decay:** A loop runs on the server every 5 seconds that decays alcohol for all online players and updates the client to trigger drunk/vomit/pass-out effects.

## 3. Custom Metadata (Core modifications)
- **Variables Added:** `bladder` (Bexiga) and `alcohol` (Álcool).
- **Core Update Rule:** We DO NOT modify `rsg-core/server/player.lua` (the core initialization functions) to avoid merge conflicts during framework updates. 
- **How we inject metadata:** We only added `bladder = 0` and `alcohol = 0` to `rsg-core/config.lua` inside the `RSGCore.Config.Player.Metadata` table. The rest of the state management is handled elegantly by `fdb-hud` and `fdb-consume`.

## 4. Visual Mechanics & Animations
- **Urination:** Command `/mijar` uses native scenario `WORLD_HUMAN_PEE` and spawns a custom yellow PTFX (`ent_anim_dog_peeing`) attached to `SKEL_Pelvis` at scale 5.0.
- **Vomit:** Uses `amb_misc@world_human_vomit@male_a@base` instead of idle_f. Used when the player exceeds the alcohol Pass Out threshold.
- **Drunkenness:** Uses native clipset `move_m@drunk@verydrunk` and screen post-fx `PlayerDrunk01`.
