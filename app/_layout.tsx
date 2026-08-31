import "react-native-gesture-handler";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useFonts, Sora_400Regular, Sora_500Medium, Sora_600SemiBold, Sora_700Bold } from "@expo-google-fonts/sora";
import { JetBrainsMono_500Medium, JetBrainsMono_700Bold } from "@expo-google-fonts/jetbrains-mono";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { SessionProvider } from "@/store/SessionContext";
import { ThemeProvider } from "@/store/ThemeContext";
import { LibraryProvider } from "@/store/LibraryContext";
import { PlaybackProvider } from "@/store/PlaybackContext";
import { PlaylistProvider } from "@/store/PlaylistContext";
import { DspProvider } from "@/store/DspContext";
import { DownloadsProvider } from "@/store/DownloadsContext";
import { SyncProvider } from "@/store/SyncContext";
import { View } from "react-native";
import { colors } from "@/ui/theme";
import { TrackPlayer } from "@/audio/trackPlayerShim";
import { PlaybackService } from "@/audio/playbackService";
import { Platform } from "react-native";
import MiniPlayerBar from "@/ui/MiniPlayerBar";

if (Platform.OS !== "web") {
  try {
    TrackPlayer.registerPlaybackService(() => PlaybackService);
  } catch {
    // registerPlaybackService throws when called twice on Fast Refresh
  }
}

export default function RootLayout() {
  // Real fonts (M19) — Sora for UI, JetBrains Mono for technical info.
  const [fontsLoaded] = useFonts({
    Sora_400Regular,
    Sora_500Medium,
    Sora_600SemiBold,
    Sora_700Bold,
    JetBrainsMono_500Medium,
    JetBrainsMono_700Bold,
  });

  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: colors.bg }}>
      <SafeAreaProvider>
        <ThemeProvider>
          <SessionProvider>
            <SyncProvider>
              <LibraryProvider>
                <PlaylistProvider>
                  <DownloadsProvider>
                    <DspProvider>
                      <PlaybackProvider>
                        <StatusBar style="light" />
                        <View style={{ flex: 1, backgroundColor: colors.bg }}>
                          <Stack
                            screenOptions={{
                              headerShown: false,
                              contentStyle: { backgroundColor: colors.bg },
                              animation: "fade",
                            }}
                          >
                            <Stack.Screen name="(tabs)" />
                            <Stack.Screen name="login" options={{ presentation: "modal", headerShown: false }} />
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
                          <MiniPlayerBar />
                        </View>
                      </PlaybackProvider>
                    </DspProvider>
                  </DownloadsProvider>
                </PlaylistProvider>
              </LibraryProvider>
            </SyncProvider>
          </SessionProvider>
        </ThemeProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}