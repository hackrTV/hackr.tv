import { Controller } from '@hotwired/stimulus'

// TerminalAnimation.tsx port: boot-sequence typewriter over the same
// line copy, keydown skips, mobile renders instantly, then an
// interactive command prompt navigates via full page loads (safe in
// both stacks during the migration).
interface TerminalLine {
  text: string
  delay: number
  klass?: string
  html?: boolean
  prompt?: boolean
}

const ROUTE_MAP: Record<string, string> = {
  FM: '/fm',
  GRID: '/grid',
  CODEX: '/codex',
  LOGS: '/logs',
  '0': '/thecyberpulse',
  '1': '/wavelength-zero',
  '2': '/voiceprint'
}

const SPEED_MULTIPLIER = 5

function buildLines (isMobile: boolean): TerminalLine[] {
  const year = new Date().getFullYear()
  const doubleLine = isMobile ? '══════════════════════════════════' : '════════════════════════════════════════════════════════════════'
  const singleLine = isMobile ? '──────────────────────────────────' : '─────────────────────────────────────────────────────────────────'
  const link = (href: string, label: string): string =>
    `<a href="${href}" data-route="${href}" class="terminal-link">${label}</a>`

  return [
    { text: doubleLine, delay: 0 },
    { text: '  HACKR.TV BROADCAST SYSTEM v3.14.1592', delay: 300, klass: 'terminal-header' },
    { text: '  INITIALIZING TRANSMISSION...', delay: 200 },
    { text: doubleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: '> SYSTEM STATUS: ONLINE', delay: 500, klass: 'terminal-prompt' },
    { text: `> YEAR: ${year} (Origin Point)`, delay: 200, klass: 'terminal-prompt' },
    { text: `> SIGNAL RANGE: ${year} - ${year + 100}`, delay: 200, klass: 'terminal-prompt' },
    { text: '', delay: 500 },
    ...(isMobile ? [
      { text: 'Welcome to hackr.tv - the multimedia', delay: 100 },
      { text: `${link('/codex/the-fracture-network', 'Fracture Network')} platform broadcasting`, delay: 100, html: true },
      { text: `urgent transmissions ${link('/timeline', 'across time')}`, delay: 100, html: true },
      { text: `${link('/timeline', 'and space')} from ${year + 100}.`, delay: 100, html: true }
    ] : [
      { text: `Welcome to hackr.tv - the multimedia ${link('/codex/the-fracture-network', 'Fracture Network')} platform broadcasting`, delay: 100, html: true },
      { text: `urgent transmissions ${link('/timeline', 'across time')} and space from ${year + 100}.`, delay: 100, html: true }
    ]),
    { text: '', delay: 500 },
    { text: singleLine, delay: 200 },
    { text: 'FEATURED ARTISTS:', delay: 300, klass: 'terminal-header' },
    { text: singleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: `[0] ${link('/thecyberpulse', 'The.CyberPul.se')}`, delay: 200, html: true },
    ...(isMobile ? [
      { text: '    Flagship Standard Bearers of', delay: 100 },
      { text: '    the Hackrs of CyberSpace', delay: 100 }
    ] : [
      { text: '    Flagship Standard Bearers of the Hackrs of CyberSpace,', delay: 100 },
      { text: '    broadcasting truth across time and space', delay: 100 }
    ]),
    { text: '', delay: 200 },
    { text: `[1] ${link('/wavelength-zero', 'Wavelength Zero')}`, delay: 200, html: true },
    { text: '    Emotive Signal refraction', delay: 100 },
    { text: '', delay: 200 },
    { text: `[2] ${link('/voiceprint', 'Voiceprint')}`, delay: 200, html: true },
    { text: '    Archived human expression', delay: 100 },
    { text: '', delay: 500 },
    { text: singleLine, delay: 200 },
    { text: 'PLATFORM SERVICES:', delay: 300, klass: 'terminal-header' },
    { text: singleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: isMobile ? `[FM] ${link('/fm', 'hackr.fm')}` : `[FM___] ${link('/fm', 'hackr.fm')}`, delay: 200, html: true },
    { text: isMobile ? '     Radio & streaming' : '        Radio & music streaming platform', delay: 100 },
    { text: '', delay: 200 },
    { text: isMobile ? `[GRID] ${link('/grid', 'THE PULSE GRID')}` : `[GRID_] ${link('/grid', 'THE PULSE GRID')}`, delay: 200, html: true },
    { text: isMobile ? '       Text-based MUD' : `        Text-based interface for CyberSpace hacking endeavors in ${year + 100}`, delay: 100 },
    { text: '', delay: 200 },
    { text: `[CODEX] ${link('/codex', 'The Codex')}`, delay: 200, html: true },
    { text: isMobile ? '        Contxt wiki' : '        Context archive & wiki', delay: 100 },
    { text: '', delay: 200 },
    { text: isMobile ? `[LOGS] ${link('/logs', 'Hackr Logs')}` : `[LOGS_] ${link('/logs', 'Hackr Logs')}`, delay: 200, html: true },
    { text: isMobile ? '       Network updates' : '        Updates from the Fracture Network', delay: 100 },
    { text: '', delay: 500 },
    { text: doubleLine, delay: 200 },
    { text: isMobile ? '  SELECT YOUR DESTINATION.' : '  TRANSMISSION READY. SELECT YOUR DESTINATION.', delay: 100 },
    { text: doubleLine, delay: 100 },
    { text: '', delay: 100 }
  ]
}

export default class extends Controller<HTMLElement> {
  static targets = ['output', 'inputLine', 'typed', 'input', 'error']

  declare readonly outputTarget: HTMLElement
  declare readonly inputLineTarget: HTMLElement
  declare readonly typedTarget: HTMLElement
  declare readonly inputTarget: HTMLInputElement
  declare readonly errorTarget: HTMLElement

  private lines: TerminalLine[] = []
  private timeoutId: number | null = null
  private typing = false
  private skipHandler = (): void => this.skip()

  connect (): void {
    const isMobile = window.matchMedia('(max-width: 767px)').matches
    this.lines = buildLines(isMobile)

    if (isMobile) {
      this.renderAll()
      this.finish()
      return
    }

    this.typing = true
    document.addEventListener('keydown', this.skipHandler, { once: true })
    this.typeFrom(0)
  }

  disconnect (): void {
    this.typing = false
    if (this.timeoutId !== null) window.clearTimeout(this.timeoutId)
    document.removeEventListener('keydown', this.skipHandler)
  }

  inputChanged (): void {
    this.typedTarget.textContent = this.inputTarget.value
  }

  inputKeydown (event: KeyboardEvent): void {
    if (event.key !== 'Enter') return
    const command = this.inputTarget.value.trim()
    if (!command) return

    const route = ROUTE_MAP[command.toUpperCase()]
    if (route) {
      // Full page load: safe whichever stack serves the destination.
      window.location.href = route
    } else {
      this.errorTarget.textContent = `UNKNOWN COMMAND: ${command}`
      this.errorTarget.hidden = false
      this.errorTarget.className = 'terminal-error'
      this.inputTarget.value = ''
      this.typedTarget.textContent = ''
    }
  }

  private typeFrom (lineIndex: number, charIndex = 0): void {
    if (!this.typing) return
    if (lineIndex >= this.lines.length) {
      this.finish()
      return
    }

    const line = this.lines[lineIndex]
    if (!line) {
      this.finish()
      return
    }
    const speed = Math.max(1, Math.floor(8 / SPEED_MULTIPLIER))

    if (charIndex === 0 && line.delay > 0) {
      this.timeoutId = window.setTimeout(() => this.typeFrom(lineIndex, 1), line.delay / SPEED_MULTIPLIER)
      return
    }

    if (charIndex <= line.text.length) {
      const partial = line.text.substring(0, charIndex)
      const el = document.createElement('div')
      if (line.html) el.innerHTML = partial
      else el.textContent = partial
      if (line.klass) el.className = line.klass

      if (this.outputTarget.lastChild && charIndex > 1) {
        this.outputTarget.removeChild(this.outputTarget.lastChild)
      }
      this.outputTarget.appendChild(el)

      this.timeoutId = window.setTimeout(() => this.typeFrom(lineIndex, charIndex + 1), speed)
    } else {
      this.timeoutId = window.setTimeout(() => this.typeFrom(lineIndex + 1, 0), 50 / SPEED_MULTIPLIER)
    }
  }

  private skip (): void {
    if (!this.typing) return
    this.typing = false
    if (this.timeoutId !== null) window.clearTimeout(this.timeoutId)
    this.renderAll()
    this.finish()
  }

  private renderAll (): void {
    this.outputTarget.innerHTML = ''
    this.lines.forEach(line => {
      const el = document.createElement('div')
      if (line.html) el.innerHTML = line.text
      else el.textContent = line.text
      if (line.klass) el.className = line.klass
      this.outputTarget.appendChild(el)
    })
  }

  private finish (): void {
    this.typing = false
    this.inputLineTarget.hidden = false
    window.requestAnimationFrame(() => this.inputTarget.focus())
  }
}
