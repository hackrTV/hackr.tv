import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { fileURLToPath } from 'url'
import path from 'path'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  server: {
    host: '0.0.0.0', // Listen on all network interfaces
    hmr: {
      host: process.env.VITE_HMR_HOST || 'localhost',
      clientPort: 3036,
      protocol: 'ws',
    },
  },
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react',
  },
  resolve: {
    alias: {
      '~': path.resolve(__dirname, './app/javascript'),
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './test/setup.ts',
  },
})
