import React, { useState, useEffect } from 'react'
import { Link, useParams } from 'react-router-dom'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { MarkdownContent } from '~/components/shared/MarkdownContent'
import { apiJson } from '~/utils/apiClient'
import { formatFutureDate } from '~/utils/dateUtils'
import { useHandbookTree } from '~/hooks/useHandbookTree'
import { HandbookLayout } from './HandbookLayout'
import type { HandbookArticle } from '~/types/handbook'

const ACCENT = '#22d3ee'

const KIND_COLORS: Record<string, string> = {
  tutorial: '#fbbf24',
  reference: ACCENT
}

export const HandbookArticlePage: React.FC = () => {
  const { slug } = useParams<{ slug: string }>()
  const { tree, loading: treeLoading } = useHandbookTree()
  const [article, setArticle] = useState<HandbookArticle | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    if (!slug) return
    setLoading(true)
    setError(null)

    let mounted = true
    apiJson<HandbookArticle>(`/api/handbook/${slug}`)
      .then(data => {
        if (mounted) {
          setArticle(data)
          setLoading(false)
        }
      })
      .catch(err => {
        if (mounted) {
          console.error('Failed to load handbook article:', err)
          setError(err?.message || 'Failed to load article')
          setLoading(false)
        }
      })
    return () => { mounted = false }
  }, [slug])

  const sections = tree?.sections || []

  if (loading || treeLoading) {
    return (
      <HandbookLayout
        sections={sections}
        currentArticleSlug={slug}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      >
        <LoadingSpinner message="Loading article..." color="cyan-168-text" size="large" />
      </HandbookLayout>
    )
  }

  if (error || !article) {
    return (
      <HandbookLayout
        sections={sections}
        currentArticleSlug={slug}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      >
        <div className="tui-window red-168 white-text">
          <fieldset className="red-168-border">
            <legend className="center">ERROR</legend>
            <div style={{ padding: '30px', textAlign: 'center' }}>
              <p>{error || 'Article not found.'}</p>
              <Link to="/handbook" className="tui-button cyan-168" style={{ marginTop: '16px', display: 'inline-block' }}>
                ← Back to Handbook
              </Link>
            </div>
          </fieldset>
        </div>
      </HandbookLayout>
    )
  }

  const kindColor = KIND_COLORS[article.kind] || ACCENT

  return (
    <HandbookLayout
      sections={sections}
      currentSectionSlug={article.section.slug}
      currentArticleSlug={article.slug}
      searchQuery={searchQuery}
      onSearchChange={setSearchQuery}
    >
      <div className="tui-window cyan-168 white-text">
        <fieldset className="cyan-168-border">
          <legend className="center">{article.section.name.toUpperCase()}</legend>
          <div style={{ padding: '30px', background: '#1a1a1a' }}>
            {/* Breadcrumb */}
            <div style={{ fontSize: '0.85em', marginBottom: '16px', color: '#666' }}>
              <Link to="/handbook" style={{ color: '#60a5fa', textDecoration: 'none' }}>Handbook</Link>
              <span style={{ margin: '0 8px' }}>/</span>
              <span style={{ color: '#a0a0a0' }}>{article.section.name}</span>
              <span style={{ margin: '0 8px' }}>/</span>
              <span style={{ color: '#d0d0d0' }}>{article.title}</span>
            </div>

            {/* Kind / difficulty badges */}
            <div style={{ marginBottom: '12px', display: 'flex', gap: '8px', alignItems: 'center' }}>
              <span
                style={{
                  display: 'inline-block',
                  padding: '3px 10px',
                  background: kindColor,
                  color: '#000',
                  fontSize: '0.75em',
                  fontWeight: 'bold',
                  textTransform: 'uppercase',
                  borderRadius: '2px'
                }}
              >
                {article.kind}
              </span>
              {article.difficulty && (
                <span
                  style={{
                    display: 'inline-block',
                    padding: '3px 10px',
                    background: '#333',
                    color: '#d0d0d0',
                    fontSize: '0.75em',
                    fontWeight: 'bold',
                    textTransform: 'uppercase',
                    borderRadius: '2px'
                  }}
                >
                  {article.difficulty}
                </span>
              )}
            </div>

            <h1 style={{ margin: '0 0 18px 0', color: kindColor, fontSize: '2.2em', fontFamily: 'monospace' }}>
              {article.title}
            </h1>

            {article.summary && (
              <div
                style={{
                  padding: '14px 18px',
                  background: '#0a0a0a',
                  border: `2px solid ${kindColor}`,
                  marginBottom: '26px',
                  borderRadius: '2px'
                }}
              >
                <p style={{ margin: 0, color: '#e5e5e5', fontSize: '1.05em', lineHeight: 1.6, fontStyle: 'italic' }}>
                  {article.summary}
                </p>
              </div>
            )}

            {article.body && <MarkdownContent content={article.body} accentColor={kindColor} />}

            {/* Prev / next nav */}
            {(article.prev_article || article.next_article) && (
              <div
                style={{
                  marginTop: '40px',
                  paddingTop: '20px',
                  borderTop: '1px solid #333',
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '12px'
                }}
              >
                <div>
                  {article.prev_article && (
                    <Link
                      to={`/handbook/${article.prev_article.slug}`}
                      style={{
                        display: 'block',
                        padding: '12px 14px',
                        background: '#0a0a0a',
                        border: '1px solid #333',
                        textDecoration: 'none',
                        color: '#d0d0d0'
                      }}
                    >
                      <div style={{ color: '#666', fontSize: '0.78em', marginBottom: '4px' }}>← PREVIOUS</div>
                      <div style={{ color: '#60a5fa' }}>{article.prev_article.title}</div>
                    </Link>
                  )}
                </div>
                <div style={{ textAlign: 'right' }}>
                  {article.next_article && (
                    <Link
                      to={`/handbook/${article.next_article.slug}`}
                      style={{
                        display: 'block',
                        padding: '12px 14px',
                        background: '#0a0a0a',
                        border: '1px solid #333',
                        textDecoration: 'none',
                        color: '#d0d0d0'
                      }}
                    >
                      <div style={{ color: '#666', fontSize: '0.78em', marginBottom: '4px' }}>NEXT →</div>
                      <div style={{ color: '#60a5fa' }}>{article.next_article.title}</div>
                    </Link>
                  )}
                </div>
              </div>
            )}

            <div
              style={{
                marginTop: '32px',
                paddingTop: '16px',
                borderTop: '1px solid #333',
                color: '#666',
                fontSize: '0.82em'
              }}
            >
              Last updated: {formatFutureDate(article.updated_at)}
            </div>
          </div>
        </fieldset>
      </div>
    </HandbookLayout>
  )
}
