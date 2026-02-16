import { describe, it, expect } from 'vitest'
import { getArtistColors } from '../artistColors'

describe('artistColors', () => {
  describe('getArtistColors', () => {
    it('returns the correct scheme for a known artist', () => {
      const colors = getArtistColors('system-rot')

      expect(colors.primary).toBe('#39ff14')
      expect(colors.secondary).toBe('#2bcc10')
      expect(colors.glow).toBe('rgba(57, 255, 20, 0.6)')
      expect(colors.glowStrong).toBe('rgba(57, 255, 20, 0.8)')
      expect(colors.background).toBe('#0a0a0a')
    })

    it('returns the default scheme for an unknown artist', () => {
      const colors = getArtistColors('nonexistent_artist')

      expect(colors.primary).toBe('#8B00FF')
      expect(colors.secondary).toBe('#6B00CC')
    })

    it('returns all five properties', () => {
      const colors = getArtistColors('xeraen')
      const keys = Object.keys(colors)

      expect(keys).toContain('primary')
      expect(keys).toContain('secondary')
      expect(keys).toContain('glow')
      expect(keys).toContain('glowStrong')
      expect(keys).toContain('background')
    })

    it('returns unique colors for different artists', () => {
      const systemRot = getArtistColors('system-rot')
      const blitzbeam = getArtistColors('blitzbeam')
      const cipherProtocol = getArtistColors('cipher-protocol')

      expect(systemRot.primary).not.toBe(blitzbeam.primary)
      expect(blitzbeam.primary).not.toBe(cipherProtocol.primary)
      expect(systemRot.primary).not.toBe(cipherProtocol.primary)
    })

    const allArtists = [
      'xeraen', 'thecyberpulse', 'system-rot', 'wavelength-zero',
      'voiceprint', 'temporal-blue-drift', 'heartbreak-havoc',
      'apex-overdrive', 'cipher-protocol', 'neon-hearts',
      'injection-vector', 'blitzbeam', 'ethereality', 'offline',
      'the-pulse-grid'
    ]

    it.each(allArtists)('returns a valid scheme for %s', (slug) => {
      const colors = getArtistColors(slug)

      expect(colors.primary).toMatch(/^#[0-9a-fA-F]{6}$/)
      expect(colors.secondary).toMatch(/^#[0-9a-fA-F]{6}$/)
      expect(colors.glow).toMatch(/^rgba\(/)
      expect(colors.glowStrong).toMatch(/^rgba\(/)
      expect(colors.background).toBe('#0a0a0a')
    })

    it('returns the same object reference for repeated calls', () => {
      const first = getArtistColors('xeraen')
      const second = getArtistColors('xeraen')

      expect(first).toBe(second)
    })

    it('returns the same default for any unknown slug', () => {
      const a = getArtistColors('unknown_a')
      const b = getArtistColors('unknown_b')

      expect(a).toBe(b)
    })

    it('wavelength-zero has gradient and accentColors set', () => {
      const colors = getArtistColors('wavelength-zero')

      expect(colors.gradient).toBeDefined()
      expect(colors.gradient).toMatch(/^linear-gradient/)
      expect(colors.accentColors).toBeDefined()
      expect(colors.accentColors!.length).toBeGreaterThan(0)
      expect(colors.accentColors!.every(c => c.startsWith('#'))).toBe(true)
    })

    it('other artists do not have gradient or accentColors', () => {
      const nonPrismaticArtists = [
        'xeraen', 'thecyberpulse', 'system-rot', 'voiceprint',
        'temporal-blue-drift', 'heartbreak-havoc', 'apex-overdrive',
        'cipher-protocol', 'neon-hearts', 'injection-vector',
        'blitzbeam', 'ethereality', 'offline', 'the-pulse-grid'
      ]

      nonPrismaticArtists.forEach(slug => {
        const colors = getArtistColors(slug)
        expect(colors.gradient).toBeUndefined()
        expect(colors.accentColors).toBeUndefined()
      })
    })
  })
})
