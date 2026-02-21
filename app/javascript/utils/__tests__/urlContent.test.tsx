import React from 'react'
import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { processUrls } from '../urlContent'

describe('processUrls', () => {
  describe('plain text (no URLs)', () => {
    it('returns single string element for text without URLs', () => {
      const result = processUrls('Hello world', true)
      expect(result).toEqual(['Hello world'])
    })

    it('returns empty array for empty string', () => {
      const result = processUrls('', true)
      expect(result).toEqual([])
    })
  })

  describe('plain URLs with allowLinks: true', () => {
    it('converts a plain URL to a clickable link', () => {
      const result = processUrls('Visit https://example.com today', true)
      expect(result).toHaveLength(3)
      expect(result[0]).toBe('Visit ')
      expect(result[2]).toBe(' today')

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(link).toHaveAttribute('target', '_blank')
      expect(link).toHaveAttribute('rel', 'noopener noreferrer')
      expect(link).toHaveTextContent('https://example.com')
    })

    it('handles multiple plain URLs', () => {
      const result = processUrls('See https://a.com and https://b.com here', true)

      const { container } = render(<>{result}</>)
      const links = container.querySelectorAll('a')
      expect(links).toHaveLength(2)
      expect(links[0]).toHaveAttribute('href', 'https://a.com')
      expect(links[1]).toHaveAttribute('href', 'https://b.com')
    })

    it('handles URL at start of text', () => {
      const result = processUrls('https://example.com is cool', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
    })

    it('handles URL at end of text', () => {
      const result = processUrls('Go to https://example.com', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
    })

    it('handles URL as only content', () => {
      const result = processUrls('https://example.com', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(container.textContent).toBe('https://example.com')
    })

    it('handles http URLs', () => {
      const result = processUrls('Visit http://example.com today', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'http://example.com')
    })
  })

  describe('plain URLs with allowLinks: false', () => {
    it('replaces URL with censorship notice', () => {
      const result = processUrls('Visit https://example.com today', false)
      expect(result).toHaveLength(3)
      expect(result[0]).toBe('Visit ')
      expect(result[2]).toBe(' today')

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
    })

    it('replaces multiple URLs with censorship notices', () => {
      const result = processUrls('See https://a.com and https://b.com here', false)

      const { container } = render(<>{result}</>)
      const spans = container.querySelectorAll('span')
      expect(spans).toHaveLength(2)
      spans.forEach(span => {
        expect(span.textContent).toBe('[LINK CENSORED BY GOVCORP]')
      })
    })

    it('applies italic red styling to censored links', () => {
      const result = processUrls('See https://evil.com', false)

      const { container } = render(<>{result}</>)
      const span = container.querySelector('span')
      expect(span).toHaveStyle({ color: '#f87171', fontStyle: 'italic' })
    })
  })

  describe('markdown links with allowLinks: true', () => {
    it('converts markdown link to clickable link with display text', () => {
      const result = processUrls('Check [my site](https://example.com) out', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(link).toHaveTextContent('my site')
    })

    it('handles multiple markdown links', () => {
      const result = processUrls('[A](https://a.com) and [B](https://b.com)', true)

      const { container } = render(<>{result}</>)
      const links = container.querySelectorAll('a')
      expect(links).toHaveLength(2)
      expect(links[0]).toHaveTextContent('A')
      expect(links[1]).toHaveTextContent('B')
    })
  })

  describe('markdown links with allowLinks: false', () => {
    it('replaces markdown link with censorship notice', () => {
      const result = processUrls('Check [my site](https://example.com) out', false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
      expect(container.textContent).not.toContain('my site')
    })
  })

  describe('mixed content', () => {
    it('handles markdown links and plain URLs together', () => {
      const text = 'See [docs](https://docs.com) or visit https://example.com'
      const result = processUrls(text, true)

      const { container } = render(<>{result}</>)
      const links = container.querySelectorAll('a')
      expect(links).toHaveLength(2)
      expect(links[0]).toHaveTextContent('docs')
      expect(links[0]).toHaveAttribute('href', 'https://docs.com')
      expect(links[1]).toHaveTextContent('https://example.com')
      expect(links[1]).toHaveAttribute('href', 'https://example.com')
    })

    it('censors both markdown and plain URLs when not allowed', () => {
      const text = 'See [docs](https://docs.com) or visit https://example.com'
      const result = processUrls(text, false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      const spans = container.querySelectorAll('span')
      expect(spans).toHaveLength(2)
      spans.forEach(span => {
        expect(span.textContent).toBe('[LINK CENSORED BY GOVCORP]')
      })
    })

    it('preserves non-URL text around links', () => {
      const result = processUrls('before https://example.com after', true)
      expect(result[0]).toBe('before ')
      expect(result[2]).toBe(' after')
    })

    it('handles text with no URLs alongside URL text', () => {
      const result = processUrls('just plain text here', false)
      expect(result).toEqual(['just plain text here'])
    })
  })

  describe('case-insensitive URL schemes', () => {
    it('censors uppercase HTTPS plain URL', () => {
      const result = processUrls('Visit HTTPS://example.com today', false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
    })

    it('censors mixed-case Https plain URL', () => {
      const result = processUrls('Visit Https://example.com today', false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
    })

    it('censors uppercase scheme in markdown link', () => {
      const result = processUrls('See [click me](HTTPS://evil.com) now', false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
    })

    it('makes uppercase scheme URL clickable for admin', () => {
      const result = processUrls('Visit HTTPS://example.com today', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'HTTPS://example.com')
    })

    it('censors HTTP with uppercase scheme', () => {
      const result = processUrls('Visit HTTP://example.com today', false)

      const { container } = render(<>{result}</>)
      expect(container.querySelectorAll('a')).toHaveLength(0)
      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
    })
  })

  describe('trailing punctuation trimming', () => {
    it('excludes trailing period from URL href', () => {
      const result = processUrls('See https://example.com.', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(container.textContent).toBe('See https://example.com.')
    })

    it('excludes trailing comma from URL href', () => {
      const result = processUrls('Visit https://example.com, then leave', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(container.textContent).toContain(', then leave')
    })

    it('excludes trailing closing paren from URL href', () => {
      const result = processUrls('(see https://example.com)', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(container.textContent).toBe('(see https://example.com)')
    })

    it('excludes trailing closing bracket from URL href', () => {
      const result = processUrls('check https://example.com]', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
    })

    it('preserves trailing punctuation as visible text when censored', () => {
      const result = processUrls('See https://example.com.', false)

      const { container } = render(<>{result}</>)
      expect(container.textContent).toBe('See [LINK CENSORED BY GOVCORP].')
    })

    it('preserves mid-URL periods (e.g. subdomains)', () => {
      const result = processUrls('Visit https://sub.example.com/path today', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://sub.example.com/path')
    })

    it('handles multiple trailing punctuation characters', () => {
      const result = processUrls('Really?! https://example.com!!', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
    })

    it('excludes trailing semicolon', () => {
      const result = processUrls('url: https://example.com; done', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(container.textContent).toContain('; done')
    })
  })

  describe('link styling', () => {
    it('applies blue underline styling to allowed links', () => {
      const result = processUrls('https://example.com', true)

      const { container } = render(<>{result}</>)
      const link = container.querySelector('a')
      expect(link).toHaveStyle({ color: '#60a5fa', textDecoration: 'underline' })
    })
  })
})
