import React from 'react'
import { Link } from 'react-router-dom'
import type { TreeEntry } from '~/types/code'

interface CodeTreeViewProps {
  repoSlug: string
  entries: TreeEntry[]
}

export const CodeTreeView: React.FC<CodeTreeViewProps> = ({ repoSlug, entries }) => {
  if (entries.length === 0) {
    return (
      <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>
        Empty directory
      </div>
    )
  }

  return (
    <div style={{ border: '1px solid #333', background: '#0d0d0d' }}>
      {entries.map((entry, i) => {
        const linkTo = entry.type === 'tree'
          ? `/code/${repoSlug}/tree/${entry.path}`
          : `/code/${repoSlug}/blob/${entry.path}`

        return (
          <Link
            key={entry.path}
            to={linkTo}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '8px 14px',
              color: entry.type === 'tree' ? '#a78bfa' : '#d0d0d0',
              textDecoration: 'none',
              borderBottom: i < entries.length - 1 ? '1px solid #1a1a1a' : 'none',
              fontFamily: "'Courier New', Courier, monospace",
              fontSize: '0.9em'
            }}
          >
            <span style={{ color: entry.type === 'tree' ? '#a78bfa' : '#6b7280', width: '18px', textAlign: 'center' }}>
              {entry.type === 'tree' ? '▸' : ' '}
            </span>
            <span>{entry.name}</span>
          </Link>
        )
      })}
    </div>
  )
}
