import { describe, it, expect } from 'vitest'
import {
  generateSlug,
  transformMarkdownLinks,
  transformHtmlLinks,
  extractCodexReferences,
  hasCodexLinks,
  getRouteForSlug,
  getFallbackDisplayName
} from '../codexLinks'

describe('codexLinks utilities', () => {
  describe('generateSlug', () => {
    it('converts text to lowercase', () => {
      expect(generateSlug('XERAEN')).toBe('xeraen')
    })

    it('converts spaces to hyphens', () => {
      expect(generateSlug('The Fracture Network')).toBe('the-fracture-network')
    })

    it('removes special characters', () => {
      expect(generateSlug('[[Entry Name]]')).toBe('entry-name')
      expect(generateSlug('Test!@#$%Entry')).toBe('testentry')
    })

    it('squeezes multiple hyphens', () => {
      expect(generateSlug('Multiple   Spaces')).toBe('multiple-spaces')
    })

    it('strips leading and trailing hyphens', () => {
      expect(generateSlug('-Edge Case-')).toBe('edge-case')
    })

    it('handles mixed case and symbols', () => {
      expect(generateSlug('PRISM 2.0: The System')).toBe('prism-20-the-system')
    })

    it('handles empty string', () => {
      expect(generateSlug('')).toBe('')
    })
  })

  describe('transformMarkdownLinks', () => {
    it('converts [[Entry Name]] to markdown link', () => {
      const result = transformMarkdownLinks('See [[XERAEN]] for details')
      expect(result).toBe('See [XERAEN](/codex/xeraen) for details')
    })

    it('handles multiple links', () => {
      const result = transformMarkdownLinks('[[XERAEN]] works with [[The Fracture Network]]')
      expect(result).toBe('[XERAEN](/codex/xeraen) works with [The Fracture Network](/codex/the-fracture-network)')
    })

    it('preserves text without links', () => {
      const result = transformMarkdownLinks('No links here')
      expect(result).toBe('No links here')
    })

    it('handles empty string', () => {
      expect(transformMarkdownLinks('')).toBe('')
    })

    it('handles multiline content', () => {
      const content = `Line 1 with [[XERAEN]]
Line 2 with [[The Fracture Network]]
Line 3 without links`
      const expected = `Line 1 with [XERAEN](/codex/xeraen)
Line 2 with [The Fracture Network](/codex/the-fracture-network)
Line 3 without links`
      expect(transformMarkdownLinks(content)).toBe(expected)
    })

    it('handles links with special characters in names', () => {
      const result = transformMarkdownLinks('See [[PRISM 2.0: The System]]')
      expect(result).toBe('See [PRISM 2.0: The System](/codex/prism-20-the-system)')
    })

    it('converts [[Entry|custom text]] to markdown link with custom display text', () => {
      const result = transformMarkdownLinks('See [[XERAEN|the legendary hackr]] for details')
      expect(result).toBe('See [the legendary hackr](/codex/xeraen) for details')
    })

    it('handles multiple links with custom text', () => {
      const result = transformMarkdownLinks('[[XERAEN|the hackr]] works with [[The Fracture Network|the network]]')
      expect(result).toBe('[the hackr](/codex/xeraen) works with [the network](/codex/the-fracture-network)')
    })

    it('handles mix of standard and custom text links', () => {
      const result = transformMarkdownLinks('[[XERAEN|custom text]] and [[The Fracture Network]]')
      expect(result).toBe('[custom text](/codex/xeraen) and [The Fracture Network](/codex/the-fracture-network)')
    })

    it('custom text overrides mappings', () => {
      const mappings = { xeraen: 'XERAEN (Official)' }
      const result = transformMarkdownLinks('See [[xeraen|the hackr]]', mappings)
      expect(result).toBe('See [the hackr](/codex/xeraen)')
    })

    it('handles multiline content with custom text', () => {
      const content = `Line 1 with [[XERAEN|custom name]]
Line 2 with [[The Fracture Network]]`
      const expected = `Line 1 with [custom name](/codex/xeraen)
Line 2 with [The Fracture Network](/codex/the-fracture-network)`
      expect(transformMarkdownLinks(content)).toBe(expected)
    })
  })

  describe('transformHtmlLinks', () => {
    it('converts [[Entry Name]] to HTML anchor', () => {
      const result = transformHtmlLinks('See [[XERAEN]] for details')
      expect(result).toBe('See <a href="/codex/xeraen">XERAEN</a> for details')
    })

    it('handles multiple links', () => {
      const result = transformHtmlLinks('[[XERAEN]] works with [[The Fracture Network]]')
      expect(result).toBe('<a href="/codex/xeraen">XERAEN</a> works with <a href="/codex/the-fracture-network">The Fracture Network</a>')
    })

    it('adds CSS class when provided', () => {
      const result = transformHtmlLinks('See [[XERAEN]]', undefined, 'codex-link')
      expect(result).toBe('See <a href="/codex/xeraen" class="codex-link">XERAEN</a>')
    })

    it('uses canonical names from mappings with CSS class', () => {
      const mappings = { xeraen: 'XERAEN', 'the-pulse-grid': 'The Pulse Grid' }
      const result = transformHtmlLinks('See [[xeraen]]', mappings, 'codex-link')
      expect(result).toBe('See <a href="/codex/xeraen" class="codex-link">XERAEN</a>')
    })

    it('preserves text without links', () => {
      const result = transformHtmlLinks('No links here')
      expect(result).toBe('No links here')
    })

    it('handles empty string', () => {
      expect(transformHtmlLinks('')).toBe('')
    })

    it('handles multiline content', () => {
      const content = `Line 1 with [[XERAEN]]
Line 2 with [[The Fracture Network]]`
      const expected = `Line 1 with <a href="/codex/xeraen">XERAEN</a>
Line 2 with <a href="/codex/the-fracture-network">The Fracture Network</a>`
      expect(transformHtmlLinks(content)).toBe(expected)
    })

    it('converts [[Entry|custom text]] to HTML anchor with custom display text', () => {
      const result = transformHtmlLinks('See [[XERAEN|the legendary hackr]] for details')
      expect(result).toBe('See <a href="/codex/xeraen">the legendary hackr</a> for details')
    })

    it('handles multiple links with custom text', () => {
      const result = transformHtmlLinks('[[XERAEN|the hackr]] works with [[The Fracture Network|the network]]')
      expect(result).toBe('<a href="/codex/xeraen">the hackr</a> works with <a href="/codex/the-fracture-network">the network</a>')
    })

    it('handles mix of standard and custom text links', () => {
      const result = transformHtmlLinks('[[XERAEN|custom text]] and [[The Fracture Network]]')
      expect(result).toBe('<a href="/codex/xeraen">custom text</a> and <a href="/codex/the-fracture-network">The Fracture Network</a>')
    })

    it('adds CSS class to links with custom text', () => {
      const result = transformHtmlLinks('See [[XERAEN|custom]]', undefined, 'codex-link')
      expect(result).toBe('See <a href="/codex/xeraen" class="codex-link">custom</a>')
    })

    it('custom text overrides mappings', () => {
      const mappings = { xeraen: 'XERAEN (Official)' }
      const result = transformHtmlLinks('See [[xeraen|the hackr]]', mappings)
      expect(result).toBe('See <a href="/codex/xeraen">the hackr</a>')
    })

    it('custom text with mappings and CSS class', () => {
      const mappings = { xeraen: 'XERAEN' }
      const result = transformHtmlLinks('See [[xeraen|custom]]', mappings, 'link')
      expect(result).toBe('See <a href="/codex/xeraen" class="link">custom</a>')
    })

    it('handles multiline content with custom text', () => {
      const content = `Line 1 with [[XERAEN|custom name]]
Line 2 with [[The Fracture Network]]`
      const expected = `Line 1 with <a href="/codex/xeraen">custom name</a>
Line 2 with <a href="/codex/the-fracture-network">The Fracture Network</a>`
      expect(transformHtmlLinks(content)).toBe(expected)
    })
  })

  describe('extractCodexReferences', () => {
    it('extracts single reference', () => {
      const result = extractCodexReferences('See [[XERAEN]]')
      expect(result).toEqual(['XERAEN'])
    })

    it('extracts multiple references', () => {
      const result = extractCodexReferences('[[XERAEN]] works with [[The Fracture Network]]')
      expect(result).toEqual(['XERAEN', 'The Fracture Network'])
    })

    it('deduplicates references', () => {
      const result = extractCodexReferences('[[XERAEN]] and [[XERAEN]] again')
      expect(result).toEqual(['XERAEN'])
    })

    it('returns empty array for text without references', () => {
      const result = extractCodexReferences('No references here')
      expect(result).toEqual([])
    })

    it('returns empty array for empty string', () => {
      expect(extractCodexReferences('')).toEqual([])
    })

    it('handles multiline content', () => {
      const content = `Line 1 with [[XERAEN]]
Line 2 with [[The Fracture Network]]
Line 3 with [[XERAEN]] again`
      const result = extractCodexReferences(content)
      expect(result).toEqual(['XERAEN', 'The Fracture Network'])
    })

    it('preserves order of first occurrence', () => {
      const result = extractCodexReferences('[[B]] [[A]] [[C]] [[A]]')
      expect(result).toEqual(['B', 'A', 'C'])
    })
  })

  describe('hasCodexLinks', () => {
    it('returns true when links present', () => {
      expect(hasCodexLinks('See [[XERAEN]]')).toBe(true)
    })

    it('returns false when no links', () => {
      expect(hasCodexLinks('No links here')).toBe(false)
    })

    it('returns false for empty string', () => {
      expect(hasCodexLinks('')).toBe(false)
    })

    it('returns true for multiple links', () => {
      expect(hasCodexLinks('[[XERAEN]] and [[The Fracture Network]]')).toBe(true)
    })

    it('returns true for multiline content with links', () => {
      const content = `Line 1 without links
Line 2 with [[XERAEN]]`
      expect(hasCodexLinks(content)).toBe(true)
    })
  })

  describe('fallback routes', () => {
    it('returns codex route for all entries (no fallbacks configured)', () => {
      expect(getRouteForSlug('xeraen')).toBe('/codex/xeraen')
      expect(getRouteForSlug('the-fracture-network')).toBe('/codex/the-fracture-network')
      expect(getRouteForSlug('apex-overdrive')).toBe('/codex/apex-overdrive')
      expect(getRouteForSlug('blitzbeam')).toBe('/codex/blitzbeam')
    })

    it('returns undefined for all slugs when no fallbacks configured', () => {
      expect(getFallbackDisplayName('xeraen')).toBeUndefined()
      expect(getFallbackDisplayName('the-fracture-network')).toBeUndefined()
      expect(getFallbackDisplayName('apex-overdrive')).toBeUndefined()
      expect(getFallbackDisplayName('blitzbeam')).toBeUndefined()
    })

    it('transformMarkdownLinks routes to codex', () => {
      const result = transformMarkdownLinks('See [[Apex Overdrive]] for details')
      expect(result).toBe('See [Apex Overdrive](/codex/apex-overdrive) for details')
    })

    it('transformHtmlLinks routes to codex', () => {
      const result = transformHtmlLinks('See [[Apex Overdrive]] for details')
      expect(result).toBe('See <a href="/codex/apex-overdrive">Apex Overdrive</a> for details')
    })

    it('custom text overrides display names', () => {
      const result = transformMarkdownLinks('See [[Apex Overdrive|the band]]')
      expect(result).toBe('See [the band](/codex/apex-overdrive)')
    })

    it('all entries route to codex', () => {
      const result = transformMarkdownLinks('[[XERAEN]] and [[Apex Overdrive]] work together')
      expect(result).toBe('[XERAEN](/codex/xeraen) and [Apex Overdrive](/codex/apex-overdrive) work together')
    })
  })

  describe('integration tests', () => {
    it('generates consistent slugs between generateSlug and transformMarkdownLinks', () => {
      const entryName = 'The Fracture Network'
      const manualSlug = generateSlug(entryName)
      const transformedContent = transformMarkdownLinks(`See [[${entryName}]]`)

      expect(transformedContent).toContain(`/codex/${manualSlug}`)
      expect(transformedContent).toBe(`See [${entryName}](/codex/${manualSlug})`)
    })

    it('extracts all references that transformMarkdownLinks would convert', () => {
      const content = 'Learn about [[XERAEN]] and [[The Fracture Network]] in [[The Pulse Grid]]'
      const references = extractCodexReferences(content)
      const transformed = transformMarkdownLinks(content)

      references.forEach(ref => {
        const slug = generateSlug(ref)
        expect(transformed).toContain(`[${ref}](/codex/${slug})`)
      })
    })

    it('handles complex real-world content', () => {
      const content = `# THE.CYBERPUL.SE Universe

The year is 2125. [[XERAEN]] operates within [[The Pulse Grid]],
a virtual network created after the [[Chronology Fracture]] event.

[[The Fracture Network]] fights against [[GovCorp]]'s surveillance.
They use [[PRISM]] technology to hide their activities.`

      const references = extractCodexReferences(content)
      expect(references).toHaveLength(6)
      expect(references).toContain('XERAEN')
      expect(references).toContain('The Pulse Grid')
      expect(references).toContain('Chronology Fracture')
      expect(references).toContain('The Fracture Network')
      expect(references).toContain('GovCorp')
      expect(references).toContain('PRISM')

      const transformed = transformMarkdownLinks(content)
      expect(transformed).toContain('[XERAEN](/codex/xeraen)')
      expect(transformed).toContain('[The Pulse Grid](/codex/the-pulse-grid)')
      expect(transformed).toContain('[GovCorp](/codex/govcorp)')
    })
  })
})
