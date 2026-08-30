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

module.exports = config;