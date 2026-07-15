import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [svelte()],
  root: '.',           // index.html fica na raiz de ui/
  build: {
    outDir: 'public',
    emptyOutDir: true,
    rollupOptions: {
      input: 'index.html',
    },
  },
  base: './',
})

