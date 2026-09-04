import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    // Set VITE_BASE (e.g. /gdp/) when the app is served from a sub-path.
    base: env.VITE_BASE || '/',
    plugins: [react()],
  }
})
