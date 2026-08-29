import { Controller } from '@hotwired/stimulus'

const HEARTBEAT_KEY = 'uplink_popout_heartbeat'
const HEARTBEAT_INTERVAL = 500 // ms

// UplinkPopoutPage.tsx heartbeat port: while the popout window is open
// it stamps localStorage every 500ms so the main window can know it's
// alive (future multi-window coordination — currently nothing consumes
// it, preserved intentionally). Key removed on close/navigation.
export default class extends Controller<HTMLElement> {
  private timer: number | null = null
  private beforeUnload = (): void => {
    localStorage.removeItem(HEARTBEAT_KEY)
  }

  connect (): void {
    localStorage.setItem(HEARTBEAT_KEY, Date.now().toString())
    this.timer = window.setInterval(() => {
      localStorage.setItem(HEARTBEAT_KEY, Date.now().toString())
    }, HEARTBEAT_INTERVAL)
    window.addEventListener('beforeunload', this.beforeUnload)
  }

  disconnect (): void {
    if (this.timer !== null) window.clearInterval(this.timer)
    this.timer = null
    window.removeEventListener('beforeunload', this.beforeUnload)
    localStorage.removeItem(HEARTBEAT_KEY)
  }
}
