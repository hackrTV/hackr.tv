import React from 'react'
import { Link } from 'react-router-dom'

/**
 * Renders a hackr bio with @mentions linked to internal profile pages
 * (keeping traffic on-platform); newlines preserved, everything else plain.
 *
 * A mention is matched only at the start of the string or right after
 * whitespace, so email local-parts (me@gmail.com) and other inline x@y
 * text are NOT turned into mentions. External URLs are left as plain text.
 */
export const BioText: React.FC<{ children: string }> = ({ children }) => {
  const nodes: React.ReactNode[] = []
  let lastIndex = 0
  let key = 0

  for (const match of children.matchAll(/(^|\s)(@[a-zA-Z0-9_]+)/g)) {
    const lead = match[1]
    const mention = match[2]
    const idx = match.index ?? 0
    const before = children.slice(lastIndex, idx) + lead
    if (before) nodes.push(<React.Fragment key={key++}>{before}</React.Fragment>)
    nodes.push(
      <Link key={key++} to={`/wire/${mention.slice(1)}`} style={{ color: '#22d3ee' }}>
        {mention}
      </Link>
    )
    lastIndex = idx + match[0].length
  }

  const rest = children.slice(lastIndex)
  if (rest) nodes.push(<React.Fragment key={key++}>{rest}</React.Fragment>)

  return <span style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>{nodes}</span>
}
