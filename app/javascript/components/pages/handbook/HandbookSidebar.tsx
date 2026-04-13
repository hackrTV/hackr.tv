import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import type { HandbookSection } from '~/types/handbook'

interface HandbookSidebarProps {
  sections: HandbookSection[]
  currentSectionSlug?: string
  currentArticleSlug?: string
  searchQuery?: string
  onSearchChange?: (q: string) => void
}

const ACCENT = '#22d3ee'
const MUTED = '#6b7280'

export const HandbookSidebar: React.FC<HandbookSidebarProps> = ({
  sections,
  currentSectionSlug,
  currentArticleSlug,
  searchQuery = '',
  onSearchChange
}) => {
  // Tracks ONLY explicit user toggles. Default open/closed state is derived
  // during render from `currentSectionSlug`, so navigation between articles
  // no longer needs an effect to "sync" the sidebar state.
  const [userToggles, setUserToggles] = useState<Record<string, boolean>>({})

  const defaultOpen = (slug: string) =>
    !currentSectionSlug || slug === currentSectionSlug

  const isOpen = (slug: string) => userToggles[slug] ?? defaultOpen(slug)

  const toggle = (slug: string) => {
    setUserToggles(prev => ({ ...prev, [slug]: !(prev[slug] ?? defaultOpen(slug)) }))
  }

  const q = searchQuery.trim().toLowerCase()
  const hasQuery = q.length > 0

  const articleMatches = (section: HandbookSection, a: HandbookSection['articles'][number]) => {
    const rawTags = (a.metadata as { search_tags?: unknown })?.search_tags
    const tags = Array.isArray(rawTags) ? rawTags.filter((t): t is string => typeof t === 'string') : []
    return (
      a.title.toLowerCase().includes(q) ||
      (a.summary || '').toLowerCase().includes(q) ||
      section.name.toLowerCase().includes(q) ||
      tags.some(t => t.toLowerCase().includes(q))
    )
  }

  const filteredSections = sections
    .map(section => ({
      section,
      matchingArticles: hasQuery
        ? section.articles.filter(a => articleMatches(section, a))
        : section.articles
    }))
    .filter(({ matchingArticles }) => !hasQuery || matchingArticles.length > 0)

  return (
    <nav
      aria-label="Handbook navigation"
      style={{
        background: '#0d0d0d',
        border: '1px solid #333',
        padding: '16px',
        color: '#d0d0d0'
      }}
    >
      <div style={{ marginBottom: '14px' }}>
        <Link
          to="/handbook"
          style={{
            display: 'block',
            color: ACCENT,
            textDecoration: 'none',
            fontWeight: 'bold',
            fontSize: '1.1em',
            marginBottom: '4px'
          }}
        >
          HACKR HANDBOOK
        </Link>
        <div style={{ color: MUTED, fontSize: '0.8em' }}>Operator's field manual</div>
      </div>

      {onSearchChange && (
        <input
          type="search"
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search articles..."
          className="tui-input"
          style={{
            width: '100%',
            padding: '6px 8px',
            marginBottom: '14px',
            background: '#0a0a0a',
            color: '#d0d0d0',
            border: '1px solid #333',
            fontSize: '0.9em'
          }}
        />
      )}

      <div>
        {filteredSections.map(({ section, matchingArticles }) => {
          const sectionOpen = hasQuery ? true : isOpen(section.slug)
          const isActiveSection = section.slug === currentSectionSlug

          return (
            <div key={section.slug} style={{ marginBottom: '6px' }}>
              <button
                onClick={() => toggle(section.slug)}
                style={{
                  background: 'none',
                  border: 'none',
                  padding: '6px 4px',
                  width: '100%',
                  textAlign: 'left',
                  color: isActiveSection ? ACCENT : '#d0d0d0',
                  fontFamily: 'inherit',
                  fontSize: '0.95em',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}
              >
                <span style={{ color: MUTED, width: '10px', display: 'inline-block' }}>
                  {sectionOpen ? '▾' : '▸'}
                </span>
                {section.icon && (
                  <span style={{ color: '#fbbf24', fontFamily: 'monospace' }}>{section.icon}</span>
                )}
                <span>{section.name}</span>
              </button>

              {sectionOpen && (
                <ul style={{ listStyle: 'none', margin: 0, padding: '2px 0 2px 28px' }}>
                  {matchingArticles.map(article => {
                    const isActive = article.slug === currentArticleSlug
                    return (
                      <li key={article.slug} style={{ margin: '2px 0' }}>
                        <Link
                          to={`/handbook/${article.slug}`}
                          style={{
                            display: 'block',
                            padding: '4px 8px',
                            textDecoration: 'none',
                            color: isActive ? '#fff' : '#a0a0a0',
                            background: isActive ? 'rgba(34, 211, 238, 0.15)' : 'transparent',
                            borderLeft: isActive ? `3px solid ${ACCENT}` : '3px solid transparent',
                            fontSize: '0.88em',
                            lineHeight: '1.4'
                          }}
                        >
                          {article.kind === 'tutorial' && (
                            <span style={{ color: '#fbbf24', fontSize: '0.75em', marginRight: '6px' }}>
                              ▶
                            </span>
                          )}
                          {article.title}
                        </Link>
                      </li>
                    )
                  })}
                </ul>
              )}
            </div>
          )
        })}

        {hasQuery && filteredSections.length === 0 && (
          <div style={{ color: MUTED, padding: '10px 4px', fontSize: '0.85em', fontStyle: 'italic' }}>
            No articles match "{searchQuery}".
          </div>
        )}
      </div>
    </nav>
  )
}
