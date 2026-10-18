import { describe, it, expect, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import EmotePickerController from './emote_picker_controller'

// Fixtures mirror the two composers that host the picker: the Uplink
// packet <input> (uplink/_packet_form) and the WIRE pulse <textarea>
// (wire/_composer). Both wire input/keydown/keyup/click to the picker and
// close it on turbo:submit-end.

const EMOTES = [
  { slug: 'smile', url: '/img/smile.webp', width: 28, height: 28 },
  { slug: 'smirk', url: '/img/smirk.webp', width: 28, height: 28 },
  { slug: 'big_smile', url: '/img/big_smile.webp', width: 28, height: 28 },
  { slug: 'wave', url: '/img/wave.gif', width: 56, height: 28 },
  { slug: 'r1', url: '/img/r1.webp', width: 28, height: 28 },
  { slug: 'r2', url: '/img/r2.webp', width: 28, height: 28 },
  { slug: 'r3', url: '/img/r3.webp', width: 28, height: 28 },
  { slug: 'r4', url: '/img/r4.webp', width: 28, height: 28 },
  { slug: 'r5', url: '/img/r5.webp', width: 28, height: 28 },
  { slug: 'r6', url: '/img/r6.webp', width: 28, height: 28 },
  { slug: 'r7', url: '/img/r7.webp', width: 28, height: 28 },
  { slug: 'r8', url: '/img/r8.webp', width: 28, height: 28 },
  { slug: 'r9', url: '/img/r9.webp', width: 28, height: 28 }
]

const FIELD_ACTIONS = 'input->emote-picker#update keydown->emote-picker#keydown keyup->emote-picker#caretMoved click->emote-picker#update'

function inputFixture (emotes: unknown[] = EMOTES): string {
  return `
    <div data-controller="emote-picker" data-emote-picker-emotes-value='${JSON.stringify(emotes)}'>
      <form data-action="turbo:submit-end->emote-picker#close">
        <div class="packet-input-field">
          <input id="content" data-emote-picker-target="input" data-action="${FIELD_ACTIONS}">
          <ul class="emote-menu emote-menu--up" hidden data-emote-picker-target="menu"></ul>
        </div>
      </form>
    </div>
    <div id="outside"></div>`
}

function textareaFixture (): string {
  return `
    <form data-controller="emote-picker" data-emote-picker-emotes-value='${JSON.stringify(EMOTES)}'
          data-action="turbo:submit-end->emote-picker#close">
      <div class="emote-anchor">
        <textarea id="content" data-emote-picker-target="input" data-action="${FIELD_ACTIONS}"></textarea>
        <ul class="emote-menu emote-menu--down" hidden data-emote-picker-target="menu"></ul>
      </div>
    </form>
    <div id="outside"></div>`
}

describe('EmotePickerController', () => {
  let application: Application

  const field = (): HTMLInputElement | HTMLTextAreaElement => document.getElementById('content') as HTMLInputElement
  const menu = (): HTMLElement => document.querySelector('[data-emote-picker-target="menu"]')!
  const options = (): string[] => Array.from(menu().querySelectorAll('.emote-option-slug')).map(el => el.textContent ?? '')
  const activeIndex = (): number => Array.from(menu().children).findIndex(li => li.classList.contains('emote-option--active'))

  // Types `value` with the caret at the end (or at `caret`) and fires input.
  function type (value: string, caret = value.length): void {
    field().value = value
    field().setSelectionRange(caret, caret)
    field().dispatchEvent(new Event('input', { bubbles: true }))
  }

  function key (name: string, init: KeyboardEventInit = {}): KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key: name, bubbles: true, cancelable: true, ...init })
    field().dispatchEvent(event)
    return event
  }

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('emote-picker', EmotePickerController)
    await Promise.resolve()
  }

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
  })

  describe('opening', () => {
    it('opens on ":" + a char, prefix matches first, infix after, capped at 8 rows', async () => {
      await start(inputFixture())
      type('hey :sm')

      expect(menu().hidden).toBe(false)
      expect(options()).toEqual([':smile:', ':smirk:', ':big_smile:'])
      expect(activeIndex()).toBe(0)
      expect(field().getAttribute('aria-expanded')).toBe('true')

      type(':r')
      expect(options().length).toBe(8)
    })

    it('matches case-insensitively and renders image previews', async () => {
      await start(inputFixture())
      type(':WAV')

      expect(options()).toEqual([':wave:'])
      const img = menu().querySelector('img')!
      expect(img.getAttribute('src')).toBe('/img/wave.gif')
      expect(img.className).toBe('emote')
      // Box comes from the server payload, so wide emotes preview wide.
      expect(img.getAttribute('width')).toBe('56')
      expect(img.getAttribute('height')).toBe('28')
    })

    it('stays closed for a bare colon, clock text, mid-word colons, and unknown slugs', async () => {
      await start(inputFixture())
      type('go :')
      expect(menu().hidden).toBe(true)
      type('at 12:30')
      expect(menu().hidden).toBe(true)
      type('http://x')
      expect(menu().hidden).toBe(true)
      type(':zzz')
      expect(menu().hidden).toBe(true)
    })

    it('tracks the token under the caret, not the end of the value', async () => {
      await start(inputFixture())
      type(':sm tail', 3)
      expect(options()).toEqual([':smile:', ':smirk:', ':big_smile:'])

      field().setSelectionRange(8, 8)
      field().dispatchEvent(new KeyboardEvent('keyup', { key: 'End', bubbles: true }))
      expect(menu().hidden).toBe(true)
    })

    it('does nothing when the server shipped no emotes', async () => {
      await start(inputFixture([]))
      type(':sm')
      expect(menu().hidden).toBe(true)
    })
  })

  describe('keyboard', () => {
    it('moves with arrows (wrapping) and exposes the active option via aria', async () => {
      await start(inputFixture())
      type(':sm')

      expect(key('ArrowDown').defaultPrevented).toBe(true)
      expect(activeIndex()).toBe(1)
      key('ArrowDown')
      key('ArrowDown')
      expect(activeIndex()).toBe(0) // wrapped
      key('ArrowUp')
      expect(activeIndex()).toBe(2)
      const active = menu().children[2]!
      expect(active.getAttribute('aria-selected')).toBe('true')
      expect(field().getAttribute('aria-activedescendant')).toBe(active.id)
    })

    it('inserts ":slug: " over the token on Enter, recounts via input, and closes', async () => {
      await start(inputFixture())
      const inputSpy = vi.fn()
      field().addEventListener('input', inputSpy)
      type('hey :sm there', 7)
      inputSpy.mockClear()
      key('ArrowDown')

      const enter = key('Enter')

      expect(enter.defaultPrevented).toBe(true) // no implicit form submit
      expect(field().value).toBe('hey :smirk: there') // existing space reused, no double space
      expect(field().selectionStart).toBe(11)
      expect(inputSpy).toHaveBeenCalledTimes(1)
      expect(menu().hidden).toBe(true)
      expect(field().getAttribute('aria-expanded')).toBe('false')
    })

    it('inserts on Tab, closes on Escape, and ignores keys while closed', async () => {
      await start(inputFixture())
      type(':wa')
      expect(key('Tab').defaultPrevented).toBe(true)
      expect(field().value).toBe(':wave: ')

      type(':sm')
      expect(key('Escape').defaultPrevented).toBe(true)
      expect(menu().hidden).toBe(true)

      expect(key('Enter').defaultPrevented).toBe(false)
      expect(key('ArrowDown').defaultPrevented).toBe(false)
    })

    it('leaves modified Enter/Tab to the host controller', async () => {
      await start(textareaFixture())
      type(':sm')

      expect(key('Enter', { ctrlKey: true }).defaultPrevented).toBe(false)
      expect(key('Enter', { metaKey: true }).defaultPrevented).toBe(false)
      expect(key('Tab', { shiftKey: true }).defaultPrevented).toBe(false)
      expect(field().value).toBe(':sm')
      expect(menu().hidden).toBe(false)
    })
  })

  describe('caret inside a token', () => {
    it('replaces the whole token when the caret sits mid-slug', async () => {
      await start(inputFixture())
      type(':wave: ok', 3) // caret after ":wa"
      expect(options()).toEqual([':wave:'])

      key('Enter')
      expect(field().value).toBe(':wave: ok')
      expect(field().selectionStart).toBe(6)
    })
  })

  describe('textarea composer', () => {
    it('finds tokens on later lines and prevents the newline on Enter', async () => {
      await start(textareaFixture())
      type('first line\n:big')

      expect(options()).toEqual([':big_smile:'])
      expect(key('Enter').defaultPrevented).toBe(true)
      expect(field().value).toBe('first line\n:big_smile: ')
    })
  })

  describe('mouse', () => {
    it('inserts on option mousedown without stealing focus, and hover moves the highlight', async () => {
      await start(inputFixture())
      type(':sm')
      const second = menu().children[1]!

      second.dispatchEvent(new MouseEvent('mouseenter'))
      expect(activeIndex()).toBe(1)

      const down = new MouseEvent('mousedown', { bubbles: true, cancelable: true })
      second.dispatchEvent(down)

      expect(down.defaultPrevented).toBe(true)
      expect(field().value).toBe(':smirk: ')
      expect(menu().hidden).toBe(true)
    })

    it('closes on an outside mousedown', async () => {
      await start(inputFixture())
      type(':sm')

      document.getElementById('outside')!.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))

      expect(menu().hidden).toBe(true)
    })
  })

  it('closes when the host form finishes a turbo submit', async () => {
    await start(textareaFixture())
    type(':sm')

    document.querySelector('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))

    expect(menu().hidden).toBe(true)
  })
})
