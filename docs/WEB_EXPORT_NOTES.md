# Web export (dev only)

`react-native-track-player` is not used on web — `src/audio/trackPlayerShim.ts`
replaces it with a no-op stub so `npx expo export --platform web` can bundle.
Playback on web is HTML5 (`src/audio/player.ts` will delegate to an <audio>
element in M7); the shim lets Metro finish without patching Metro's config.

To get a working web bundle on CI, just run:

  npx expo export --platform web

If you skip the shim and import the real module on web, the bundler walks into
`node_modules/react-native-track-player/lib/web` and you'll see the slow
"TrackPlayerModule" crawl in the export logs.