import React from 'react'
import { CodexText } from './CodexText'
import { processUrls } from '../../utils/urlContent'

interface WireTextProps {
  children: string
  posterIsAdmin: boolean
}

/**
 * WireText - Processes URLs in pulse content, then delegates to CodexText for [[Codex]] links.
 *
 * Admin posters: URLs become clickable links.
 * Non-admin posters: URLs are redacted with a GovCorp censorship notice.
 */
export const WireText: React.FC<WireTextProps> = ({ children, posterIsAdmin }) => {
  const urlProcessed = processUrls(children, posterIsAdmin)
  let keyIdx = 0

  // Wrap string fragments in CodexText for [[Codex]] link processing
  const segments: React.ReactNode[] = urlProcessed.map((part) => {
    if (typeof part === 'string') {
      return <CodexText key={`ct-${keyIdx++}`}>{part}</CodexText>
    }
    return part
  })

  return <>{segments}</>
}
