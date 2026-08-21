import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Mobile "jump to article" selector (HandbookLayout MobileSectionSelector
// port): navigate on change.
export default class extends Controller<HTMLSelectElement> {
  go (): void {
    const value = this.element.value
    Turbo.visit(value === '' ? this.element.dataset.rootPath || '/' : value)
  }
}
