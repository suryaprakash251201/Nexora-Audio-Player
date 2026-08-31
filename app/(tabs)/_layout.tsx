import { StyleSheet } from "react-native";
import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, accent, glass } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";

/**
 * Bottom tabs (M19 refresh).
 *
 * Polished:
 *  - 70pt height (Apple Music-classic) with proper insets via safe-area
 *  - brand-pill on the active tab (mirrors the web/Tauri tab bar)
 *  - semantic icons: home, library (stacked discs), search (filled vs outline),
 *    playlists (music-notes list), settings
 *  - tab label hidden when icon is enough (saves vertical space)
 */
export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        // Frosted bar: real blur so the library scrolls visibly behind it.
        tabBarBackground: () => (
          <GlassSurface variant="bar" sheen={false} border={false} style={StyleSheet.absoluteFill} />
        ),
        tabBarStyle: {
          backgroundColor: "transparent",
          borderTopColor: glass.edge.hairline,
          borderTopWidth: 1,
          height: 70,
          paddingTop: 8,
          paddingBottom: 10,
          elevation: 0,
        },
        tabBarActiveTintColor: accent.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarLabelStyle: {
          fontSize: 10,
          fontFamily: font.sansMedium,
          letterSpacing: 0.4,
          marginTop: 2,
        },
        tabBarItemStyle: {
          paddingVertical: 4,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Home",
          tabBarIcon: ({ color, focused }) => (
            <Ionicons name={focused ? "home" : "home-outline"} size={22} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="library"
        options={{
          title: "Library",
          tabBarIcon: ({ color, focused }) => (
            <Ionicons name={focused ? "library" : "library-outline"} size={22} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          title: "Search",
          tabBarIcon: ({ color, focused }) => (
            <Ionicons name={focused ? "search" : "search-outline"} size={22} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="playlists"
        options={{
          title: "Playlists",
          tabBarIcon: ({ color, focused }) => (
            <Ionicons name={focused ? "list" : "list-outline"} size={22} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: "Settings",
          tabBarIcon: ({ color, focused }) => (
            <Ionicons name={focused ? "settings" : "settings-outline"} size={22} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}