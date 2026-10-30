import { Controller } from '@hotwired/stimulus'

// A textarea that grows with its content (the /root console's lyrics,
// description, credits and notes fields): the height follows scrollHeight
// on connect and on every input, so a long lyric sheet never scrolls
// inside a small box. CSS keeps a min-height; resize stays available.
export default class extends Controller<HTMLTextAreaElement> {
  connect (): void {
    this.grow()
  }

  grow (): void {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight + 2}px`
  }
}
