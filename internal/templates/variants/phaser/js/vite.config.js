import { defineConfig } from 'vite';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in jsconfig.json
      '~': path.resolve(process.cwd(), 'src'),
    },
  },
});
