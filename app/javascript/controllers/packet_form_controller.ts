import { Controller } from '@hotwired/stimulus'

// PacketInput.tsx port: "{length}/{limit}" counter with warning (>90%)
// and over-limit states, submit disabled when empty/over, input cleared
// and refocused after a successful turbo submit, and a slow-mode
// cooldown that counts down on the TX button. Server errors replace the
// error slot (a target of this controller); errorTargetConnected reads
// the slot's wait_seconds to start server-directed cooldowns.
// multiline (the /uplink shell's textarea): Enter sends, Shift+Enter
// inserts a newline, the field auto-grows to a cap, and focus returns
// to the field when a slow-mode cooldown that disabled it ends. An
// Enter the emote picker already consumed (defaultPrevented — its
// keydown action is listed first) never sends.
// Replies (shell composer): packet:reply from a packet's hover control
// (listened for on document — the packet isn't a descendant) arms the
// hidden reply_to_id and shows the "REPLYING TO <sender> [x]" bar; [x],
// Escape (after the emote picker had its turn) and a successful send
// disarm it. The dock/popout composer has no reply targets and ignores
// the event.

const MAX_FIELD_HEIGHT_PX = 160

type ComposerField = HTMLInputElement | HTMLTextAreaElement

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'count', 'submit', 'error', 'replyTo', 'replyBar', 'replySender']
  static values = { slowMode: Number, limit: Number, multiline: Boolean }

  declare readonly inputTarget: ComposerField
  declare readonly countTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly hasReplyToTarget: boolean
  declare readonly replyToTarget: HTMLInputElement
  declare readonly hasReplyBarTarget: boolean
  declare readonly replyBarTarget: HTMLElement
  declare readonly hasReplySenderTarget: boolean
  declare readonly replySenderTarget: HTMLElement
  declare readonly slowModeValue: number
  declare readonly limitValue: number
  declare readonly multilineValue: boolean

  private cooldownTimer: number | null = null
  private cooldownRemaining = 0
  private baseDisabled = false
  private refocusAfterCooldown = false

  connect (): void {
    this.baseDisabled = this.inputTarget.disabled
    this.update()
  }

  disconnect (): void {
    this.stopCooldown()
  }

  update (): void {
    const length = this.inputTarget.value.length
    const over = length > this.limitValue
    const near = !over && length > this.limitValue * 0.9
    this.countTarget.textContent = `${length}/${this.limitValue}`
    this.countTarget.classList.toggle('over-limit', over)
    this.countTarget.classList.toggle('warning', near)
    this.inputTarget.closest('.packet-input-field')?.classList.toggle('packet-input-field--over', over)
    this.refreshDisabled()
    this.autogrow()
  }

  submitted (event: Event): void {
    const detail = (event as CustomEvent).detail
    if (detail?.success) {
      this.inputTarget.value = ''
      this.cancelReply()
      if (this.slowModeValue > 0) this.startCooldown(this.slowModeValue)
      this.update()
      this.refocusAfterCooldown = this.inputTarget.disabled
      this.inputTarget.focus()
    }
  }

  // Multiline only: Enter sends, Shift+Enter keeps the newline. Coarse
  // pointers (soft keyboards) keep Enter as newline — TX sends there.
  // An open emote menu owns Enter (it picks), so it never sends.
  keydown (event: KeyboardEvent): void {
    if (!this.multilineValue || event.defaultPrevented || event.isComposing) return
    if (event.key === 'Escape') {
      if (!this.replying) return
      event.preventDefault()
      this.cancelReply()
      return
    }
    if (event.key !== 'Enter' || event.shiftKey) return
    if (this.element.querySelector('.emote-menu:not([hidden])')) return
    if (typeof window.matchMedia === 'function' && window.matchMedia('(pointer: coarse)').matches) return
    event.preventDefault()
    if (this.submitTarget.disabled) return
    this.inputTarget.form?.requestSubmit()
  }

  // ── Replies ────────────────────────────────────────────────────────

  // A cooldown-disabled field still arms (the send waits anyway); a
  // role-gated / squelched one never does.
  reply (event: CustomEvent<{ id?: string, sender?: string }>): void {
    if (!this.canReply || this.baseDisabled) return
    const id = event.detail?.id
    if (!id || !/^\d+$/.test(id)) return
    this.replyToTarget.value = id
    if (this.hasReplySenderTarget) this.replySenderTarget.textContent = event.detail?.sender ?? ''
    this.replyBarTarget.hidden = false
    this.inputTarget.focus()
  }

  cancelReply (): void {
    if (!this.canReply) return
    this.replyToTarget.value = ''
    this.replyBarTarget.hidden = true
    if (this.hasReplySenderTarget) this.replySenderTarget.textContent = ''
    if (!this.inputTarget.disabled) this.inputTarget.focus()
  }

  private get canReply (): boolean {
    return this.hasReplyToTarget && this.hasReplyBarTarget
  }

  private get replying (): boolean {
    return this.canReply && this.replyToTarget.value !== ''
  }

  errorTargetConnected (el: HTMLElement): void {
    const wait = Number(el.dataset.waitSeconds ?? 0)
    if (wait > 0) this.startCooldown(wait)
  }

  private startCooldown (seconds: number): void {
    this.stopCooldown()
    this.cooldownRemaining = seconds
    this.render()
    this.cooldownTimer = window.setInterval(() => {
      this.cooldownRemaining -= 1
      if (this.cooldownRemaining <= 0) {
        this.stopCooldown()
        this.render()
        this.refocus()
        return
      }
      this.render()
    }, 1000)
  }

  // Cooldowns disable the field, which drops focus; hand it back once the
  // field is usable again — unless the viewer moved on to something else.
  private refocus (): void {
    if (!this.refocusAfterCooldown) return
    this.refocusAfterCooldown = false
    if (document.activeElement === document.body && !this.inputTarget.disabled) this.inputTarget.focus()
  }

  private autogrow (): void {
    if (!this.multilineValue) return
    const field = this.inputTarget
    field.style.height = 'auto'
    if (field.scrollHeight > 0) field.style.height = `${Math.min(field.scrollHeight, MAX_FIELD_HEIGHT_PX)}px`
  }

  private stopCooldown (): void {
    if (this.cooldownTimer !== null) {
      window.clearInterval(this.cooldownTimer)
      this.cooldownTimer = null
    }
    this.cooldownRemaining = 0
  }

  private render (): void {
    const cooling = this.cooldownRemaining > 0
    this.submitTarget.textContent = cooling ? `${this.cooldownRemaining}s` : 'TX'
    this.submitTarget.classList.toggle('packet-input-send--cooldown', cooling)
    this.refreshDisabled()
  }

  private refreshDisabled (): void {
    const cooling = this.cooldownRemaining > 0
    const length = this.inputTarget.value.length
    const over = length > this.limitValue
    this.inputTarget.disabled = this.baseDisabled || cooling
    this.submitTarget.disabled = this.baseDisabled || cooling || over || this.inputTarget.value.trim() === ''
  }
}
