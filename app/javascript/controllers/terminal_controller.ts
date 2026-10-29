import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// The home console (home/_terminal). The screen is server-rendered; this
// flicks its lines on in order like a boot log (a keydown or a click
// skips to the end; phones, reduced motion and a Turbo cache restore
// render at once), then runs the "> " prompt: a typed tag matches a row
// link's data-command and Turbo-visits its href (the permanent player
// survives — the old full page load was a migration-era precaution),
// ? / help lists the commands, clear wipes the replies. The line copy
// lives in the partial, not here.
const LINE_MS = 30
const PAUSE_MS = 140 // after the banner, before a rule

export default class extends Controller<HTMLElement> {
  static targets = ['line', 'inputLine', 'typed', 'input', 'reply']

  declare readonly lineTargets: HTMLElement[]
  declare readonly inputLineTarget: HTMLElement
  declare readonly typedTarget: HTMLElement
  declare readonly inputTarget: HTMLInputElement
  declare readonly replyTarget: HTMLElement

  private booting = false
  private timeoutId: number | null = null

  connect (): void {
    const instant = this.element.dataset.boot === 'done' ||
      window.matchMedia('(max-width: 767px)').matches ||
      window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (instant) {
      this.finish()
      return
    }
    this.booting = true
    this.reveal(0)
  }

  disconnect (): void {
    this.booting = false
    this.clearTimer()
  }

  // keydown@document / a click anywhere on the console: skip the boot.
  skip (): void {
    if (!this.booting) return
    this.finish()
  }

  inputChanged (): void {
    this.typedTarget.textContent = this.inputTarget.value
  }

  inputKeydown (event: KeyboardEvent): void {
    if (event.key !== 'Enter') return
    const command = this.inputTarget.value.trim()
    if (!command) return
    this.inputTarget.value = ''
    this.typedTarget.textContent = ''
    this.run(command)
  }

  private run (command: string): void {
    const key = command.toLowerCase()
    if (key === 'clear') {
      this.replyTarget.replaceChildren()
      this.replyTarget.hidden = true
      return
    }

    const links = this.commands()
    this.say(`> ${command}`, 'console-echo')
    if (key === '?' || key === 'help') {
      this.say(`COMMANDS: ${[...links.keys()].join(' ')} · clear`)
      return
    }

    const link = links.get(key)
    if (link) {
      this.say(`CONNECTING ${link.getAttribute('href') ?? ''} ...`)
      Turbo.visit(link.href)
    } else {
      this.say(`UNKNOWN COMMAND: ${command}`, 'console-err')
    }
  }

  // The rows' links, keyed by their data-command (first one wins).
  private commands (): Map<string, HTMLAnchorElement> {
    const map = new Map<string, HTMLAnchorElement>()
    this.element.querySelectorAll<HTMLAnchorElement>('a[data-command]').forEach(link => {
      const key = link.dataset.command
      if (key && !map.has(key)) map.set(key, link)
    })
    return map
  }

  private say (text: string, klass = ''): void {
    const line = document.createElement('div')
    line.textContent = text
    if (klass) line.className = klass
    this.replyTarget.appendChild(line)
    this.replyTarget.hidden = false
  }

  private reveal (index: number): void {
    if (!this.booting) return
    const line = this.lineTargets[index]
    if (!line) {
      this.finish()
      return
    }
    line.classList.add('console-line--on')
    const next = this.lineTargets[index + 1]
    const pause = index === 0 || (next?.classList.contains('console-rule') ?? false)
    this.timeoutId = window.setTimeout(() => this.reveal(index + 1), pause ? PAUSE_MS : LINE_MS)
  }

  private finish (): void {
    this.booting = false
    this.clearTimer()
    this.lineTargets.forEach(line => line.classList.add('console-line--on'))
    this.element.dataset.boot = 'done'
    this.inputLineTarget.hidden = false
    window.requestAnimationFrame(() => this.inputTarget.focus({ preventScroll: true }))
  }

  private clearTimer (): void {
    if (this.timeoutId !== null) window.clearTimeout(this.timeoutId)
    this.timeoutId = null
  }
}
