import { Controller } from '@hotwired/stimulus'

// PacketList.tsx pin-to-bottom port, shared with the /grid terminal:
// stay pinned while the user is within 50px of the bottom; once they
// scroll up to read history, appended entries stop yanking the
// viewport. Turbo Stream appends surface as childList mutations. An
// optional cap value trims the oldest children on append (the grid
// terminal's 500-line cap; 0 = uncapped). A frame reload replaces this
// element wholesale, so the fresh instance re-pins on connect.
export default class extends Controller<HTMLElement> {
  static values = { cap: Number }

  declare readonly capValue: number

  private observer: MutationObserver | null = null
  private atBottom = true
  private scrollHandler = (): void => {
    this.atBottom = this.checkAtBottom()
  }

  connect (): void {
    this.scrollToBottom()
    this.element.addEventListener('scroll', this.scrollHandler)
    this.observer = new MutationObserver(() => {
      this.trim()
      if (this.atBottom) this.scrollToBottom()
    })
    this.observer.observe(this.element, { childList: true })
  }

  disconnect (): void {
    this.element.removeEventListener('scroll', this.scrollHandler)
    this.observer?.disconnect()
    this.observer = null
  }

  private trim (): void {
    if (this.capValue <= 0) return
    while (this.element.children.length > this.capValue) {
      this.element.firstElementChild?.remove()
    }
  }

  private checkAtBottom (): boolean {
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < 50
  }

  private scrollToBottom (): void {
    this.element.scrollTop = this.element.scrollHeight
    this.atBottom = true
  }
}
