import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [svelte()],
  root: '.',           // index.html fica na raiz de ui/
  build: {
    outDir: 'public',
    rollupOptions: {
      input: 'index.html',
      output: {
        entryFileNames: 'index.js',
        chunkFileNames: 'index.js',
        assetFileNames: (info) => info.name?.endsWith('.css') ? 'index.css' : info.name,
      },
    },
  },
  base: './',
})

