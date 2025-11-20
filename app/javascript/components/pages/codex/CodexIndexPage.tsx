import React, { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import type { CodexEntrySummary } from '~/types/codex'

const ENTRY_TYPE_COLORS: Record<string, string> = {
  person: '#a78bfa',      // purple
  organization: '#60a5fa', // blue
  event: '#f472b6',       // pink
  location: '#34d399',    // green
  technology: '#fbbf24',  // yellow
  faction: '#f87171',     // red
  item: '#a3e635'         // lime
}

const ENTRY_TYPE_ICONS: Record<string, string> = {
  person: '👤',
  organization: '🏢',
  event: '📅',
  location: '📍',
  technology: '⚙️',
  faction: '⚔️',
  item: '📦'
}

export const CodexIndexPage: React.FC = () => {
  const [entries, setEntries] = useState<CodexEntrySummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedType, setSelectedType] = useState<string>('all')
  const [searchQuery, setSearchQuery] = useState<string>('')

  useEffect(() => {
    fetch('/api/codex')
      .then(res => res.json())
      .then(data => {
        setEntries(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load codex entries:', err)
        setError('Failed to load codex entries')
        setLoading(false)
      })
  }, [])

  const filteredEntries = useMemo(() => {
    let filtered = entries

    // Filter by type
    if (selectedType !== 'all') {
      filtered = filtered.filter(entry => entry.entry_type === selectedType)
    }

    // Filter by search query
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(entry =>
        entry.name.toLowerCase().includes(query) ||
        (entry.summary && entry.summary.toLowerCase().includes(query))
      )
    }

    return filtered
  }, [entries, selectedType, searchQuery])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: '1200px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading Codex..." color="cyan-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: '1200px', margin: '30px auto', textAlign: 'center', color: '#f87171' }}>
          {error}
        </div>
      </DefaultLayout>
    )
  }

  const entryTypes = Array.from(new Set(entries.map(e => e.entry_type)))

  return (
    <DefaultLayout>
      <div style={{ maxWidth: '1200px', margin: '30px auto' }}>
        {/* Header */}
        <div className="tui-window cyan-168 white-text">
          <fieldset className="cyan-168-border">
            <legend className="center">THE CODEX :: Knowledge Archive</legend>
            <div style={{ padding: '20px', background: '#1a1a1a' }}>
              <p style={{ color: '#b0b0b0', margin: 0, textAlign: 'center', fontSize: '1.05em', lineHeight: '1.6' }}>
                A comprehensive archive of people, organizations, events, and technologies within THE.CYBERPUL.SE universe
              </p>
            </div>
          </fieldset>
        </div>

        {/* Filter Controls */}
        <div style={{ margin: '20px 0', display: 'flex', gap: '20px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          {/* Type Filter */}
          <div style={{ flex: '0 0 auto' }}>
            <label style={{ display: 'block', marginBottom: '8px', color: '#888', fontSize: '0.9em' }}>
              FILTER BY TYPE:
            </label>
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              <button
                onClick={() => setSelectedType('all')}
                className={`tui-button ${selectedType === 'all' ? 'cyan-168' : 'grey-168'}`}
                style={{ padding: '5px 15px' }}
              >
                All ({entries.length})
              </button>
              {entryTypes.map(type => (
                <button
                  key={type}
                  onClick={() => setSelectedType(type)}
                  className={`tui-button ${selectedType === type ? 'cyan-168' : 'grey-168'}`}
                  style={{ padding: '5px 15px' }}
                >
                  {ENTRY_TYPE_ICONS[type]} {type.charAt(0).toUpperCase() + type.slice(1)} ({entries.filter(e => e.entry_type === type).length})
                </button>
              ))}
            </div>
          </div>

          {/* Search */}
          <div style={{ flex: '1 1 300px' }}>
            <label htmlFor="codex-search" style={{ display: 'block', marginBottom: '8px', color: '#888', fontSize: '0.9em' }}>
              SEARCH:
            </label>
            <input
              id="codex-search"
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name or summary..."
              className="tui-input"
              style={{
                width: '100%',
                padding: '8px 12px',
                background: '#0a0a0a',
                border: '1px solid #444',
                color: '#ccc',
                fontFamily: 'monospace'
              }}
            />
          </div>
        </div>

        {/* Results Count */}
        <div style={{ margin: '10px 0', color: '#666', fontSize: '0.9em' }}>
          Showing {filteredEntries.length} of {entries.length} entries
        </div>

        {/* Entries Grid */}
        {filteredEntries.length > 0 ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '20px', marginTop: '20px' }}>
            {filteredEntries.map(entry => (
              <Link
                key={entry.id}
                to={`/codex/${entry.slug}`}
                style={{ textDecoration: 'none' }}
              >
                <div
                  className="tui-window white-text"
                  style={{
                    background: '#0d0d0d',
                    borderLeft: `4px solid ${ENTRY_TYPE_COLORS[entry.entry_type] || '#888'}`,
                    height: '100%',
                    transition: 'all 0.2s',
                    cursor: 'pointer'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = '#1a1a1a'
                    e.currentTarget.style.transform = 'translateY(-2px)'
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = '#0d0d0d'
                    e.currentTarget.style.transform = 'translateY(0)'
                  }}
                >
                  <div style={{ padding: '20px' }}>
                    {/* Type Badge */}
                    <div style={{ marginBottom: '10px' }}>
                      <span style={{
                        display: 'inline-block',
                        padding: '3px 10px',
                        background: ENTRY_TYPE_COLORS[entry.entry_type] || '#888',
                        color: '#000',
                        fontSize: '0.75em',
                        fontWeight: 'bold',
                        textTransform: 'uppercase',
                        borderRadius: '3px'
                      }}>
                        {ENTRY_TYPE_ICONS[entry.entry_type]} {entry.entry_type}
                      </span>
                    </div>

                    {/* Name */}
                    <h3 style={{
                      margin: '0 0 10px 0',
                      fontSize: '1.3em',
                      color: ENTRY_TYPE_COLORS[entry.entry_type] || '#888'
                    }}>
                      {entry.name}
                    </h3>

                    {/* Summary */}
                    {entry.summary && (
                      <p style={{
                        margin: '0 0 15px 0',
                        color: '#9ca3af',
                        lineHeight: '1.5',
                        fontSize: '0.9em'
                      }}>
                        {entry.summary}
                      </p>
                    )}

                    {/* Metadata Tags */}
                    {entry.metadata && Object.keys(entry.metadata).length > 0 && (
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px' }}>
                        {Object.entries(entry.metadata).slice(0, 3).map(([key, value]) => (
                          <span
                            key={key}
                            style={{
                              padding: '2px 8px',
                              background: '#1a1a1a',
                              border: '1px solid #333',
                              color: '#666',
                              fontSize: '0.75em',
                              borderRadius: '3px'
                            }}
                          >
                            {key}: {value}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <div className="tui-window white-text" style={{ padding: '60px', textAlign: 'center', background: '#0d0d0d', marginTop: '20px' }}>
            <p style={{ color: '#6b7280', fontSize: '1.1em', lineHeight: '1.8' }}>
              No entries found matching your criteria.
              <br />
              <span style={{ fontSize: '0.9em' }}>Try adjusting your filters or search query...</span>
            </p>
          </div>
        )}
      </div>
    </DefaultLayout>
  )
}
