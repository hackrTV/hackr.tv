import React, { useState, useEffect } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { formatFutureDate } from '~/utils/dateUtils'
import { apiJson } from '~/utils/apiClient'
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

interface PaginationMeta {
  timelines: TimelineSummary
  timeline: string
  total: number
  page: number
  per_page: number
  total_pages: number
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
  const currentSort = searchParams.get('sort') === 'asc' ? 'asc' : 'desc'
  const requestKey = `${currentTimeline}:${currentPage}:${currentSort}`
  const loading = fetchedKey !== requestKey

  useEffect(() => {
    apiJson<{ logs: HackrLog[]; meta: PaginationMeta }>(`/api/logs?timeline=${currentTimeline}&page=${currentPage}&sort=${currentSort}`)
      .then(data => {
        setLogs(data?.logs || [])
        setMeta(data?.meta || null)
        setFetchedKey(requestKey)
      })
      .catch(err => {
        console.error('Failed to load logs:', err)
        setError('Failed to load logs')
        setFetchedKey(requestKey)
      })
  // eslint-disable-next-line react-hooks/exhaustive-deps -- requestKey is derived from the deps already listed
  }, [currentTimeline, currentPage, currentSort])

  const switchTimeline = (timeline: string) => {
    setSearchParams({ timeline, page: '1', sort: currentSort })
    window.scrollTo(0, 0)
  }

  const toggleSort = () => {
    const newSort = currentSort === 'desc' ? 'asc' : 'desc'
    setSearchParams({ timeline: currentTimeline, page: '1', sort: newSort })
    window.scrollTo(0, 0)
  }

  const goToPage = (page: number) => {
    setSearchParams({ timeline: currentTimeline, page: page.toString(), sort: currentSort })
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

  // Build timeline keys for tabs in defined display order
  const timelineKeys = meta?.timelines
    ? TIMELINE_ORDER.filter(tl => tl in meta.timelines)
    : [currentTimeline]

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto', position: 'relative' }}>
        {/* Timeline Tabs — desktop: side tabs outside left edge */}
        {isDesktop && meta?.timelines && (
          <TimelineSideTabs currentTimeline={currentTimeline} currentSort={currentSort} timelines={meta.timelines} />
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
                const info = meta?.timelines?.[tl]
                const count = info?.count ?? 0
                const era = info ? formatEra(info) : ''
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
                      boxShadow: 'none'
                    } : {
                      padding: '6px 14px',
                      backgroundColor: '#252525',
                      color: '#666',
                      boxShadow: 'none'
                    }}
                  >
                    {tlConfig ? `${era} — ${tlConfig.name} (${count})` : `${tl} (${count})`}
                  </button>
                )
              })}
            </div>
          )}

          <div style={{ marginBottom: '30px', paddingBottom: '15px', borderBottom: '1px solid #4b5563', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <p style={{ margin: 0, fontSize: '0.9em', color: '#888' }}>{config.subtitle}</p>
            <button
              onClick={toggleSort}
              style={{
                background: 'none',
                border: '1px solid #333',
                color: '#666',
                padding: '4px 10px',
                cursor: 'pointer',
                fontFamily: 'inherit',
                fontSize: '0.8em',
                whiteSpace: 'nowrap'
              }}
            >
              {currentSort === 'desc' ? 'Newest first ↓' : 'Oldest first ↑'}
            </button>
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
