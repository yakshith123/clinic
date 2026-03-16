import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: true, // Expose to all network interfaces
  },
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        mr: 'mr-register.html',
        register: 'register.html'
      }
    }
  }
})
