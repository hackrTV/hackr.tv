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

// Node 22+ ships an experimental `localStorage`/`sessionStorage` global
// that is an empty object unless --localstorage-file is given, and
// vitest's jsdom environment keeps that stub instead of jsdom's Storage
// (window === globalThis here). Replace both with an in-memory Storage so
// controllers that persist via Web Storage (popout heartbeat + its dock
// consumer, …) are testable.
function memoryStorage (): Storage {
  const store = new Map<string, string>()
  const storage = {
    get length (): number { return store.size },
    clear: (): void => { store.clear() },
    getItem: (key: string): string | null => store.get(String(key)) ?? null,
    key: (index: number): string | null => Array.from(store.keys())[index] ?? null,
    removeItem: (key: string): void => { store.delete(String(key)) },
    setItem: (key: string, value: string): void => { store.set(String(key), String(value)) }
  }
  return storage as Storage
}

for (const name of ['localStorage', 'sessionStorage']) {
  Object.defineProperty(globalThis, name, { value: memoryStorage(), configurable: true, writable: true })
}
