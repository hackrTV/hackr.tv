import { Controller } from '@hotwired/stimulus'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface Subscription {
  unsubscribe: () => void
}

interface UplinkMessage {
  type: string
  presence_count?: number
  count?: number
}

interface FrameElementLike {
  src: string | null
  reload: () => void
}

// Uplink panel shell (useUplink.ts + PresenceIndicator/ReconnectingBanner
// port). Packets arrive as Turbo Stream HTML on the panel's
// turbo_stream_from subscription; this controller holds a SEPARATE
// LiveChatChannel subscription purely for presence counts and connection
// state (the JSON channel's real consumers are relay/synthia). On cable
// reconnect it reloads the log frame so packets broadcast during the gap
// are recovered — the SPA's initial_packets re-merge equivalent.
// ActionCable's ConnectionMonitor handles retry/backoff, so there is no
// manual reconnect button.
export default class extends Controller<HTMLElement> {
  static targets = ['banner', 'presenceDot', 'presenceText', 'logFrame']
  static values = { channel: String, logSrc: String }

  declare readonly bannerTarget: HTMLElement
  declare readonly hasBannerTarget: boolean
  declare readonly presenceDotTarget: HTMLElement
  declare readonly hasPresenceDotTarget: boolean
  declare readonly presenceTextTarget: HTMLElement
  declare readonly hasPresenceTextTarget: boolean
  declare readonly logFrameTarget: HTMLElement
  declare readonly hasLogFrameTarget: boolean
  declare readonly channelValue: string
  declare readonly logSrcValue: string

  private sub: Subscription | null = null
  private everConnected = false
  private count = 0

  connect (): void {
    if (!this.channelValue) {
      this.renderDisconnected()
      return
    }
    this.sub = getActionCableConsumer().subscriptions.create(
      { channel: 'LiveChatChannel', chat_channel: this.channelValue },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        rejected: () => this.handleRejected(),
        received: (message: UplinkMessage) => this.handleMessage(message)
      }
    ) as unknown as Subscription
  }

  disconnect (): void {
    this.sub?.unsubscribe()
    this.sub = null
  }

  popout (): void {
    window.open('/uplink/popout', 'hackr_uplink_popout', 'popup=yes,width=420,height=680')
  }

  private handleConnected (): void {
    this.hideBanner()
    if (this.everConnected) this.reloadLog()
    this.everConnected = true
    this.renderPresence()
  }

  private handleDisconnected (): void {
    this.showBanner('Reconnecting to uplink...', false)
    this.renderDisconnected()
  }

  private handleRejected (): void {
    // Blackout or non-viewable channel — permanent for this page load.
    this.showBanner('Uplink disconnected', true)
    this.renderDisconnected()
  }

  private handleMessage (message: UplinkMessage): void {
    if (message.type === 'initial_packets' && message.presence_count !== undefined) {
      this.count = message.presence_count
      this.renderPresence()
    } else if (message.type === 'presence_update' && message.count !== undefined) {
      this.count = message.count
      this.renderPresence()
    }
    // Packet payloads are ignored — the log updates over Turbo Streams.
  }

  private reloadLog (): void {
    if (!this.hasLogFrameTarget || !this.logSrcValue) return
    const frame = this.logFrameTarget as unknown as FrameElementLike
    if (frame.src) {
      frame.reload()
    } else {
      frame.src = this.logSrcValue
    }
  }

  private showBanner (text: string, terminal: boolean): void {
    if (!this.hasBannerTarget) return
    this.bannerTarget.textContent = text
    this.bannerTarget.classList.toggle('uplink-banner--disconnected', terminal)
    this.bannerTarget.hidden = false
  }

  private hideBanner (): void {
    if (this.hasBannerTarget) this.bannerTarget.hidden = true
  }

  private renderPresence (): void {
    if (!this.hasPresenceTextTarget) return
    this.presenceDotTarget.classList.add('presence-dot--connected')
    this.presenceTextTarget.classList.remove('presence-text--disconnected')
    this.presenceTextTarget.innerHTML =
      `<span class="presence-count">${this.count}</span> operative${this.count === 1 ? '' : 's'} connected`
  }

  private renderDisconnected (): void {
    if (!this.hasPresenceTextTarget) return
    this.presenceDotTarget.classList.remove('presence-dot--connected')
    this.presenceTextTarget.classList.add('presence-text--disconnected')
    this.presenceTextTarget.textContent = 'Disconnected'
  }
}
