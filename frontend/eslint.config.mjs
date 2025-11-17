import loveConfig from "eslint-config-love";
import typescriptEslint from "@typescript-eslint/eslint-plugin";
import reactPlugin from "eslint-plugin-react";
import reactHooksPlugin from "eslint-plugin-react-hooks";
import cypressPlugin from "eslint-plugin-cypress";
import prettierPlugin from "eslint-plugin-prettier";
import prettierRecommended from "eslint-plugin-prettier/recommended";
import globals from "globals";
import tsParser from "@typescript-eslint/parser";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
});

export default [
  {
    ignores: [
      "**/node_modules/",
      "**/dist/",
      "**/.git/",
      "**/coverage/",
      "**/.vite/",
      "**/routeTree.gen.ts",
      ".husky/",
      ".vscode/",
      ".yarn/",
      "public/assets/",
      "tsconfig.*.json",
    ],
  },
  ...loveConfig,
  ...compat.extends(
    "plugin:react/recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier",
  ),
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      react: reactPlugin,
      "react-hooks": reactHooksPlugin,
      "@typescript-eslint": typescriptEslint,
      prettier: prettierPlugin,
    },

    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },

      parser: tsParser,
      ecmaVersion: "latest",
      sourceType: "module",

      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
        project: ["./tsconfig.json"],
      },

      settings: {
        react: {
          version: "detect",
        },
      },
    },

    rules: {
      // General ESLint rules
      "no-console": "off",
      "no-debugger": "warn",
      "no-unused-vars": "off",
      "no-empty": ["error", { allowEmptyCatch: true }],
      "no-undef": "off",
      "no-use-before-define": "off",
      "no-restricted-imports": [
        "error",
        {
          paths: [
            {
              name: "react",
              importNames: ["default"],
              message: "Please import from 'react/jsx-runtime' instead.",
            },
          ],
        },
      ],

      // React rules
      "react/jsx-uses-react": "off",
      "react/react-in-jsx-scope": "off",
      "react/prop-types": "off",
      "react/display-name": "off",
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",

      // TypeScript rules
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/explicit-module-boundary-types": "off",
      "@typescript-eslint/no-empty-interface": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/ban-types": "off",
      "@typescript-eslint/no-use-before-define": ["error", { functions: false }],
      "@typescript-eslint/no-var-requires": "off",
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports" },
      ],

      // Prettier
      "prettier/prettier": [
        "error",
        {
          endOfLine: "auto",
        },
        { usePrettierrc: true },
      ],
    },
  },
  {
    files: ["**/*.cy.{js,jsx,ts,tsx}", "e2e/**/*.{js,ts}"],
    plugins: {
      cypress: cypressPlugin,
    },
    languageOptions: {
      globals: {
        ...globals.mocha,
      },
    },
    rules: {
      ...cypressPlugin.configs.recommended.rules,
    },
  },
  prettierRecommended,
];

