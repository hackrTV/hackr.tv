import { Controller } from '@hotwired/stimulus'

// Per-viewer state for a packet's reaction chips (uplink/_reactions).
// The chip row is rendered viewer-neutral — the model replaces it for
// everyone on every reaction — with each chip's reactors as callsign
// tokens (data-reactors), so on every (re)connect this marks the chips
// the viewer reacted with (--own, aria-pressed) from the layout's
// uplink-callsign meta, disables every chip for a logged-out viewer
// (the popout: nothing to toggle), and refreshes the broadcast forms'
// CSRF tokens from the page meta, as the packet controller does for the
// row's own forms.

export default class extends Controller<HTMLElement> {
  connect (): void {
    const token = this.meta('uplink-callsign')?.toUpperCase() ?? null
    const loggedIn = this.meta('current-hackr-id') !== null
    this.element.querySelectorAll<HTMLButtonElement>('.packet-reaction').forEach(chip => {
      const reactors = (chip.dataset.reactors ?? '').split(',')
      const own = token !== null && reactors.includes(token)
      chip.classList.toggle('packet-reaction--own', own)
      chip.setAttribute('aria-pressed', String(own))
      chip.disabled = !loggedIn
    })
    const csrf = this.meta('csrf-token')
    if (!csrf) return
    this.element.querySelectorAll<HTMLInputElement>('input[name="authenticity_token"]').forEach(input => {
      input.value = csrf
    })
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }
}
