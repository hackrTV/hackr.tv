import { Controller } from '@hotwired/stimulus'

// Emote autocomplete for the chat composers (Uplink packet <input>, WIRE
// pulse <textarea>). Typing ":" + 1-32 slug chars opens a listbox of
// matching emotes (prefix hits first, then infix, max 8); ↑/↓ wrap,
// Enter/Tab/click insert ":slug: " over the typed token, Escape or an
// outside mousedown closes. It talks to the host controller (packet-form /
// composer) only through the bubbled `input` event it dispatches after an
// insert, so counters and submit state recompute without coupling. The
// emote list is the server-rendered `emotes` value ({slug, url}[]); the
// menu <ul> is a target the ERB places inside a position:relative anchor
// with an .emote-menu--up|down modifier.

interface Emote {
  slug: string
  url: string
}

interface Token {
  start: number
  end: number
  query: string
}

type ComposerField = HTMLInputElement | HTMLTextAreaElement

const MAX_ROWS = 8
// ":" at the start or after a non-slug character, then 1-32 slug chars
// running up to the caret. The boundary keeps "12:30" from opening.
const TOKEN_AT_CARET = /(^|[^a-z0-9_:]):([a-z0-9_]{1,32})$/i
// Rest of a token the caret is sitting inside (":wa|ve:"), so the insert
// replaces the whole thing instead of leaving "ve:" behind.
const TOKEN_TAIL = /^[a-z0-9_]*:?/i
const CARET_KEYS = new Set(['ArrowLeft', 'ArrowRight', 'Home', 'End'])

let menuSequence = 0

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'menu']
  static values = { emotes: Array }

  declare readonly inputTarget: ComposerField
  declare readonly menuTarget: HTMLElement
  declare readonly emotesValue: Emote[]

  private matches: Emote[] = []
  private active = 0
  private token: Token | null = null

  connect (): void {
    if (!this.menuTarget.id) this.menuTarget.id = `emote-menu-${++menuSequence}`
    this.inputTarget.setAttribute('aria-controls', this.menuTarget.id)
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
    document.addEventListener('mousedown', this.onDocumentMouseDown)
  }

  disconnect (): void {
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
  }

  private readonly onDocumentMouseDown = (event: MouseEvent): void => {
    if (!this.isOpen) return
    if (!this.element.contains(event.target as Node)) this.close()
  }

  get isOpen (): boolean {
    return !this.menuTarget.hidden
  }

  // input / click: re-read the token under the caret.
  update (): void {
    this.token = this.tokenAtCaret()
    if (!this.token) {
      this.close()
      return
    }
    this.matches = this.search(this.token.query)
    if (this.matches.length === 0) {
      this.close()
      return
    }
    this.active = 0
    this.render()
  }

  // keyup: the caret moved without an input event (arrows/Home/End).
  caretMoved (event: KeyboardEvent): void {
    if (CARET_KEYS.has(event.key)) this.update()
  }

  keydown (event: KeyboardEvent): void {
    if (!this.isOpen) return
    switch (event.key) {
    case 'ArrowDown':
      event.preventDefault()
      this.move(1)
      break
    case 'ArrowUp':
      event.preventDefault()
      this.move(-1)
      break
    case 'Enter':
    case 'Tab':
      // Modified Enter/Tab belong to the host (Cmd/Ctrl+Enter submits the
      // WIRE composer; Shift+Tab moves focus backwards).
      if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) return
      event.preventDefault()
      this.pick(this.active)
      break
    case 'Escape':
      event.preventDefault()
      this.close()
      break
    }
  }

  close (): void {
    this.menuTarget.hidden = true
    this.menuTarget.replaceChildren()
    this.inputTarget.setAttribute('aria-expanded', 'false')
    this.inputTarget.removeAttribute('aria-activedescendant')
    this.token = null
    this.matches = []
  }

  private tokenAtCaret (): Token | null {
    const field = this.inputTarget
    const caret = field.selectionStart ?? field.value.length
    const match = TOKEN_AT_CARET.exec(field.value.slice(0, caret))
    if (!match) return null
    const boundary = match[1] ?? ''
    const query = match[2] ?? ''
    const tail = TOKEN_TAIL.exec(field.value.slice(caret))?.[0] ?? ''
    return { start: match.index + boundary.length, end: caret + tail.length, query: query.toLowerCase() }
  }

  private search (query: string): Emote[] {
    const prefix: Emote[] = []
    const infix: Emote[] = []
    for (const emote of this.emotesValue) {
      if (emote.slug.startsWith(query)) prefix.push(emote)
      else if (emote.slug.includes(query)) infix.push(emote)
    }
    return prefix.concat(infix).slice(0, MAX_ROWS)
  }

  private move (delta: number): void {
    const count = this.matches.length
    this.active = (this.active + delta + count) % count
    this.paint(true)
  }

  private pick (index: number): void {
    const emote = this.matches[index]
    const token = this.token
    if (!emote || !token) {
      this.close()
      return
    }
    const field = this.inputTarget
    const spacer = /^\s/.test(field.value.slice(token.end)) ? '' : ' '
    field.setRangeText(`:${emote.slug}:${spacer}`, token.start, token.end, 'end')
    this.close()
    field.focus()
    field.dispatchEvent(new Event('input', { bubbles: true }))
  }

  private render (): void {
    this.menuTarget.replaceChildren(...this.matches.map((emote, index) => this.buildOption(emote, index)))
    this.menuTarget.hidden = false
    this.inputTarget.setAttribute('aria-expanded', 'true')
    this.paint(false)
  }

  private buildOption (emote: Emote, index: number): HTMLElement {
    const option = document.createElement('li')
    option.id = `${this.menuTarget.id}-option-${index}`
    option.className = 'emote-option'
    option.setAttribute('role', 'option')
    option.addEventListener('mousedown', (event) => {
      event.preventDefault() // keep focus in the field
      this.pick(index)
    })
    option.addEventListener('mouseenter', () => {
      this.active = index
      this.paint(false)
    })

    const img = document.createElement('img')
    img.src = emote.url
    img.alt = ''
    img.width = 28
    img.height = 28
    img.className = 'emote'

    const slug = document.createElement('span')
    slug.className = 'emote-option-slug'
    slug.textContent = `:${emote.slug}:`

    option.append(img, slug)
    return option
  }

  private paint (scroll: boolean): void {
    Array.from(this.menuTarget.children).forEach((option, index) => {
      const isActive = index === this.active
      option.classList.toggle('emote-option--active', isActive)
      option.setAttribute('aria-selected', String(isActive))
      if (!isActive) return
      this.inputTarget.setAttribute('aria-activedescendant', option.id)
      if (scroll && typeof option.scrollIntoView === 'function') option.scrollIntoView({ block: 'nearest' })
    })
  }
}
