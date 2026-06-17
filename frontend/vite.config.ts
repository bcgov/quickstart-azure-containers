import { defineConfig, loadEnv } from 'vite'
import { fileURLToPath, URL } from 'node:url'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'

export default ({ mode }) => {
  // Load app-level env vars to node-level env vars.
  const loadedEnv = loadEnv(mode, process.cwd());
  for (const [key, value] of Object.entries(loadedEnv)) {
    if (key.startsWith('VITE_')) {
      process.env[key] = value;
    }
  }

  const define: Record<string, any> = {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
  }
  return defineConfig({
    define,
    plugins: [
      TanStackRouterVite({
        target: 'react',
        autoCodeSplitting: true,
      }),
      react(),
    ],
    server: {
      port: parseInt(process.env.VITE_PORT, 10),
      fs: {
        // Allow serving files from one level up to the project root
        allow: ['..'],
      },
      proxy: {
        // Proxy API requests to the backend
        '/api': {
          target: process.env.VITE_API_BASE_URL || 'http://localhost:3001',
          changeOrigin: true,
        },
      },
    },
    resolve: {
      // https://vitejs.dev/config/shared-options.html#resolve-alias
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
        '~': fileURLToPath(new URL('./node_modules', import.meta.url)),
        '~bootstrap': fileURLToPath(
          new URL('./node_modules/bootstrap', import.meta.url),
        ),
      },
      extensions: ['.js', '.json', '.jsx', '.mjs', '.ts', '.tsx', '.vue'],
    },
    build: {
      // Build Target
      // https://vitejs.dev/config/build-options.html#build-target
      target: 'esnext',
      // Minify option
      // https://vite.dev/config/build-options.html#build-minify
      // Vite 8 (Rolldown) uses the native `oxc` minifier by default;
      // `esbuild` is no longer bundled.
      minify: 'oxc',
      // Rollup Options
      // https://vitejs.dev/config/build-options.html#build-rollupoptions
      rollupOptions: {
        output: {
          // Split external libraries from transpiled code.
          // Vite 8 uses Rolldown, which replaces Rollup's object-form
          // `manualChunks` with `advancedChunks.groups`.
          advancedChunks: {
            groups: [
              {
                name: 'react',
                test: /[\\/]node_modules[\\/](react|react-dom)[\\/]/,
              },
              {
                name: 'axios',
                test: /[\\/]node_modules[\\/]axios[\\/]/,
              },
            ],
          },
        },
      },
    },
    css: {
      preprocessorOptions: {
        scss: {
          // Silence deprecation warnings caused by Bootstrap SCSS
          // which is out of our control.
          silenceDeprecations: [
            'mixed-decls',
            'color-functions',
            'global-builtin',
            'import',
          ],
        },
      },
    },
  })
}
