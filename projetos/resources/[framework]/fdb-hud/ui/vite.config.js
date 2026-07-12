import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [svelte()],
  build: {
    outDir: 'public',
    emptyOutDir: false,
    rollupOptions: {
      output: {
        entryFileNames: 'index.js',
        assetFileNames: (info) => info.name?.endsWith('.css') ? 'index.css' : info.name,
      },
    },
  },
  base: './',
})
