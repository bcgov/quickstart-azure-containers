import { defineConfig } from "vitest/config";
import swc from "unplugin-swc";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

// https://vitejs.dev/config/
export default defineConfig({
  resolve: {
    alias: {
      src: resolve(__dirname, "src"),
    },
  },
  test: {
    include: ["**/*.e2e-spec.ts", "**/*.spec.ts"],
    exclude: ["**/node_modules/**"],
    globals: true,
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text-summary", "text", "json", "html"],
    },
    reporters: process.env.GITHUB_ACTIONS
      ? [["vitest-sonar-reporter", { outputFile: "test-report.xml" }]]
      : [],
  },
  plugins: [swc.vite()],
});
