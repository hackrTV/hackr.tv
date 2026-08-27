import { Controller } from '@hotwired/stimulus'

const KONAMI = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'KeyB', 'KeyA']
const TYPE_TRIGGER = '/terminal'
const TYPE_BUFFER_MAX = 12
const TYPE_IDLE_MS = 3000

declare global {
  interface Window {
    hackr?: { terminal: () => string, help: () => string }
  }
}

// TerminalModal.tsx + useTerminalAccess.ts port: the terminal easter
// egg. The overlay wraps an iframe onto the existing Hotwire /terminal
// page (that's all the SPA modal did). Openers: Konami code, Ctrl+`,
// typing "/terminal" outside inputs, window.hackr.terminal(), and a
// terminal:open window event (nav button). Lives on the hotwire layout,
// so every Hotwire page has it.
export default class extends Controller<HTMLElement> {
  static targets = ['backdrop', 'panel', 'frame']

  declare readonly backdropTarget: HTMLElement
  declare readonly panelTarget: HTMLElement
  declare readonly frameTarget: HTMLIFrameElement

  private konamiIndex = 0
  private typeBuffer = ''
  private typeTimeout: number | null = null

  private keydown = (event: KeyboardEvent): void => {
    // Ctrl+` toggles (not while typing in a field).
    if (event.ctrlKey && event.key === '`') {
      if (!this.inInputField(event.target)) {
        event.preventDefault()
        this.toggle()
      }
      return
    }

    if (event.key === 'Escape' && this.isOpen()) {
      this.close()
      return
    }

    // Konami sequence (works even in inputs, for fun).
    if (event.code === KONAMI[this.konamiIndex]) {
      this.konamiIndex += 1
      if (this.konamiIndex === KONAMI.length) {
        this.konamiIndex = 0
        this.open()
      }
    } else {
      this.konamiIndex = event.code === KONAMI[0] ? 1 : 0
    }

    // Type-to-open "/terminal" (outside inputs, while closed).
    if (this.isOpen() || this.inInputField(event.target)) return
    if (event.key.length === 1) {
      this.typeBuffer = (this.typeBuffer + event.key).slice(-TYPE_BUFFER_MAX)
      if (this.typeTimeout !== null) window.clearTimeout(this.typeTimeout)
      this.typeTimeout = window.setTimeout(() => { this.typeBuffer = '' }, TYPE_IDLE_MS)
      if (this.typeBuffer.toLowerCase().includes(TYPE_TRIGGER)) {
        this.typeBuffer = ''
        this.open()
      }
    }
  }

  private externalOpen = (): void => this.open()

  // Delegated opener for nav items etc. — any [data-terminal-open]
  // element opens the egg without needing controller scope.
  private clickOpen = (event: MouseEvent): void => {
    if ((event.target as Element | null)?.closest('[data-terminal-open]')) {
      event.preventDefault()
      this.open()
    }
  }

  connect (): void {
    document.addEventListener('keydown', this.keydown)
    document.addEventListener('click', this.clickOpen)
    window.addEventListener('terminal:open', this.externalOpen)
    window.hackr = {
      terminal: () => {
        this.open()
        return 'Accessing terminal…'
      },
      help: () => 'Try: hackr.terminal() — or the old codes.'
    }
  }

  disconnect (): void {
    document.removeEventListener('keydown', this.keydown)
    document.removeEventListener('click', this.clickOpen)
    window.removeEventListener('terminal:open', this.externalOpen)
    delete window.hackr
  }

  open (): void {
    if (this.isOpen()) return
    if (!this.frameTarget.src) this.frameTarget.src = '/terminal'
    this.backdropTarget.hidden = false
    this.panelTarget.hidden = false
    requestAnimationFrame(() => requestAnimationFrame(() => this.panelTarget.classList.add('terminal-egg--open')))
    document.body.style.overflow = 'hidden'
  }

  close (): void {
    this.panelTarget.classList.remove('terminal-egg--open')
    window.setTimeout(() => {
      this.panelTarget.hidden = true
      this.backdropTarget.hidden = true
    }, 400)
    document.body.style.overflow = ''
  }

  toggle (): void {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  private isOpen (): boolean {
    return !this.panelTarget.hidden
  }

  private inInputField (target: EventTarget | null): boolean {
    const el = target as HTMLElement | null
    if (!el) return false
    return el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable
  }
}
