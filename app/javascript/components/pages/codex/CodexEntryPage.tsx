import React, { useState, useEffect } from 'react'
import { Link, useParams } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeRaw from 'rehype-raw'
import rehypeSanitize from 'rehype-sanitize'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import type { CodexEntry } from '~/types/codex'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'
import { formatFutureDate } from '~/utils/dateUtils'
import { apiFetch, apiJson } from '~/utils/apiClient'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useHackrScopedDedupSet } from '~/hooks/useHackrScopedDedup'

const ENTRY_TYPE_COLORS: Record<string, string> = {
  person: '#a78bfa',
  organization: '#60a5fa',
  event: '#f472b6',
  location: '#34d399',
  technology: '#fbbf24',
  faction: '#f87171',
  band: '#fb923c',
  item: '#a3e635',
  concept: '#22d3ee'
}

const ENTRY_TYPE_ICONS: Record<string, string> = {
  person: '👤',
  organization: '🏢',
  event: '📅',
  location: '📍',
  technology: '⚙️',
  faction: '⚔️',
  band: '🎸',
  item: '📦',
  concept: '💡'
}

export const CodexEntryPage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>()
  const [entry, setEntry] = useState<CodexEntry | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { mappings } = useCodexMappings()
  const { hackr } = useGridAuth()

  useEffect(() => {
    if (!slug) return

    let isMounted = true

    apiJson<CodexEntry>(`/api/codex/${slug}`)
      .then(data => {
        if (isMounted) {
          setEntry(data)
          setLoading(false)
        }
      })
      .catch(err => {
        if (isMounted) {
          console.error('Failed to load codex entry:', err)
          setError(err.message || 'Failed to load codex entry')
          setLoading(false)
        }
      })

    return () => {
      isMounted = false
    }
  }, [slug])

  // Credit the read once BOTH the entry and auth have resolved. Fires
  // even if auth resolves after the codex fetch. Dedup set is scoped
  // to hackr.id so a logout/login swap resets cleanly.
  const creditedSlugsRef = useHackrScopedDedupSet<string>(hackr?.id)
  useEffect(() => {
    if (!hackr || !entry?.slug) return
    if (creditedSlugsRef.current.has(entry.slug)) return
    creditedSlugsRef.current.add(entry.slug)
    apiFetch(`/api/codex/${encodeURIComponent(entry.slug)}/read`, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }, [hackr, entry?.slug, creditedSlugsRef])

  if (loading) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading entry..." color="cyan-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !entry) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <div className="tui-window red-168 white-text">
            <fieldset className="red-168-border">
              <legend className="center">ERROR</legend>
              <div style={{ padding: '40px', textAlign: 'center' }}>
                <p style={{ fontSize: '1.2em', marginBottom: '20px' }}>
                  {error || 'Entry not found'}
                </p>
                <Link to="/codex" className="tui-button cyan-168">
                  ← Back to Codex
                </Link>
              </div>
            </fieldset>
          </div>
        </div>
      </DefaultLayout>
    )
  }

  const typeColor = ENTRY_TYPE_COLORS[entry.entry_type] || '#888'
  const typeIcon = ENTRY_TYPE_ICONS[entry.entry_type] || '📄'

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto' }}>
        {/* Back Link */}
        <div style={{ marginBottom: '20px' }}>
          <Link to="/codex" className="tui-button cyan-168">
            ← Back to Codex
          </Link>
        </div>

        {/* Entry Content */}
        <div className="tui-window cyan-168 white-text">
          <fieldset className="cyan-168-border">
            <legend className="center">CODEX ENTRY</legend>
            <div style={{ padding: '30px', background: '#1a1a1a' }}>
              {/* Type Badge */}
              <div style={{ marginBottom: '15px' }}>
                <span style={{
                  display: 'inline-block',
                  padding: '5px 15px',
                  background: typeColor,
                  color: '#000',
                  fontSize: '0.85em',
                  fontWeight: 'bold',
                  textTransform: 'uppercase',
                  borderRadius: '3px'
                }}>
                  {typeIcon} {entry.entry_type}
                </span>
              </div>

              {/* Entry Name */}
              <h1 style={{
                margin: '0 0 20px 0',
                fontSize: '2.2em',
                color: typeColor,
                fontFamily: 'monospace'
              }}>
                {entry.name}
              </h1>

              {/* Summary */}
              {entry.summary && (
                <div style={{
                  padding: '15px',
                  background: '#0a0a0a',
                  border: `2px solid ${typeColor}`,
                  marginBottom: '30px',
                  borderRadius: '3px'
                }}>
                  <p style={{
                    margin: 0,
                    color: '#e5e5e5',
                    fontSize: '1.1em',
                    lineHeight: '1.6',
                    fontStyle: 'italic'
                  }}>
                    {entry.summary}
                  </p>
                </div>
              )}

              {/* Metadata */}
              {entry.metadata && Object.keys(entry.metadata).length > 0 && (
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                  gap: '15px',
                  marginBottom: '30px',
                  padding: '20px',
                  background: '#0a0a0a',
                  border: '1px solid #333',
                  borderRadius: '3px'
                }}>
                  {Object.entries(entry.metadata).filter(([key]) => key !== 'search_tags').map(([key, value]) => (
                    <div key={key}>
                      <div style={{ color: '#888', fontSize: '0.8em', textTransform: 'uppercase', marginBottom: '5px' }}>
                        {key.replace(/_/g, ' ')}
                      </div>
                      <div style={{ color: '#e5e5e5', fontSize: '0.95em' }}>
                        {value}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Main Content */}
              {entry.content && (
                <div
                  className="codex-content"
                  style={{
                    color: '#e5e5e5',
                    lineHeight: '1.8',
                    fontSize: '1.05em'
                  }}
                >
                  <ReactMarkdown
                    remarkPlugins={[remarkGfm]}
                    rehypePlugins={[rehypeRaw, rehypeSanitize]}
                    components={{
                      h1: ({ _node, ...props }) => <h1 style={{ color: typeColor, marginTop: '30px', marginBottom: '15px', fontSize: '1.8em' }} {...props} />,
                      h2: ({ _node, ...props }) => <h2 style={{ color: typeColor, marginTop: '25px', marginBottom: '12px', fontSize: '1.5em' }} {...props} />,
                      h3: ({ _node, ...props }) => <h3 style={{ color: typeColor, marginTop: '20px', marginBottom: '10px', fontSize: '1.3em' }} {...props} />,
                      p: ({ _node, ...props }) => <p style={{ marginBottom: '15px' }} {...props} />,
                      a: ({ _node, href, children, ...props }) => {
                        const linkStyle = {
                          display: 'inline' as const,
                          color: '#60a5fa',
                          textDecoration: 'none',
                          borderBottom: '1px solid #60a5fa',
                          transition: 'color 0.2s'
                        }
                        // Use React Router Link for internal links
                        if (href && href.startsWith('/')) {
                          return (
                            <Link
                              to={href}
                              style={linkStyle}
                              onMouseEnter={(e) => e.currentTarget.style.color = '#93c5fd'}
                              onMouseLeave={(e) => e.currentTarget.style.color = '#60a5fa'}
                            >
                              {children}
                            </Link>
                          )
                        }
                        // Use regular anchor for external links
                        return (
                          <a
                            href={href}
                            style={linkStyle}
                            onMouseEnter={(e) => e.currentTarget.style.color = '#93c5fd'}
                            onMouseLeave={(e) => e.currentTarget.style.color = '#60a5fa'}
                            {...props}
                          >
                            {children}
                          </a>
                        )
                      },
                      ul: ({ _node, ...props }) => <ul style={{ marginLeft: '20px', marginBottom: '15px' }} {...props} />,
                      ol: ({ _node, ...props }) => <ol style={{ marginLeft: '20px', marginBottom: '15px' }} {...props} />,
                      li: ({ _node, ...props }) => <li style={{ marginBottom: '8px' }} {...props} />,
                      strong: ({ _node, ...props }) => <strong style={{ color: '#fff' }} {...props} />,
                      code: ({ _node, ...props }) => (
                        <code
                          style={{
                            background: '#0a0a0a',
                            padding: '2px 6px',
                            borderRadius: '3px',
                            fontFamily: 'monospace',
                            fontSize: '0.9em',
                            color: '#fbbf24'
                          }}
                          {...props}
                        />
                      ),
                      pre: ({ _node, ...props }) => (
                        <pre
                          style={{
                            background: '#0a0a0a',
                            padding: '15px',
                            borderRadius: '3px',
                            overflow: 'auto',
                            marginBottom: '15px',
                            border: '1px solid #333'
                          }}
                          {...props}
                        />
                      ),
                      table: ({ _node, ...props }) => (
                        <table
                          style={{
                            width: '100%',
                            borderCollapse: 'collapse',
                            marginBottom: '20px',
                            background: '#0a0a0a',
                            border: `1px solid ${typeColor}`
                          }}
                          {...props}
                        />
                      ),
                      thead: ({ _node, ...props }) => (
                        <thead
                          style={{
                            background: typeColor,
                            color: '#000'
                          }}
                          {...props}
                        />
                      ),
                      th: ({ _node, ...props }) => (
                        <th
                          style={{
                            padding: '12px 15px',
                            textAlign: 'left',
                            fontWeight: 'bold',
                            borderBottom: `2px solid ${typeColor}`
                          }}
                          {...props}
                        />
                      ),
                      td: ({ _node, ...props }) => (
                        <td
                          style={{
                            padding: '10px 15px',
                            borderBottom: '1px solid #333'
                          }}
                          {...props}
                        />
                      ),
                      tr: ({ _node, ...props }) => (
                        <tr
                          style={{
                            transition: 'background 0.2s'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.background = '#1a1a1a'}
                          onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                          {...props}
                        />
                      )
                    }}
                  >
                    {transformMarkdownLinks(entry.content, mappings)}
                  </ReactMarkdown>
                </div>
              )}

              {/* Updated At */}
              {entry.updated_at && (
                <div style={{
                  marginTop: '40px',
                  paddingTop: '20px',
                  borderTop: '1px solid #333',
                  color: '#666',
                  fontSize: '0.85em'
                }}>
                  Last updated: {formatFutureDate(entry.updated_at)}
                </div>
              )}
            </div>
          </fieldset>
        </div>

        {/* Back Link (bottom) */}
        <div style={{ marginTop: '20px' }}>
          <Link to="/codex" className="tui-button cyan-168">
            ← Back to Codex
          </Link>
        </div>
      </div>
    </DefaultLayout>
  )
}
