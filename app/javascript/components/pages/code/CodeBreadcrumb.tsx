import React from 'react'
import { Link } from 'react-router-dom'

interface CodeBreadcrumbProps {
  repoSlug: string
  path?: string
  isBlob?: boolean
}

export const CodeBreadcrumb: React.FC<CodeBreadcrumbProps> = ({ repoSlug, path, isBlob }) => {
  const segments = path ? path.split('/').filter(Boolean) : []

  return (
    <div style={{ marginBottom: '15px', fontSize: '0.95em' }}>
      <Link to="/code" style={{ color: '#a78bfa', textDecoration: 'none' }}>code</Link>
      <span style={{ color: '#6b7280', margin: '0 6px' }}>/</span>
      {segments.length === 0 && !isBlob ? (
        <span style={{ color: '#d0d0d0' }}>{repoSlug}</span>
      ) : (
        <Link to={`/code/${repoSlug}`} style={{ color: '#a78bfa', textDecoration: 'none' }}>{repoSlug}</Link>
      )}
      {segments.map((segment, i) => {
        const isLast = i === segments.length - 1
        const segmentPath = segments.slice(0, i + 1).join('/')
        const linkType = isLast && isBlob ? 'blob' : 'tree'

        return (
          <React.Fragment key={i}>
            <span style={{ color: '#6b7280', margin: '0 6px' }}>/</span>
            {isLast ? (
              <span style={{ color: '#d0d0d0' }}>{segment}</span>
            ) : (
              <Link
                to={`/code/${repoSlug}/${linkType}/${segmentPath}`}
                style={{ color: '#a78bfa', textDecoration: 'none' }}
              >
                {segment}
              </Link>
            )}
          </React.Fragment>
        )
      })}
    </div>
  )
}
