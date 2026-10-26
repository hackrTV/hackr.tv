import { Controller } from '@hotwired/stimulus'

// The typing line between the /uplink shell's log and composer
// (uplink/_typing). The element is replaced on the channel's
// uplink_typing Turbo stream on every touch/stop with the composing
// hackrs' aliases (viewer-neutral), so on every connect this renders
// the text — "@alias is transmitting..." for one, two or three named,
// a count beyond — minus the viewer's own alias (the layout's
// current-hackr-alias meta: you never watch yourself type), and clears
// it ttl ms later unless a newer broadcast replaced the element first
// (a typer who vanished without a stop fades; one who keeps typing is
// re-touched every 3s). The strip keeps its height so the composer
// never shifts.

const NAMED_MAX = 3

export default class extends Controller<HTMLElement> {
  static values = { aliases: Array, ttl: Number }

  declare readonly aliasesValue: string[]
  declare readonly ttlValue: number

  private timer: number | null = null

  connect (): void {
    const own = this.meta('current-hackr-alias')?.toLowerCase() ?? null
    const aliases = this.aliasesValue
      .map(alias => String(alias).trim())
      .filter(alias => alias !== '' && alias.toLowerCase() !== own)
    this.show(typingLabel(aliases))
    if (aliases.length > 0 && this.ttlValue > 0) {
      this.timer = window.setTimeout(() => this.show(''), this.ttlValue)
    }
  }

  disconnect (): void {
    if (this.timer !== null) window.clearTimeout(this.timer)
    this.timer = null
  }

  private show (text: string): void {
    this.element.textContent = text
    this.element.classList.toggle('uplink-typing--active', text !== '')
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }
}

export function typingLabel (aliases: string[]): string {
  const names = aliases.map(alias => `@${alias}`)
  if (names.length === 0) return ''
  if (names.length > NAMED_MAX) return `${names.length} operatives are transmitting...`
  if (names.length === 1) return `${names[0]} is transmitting...`
  return `${names.slice(0, -1).join(', ')} and ${names[names.length - 1]} are transmitting...`
}
