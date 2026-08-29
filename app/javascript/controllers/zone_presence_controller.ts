import { Controller } from '@hotwired/stimulus'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface Subscription {
  unsubscribe: () => void
}

interface PresenceEvent {
  type: string
  from_room_id?: number
  to_room_id?: number
}

// useZonePresence.ts port: ZoneChannel presence_update events adjust the
// map's per-room count badges in place. This controller sits ON the
// replaced map fragment, so each movement re-subscribes with the new
// room's zone (the server derives the zone at subscribe time).
export default class extends Controller<HTMLElement> {
  private sub: Subscription | null = null

  connect (): void {
    this.sub = getActionCableConsumer().subscriptions.create(
      { channel: 'ZoneChannel' },
      { received: (event: PresenceEvent) => this.handle(event) }
    ) as unknown as Subscription
  }

  disconnect (): void {
    this.sub?.unsubscribe()
    this.sub = null
  }

  private handle (event: PresenceEvent): void {
    if (event.type !== 'presence_update') return
    if (event.from_room_id) this.bump(event.from_room_id, -1)
    if (event.to_room_id) this.bump(event.to_room_id, +1)
  }

  private bump (roomId: number, delta: number): void {
    const badge = this.element.querySelector<SVGGElement>(`[data-presence-room="${roomId}"]`)
    const text = badge?.querySelector<SVGTextElement>('[data-presence-count]')
    if (!badge || !text) return
    const count = Math.max(0, (parseInt(text.textContent ?? '0', 10) || 0) + delta)
    text.textContent = String(count)
    badge.setAttribute('visibility', count > 0 ? 'visible' : 'hidden')
  }
}
