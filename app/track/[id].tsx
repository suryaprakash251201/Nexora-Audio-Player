/**
 * Now Playing — full screen (M7 redesign; M1 placeholder).
 * Exists so `expo export` + routing verification can succeed.
 */
import { View, Text } from "react-native";
import { useLocalSearchParams } from "expo-router";

export default function NowPlayingScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return (
    <View style={{ flex: 1, backgroundColor: "#0B0B12", alignItems: "center", justifyContent: "center" }}>
      <Text style={{ color: "#fff" }}>Now Playing — {id}</Text>
      <Text style={{ color: "rgba(255,255,255,0.5)", marginTop: 8 }}>M7 will replace this screen.</Text>
    </View>
  );
}