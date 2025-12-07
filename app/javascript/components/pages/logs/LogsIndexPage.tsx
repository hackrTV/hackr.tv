import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { formatFutureDate } from '~/utils/dateUtils'

interface HackrLog {
  id: number
  title: string
  slug: string
  body: string
  published_at: string
  created_at: string
  author: {
    id: number
    hackr_alias: string
  }
}

const truncateMarkdown = (markdown: string, maxLength: number = 300): string => {
  // Remove markdown formatting and truncate
  const plainText = markdown
    .replace(/[#*_`]/g, '') // Remove markdown symbols
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Convert links to text
    .trim()

  if (plainText.length <= maxLength) {
    return plainText
  }

  return plainText.substring(0, maxLength).trim() + '...'
}

export const LogsIndexPage: React.FC = () => {
  const [logs, setLogs] = useState<HackrLog[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetch('/api/logs')
      .then(res => res.json())
      .then(data => {
        setLogs(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load logs:', err)
        setError('Failed to load logs')
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading Hackr Logs transmissions..." color="purple-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto', textAlign: 'center', color: '#f87171' }}>
          {error}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto', background: '#1a1a1a', color: '#d0d0d0', padding: '20px', border: '1px solid #333' }}>
        <div style={{ marginBottom: '30px', paddingBottom: '15px', borderBottom: '1px solid #4b5563' }}>
          <h1 style={{ margin: 0, fontSize: '1.4em', color: '#a78bfa' }}>HACKR LOGS</h1>
          <p style={{ margin: '5px 0 0 0', fontSize: '0.9em', color: '#888' }}>Transmissions from the Fracture Network</p>
        </div>

        {logs.length > 0 ? (
          logs.map(log => (
            <div key={log.id} style={{ background: '#0d0d0d', marginBottom: '25px', padding: '25px', borderLeft: '3px solid #6366f1' }}>
              {/* Title */}
              <h2 style={{ margin: '0 0 12px 0' }}>
                <Link to={`/logs/${log.slug}`} style={{ color: '#a78bfa', textDecoration: 'none', fontSize: '1.3em' }}>
                  {log.title}
                </Link>
              </h2>

              {/* Metadata */}
              <div style={{ marginBottom: '18px', fontSize: '0.85em' }}>
                <span style={{ color: '#6b7280' }}>Published:</span>{' '}
                <span style={{ color: '#9ca3af' }}>{formatFutureDate(log.published_at)}</span>
                <span style={{ color: '#4b5563', margin: '0 8px' }}>•</span>
                <span style={{ color: '#6b7280' }}>By:</span>{' '}
                <span style={{ color: '#9ca3af' }}>{log.author.hackr_alias}</span>
              </div>

              {/* Excerpt */}
              <div style={{ color: '#9ca3af', lineHeight: '1.7', marginBottom: '15px' }}>
                {truncateMarkdown(log.body || '', 300)}
              </div>

              {/* Read More Link */}
              <div>
                <Link to={`/logs/${log.slug}`} style={{ color: '#818cf8', textDecoration: 'none', fontSize: '0.9em' }}>
                  Read more →
                </Link>
              </div>
            </div>
          ))
        ) : (
          <div style={{ padding: '60px', textAlign: 'center', background: '#0d0d0d', border: '1px solid #333' }}>
            <p style={{ color: '#6b7280', fontSize: '1.1em', lineHeight: '1.8' }}>
              No transmissions available yet.
              <br />
              <span style={{ fontSize: '0.9em' }}>Check back soon for updates from the Fracture Network...</span>
            </p>
          </div>
        )}
      </div>
    </DefaultLayout>
  )
}
