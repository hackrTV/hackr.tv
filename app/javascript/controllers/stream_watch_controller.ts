import { Controller } from '@hotwired/stimulus'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface Unsubscribable {
  unsubscribe: () => void
}

// useStreamWatch.ts port: while the tab is visible, hold a
// StreamWatchChannel subscription so the server credits watch time on
// its 60s tick. Rendered only on the live-stream embed for logged-in
// viewers; anonymous viewers aren't tracked (channel rejects them).
export default class extends Controller<HTMLElement> {
  private sub: Unsubscribable | null = null
  private visibilityHandler = (): void => this.handleVisibility()

  connect (): void {
    if (!document.querySelector('meta[name="current-hackr-id"]')) return

    document.addEventListener('visibilitychange', this.visibilityHandler)
    if (document.visibilityState === 'visible') this.open()
  }

  disconnect (): void {
    document.removeEventListener('visibilitychange', this.visibilityHandler)
    this.close()
  }

  private handleVisibility (): void {
    if (document.visibilityState === 'visible') this.open()
    else this.close()
  }

  private open (): void {
    if (this.sub) return
    this.sub = getActionCableConsumer().subscriptions.create({
      channel: 'StreamWatchChannel'
    }) as unknown as Unsubscribable
  }

  private close (): void {
    this.sub?.unsubscribe()
    this.sub = null
  }
}
