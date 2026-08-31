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

// Belt-and-suspenders for web: if any transitive dep still pulls
// `shaka-player` (peer of rntp web) on web, resolve it to an empty stub
// instead of hard-failing the bundle. The proper web shim is
// `src/audio/trackPlayerShim.web.ts`; this just prevents stray imports
// (e.g. `react-native-track-player/lib/web/...`) from breaking CI.
const path = require("path");
const emptyStub = path.resolve(__dirname, "src/audio/trackPlayerShim.web.ts");
const originalResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (platform === "web" && moduleName.startsWith("shaka-player")) {
    return { filePath: emptyStub, type: "sourceFile" };
  }
  // Also alias RNTP itself on web to the shim so `import "react-native-track-player"`
  // elsewhere (e.g. stray code) doesn't pull the web Player that needs shaka.
  if (platform === "web" && moduleName === "react-native-track-player") {
    return { filePath: emptyStub, type: "sourceFile" };
  }
  if (originalResolveRequest) return originalResolveRequest(context, moduleName, platform);
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;