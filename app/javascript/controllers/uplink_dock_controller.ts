import { Controller } from '@hotwired/stimulus'

const HEARTBEAT_KEY = 'uplink_popout_heartbeat'
const STALE_MS = 1500 // three missed 500ms beats
const POLL_MS = 500
const CLOSE_GRACE_MS = 300
const POPPED_CLASS = 'uplink-popped'

// Consumer of the popout window's localStorage heartbeat
// (popout_heartbeat controller: stamps every 500ms, removes the key on
// close/navigation). While a popout is alive this toggles .uplink-popped
// on the live embed so the docked chat column hides and the video takes
// the whole row (the whole viewport in theater mode); when the popout
// closes the dock returns.
//
// "Alive" means the newest stamp ever observed is younger than STALE_MS
// — not "the key exists right now" — so the popout's own Turbo visits
// between channel tabs (disconnect → removeItem → connect → setItem)
// never flicker the dock. A storage event with a null value (removeItem)
// schedules a short grace check so a real close restores the dock
// quickly; a popout killed without unloading goes stale and is caught by
// the poll.
export default class extends Controller<HTMLElement> {
  private timer: number | null = null
  private closeCheck: number | null = null
  private lastSeen = 0 // newest heartbeat stamp observed (ms epoch)
  private storageHandler = (event: StorageEvent): void => {
    if (event.key !== HEARTBEAT_KEY && event.key !== null) return
    if (event.newValue === null) this.scheduleCloseCheck()
    else this.evaluate()
  }

  connect (): void {
    window.addEventListener('storage', this.storageHandler)
    this.evaluate()
    this.timer = window.setInterval(() => this.evaluate(), POLL_MS)
  }

  disconnect (): void {
    window.removeEventListener('storage', this.storageHandler)
    if (this.timer !== null) window.clearInterval(this.timer)
    if (this.closeCheck !== null) window.clearTimeout(this.closeCheck)
    this.timer = null
    this.closeCheck = null
    this.element.classList.remove(POPPED_CLASS)
  }

  private evaluate (): void {
    const stamp = this.readStamp()
    if (stamp > this.lastSeen) this.lastSeen = stamp
    this.element.classList.toggle(POPPED_CLASS, Date.now() - this.lastSeen < STALE_MS)
  }

  private scheduleCloseCheck (): void {
    if (this.closeCheck !== null) window.clearTimeout(this.closeCheck)
    this.closeCheck = window.setTimeout(() => {
      this.closeCheck = null
      if (this.readStamp() === 0) this.lastSeen = 0
      this.evaluate()
    }, CLOSE_GRACE_MS)
  }

  private readStamp (): number {
    try {
      const raw = localStorage.getItem(HEARTBEAT_KEY)
      return raw === null ? 0 : Number(raw) || 0
    } catch {
      return 0
    }
  }
}
