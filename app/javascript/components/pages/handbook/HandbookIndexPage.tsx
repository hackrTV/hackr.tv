import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import { formatFutureDate } from '~/utils/dateUtils'
import { useHandbookTree } from '~/hooks/useHandbookTree'
import { HandbookLayout } from './HandbookLayout'
import type { HandbookArticleSummary } from '~/types/handbook'

const ACCENT = '#22d3ee'

export const HandbookIndexPage: React.FC = () => {
  const { tree, loading, error } = useHandbookTree()
  const [searchQuery, setSearchQuery] = useState('')
  const [recent, setRecent] = useState<HandbookArticleSummary[]>([])

  useEffect(() => {
    apiJson<HandbookArticleSummary[]>('/api/handbook/recent?limit=5')
      .then(setRecent)
      .catch(err => console.error('Failed to load recent handbook articles:', err))
  }, [])

  if (loading) {
    return (
      <HandbookLayout
        sections={[]}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      >
        <LoadingSpinner message="Loading handbook..." color="cyan-168-text" size="large" />
      </HandbookLayout>
    )
  }

  if (error || !tree) {
    return (
      <HandbookLayout
        sections={[]}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      >
        <div className="tui-window red-168 white-text">
          <fieldset className="red-168-border">
            <legend className="center">ERROR</legend>
            <div style={{ padding: '30px', textAlign: 'center' }}>
              <p>{error || 'Failed to load handbook.'}</p>
            </div>
          </fieldset>
        </div>
      </HandbookLayout>
    )
  }

  const totalArticles = tree.sections.reduce((sum, s) => sum + s.articles.length, 0)

  return (
    <HandbookLayout
      sections={tree.sections}
      searchQuery={searchQuery}
      onSearchChange={setSearchQuery}
    >
      <div className="tui-window cyan-168 white-text">
        <fieldset className="cyan-168-border">
          <legend className="center">HACKR HANDBOOK</legend>
          <div style={{ padding: '30px', background: '#1a1a1a' }}>
            <h1 style={{ margin: '0 0 12px 0', color: ACCENT, fontSize: '2em', fontFamily: 'monospace' }}>
              Operator's Field Manual
            </h1>
            <p style={{ color: '#d0d0d0', marginBottom: '24px', lineHeight: 1.6 }}>
              Practical documentation for using hackr.tv — THE PULSE GRID, WIRE, Uplink, Vault,
              the terminal interface, and everything in between.{' '}
              {totalArticles > 0 && (
                <span style={{ color: '#888' }}>
                  {tree.sections.length} sections · {totalArticles} articles
                </span>
              )}
            </p>

            {recent.length > 0 && (
              <div
                style={{
                  background: '#0a0a0a',
                  border: '1px solid #333',
                  padding: '18px 20px',
                  marginBottom: '32px'
                }}
              >
                <h2 style={{ color: ACCENT, margin: '0 0 12px 0', fontSize: '0.95em', letterSpacing: '1px' }}>
                  :: RECENTLY UPDATED ::
                </h2>
                <ul style={{ listStyle: 'none', margin: 0, padding: 0 }}>
                  {recent.map(article => (
                    <li key={article.slug} style={{ marginBottom: '6px' }}>
                      <Link
                        to={`/handbook/${article.slug}`}
                        style={{ color: '#d0d0d0', textDecoration: 'none' }}
                      >
                        <span style={{ color: '#60a5fa' }}>{article.title}</span>
                        {article.section && (
                          <span style={{ color: '#666', fontSize: '0.85em' }}>
                            {' '}— {article.section.name}
                          </span>
                        )}
                        <span style={{ color: '#555', fontSize: '0.8em', marginLeft: '8px' }}>
                          {formatFutureDate(article.updated_at)}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <h2 style={{ color: ACCENT, margin: '0 0 16px 0', fontSize: '1em', letterSpacing: '1px' }}>
              :: TABLE OF CONTENTS ::
            </h2>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '18px' }}>
              {tree.sections.map(section => (
                <div
                  key={section.slug}
                  style={{ background: '#0a0a0a', border: '1px solid #333', padding: '16px 18px' }}
                >
                  <h3 style={{ margin: '0 0 6px 0', color: '#fff', fontSize: '1.1em' }}>
                    {section.icon && (
                      <span style={{ color: '#fbbf24', marginRight: '8px', fontFamily: 'monospace' }}>
                        {section.icon}
                      </span>
                    )}
                    {section.name}
                  </h3>
                  {section.summary && (
                    <p style={{ color: '#888', fontSize: '0.88em', margin: '0 0 10px 0', lineHeight: 1.5 }}>
                      {section.summary}
                    </p>
                  )}
                  <ul style={{ listStyle: 'none', margin: 0, padding: 0 }}>
                    {section.articles.map(article => (
                      <li key={article.slug} style={{ margin: '4px 0' }}>
                        <Link
                          to={`/handbook/${article.slug}`}
                          style={{
                            color: '#a0a0a0',
                            textDecoration: 'none',
                            fontSize: '0.9em',
                            display: 'inline-block',
                            padding: '2px 0'
                          }}
                        >
                          {article.kind === 'tutorial' && (
                            <span style={{ color: '#fbbf24', marginRight: '6px' }}>▶</span>
                          )}
                          <span style={{ color: '#60a5fa' }}>{article.title}</span>
                          {article.difficulty && (
                            <span
                              style={{
                                color: '#666',
                                fontSize: '0.82em',
                                marginLeft: '6px',
                                textTransform: 'uppercase'
                              }}
                            >
                              [{article.difficulty}]
                            </span>
                          )}
                        </Link>
                      </li>
                    ))}
                    {section.articles.length === 0 && (
                      <li style={{ color: '#555', fontSize: '0.85em', fontStyle: 'italic' }}>
                        No articles yet.
                      </li>
                    )}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        </fieldset>
      </div>
    </HandbookLayout>
  )
}
