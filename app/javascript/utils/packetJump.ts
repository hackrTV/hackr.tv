// Scroll a packet row into view and flash it — a TUI blink: a class the
// CSS paints, no transition, removed after FLASH_MS. Shared by the reply
// quote (packet controller) and the pins panel (popover#jump). false when
// the packet is not in the loaded log — above the fetched history, or in
// another channel — and then nothing happens (item 9's around= mode is
// the eventual answer).

const FLASH_MS = 1200

export function jumpToPacket (id: string | number | null | undefined): boolean {
  const key = String(id ?? '')
  if (!/^\d+$/.test(key)) return false
  const packet = document.getElementById(`chat_message_${key}`)
  if (!packet) return false
  if (typeof packet.scrollIntoView === 'function') packet.scrollIntoView({ block: 'center' })
  packet.classList.add('packet--flash')
  window.setTimeout(() => packet.classList.remove('packet--flash'), FLASH_MS)
  return true
}
