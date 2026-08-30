import "react-native-gesture-handler";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { SessionProvider } from "@/store/SessionContext";
import { ThemeProvider } from "@/store/ThemeContext";
import { LibraryProvider } from "@/store/LibraryContext";
import { PlaybackProvider } from "@/store/PlaybackContext";
import { DspProvider } from "@/store/DspContext";
import { DownloadsProvider } from "@/store/DownloadsContext";
import { SyncProvider } from "@/store/SyncContext";
import { colors } from "@/ui/theme";
import { TrackPlayer } from "@/audio/trackPlayerShim";
import { PlaybackService } from "@/audio/playbackService";
import { Platform } from "react-native";

if (Platform.OS !== "web") {
  try {
    TrackPlayer.registerPlaybackService(() => PlaybackService);
  } catch {
    // registerPlaybackService throws when called twice on Fast Refresh
  }
}

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: colors.bg }}>
      <SafeAreaProvider>
        <ThemeProvider>
          <SessionProvider>
            <SyncProvider>
              <LibraryProvider>
                <DownloadsProvider>
                  <DspProvider>
                    <PlaybackProvider>
                      <StatusBar style="light" />
                      <Stack
                        screenOptions={{
                          headerShown: false,
                          contentStyle: { backgroundColor: colors.bg },
                          animation: "fade",
                        }}
                      >
                        <Stack.Screen name="(tabs)" />
                        <Stack.Screen
                          name="track/[id]"
                          options={{
                            presentation: "transparentModal",
                            animation: "fade",
                          }}
                        />
                        <Stack.Screen
                          name="dsp"
                          options={{ presentation: "modal" }}
                        />
                        <Stack.Screen
                          name="info/[id]"
                          options={{ presentation: "modal" }}
                        />
                      </Stack>
                    </PlaybackProvider>
                  </DspProvider>
                </DownloadsProvider>
              </LibraryProvider>
            </SyncProvider>
          </SessionProvider>
        </ThemeProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}