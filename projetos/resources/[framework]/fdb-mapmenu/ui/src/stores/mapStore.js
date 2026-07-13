import { writable } from 'svelte/store'

export const visible = writable(false)
export const coords = writable({ x: 0, y: 0 })

export const mapStore = {
    open(playerCoords) {
        coords.set(playerCoords || { x: 0, y: 0 })
        visible.set(true)
    },
    close() {
        visible.set(false)
    }
}
