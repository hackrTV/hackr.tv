import { Controller } from '@hotwired/stimulus'

// Typed confirmation for a destructive /root form (deleting a release
// takes its tracks with it): the submit is stopped unless the operator
// types the record's slug (data-confirm-slug-slug-value) into the prompt.
// Cancelling the prompt just cancels; a wrong answer says so.
export default class extends Controller<HTMLFormElement> {
  static values = { slug: String }

  declare readonly slugValue: string

  check (event: Event): void {
    const typed = window.prompt(`Type "${this.slugValue}" to confirm deletion:`)
    if (typed === this.slugValue) return
    event.preventDefault()
    if (typed !== null) window.alert('Slug did not match. Deletion cancelled.')
  }
}
