// Navigate to a URL the way the page supports: Turbo.visit when Turbo is
// loaded (the Hotwire layouts — the permanent player survives), a full
// load otherwise (the admin layout runs Stimulus alone, no Turbo, so its
// DOMContentLoaded-era inline scripts keep working on the next page).
// The terminal controller's "> " prompt goes through here.
type TurboLike = { visit: (url: string) => void }

export function visit (url: string): void {
  const turbo = (window as Window & { Turbo?: TurboLike }).Turbo
  if (turbo) {
    turbo.visit(url)
  } else {
    window.location.assign(url)
  }
}
