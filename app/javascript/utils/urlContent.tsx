import React from 'react'

const linkStyle: React.CSSProperties = { color: '#60a5fa', textDecoration: 'underline' }
const censorStyle: React.CSSProperties = { color: '#f87171', fontStyle: 'italic' }

/**
 * processUrls - Replaces URLs in text with React elements.
 *
 * allowLinks: true  → clickable <a> tags
 * allowLinks: false → [LINK CENSORED BY GOVCORP] spans
 *
 * Handles markdown-style links [text](url) first, then plain URLs.
 */
export function processUrls (text: string, allowLinks: boolean): (string | React.ReactNode)[] {
  let keyIdx = 0

  // First pass: extract markdown links [text](url)
  const mdParts: (string | React.ReactNode)[] = []
  let lastIndex = 0
  let match: RegExpExecArray | null
  const markdownLinkRe = /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/gi

  while ((match = markdownLinkRe.exec(text)) !== null) {
    if (match.index > lastIndex) {
      mdParts.push(text.slice(lastIndex, match.index))
    }

    if (allowLinks) {
      mdParts.push(
        <a key={`md-${keyIdx++}`} href={match[2]} target="_blank" rel="noopener noreferrer" style={linkStyle}>
          {match[1]}
        </a>
      )
    } else {
      mdParts.push(
        <span key={`md-${keyIdx++}`} style={censorStyle}>[LINK CENSORED BY GOVCORP]</span>
      )
    }

    lastIndex = match.index + match[0].length
  }
  if (lastIndex < text.length) {
    mdParts.push(text.slice(lastIndex))
  }

  // Second pass: extract plain URLs from remaining string fragments
  const result: (string | React.ReactNode)[] = []

  for (const part of mdParts) {
    if (typeof part !== 'string') {
      result.push(part)
      continue
    }

    let urlLastIndex = 0
    const plainUrlRe = /\b(https?:\/\/[^\s<]+)/gi
    while ((match = plainUrlRe.exec(part)) !== null) {
      // Trim trailing punctuation that's likely sentence-level, not part of the URL
      let url = match[1]
      const trailingPunctRe = /[.,;:!?\])\u2019']+$/
      const punctMatch = url.match(trailingPunctRe)
      if (punctMatch) {
        url = url.slice(0, -punctMatch[0].length)
      }

      if (match.index > urlLastIndex) {
        result.push(part.slice(urlLastIndex, match.index))
      }

      if (allowLinks) {
        result.push(
          <a key={`url-${keyIdx++}`} href={url} target="_blank" rel="noopener noreferrer" style={linkStyle}>
            {url}
          </a>
        )
      } else {
        result.push(
          <span key={`url-${keyIdx++}`} style={censorStyle}>[LINK CENSORED BY GOVCORP]</span>
        )
      }

      // Emit trimmed punctuation back as plain text
      urlLastIndex = match.index + match[0].length - (punctMatch ? punctMatch[0].length : 0)
    }

    if (urlLastIndex === 0) {
      result.push(part)
    } else if (urlLastIndex < part.length) {
      result.push(part.slice(urlLastIndex))
    }
  }

  return result
}
