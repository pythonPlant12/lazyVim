// Global ESLint fallback config — used when no project-level ESLint config is found.
// Only core ESLint rules are used here (no plugins) to avoid dependency issues.
export default [
  {
    rules: {
      "no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],
      "no-undef": "warn",
      "no-console": "off",
      "prefer-const": "warn",
      "no-var": "warn",
      "eqeqeq": ["warn", "always", { "null": "ignore" }],
      "no-duplicate-imports": "warn",
    },
  },
];
