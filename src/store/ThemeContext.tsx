import React, { createContext, useContext, useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { colors as darkColors } from "@/ui/theme";

type ThemeName = "dark" | "light";
type ThemeContextValue = { theme: ThemeName; setTheme: (t: ThemeName) => void; colors: typeof darkColors };

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<ThemeName>("dark");
  useEffect(() => {
    AsyncStorage.getItem("nexora_audio.theme").then((v) => {
      if (v === "dark" || v === "light") setThemeState(v);
    }).catch(() => {});
  }, []);
  const setTheme = (t: ThemeName) => {
    setThemeState(t);
    AsyncStorage.setItem("nexora_audio.theme", t).catch(() => {});
  };
  // For M1+ the audiophile app is always dark; light is reserved for future.
  const colors = darkColors;
  return <ThemeContext.Provider value={{ theme, setTheme, colors }}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const v = useContext(ThemeContext);
  if (!v) throw new Error("useTheme must be used within ThemeProvider");
  return v;
}