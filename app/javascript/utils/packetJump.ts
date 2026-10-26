// Scroll a packet row into view and flash it — a TUI blink: a class the
// CSS paints, no transition, removed after flashMs (FLASH_MS unless the
// caller wants it to linger, as a located log does on open). Shared by
// the reply quote (packet controller), the pins panel (popover#jump),
// the search hits (uplink-shell#locate) and the packet-log controller's
// focus. false when the packet is not in the loaded log — beyond the
// fetched history, or in another channel — and then nothing happens;
// the callers' links then visit /uplink?around=<id>, which opens the
// log on it.

const FLASH_MS = 1200

export function jumpToPacket (id: string | number | null | undefined, flashMs = FLASH_MS): boolean {
  const key = String(id ?? '')
  if (!/^\d+$/.test(key)) return false
  const packet = document.getElementById(`chat_message_${key}`)
  if (!packet) return false
  if (typeof packet.scrollIntoView === 'function') packet.scrollIntoView({ block: 'center' })
  packet.classList.add('packet--flash')
  window.setTimeout(() => packet.classList.remove('packet--flash'), flashMs)
  return true
}
