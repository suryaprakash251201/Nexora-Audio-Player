/**
 * Minimal metro config for the Nexora audiophile client.
 *
 * Mirrors the upstream mobile app's alias for `@/` → `src/` so imports stay
 * consistent, plus expo-router specific setup.
 */
const { getDefaultConfig } = require("expo/metro-config");

const config = getDefaultConfig(__dirname);

config.resolver.alias = {
  ...(config.resolver.alias || {}),
  "@/": __dirname + "/src",
};

// Register `.wasm` as a Metro asset so `expo-sqlite`'s web worker can resolve
// its `wa-sqlite.wasm` binary. Without this, `expo export --platform web`
// fails with "Unable to resolve module ./wa-sqlite/wa-sqlite.wasm".
config.resolver.assetExts = [...new Set([...(config.resolver.assetExts || []), "wasm"])];

module.exports = config;