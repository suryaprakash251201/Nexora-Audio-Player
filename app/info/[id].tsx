import { View, Text } from "react-native";
import { useLocalSearchParams } from "expo-router";
export default function InfoScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <View style={{ flex: 1, backgroundColor: "#0B0B12", alignItems: "center", justifyContent: "center" }}><Text style={{ color: "#fff" }}>{id}</Text></View>;
}