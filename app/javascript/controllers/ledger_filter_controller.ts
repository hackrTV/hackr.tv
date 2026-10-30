import { Controller } from '@hotwired/stimulus'

// Client-side filter over a console ledger (the /root tracks screen):
// the FILTER row's input against each row's data-search haystack
// (title + slug + artist + release, downcased, built server-side). A
// // GROUP // section whose rows are all hidden hides too, and the count
// target reads "shown / total". Everything is server-rendered; this only
// toggles visibility.
export default class extends Controller<HTMLElement> {
  static targets = ['input', 'row', 'group', 'count']

  declare readonly inputTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly groupTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement

  connect (): void {
    if (this.inputTarget.value) this.filter()
  }

  filter (): void {
    const query = this.inputTarget.value.trim().toLowerCase()
    let shown = 0
    this.rowTargets.forEach(row => {
      const hit = query === '' || (row.dataset.search ?? '').includes(query)
      row.hidden = !hit
      if (hit) shown++
    })
    this.groupTargets.forEach(group => {
      const rows = this.rowTargets.filter(row => group.contains(row))
      group.hidden = rows.length > 0 && rows.every(row => row.hidden)
    })
    this.countTarget.textContent = `${shown} / ${this.rowTargets.length}`
  }

  clear (): void {
    this.inputTarget.value = ''
    this.filter()
    this.inputTarget.focus()
  }
}
