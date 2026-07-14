import { writable } from 'svelte/store'

export const visible = writable(false)
export const coords = writable({ x: 0, y: 0 })
export const markers = writable([])

export const mapStore = {
    open(playerCoords, playerMarkers) {
        coords.set(playerCoords || { x: 0, y: 0 })
        markers.set(playerMarkers || [])
        visible.set(true)
    },
    close() {
        visible.set(false)
    }
}
