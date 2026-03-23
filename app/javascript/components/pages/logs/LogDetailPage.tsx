import React, { useState, useEffect } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeSanitize from 'rehype-sanitize'
import { useGridAuth } from '~/hooks/useGridAuth'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'
import { formatFutureDate } from '~/utils/dateUtils'
import { apiJson } from '~/utils/apiClient'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { TIMELINE_ORDER, TIMELINE_CONFIG, formatEra } from './timelineConfig'
import type { TimelineSummary } from './timelineConfig'
import { TimelineSideTabs } from './TimelineSideTabs'

interface HackrLog {
  id: number
  title: string
  slug: string
  body: string
  timeline: string
  published_at: string
  created_at: string
  author: {
    id: number
    hackr_alias: string
  }
}

export const LogDetailPage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>()
  const [searchParams] = useSearchParams()
  const { hackr } = useGridAuth()
  const { mappings } = useCodexMappings()
  const { isDesktop } = useMobileDetect()
  const currentSort = searchParams.get('sort') === 'asc' ? 'asc' : 'desc'
  const [log, setLog] = useState<HackrLog | null>(null)
  const [timelines, setTimelines] = useState<TimelineSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!slug) return

    apiJson<HackrLog>(`/api/logs/${slug}`)
      .then(data => {
        setLog(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load log:', err)
        setError('Log not found or not yet published.')
        setLoading(false)
      })

    // Fetch timeline summary for side tabs
    apiJson<{ meta: { timelines: TimelineSummary } }>('/api/logs?per_page=5')
      .then(data => setTimelines(data.meta.timelines))
      .catch(() => {}) // Non-critical — tabs just won't render
  }, [slug])

  if (loading) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading transmission..." color="purple-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !log) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto', textAlign: 'center', color: '#f87171' }}>
          {error || 'Log not found'}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto', position: 'relative' }}>
        {/* Timeline Tabs — desktop: side tabs outside left edge */}
        {isDesktop && timelines && (
          <TimelineSideTabs currentTimeline={log.timeline} currentSort={currentSort} timelines={timelines} />
        )}

        {/* Timeline Tabs — mobile/tablet: inline tabs above content */}
        {!isDesktop && timelines && (
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '10px' }}>
            {TIMELINE_ORDER.filter(tl => tl in timelines).map(tl => {
              const tlConfig = TIMELINE_CONFIG[tl]
              const info = timelines[tl]
              const count = info?.count ?? 0
              const era = info ? formatEra(info) : ''
              const isActive = tl === log.timeline
              return (
                <Link
                  key={tl}
                  to={`/logs?timeline=${tl}&page=1&sort=${currentSort}`}
                  className="tui-button"
                  style={isActive ? {
                    padding: '6px 14px',
                    backgroundColor: 'rgb(0, 168, 168)',
                    color: '#000',
                    fontWeight: 'bold',
                    boxShadow: 'none',
                    textDecoration: 'none'
                  } : {
                    padding: '6px 14px',
                    backgroundColor: '#252525',
                    color: '#666',
                    boxShadow: 'none',
                    textDecoration: 'none'
                  }}
                >
                  {tlConfig ? `${era} — ${tlConfig.name} (${count})` : `${tl} (${count})`}
                </Link>
              )
            })}
          </div>
        )}

        <div style={{ background: '#1a1a1a', color: '#d0d0d0', padding: '30px', border: '1px solid #333' }}>
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
            <div style={{ color: '#b4b4b4', lineHeight: '1.8', fontSize: '1.05em', textAlign: 'justify' }}>
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                rehypePlugins={[rehypeSanitize]}
                components={{
                  a: ({ href, children }) => (
                    <Link to={href || '#'} style={{ color: '#818cf8', textDecoration: 'none', display: 'inline' }}>
                      {children}
                    </Link>
                  )
                }}
              >
                {transformMarkdownLinks(log.body, mappings)}
              </ReactMarkdown>
            </div>
          </div>

          {/* Navigation */}
          <div style={{ paddingTop: '20px', borderTop: '1px solid #4b5563' }}>
            <Link to={`/logs?timeline=${log.timeline}&sort=${currentSort}`} style={{ color: '#818cf8', textDecoration: 'none', padding: '8px 16px', display: 'inline-block' }}>
              ← Back to All Logs
            </Link>
          </div>
        </div>
      </div>
    </DefaultLayout>
  )
}
