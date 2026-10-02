import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import RadioStreamController from './radio_stream_controller'

// Fixture mirrors radio/show.html.erb's raw-stream path: page-wide
// controller, per-station TUNE IN buttons, fixed bottom bar.

const FIXTURE = `
  <div data-controller="radio-stream">
    <button id="tune-7" data-action="radio-stream#tuneIn"
            data-stream-url="https://stream.example/7" data-station-id="7"
            data-station-name="RAW ONE" data-station-genre="noise">TUNE IN</button>
    <button id="tune-8" data-action="radio-stream#tuneIn"
            data-stream-url="https://stream.example/8" data-station-id="8"
            data-station-name="RAW TWO" data-station-genre="drone">TUNE IN</button>
    <audio data-radio-stream-target="audio"></audio>
    <div data-radio-stream-target="bar" hidden>
      <span data-radio-stream-target="stationName"></span>
      <span data-radio-stream-target="genre"></span>
      <button data-action="radio-stream#stop">■ STOP</button>
      <input data-radio-stream-target="volume" type="range" min="0" max="100" value="50"
             data-action="input->radio-stream#volumeChanged">
    </div>
  </div>`

describe('RadioStreamController', () => {
  let application: Application
  let fetchMock: ReturnType<typeof vi.fn>

  const audio = (): HTMLAudioElement => document.querySelector('[data-radio-stream-target="audio"]')!
  const bar = (): HTMLElement => document.querySelector('[data-radio-stream-target="bar"]')!

  async function settle (): Promise<void> {
    await Promise.resolve()
    await Promise.resolve()
  }

  beforeEach(async () => {
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('fetch', fetchMock)
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    document.head.appendChild(meta)
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('radio-stream', RadioStreamController)
    await settle()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application.stop()
    document.head.querySelector('meta[name="current-hackr-id"]')?.remove()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('tunes in: wires the audio element, shows the bar, credits once per station', async () => {
    document.getElementById('tune-7')!.click()
    await settle()

    expect(audio().src).toBe('https://stream.example/7')
    expect(audio().volume).toBe(0.5)
    expect(bar().hidden).toBe(false)
    expect(document.querySelector('[data-radio-stream-target="stationName"]')!.textContent).toBe('RAW ONE')
    expect(document.querySelector('[data-radio-stream-target="genre"]')!.textContent).toBe('noise')
    expect(fetchMock).toHaveBeenCalledWith('/api/radio_stations/7/tune_in', { method: 'POST' })

    // Same station again: no second credit
    document.getElementById('tune-7')!.click()
    await settle()
    expect(fetchMock).toHaveBeenCalledTimes(1)

    // Different station: credits
    document.getElementById('tune-8')!.click()
    await settle()
    expect(fetchMock).toHaveBeenCalledWith('/api/radio_stations/8/tune_in', { method: 'POST' })
  })

  it('does not credit when logged out', async () => {
    document.head.querySelector('meta[name="current-hackr-id"]')!.remove()
    document.getElementById('tune-7')!.click()
    await settle()

    expect(fetchMock).not.toHaveBeenCalled()
    expect(bar().hidden).toBe(false)
  })

  it('stop pauses, clears the source, and hides the bar', async () => {
    document.getElementById('tune-7')!.click()
    await settle()

    document.querySelector<HTMLElement>('[data-action="radio-stream#stop"]')!.click()

    expect(audio().getAttribute('src')).toBeNull()
    expect(bar().hidden).toBe(true)
  })

  it('volume slider drives the audio element', async () => {
    const volume = document.querySelector<HTMLInputElement>('[data-radio-stream-target="volume"]')!
    volume.value = '80'
    volume.dispatchEvent(new Event('input'))

    expect(audio().volume).toBe(0.8)
  })

  it('alerts when the stream cannot play', async () => {
    const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
    vi.spyOn(console, 'error').mockImplementation(() => {})
    vi.spyOn(window.HTMLMediaElement.prototype, 'play').mockRejectedValueOnce(new Error('no stream'))

    document.getElementById('tune-7')!.click()
    await settle()

    expect(alertSpy).toHaveBeenCalledWith('Error: Unable to connect to radio stream. Please check the stream URL.')
    expect(fetchMock).not.toHaveBeenCalled()
  })
})
