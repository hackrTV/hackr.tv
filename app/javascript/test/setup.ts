import '@testing-library/jest-dom'

// Mock HTMLMediaElement methods that aren't implemented in jsdom
window.HTMLMediaElement.prototype.load = function () {
  // Trigger canplay event after a short delay to simulate loading
  setTimeout(() => {
    this.dispatchEvent(new Event('canplay'))
  }, 0)
}

window.HTMLMediaElement.prototype.play = function () {
  return Promise.resolve()
}

window.HTMLMediaElement.prototype.pause = function () {
  // do nothing
}
