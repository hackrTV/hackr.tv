import React, { useState, useEffect } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { formatFutureDate } from '~/utils/dateUtils'
import { apiJson } from '~/utils/apiClient'

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

interface PaginationMeta {
  timelines: Record<string, number>
  timeline: string
  total: number
  page: number
  per_page: number
  total_pages: number
}

const TIMELINE_CONFIG: Record<string, { label: string; subtitle: string }> = {
  '2120s': {
    label: '2120s — THE FRACTURE NETWORK',
    subtitle: 'Transmissions from the Fracture Network',
  },
  '2020s': {
    label: '2020s — THE LISTENERS',
    subtitle: 'Signals received in the present day',
  },
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
  const [searchParams, setSearchParams] = useSearchParams()
  const [logs, setLogs] = useState<HackrLog[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [fetchedKey, setFetchedKey] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const { isDesktop } = useMobileDetect()
  const currentTimeline = searchParams.get('timeline') || '2120s'
  const currentPage = parseInt(searchParams.get('page') || '1', 10)
  const requestKey = `${currentTimeline}:${currentPage}`
  const loading = fetchedKey !== requestKey

  useEffect(() => {
    apiJson<{ logs: HackrLog[]; meta: PaginationMeta }>(`/api/logs?timeline=${currentTimeline}&page=${currentPage}`)
      .then(data => {
        setLogs(data.logs)
        setMeta(data.meta)
        setFetchedKey(requestKey)
      })
      .catch(err => {
        console.error('Failed to load logs:', err)
        setError('Failed to load logs')
        setFetchedKey(requestKey)
      })
  }, [currentTimeline, currentPage])

  const switchTimeline = (timeline: string) => {
    setSearchParams({ timeline, page: '1' })
    window.scrollTo(0, 0)
  }

  const goToPage = (page: number) => {
    setSearchParams({ timeline: currentTimeline, page: page.toString() })
    window.scrollTo(0, 0)
  }

  const config = TIMELINE_CONFIG[currentTimeline] || TIMELINE_CONFIG['2120s']

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

  // Build sorted timeline keys for tabs (ensure consistent order)
  const timelineKeys = meta?.timelines ? Object.keys(meta.timelines).sort().reverse() : [currentTimeline]

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto', position: 'relative' }}>
        {/* Timeline Tabs — desktop: side tabs outside left edge */}
        {isDesktop && (
          <div style={{
            position: 'absolute',
            right: '100%',
            top: '0',
            display: 'flex',
            flexDirection: 'column',
            gap: '4px',
            marginRight: '-1px',
          }}>
            {timelineKeys.map(tl => {
              const tlConfig = TIMELINE_CONFIG[tl]
              const count = meta?.timelines?.[tl] ?? 0
              const isActive = tl === currentTimeline
              return (
                <button
                  key={tl}
                  onClick={() => switchTimeline(tl)}
                  style={isActive ? {
                    padding: '10px 14px',
                    backgroundColor: '#1a1a1a',
                    color: '#22d3ee',
                    fontWeight: 'bold',
                    fontFamily: 'inherit',
                    fontSize: 'inherit',
                    border: '1px solid #333',
                    borderRight: '1px solid #1a1a1a',
                    cursor: 'pointer',
                    textAlign: 'right',
                    whiteSpace: 'nowrap',
                  } : {
                    padding: '10px 14px',
                    backgroundColor: '#111',
                    color: '#555',
                    fontFamily: 'inherit',
                    fontSize: 'inherit',
                    border: '1px solid #2a2a2a',
                    borderRight: '1px solid #333',
                    cursor: 'pointer',
                    textAlign: 'right',
                    whiteSpace: 'nowrap',
                  }}
                >
                  <span style={{ fontSize: '1em' }}>{tl}</span>
                  <br />
                  <span style={{ fontSize: '0.75em' }}>
                    {tlConfig ? `${tlConfig.label.split(' — ')[1]} (${count})` : `(${count})`}
                  </span>
                </button>
              )
            })}
          </div>
        )}

        {/* Main Content Container */}
        <div style={{ background: '#1a1a1a', color: '#d0d0d0', padding: '20px', border: '1px solid #333' }}>
        <div style={{ marginBottom: '15px' }}>
          <h1 style={{ margin: 0, fontSize: '1.4em', color: '#a78bfa' }}>HACKR LOGS</h1>
        </div>

        {/* Timeline Tabs — mobile/tablet: inline tabs below header */}
        {!isDesktop && (
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '15px' }}>
            {timelineKeys.map(tl => {
              const tlConfig = TIMELINE_CONFIG[tl]
              const count = meta?.timelines?.[tl] ?? 0
              const isActive = tl === currentTimeline
              return (
                <button
                  key={tl}
                  onClick={() => switchTimeline(tl)}
                  className="tui-button"
                  style={isActive ? {
                    padding: '6px 14px',
                    backgroundColor: 'rgb(0, 168, 168)',
                    color: '#000',
                    fontWeight: 'bold',
                    boxShadow: 'none',
                  } : {
                    padding: '6px 14px',
                    backgroundColor: '#252525',
                    color: '#666',
                    boxShadow: 'none',
                  }}
                >
                  {tl} — {tlConfig ? `${tlConfig.label.split(' — ')[1]} (${count})` : `(${count})`}
                </button>
              )
            })}
          </div>
        )}

        <div style={{ marginBottom: '30px', paddingBottom: '15px', borderBottom: '1px solid #4b5563' }}>
          <p style={{ margin: 0, fontSize: '0.9em', color: '#888' }}>{config.subtitle}</p>
        </div>

        {logs.length > 0 ? (
          <>
            {logs.map(log => (
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
                <div style={{ color: '#9ca3af', lineHeight: '1.7', marginBottom: '15px', textAlign: 'justify' }}>
                  {truncateMarkdown(log.body || '', 300)}
                </div>

                {/* Read More Link */}
                <div>
                  <Link to={`/logs/${log.slug}`} style={{ color: '#818cf8', textDecoration: 'none', fontSize: '0.9em' }}>
                    Read more →
                  </Link>
                </div>
              </div>
            ))}

            {/* Pagination */}
            {meta && meta.total_pages > 1 && (
              <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '10px', marginTop: '30px', paddingTop: '20px', borderTop: '1px solid #333' }}>
                <button
                  onClick={() => goToPage(currentPage - 1)}
                  disabled={currentPage <= 1}
                  style={{
                    background: currentPage <= 1 ? '#2a2a2a' : '#4b5563',
                    color: currentPage <= 1 ? '#555' : '#d0d0d0',
                    border: 'none',
                    padding: '8px 16px',
                    cursor: currentPage <= 1 ? 'not-allowed' : 'pointer',
                    fontFamily: 'inherit'
                  }}
                >
                  « Prev
                </button>

                <span style={{ color: '#9ca3af', fontSize: '0.9em' }}>
                  Page {meta.page} of {meta.total_pages}
                </span>

                <button
                  onClick={() => goToPage(currentPage + 1)}
                  disabled={currentPage >= meta.total_pages}
                  style={{
                    background: currentPage >= meta.total_pages ? '#2a2a2a' : '#4b5563',
                    color: currentPage >= meta.total_pages ? '#555' : '#d0d0d0',
                    border: 'none',
                    padding: '8px 16px',
                    cursor: currentPage >= meta.total_pages ? 'not-allowed' : 'pointer',
                    fontFamily: 'inherit'
                  }}
                >
                  Next »
                </button>
              </div>
            )}
          </>
        ) : (
          <div style={{ padding: '60px', textAlign: 'center', background: '#0d0d0d', border: '1px solid #333' }}>
            <p style={{ color: '#6b7280', fontSize: '1.1em', lineHeight: '1.8' }}>
              No transmissions available yet.
              <br />
              <span style={{ fontSize: '0.9em' }}>Check back soon for updates from the Fracture Network...</span>
            </p>
          </div>
        )}
        </div>{/* end Main Content Container */}
      </div>
    </DefaultLayout>
  )
}
