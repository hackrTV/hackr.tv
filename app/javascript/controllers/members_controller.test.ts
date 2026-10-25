import { describe, it, expect, afterEach } from 'vitest'
import { Application } from '@hotwired/stimulus'
import MembersController from './members_controller'

// Fixture mirrors uplink/_members: callsign rows with their role and a
// hidden […] operator-menu button each; the viewer's token comes from the
// uplink-callsign meta (uplink/show), alias + role from the layout metas.

function row (token: string, role: string): string {
  return `<li class="uplink-member uplink-member--${role}" data-callsign="${token}" data-role="${role}"><span class="uplink-member-dot"></span><span class="uplink-member-name">SIG-${token}</span><button type="button" class="uplink-member-mod" hidden>…</button></li>`
}

function fixture (): string {
  return `
    <div id="uplink-members" data-controller="members">
      ${row('A1B2C3', 'operative')}
      ${row('D4E5F6', 'operative')}
      ${row('0F0F0F', 'operator')}
      ${row('ADADAD', 'admin')}
    </div>`
}

describe('MembersController', () => {
  let application: Application

  const metas: HTMLMetaElement[] = []

  function meta (name: string, content: string): void {
    const el = document.createElement('meta')
    el.name = name
    el.content = content
    document.head.appendChild(el)
    metas.push(el)
  }

  async function start (): Promise<void> {
    document.body.innerHTML = fixture()
    application = Application.start()
    application.register('members', MembersController)
    await Promise.resolve()
  }

  afterEach(async () => {
    document.body.innerHTML = ''
    metas.splice(0).forEach(el => el.remove())
    await Promise.resolve()
    application?.stop()
  })

  it('reveals the viewer\'s own row by token and leaves the rest anonymized', async () => {
    meta('uplink-callsign', 'D4E5F6')
    meta('current-hackr-alias', 'xeraen')
    await start()

    const rows = document.querySelectorAll('.uplink-member')
    expect(rows[0].classList.contains('uplink-member--self')).toBe(false)
    expect(rows[0].querySelector('.uplink-member-name')!.textContent).toBe('SIG-A1B2C3')
    expect(rows[1].classList.contains('uplink-member--self')).toBe(true)
    expect(rows[1].querySelector('.uplink-member-name')!.textContent).toBe('@xeraen')
    expect((rows[1] as HTMLElement).title).toBe('You')
  })

  it('re-reveals after the roster is replaced (reconnect)', async () => {
    meta('uplink-callsign', 'A1B2C3')
    meta('current-hackr-alias', 'xeraen')
    await start()
    document.getElementById('uplink-members')!.outerHTML = fixture()
    await Promise.resolve()

    expect(document.querySelector('.uplink-member--self .uplink-member-name')!.textContent).toBe('@xeraen')
  })

  it('does nothing without the metas', async () => {
    await start()
    expect(document.querySelector('.uplink-member--self')).toBeNull()
    expect(document.querySelectorAll('.uplink-member-mod:not([hidden])').length).toBe(0)
  })

  function moderable (): string[] {
    return Array.from(document.querySelectorAll<HTMLElement>('.uplink-member'))
      .filter(r => !r.querySelector<HTMLElement>('.uplink-member-mod')!.hidden)
      .map(r => r.dataset.callsign!)
  }

  it('reveals the operator menu to an operator on the operatives only — not on themselves, peers or admins', async () => {
    meta('uplink-callsign', 'A1B2C3')
    meta('current-hackr-alias', 'xeraen')
    meta('current-hackr-role', 'operator')
    await start()

    expect(moderable()).toEqual(['D4E5F6'])
  })

  it('reveals it to an admin on operators and operatives, keeps it from operatives, and re-reveals after a roster replace', async () => {
    meta('uplink-callsign', 'ADADAD')
    meta('current-hackr-alias', 'root')
    meta('current-hackr-role', 'admin')
    await start()
    expect(moderable()).toEqual(['A1B2C3', 'D4E5F6', '0F0F0F'])

    document.getElementById('uplink-members')!.outerHTML = fixture()
    await Promise.resolve()
    expect(moderable()).toEqual(['A1B2C3', 'D4E5F6', '0F0F0F'])

    application.stop()
    metas.splice(0).forEach(el => el.remove())
    meta('uplink-callsign', 'D4E5F6')
    meta('current-hackr-alias', 'ghost')
    meta('current-hackr-role', 'operative')
    await start()
    expect(moderable()).toEqual([])
  })
})
