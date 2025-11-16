import React, { useState, useEffect } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeSanitize from 'rehype-sanitize'
import { useGridAuth } from '~/hooks/useGridAuth'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

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

const formatFutureDate = (dateStr: string, includeTime: boolean = false): string => {
  const date = new Date(dateStr)
  // Add 100 years to match the future date helper
  date.setFullYear(date.getFullYear() + 100)

  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }

  if (includeTime) {
    options.hour = '2-digit'
    options.minute = '2-digit'
    options.hour12 = false
  }

  return date.toLocaleDateString('en-US', options) + (includeTime ? ` at ${date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })}` : '')
}

export const LogDetailPage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>()
  const navigate = useNavigate()
  const { hackr } = useGridAuth()
  const [log, setLog] = useState<HackrLog | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!slug) return

    fetch(`/api/logs/${slug}`)
      .then(res => {
        if (!res.ok) {
          throw new Error('Log not found')
        }
        return res.json()
      })
      .then(data => {
        setLog(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load log:', err)
        setError('Log not found or not yet published.')
        setLoading(false)
      })
  }, [slug])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: '800px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading transmission..." color="purple-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !log) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: '800px', margin: '30px auto', textAlign: 'center', color: '#f87171' }}>
          {error || 'Log not found'}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      <div style={{ maxWidth: '800px', margin: '30px auto', background: '#1a1a1a', color: '#d0d0d0', padding: '30px', border: '1px solid #333' }}>
        {/* Title */}
        <h1 style={{ margin: '0 0 20px 0', fontSize: '1.8em', color: '#a78bfa', lineHeight: '1.3' }}>
          {log.title}
        </h1>

        {/* Metadata Header */}
        <div style={{ marginBottom: '30px', paddingBottom: '20px', borderBottom: '1px solid #4b5563' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '15px', fontSize: '0.9em' }}>
            <div>
              <span style={{ color: '#6b7280' }}>Published:</span>{' '}
              <span style={{ color: '#9ca3af' }}>{formatFutureDate(log.published_at, true)}</span>
            </div>
            <div>
              <span style={{ color: '#6b7280' }}>Author:</span>{' '}
              <span style={{ color: '#9ca3af' }}>{log.author.hackr_alias}</span>
              {hackr?.role === 'admin' && log.author.id === hackr.id && (
                <span style={{ color: '#f87171', fontSize: '0.85em', marginLeft: '5px' }}>[ADMIN]</span>
              )}
            </div>
          </div>
        </div>

        {/* Log Content */}
        <div style={{ background: '#0d0d0d', padding: '30px', marginBottom: '30px', borderLeft: '3px solid #6366f1' }}>
          <div style={{ color: '#b4b4b4', lineHeight: '1.8', fontSize: '1.05em' }}>
            <ReactMarkdown
              remarkPlugins={[remarkGfm]}
              rehypePlugins={[rehypeSanitize]}
            >
              {log.body}
            </ReactMarkdown>
          </div>
        </div>

        {/* Navigation */}
        <div style={{ paddingTop: '20px', borderTop: '1px solid #4b5563' }}>
          <Link to="/logs" style={{ color: '#818cf8', textDecoration: 'none', padding: '8px 16px', display: 'inline-block' }}>
            ← Back to All Logs
          </Link>
          {hackr?.role === 'admin' && (
            <a href={`/root/hackr_logs/${log.slug}/edit`} style={{ color: '#a78bfa', textDecoration: 'none', padding: '8px 16px', marginLeft: '10px', display: 'inline-block' }}>
              ✎ Edit This Log
            </a>
          )}
        </div>
      </div>
    </DefaultLayout>
  )
}
