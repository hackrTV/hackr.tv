// Localizes a server-rendered <time datetime="…"> (stamped in the server's
// zone as HH:MM or a full date) for the viewer's zone: the text becomes
// a 24h clock ("14:03") or the full local stamp ("2026-10-26 14:03"), the
// title always the full one. hourCycle h23, not hour12: false — the
// latter resolves to h24 in Chromium ("24:30").
export function localizeTimeElement (el: HTMLTimeElement, style: 'clock' | 'full' = 'clock'): void {
  const stamp = el.getAttribute('datetime')
  if (!stamp) return
  const date = new Date(stamp)
  if (Number.isNaN(date.getTime())) return
  const clock = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hourCycle: 'h23' })
  const full = `${date.toLocaleDateString('en-CA', { year: 'numeric', month: '2-digit', day: '2-digit' })} ${clock}`
  el.textContent = style === 'full' ? full : clock
  el.title = full
}
