import { Controller } from '@hotwired/stimulus'

// Artist bio-view achievement credit (BandProfilePage/XeraenPage/
// TheCyberPulsePage useEffect port): logged-in viewers POST bio_viewed
// once per page visit; the server dedups repeat views.
export default class extends Controller {
  static values = { slug: String }

  declare slugValue: string

  connect (): void {
    if (!this.slugValue) return
    if (document.querySelector('meta[name="current-hackr-id"]') === null) return

    fetch(`/api/artists/${encodeURIComponent(this.slugValue)}/bio_viewed`, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }
}
