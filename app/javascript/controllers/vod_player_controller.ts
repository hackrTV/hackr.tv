import { Controller } from '@hotwired/stimulus'

// YouTubePlayer.tsx port for the Hotwire vidz pages: a click-to-play
// thumbnail that swaps in a YouTube IFrame API player, plus the
// VodzShowPage watch credit — the first PLAYING state POSTs the watch
// URL once (logged-in viewers only; the server dedups repeats). Firing
// on real playback instead of page load matches the achievement copy
// ("Watched your first VOD").

interface YTPlayerApi {
  playVideo: () => void
  destroy: () => void
}

interface YTNamespace {
  Player: new (element: HTMLElement, config: Record<string, unknown>) => YTPlayerApi
  PlayerState?: { PLAYING: number }
}

// Local casts instead of a global Window augmentation so this file never
// collides with the SPA's YouTubePlayer declarations (and survives their
// removal once the migration finishes).
const getYT = (): YTNamespace | undefined =>
  (window as unknown as { YT?: YTNamespace }).YT

const API_SRC = 'https://www.youtube.com/iframe_api'

export default class extends Controller {
  static targets = ['thumb', 'frame']
  static values = { videoId: String, watchUrl: String }

  declare readonly thumbTarget: HTMLElement
  declare readonly frameTarget: HTMLElement
  declare videoIdValue: string
  declare watchUrlValue: string

  private player: YTPlayerApi | null = null
  private watchFired = false

  disconnect (): void {
    this.player?.destroy()
    this.player = null
  }

  play (): void {
    if (this.player) return
    void this.withApi().then(() => this.createPlayer())
  }

  private async withApi (): Promise<void> {
    if (getYT()?.Player) return

    await new Promise<void>((resolve) => {
      const host = window as unknown as { onYouTubeIframeAPIReady?: () => void }
      const previous = host.onYouTubeIframeAPIReady
      host.onYouTubeIframeAPIReady = () => {
        previous?.()
        resolve()
      }
      if (document.querySelector(`script[src="${API_SRC}"]`) === null) {
        const tag = document.createElement('script')
        tag.src = API_SRC
        document.head.appendChild(tag)
      }
    })
  }

  private createPlayer (): void {
    const yt = getYT()
    if (!yt || this.player) return

    // YT.Player replaces the mount element with the player iframe.
    this.player = new yt.Player(this.frameTarget, {
      height: '100%',
      width: '100%',
      videoId: this.videoIdValue,
      playerVars: { autoplay: 1, controls: 1, modestbranding: 1, rel: 0 },
      events: {
        onReady: (event: { target: YTPlayerApi }) => { event.target.playVideo() },
        onStateChange: (event: { data: number }) => {
          const playing = yt.PlayerState?.PLAYING ?? 1
          if (event.data === playing) this.creditWatch()
        }
      }
    })
    this.thumbTarget.hidden = true
  }

  private creditWatch (): void {
    if (this.watchFired) return
    this.watchFired = true
    if (!this.watchUrlValue) return
    if (document.querySelector('meta[name="current-hackr-id"]') === null) return

    fetch(this.watchUrlValue, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }
}
