import { Controller } from '@hotwired/stimulus'

const HISTORY_KEY = 'grid_command_history'
const MAX_HISTORY = 100
const CLEAR_COMMANDS = ['clear', 'cls', 'cl']

// GridGamePage command flow port: instant client-side echo (separator +
// cyan "> cmd"), clear/cls handled without a round-trip, ↑/↓ history on
// sessionStorage (useCommandHistory.ts semantics: draft preservation,
// dedup-last, 100 cap), input disabled while a command executes and
// refocused after (CommandInput.tsx parity).
export default class extends Controller<HTMLElement> {
  static targets = ['log', 'input', 'submit']

  declare readonly logTarget: HTMLElement
  declare readonly inputTarget: HTMLInputElement
  declare readonly submitTarget: HTMLButtonElement

  private history: string[] = []
  private historyIndex = -1
  private draft = ''

  connect (): void {
    try {
      const stored = JSON.parse(sessionStorage.getItem(HISTORY_KEY) ?? '[]')
      this.history = Array.isArray(stored) ? stored : []
    } catch {
      this.history = []
    }
  }

  submit (event: Event): void {
    const command = this.inputTarget.value.trim()
    if (!command) {
      event.preventDefault()
      return
    }

    this.addToHistory(command)

    if (CLEAR_COMMANDS.includes(command.toLowerCase())) {
      event.preventDefault()
      this.logTarget.innerHTML = ''
      this.inputTarget.value = ''
      this.inputTarget.focus()
      return
    }

    this.echo(command)
  }

  started (): void {
    // FormData is captured before submit-start fires, so disabling here
    // doesn't drop the field from the POST.
    this.inputTarget.disabled = true
  }

  submitted (event: Event): void {
    this.inputTarget.disabled = false
    const detail = (event as CustomEvent).detail
    if (detail?.success) {
      this.inputTarget.value = ''
    } else {
      this.appendErrorLine('Error: Network error. Please try again.')
    }
    this.inputTarget.focus()
  }

  keydown (event: KeyboardEvent): void {
    if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.inputTarget.value = this.navigateUp(this.inputTarget.value)
    } else if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.inputTarget.value = this.navigateDown()
    }
  }

  private navigateUp (currentInput: string): string {
    if (this.history.length === 0) return currentInput
    if (this.historyIndex === -1) {
      this.draft = currentInput
      this.historyIndex = this.history.length - 1
    } else {
      this.historyIndex = Math.max(0, this.historyIndex - 1)
    }
    return this.history[this.historyIndex] ?? currentInput
  }

  private navigateDown (): string {
    if (this.historyIndex === -1) return this.inputTarget.value
    this.historyIndex += 1
    if (this.historyIndex >= this.history.length) {
      this.historyIndex = -1
      return this.draft
    }
    return this.history[this.historyIndex] ?? ''
  }

  private addToHistory (command: string): void {
    if (this.history[this.history.length - 1] !== command) {
      this.history = [...this.history, command].slice(-MAX_HISTORY)
      try {
        sessionStorage.setItem(HISTORY_KEY, JSON.stringify(this.history))
      } catch {
        // storage full/unavailable — history just won't persist
      }
    }
    this.historyIndex = -1
    this.draft = ''
  }

  // GridGamePage echo: 1px separator rule + cyan "> command". While a
  // breach overlay is up (tactical), the echo lands in its log instead
  // (TacticalContext routed output to breachOutput in breach).
  private echo (command: string): void {
    const separator = document.createElement('div')
    separator.className = 'grid-echo-separator'
    const echo = document.createElement('div')
    echo.className = 'grid-line'
    const span = document.createElement('span')
    span.className = 'grid-echo'
    span.textContent = `> ${command}`
    echo.appendChild(span)
    this.echoTargetElement().append(separator, echo)
  }

  private echoTargetElement (): HTMLElement {
    const breachLog = document.getElementById('breach-log')
    if (breachLog && !breachLog.hidden && breachLog.offsetParent !== null) return breachLog
    return this.logTarget
  }

  private appendErrorLine (text: string): void {
    const line = document.createElement('div')
    line.className = 'grid-line grid-error-line'
    line.textContent = text
    this.logTarget.appendChild(line)
  }
}
