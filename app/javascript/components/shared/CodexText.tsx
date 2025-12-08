import React from 'react'
import { Link } from 'react-router-dom'
import { generateSlug } from '../../utils/codexLinks'

interface CodexTextProps {
  children: React.ReactNode
  className?: string
  style?: React.CSSProperties
}

/**
 * CodexText - Renders text with [[Entry Name]] syntax converted to Codex links
 *
 * Use this component to wrap any text content that may contain Codex references.
 * The [[Entry Name]] syntax will be converted to clickable <Link> components.
 *
 * Supports custom display text: [[Entry Name|custom text]]
 * Supports mixed content with JSX expressions like {futureYear}
 *
 * @example
 * <CodexText>
 *   The [[Fracture Network]] fights against [[GovCorp]] tyranny.
 * </CodexText>
 *
 * @example
 * <CodexText>
 *   In {futureYear}, [[XERAEN]] broadcasts from the future.
 * </CodexText>
 */
export const CodexText: React.FC<CodexTextProps> = ({ children, className, style }) => {
  // Parse a string and split into segments (text and links)
  const parseString = (text: string, keyPrefix: string): React.ReactNode[] => {
    const parts: React.ReactNode[] = []
    const regex = /\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g
    let lastIndex = 0
    let match

    while ((match = regex.exec(text)) !== null) {
      // Add text before the match
      if (match.index > lastIndex) {
        parts.push(text.slice(lastIndex, match.index))
      }

      // Add the link
      const entryName = match[1]
      const customText = match[2]
      const slug = generateSlug(entryName)
      const displayText = customText || entryName

      parts.push(
        <Link
          key={`${keyPrefix}-${slug}-${match.index}`}
          to={`/codex/${slug}`}
          className="codex-link"
          style={{ color: 'inherit', textDecoration: 'underline' }}
        >
          {displayText}
        </Link>
      )

      lastIndex = match.index + match[0].length
    }

    // Add remaining text after last match
    if (lastIndex < text.length) {
      parts.push(text.slice(lastIndex))
    }

    return parts
  }

  // Process children which may be a string, number, array, or other ReactNode
  const processChildren = (node: React.ReactNode, keyPrefix = 'codex'): React.ReactNode => {
    if (typeof node === 'string') {
      const parsed = parseString(node, keyPrefix)
      return parsed.length === 1 ? parsed[0] : parsed
    }

    if (typeof node === 'number') {
      return node
    }

    if (Array.isArray(node)) {
      return node.map((child, index) => {
        const result = processChildren(child, `${keyPrefix}-${index}`)
        // If result is an array, wrap in fragment with key
        if (Array.isArray(result)) {
          return <React.Fragment key={`${keyPrefix}-${index}`}>{result}</React.Fragment>
        }
        return result
      })
    }

    // For other ReactNodes (elements, null, undefined, etc.), return as-is
    return node
  }

  const content = processChildren(children)

  // If className or style provided, wrap in span
  if (className || style) {
    return <span className={className} style={style}>{content}</span>
  }

  // Otherwise return fragment
  return <>{content}</>
}
