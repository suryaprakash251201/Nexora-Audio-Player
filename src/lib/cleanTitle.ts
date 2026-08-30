/**
 * Clean a raw file name into a display track title.
 *
 * Mirrors `@nexora/core`'s `cleanTrackTitle` plus a tiny local fallback so we
 * don't need the monorepo alias. Rules:
 *  - Strip extension
 *  - Strip leading track numbers: "01 - Song" → "Song", "03_Song" → "Song"
 *  - Strip trailing bracketed text: "Song [Remastered 2011]" → "Song"
 *  - Collapse whitespace
 *  - Empty result → "Unknown Track"
 */
export function cleanTrackTitle(raw: string): string {
  if (!raw) return "Unknown Track";
  // remove extension
  let t = raw.replace(/\.[a-z0-9]{1,8}$/i, "");
  // leading track numbers
  t = t.replace(/^\s*0*\d+\s*[-_.]+\s*/, "");
  t = t.replace(/^\s*0*\d+\s+/, "");
  // trailing bracketed
  t = t.replace(/\s*[\(\[].*?[\)\]]\s*$/, "");
  // collapse
  t = t.replace(/\s+/g, " ").trim();
  // underscores → spaces
  if (!t.includes(" ") && t.includes("_")) t = t.replace(/_/g, " ");
  return t || "Unknown Track";
}

export function parseArtistTitle(filename: string): { artist: string | null; title: string } {
  const cleaned = cleanTrackTitle(filename);
  // "Artist - Title" convention
  const m = cleaned.match(/^(.+?)\s+[-–—]\s+(.+)$/);
  if (m) return { artist: m[1].trim() || null, title: m[2].trim() || cleaned };
  return { artist: null, title: cleaned };
}