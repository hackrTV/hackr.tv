import { describe, it, expect, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import ReactionsController from './reactions_controller'

// Fixture mirrors uplink/_reactions: a chip row with two chips, each a
// button_to form carrying the reactors' callsign tokens.

function row (id: number): string {
  return `
    <div id="reactions_chat_message_${id}" class="packet-reactions" data-controller="reactions">
      <form class="packet-reaction-form" method="post" action="/uplink/packets/${id}/reactions?emote_slug=wave">
        <button class="packet-reaction" data-reactors="ABC123,DEF456" data-emote="wave" type="submit"><span class="packet-reaction-count">2</span></button>
        <input type="hidden" name="authenticity_token" value="stale" autocomplete="off">
      </form>
      <form class="packet-reaction-form" method="post" action="/uplink/packets/${id}/reactions?emote_slug=gg">
        <button class="packet-reaction" data-reactors="DEF456" data-emote="gg" type="submit"><span class="packet-reaction-count">1</span></button>
      </form>
    </div>`
}

describe('ReactionsController', () => {
  let application: Application | null = null
  const metas: HTMLMetaElement[] = []

  function meta (name: string, content: string): void {
    const m = document.createElement('meta')
    m.name = name
    m.content = content
    document.head.appendChild(m)
    metas.push(m)
  }

  async function start (html = row(1)): Promise<void> {
    document.body.innerHTML = `<div id="uplink-log"><div class="packet">${html}</div></div>`
    application = Application.start()
    application.register('reactions', ReactionsController)
    await Promise.resolve()
  }

  const chips = (): HTMLButtonElement[] => Array.from(document.querySelectorAll<HTMLButtonElement>('.packet-reaction'))

  afterEach(async () => {
    document.body.innerHTML = ''
    metas.splice(0).forEach(m => m.remove())
    await Promise.resolve()
    application?.stop()
    application = null
    vi.restoreAllMocks()
  })

  it('marks the chips the viewer reacted with from the callsign meta and refreshes the CSRF tokens', async () => {
    meta('current-hackr-id', '7')
    meta('uplink-callsign', 'abc123') // case-insensitive: tokens are upper-case
    meta('csrf-token', 'fresh')
    await start()

    const [wave, gg] = chips()
    expect(wave?.classList.contains('packet-reaction--own')).toBe(true)
    expect(wave?.getAttribute('aria-pressed')).toBe('true')
    expect(gg?.classList.contains('packet-reaction--own')).toBe(false)
    expect(gg?.getAttribute('aria-pressed')).toBe('false')
    expect(chips().every(chip => !chip.disabled)).toBe(true)
    expect(document.querySelector<HTMLInputElement>('input[name="authenticity_token"]')?.value).toBe('fresh')
  })

  it('re-marks on every replace (a Turbo Stream swap reconnects the controller)', async () => {
    meta('current-hackr-id', '7')
    meta('uplink-callsign', 'DEF456')
    await start()
    expect(chips().map(chip => chip.classList.contains('packet-reaction--own'))).toEqual([true, true])

    const fresh = document.createElement('template')
    fresh.innerHTML = row(1).replace('data-reactors="ABC123,DEF456"', 'data-reactors="ABC123"')
    document.getElementById('reactions_chat_message_1')!.replaceWith(fresh.content.firstElementChild!)
    await Promise.resolve()
    await Promise.resolve()

    expect(chips().map(chip => chip.classList.contains('packet-reaction--own'))).toEqual([false, true])
  })

  it('marks nothing without a callsign meta, and disables every chip for a logged-out viewer', async () => {
    await start()
    expect(chips().every(chip => !chip.classList.contains('packet-reaction--own'))).toBe(true)
    expect(chips().every(chip => chip.disabled)).toBe(true)

    application?.stop()
    meta('current-hackr-id', '7')
    await start()
    expect(chips().every(chip => !chip.classList.contains('packet-reaction--own'))).toBe(true)
    expect(chips().every(chip => !chip.disabled)).toBe(true)
  })
})
