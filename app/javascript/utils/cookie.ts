// Per-browser layout choices (the WIRE's pane and view) ride plain
// cookies, so the server renders the chosen layout on the first paint.
// A year, site-wide, Lax; values are short tokens the server compares
// to literals.
const MAX_AGE = 60 * 60 * 24 * 365

export function readCookie (name: string): string | null {
  const prefix = `${name}=`
  for (const part of document.cookie.split(';')) {
    const trimmed = part.trim()
    if (trimmed.startsWith(prefix)) return decodeURIComponent(trimmed.slice(prefix.length))
  }
  return null
}

export function writeCookie (name: string, value: string): void {
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=${MAX_AGE}; SameSite=Lax`
}
