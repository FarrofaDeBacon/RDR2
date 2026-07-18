import { writable, derived } from 'svelte/store'

// ── Estado base ───────────────────────────────────────────────────

const _vehicle = writable({ speed: 0, gear: 1, rpm: 0, unit: 'kmh' })
const _compass = writable({ degrees: 0, cardinal: 'N' })
const _money   = writable({ cash: 0, gold: 0 })
const _vehicleVisible = writable(false)
const _config  = writable({})
const _minimap = writable({ visible: false })
const _editMode = writable(false)

// ── Exports públicos (read-only) ──────────────────────────────────

export const vehicle        = { subscribe: _vehicle.subscribe }
export const compass        = { subscribe: _compass.subscribe }
export const money          = { subscribe: _money.subscribe }
export const vehicleVisible = { subscribe: _vehicleVisible.subscribe }
export const config         = { subscribe: _config.subscribe }
export const minimap        = { subscribe: _minimap.subscribe }
export const editMode       = { subscribe: _editMode.subscribe }

// ── Mutações ──────────────────────────────────────────────────────
export const hudStore = {
  init(data) {
    if (data?.config) _config.set(data.config)
  },

  setVehicle(data)       { _vehicle.set(data) },
  setVehicleVisible(v)   { _vehicleVisible.set(v) },
  setCompass(data)       { _compass.set(data) },
  setMoney(data)         { _money.set(data) },
  setMinimap(data)       { _minimap.set(data) },
  setEditMode(v)         { _editMode.set(v) },
}
