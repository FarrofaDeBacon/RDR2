<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# 📜 rsg-menubase
**Menu base system for RedM using RSG Core.**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

> A flexible and immersive menu framework built on NUI for RedM.  
> Designed to be used by RSG Core and its official resources.

---

## 🛠️ Dependencies
- **rsg-core** (framework & events)  
- **ox_lib** (optional for locale support)

**License:** GPL‑3.0

---

## ✨ Features
- 📋 **Dynamic NUI menu system** for RSG Core.  
- 🧩 Supports multiple menu types via `MenuData.RegisteredTypes`.  
- 🎨 **Stylized Red Dead UI** (paper textures, ink fonts, western visuals).  
- 🔄 **Menu actions**: open, close, submit, cancel, and value change.  
- 🧠 **Player control options:** disable movement, disable inventory, mouse control.  
- 🎧 **Open/close sound effects** (`menu_open.mp3`, `menu_close.mp3`).  
- ⚙️ **Simple NUI API** through client events and exports.  

---

## ⚙️ Example Usage
```lua
-- Example: Open a simple menu
local elements = {
    { label = "Option 1", value = "opt1" },
    { label = "Option 2", value = "opt2" }
}

MenuData.Open('default', GetCurrentResourceName(), 'example_menu', {
    title = "Example Menu",
    align = "top-left",
    elements = elements
}, function(data, menu)
    print("Selected:", data.current.value)
    menu.close()
end, function(data, menu)
    menu.close()
end)
```

> 🧠 Menus use the **default** type defined in `client/main.lua`. You can register custom types using `MenuData.RegisterType()`.

---

## 🔁 Client Events
| Event | Description |
|-------|--------------|
| `rsg-menubase:client:openMenu` | Opens a menu UI. |
| `rsg-menubase:client:closeMenu` | Closes the current menu. |
| `rsg-menubase:client:disableMovement` | Disables player movement while a menu is open. |
| `rsg-menubase:client:lockInventory` | Locks inventory while the menu is active. |

---

## 📂 Installation
1. Add `rsg-menubase` to your `resources/[rsg]` folder.  
2. In your `server.cfg`, add:
   ```cfg
   ensure ox_lib
   ensure rsg-core
   ensure rsg-menubase
   ```
3. Restart your server.

---

## 🎨 Customization
You can modify the UI appearance by editing files under `html/`:
- `html/ui.html` — menu layout
- `html/css/app.css` — styles
- `html/js/app.js` — logic
- `html/sounds/menu_open.mp3` / `menu_close.mp3` — sounds

All assets (paper, ink, icons, fonts) are stored in `html/img/`.

---

## 💎 Credits
- **QRCore‑RedM‑Re / qr_menu** — base structure  
  🔗 [https://github.com/QRCore-RedM-Re/qr_menu](https://github.com/QRCore-RedM-Re/qr_menu)  
- **ktos93** — original NUI implementation  
  🔗 [https://github.com/ktos93](https://github.com/ktos93)  
- **ESX‑Org** — original design inspiration  
  🔗 [https://github.com/ESX-Org](https://github.com/ESX-Org)  
- **RSG / Rexshack‑RedM** — adaptation & maintenance  
- **Community contributors & translators**  
- License: GPL‑3.0
