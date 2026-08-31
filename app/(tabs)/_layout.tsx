import React from "react";
import { StyleSheet, View } from "react-native";
import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors, font, accent, glass, radius, shadow } from "@/ui/theme";
import { GlassSurface } from "@/ui/Glass";
import { Haptics } from "@/lib/haptics";

/**
 * Bottom Tabs Layout — Luxury Floating Glass Dock.
 */
export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarBackground: () => (
          <GlassSurface
            variant="bar"
            intensity={glass.blur.bar}
            sheen={false}
            border={false}
            style={StyleSheet.absoluteFill}
          />
        ),
        tabBarStyle: {
          backgroundColor: "transparent",
          borderTopColor: glass.edge.hairline,
          borderTopWidth: 1,
          height: 72,
          paddingTop: 8,
          paddingBottom: 12,
          ...shadow.lg,
        },
        tabBarActiveTintColor: accent.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarLabelStyle: {
          fontSize: 10,
          fontFamily: font.sansBold,
          fontWeight: "800",
          letterSpacing: 0.6,
          marginTop: 2,
        },
        tabBarItemStyle: {
          paddingVertical: 2,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Home",
          tabBarIcon: ({ color, focused }) => (
            <View style={focused ? styles.activeTabIcon : styles.tabIcon}>
              <Ionicons name={focused ? "home" : "home-outline"} size={22} color={color} />
            </View>
          ),
        }}
        listeners={{
          tabPress: () => Haptics.tapLight(),
        }}
      />
      <Tabs.Screen
        name="library"
        options={{
          title: "Library",
          tabBarIcon: ({ color, focused }) => (
            <View style={focused ? styles.activeTabIcon : styles.tabIcon}>
              <Ionicons name={focused ? "library" : "library-outline"} size={22} color={color} />
            </View>
          ),
        }}
        listeners={{
          tabPress: () => Haptics.tapLight(),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          title: "Search",
          tabBarIcon: ({ color, focused }) => (
            <View style={focused ? styles.activeTabIcon : styles.tabIcon}>
              <Ionicons name={focused ? "search" : "search-outline"} size={22} color={color} />
            </View>
          ),
        }}
        listeners={{
          tabPress: () => Haptics.tapLight(),
        }}
      />
      <Tabs.Screen
        name="playlists"
        options={{
          title: "Playlists",
          tabBarIcon: ({ color, focused }) => (
            <View style={focused ? styles.activeTabIcon : styles.tabIcon}>
              <Ionicons name={focused ? "musical-notes" : "musical-notes-outline"} size={22} color={color} />
            </View>
          ),
        }}
        listeners={{
          tabPress: () => Haptics.tapLight(),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: "Settings",
          tabBarIcon: ({ color, focused }) => (
            <View style={focused ? styles.activeTabIcon : styles.tabIcon}>
              <Ionicons name={focused ? "settings" : "settings-outline"} size={22} color={color} />
            </View>
          ),
        }}
        listeners={{
          tabPress: () => Haptics.tapLight(),
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabIcon: {
    alignItems: "center",
    justifyContent: "center",
    width: 36,
    height: 28,
  },
  activeTabIcon: {
    alignItems: "center",
    justifyContent: "center",
    width: 36,
    height: 28,
    borderRadius: radius.md,
    backgroundColor: "rgba(139,92,246,0.14)",
  },
});