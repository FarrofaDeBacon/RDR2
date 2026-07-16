import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [svelte()],
  base: './', // Isso é super importante para o RedM carregar o index.html corretamente!
  build: {
    outDir: 'dist',
    emptyOutDir: true
  }
})
