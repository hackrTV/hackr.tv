import { Controller } from '@hotwired/stimulus'

// Command-template forms (CredTab rename/send port): fields carry
// data-arg-name; on submit the {name} placeholders in the template are
// interpolated into the hidden input the command bus reads. Submission
// is blocked while any placeholder is empty. A field with
// data-arg-optional keeps its surrounding {name?...} group only when
// filled (used for "from CACHE" suffixes).
export default class extends Controller<HTMLElement> {
  static targets = ['field', 'command']
  static values = { template: String }

  declare readonly fieldTargets: Array<HTMLInputElement | HTMLSelectElement>
  declare readonly commandTarget: HTMLInputElement
  declare readonly templateValue: string

  submit (event: Event): void {
    let command = this.templateValue
    for (const field of this.fieldTargets) {
      const name = field.dataset.argName
      if (!name) continue
      const value = field.value.trim()
      const optional = new RegExp(`\\{${name}\\?([^}]*)\\}`)
      if (command.match(optional)) {
        command = command.replace(optional, value ? `$1${value}` : '')
        continue
      }
      if (!value) {
        event.preventDefault()
        field.focus()
        return
      }
      command = command.split(`{${name}}`).join(value)
    }
    this.commandTarget.value = command.trim()
  }

  // "Other address..." toggle for the transfer select.
  toggleCustom (event: Event): void {
    const select = event.currentTarget as HTMLSelectElement
    const custom = this.fieldTargets.find(f => f.dataset.argCustom === 'true') as HTMLInputElement | undefined
    if (!custom) return
    const isCustom = select.value === '__custom__'
    custom.hidden = !isCustom
    if (isCustom) {
      select.dataset.argName = ''
      custom.dataset.argName = 'to'
      custom.focus()
    } else {
      select.dataset.argName = 'to'
      custom.dataset.argName = ''
    }
  }
}
