import { Controller } from '@hotwired/stimulus'

// A file field on the /root console forms (cover image, audio file): the
// native input is visually hidden, a [^] CHOOSE FILE console button opens
// it and the name target echoes the pick. Nothing is uploaded until the
// form commits.
export default class extends Controller<HTMLElement> {
  static targets = ['input', 'name']

  declare readonly inputTarget: HTMLInputElement
  declare readonly nameTarget: HTMLElement

  open (): void {
    this.inputTarget.click()
  }

  changed (): void {
    const file = this.inputTarget.files?.[0]
    this.nameTarget.textContent = file ? file.name : 'no file chosen'
  }
}
