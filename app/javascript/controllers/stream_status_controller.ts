import { Controller } from '@hotwired/stimulus'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface Unsubscribable {
  unsubscribe: () => void
}

interface StreamStatusMessage {
  type: 'stream_status' | 'stream_live' | 'stream_ended' | 'scheduled_stream_updated'
  is_live?: boolean
}

declare global {
  interface Window {
    Turbo?: { visit: (location: string, options?: { action?: string }) => void }
  }
}

// useStreamStatus.ts port for the server-rendered home page: the page
// shows the state it was rendered with; when the live state CHANGES, a
// Turbo reload re-renders it (embed appears/disappears server-side).
export default class extends Controller<HTMLElement> {
  static values = { live: Boolean }

  declare readonly liveValue: boolean

  private sub: Unsubscribable | null = null

  connect (): void {
    this.sub = getActionCableConsumer().subscriptions.create(
      { channel: 'StreamStatusChannel' },
      {
        received: (message: StreamStatusMessage) => this.handle(message)
      }
    ) as unknown as Unsubscribable
  }

  disconnect (): void {
    this.sub?.unsubscribe()
    this.sub = null
  }

  private handle (message: StreamStatusMessage): void {
    const nowLive = message.type === 'stream_ended' ? false : message.is_live
    if (nowLive === undefined) return
    if (nowLive !== this.liveValue) {
      window.Turbo?.visit(window.location.href, { action: 'replace' })
    }
  }
}
