import React, { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import type { CodeRepository } from '~/types/code'

const LANGUAGE_COLORS: Record<string, string> = {
  Ruby: '#cc342d',
  JavaScript: '#f1e05a',
  TypeScript: '#3178c6',
  Go: '#00add8',
  Python: '#3572a5',
  Rust: '#dea584',
  Shell: '#89e051',
  HTML: '#e34c26',
  CSS: '#563d7c',
  Lua: '#000080',
  C: '#555555',
  'C++': '#f34b7d',
  Java: '#b07219',
  Swift: '#ffac45',
  Kotlin: '#a97bff',
  Elixir: '#6e4a7e',
  Dockerfile: '#384d54'
}

const formatDate = (dateStr: string | null): string => {
  if (!dateStr) return 'N/A'
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffDays === 0) return 'today'
  if (diffDays === 1) return 'yesterday'
  if (diffDays < 30) return `${diffDays}d ago`
  if (diffDays < 365) return `${Math.floor(diffDays / 30)}mo ago`
  return `${Math.floor(diffDays / 365)}y ago`
}

export const CodeIndexPage: React.FC = () => {
  const [repos, setRepos] = useState<CodeRepository[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [langFilter, setLangFilter] = useState<string | null>(null)

  useEffect(() => {
    apiJson<CodeRepository[]>('/api/code')
      .then(data => {
        setRepos(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load repos:', err)
        setError('Failed to load repositories')
        setLoading(false)
      })
  }, [])

  const languages = useMemo(() => {
    const langs = new Set<string>()
    repos.forEach(r => { if (r.language) langs.add(r.language) })
    return Array.from(langs).sort()
  }, [repos])

  const filtered = useMemo(() => {
    return repos.filter(r => {
      if (langFilter && r.language !== langFilter) return false
      if (search) {
        const q = search.toLowerCase()
        return r.name.toLowerCase().includes(q) ||
          (r.description?.toLowerCase().includes(q) ?? false)
      }
      return true
    })
  }, [repos, search, langFilter])

  if (loading) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading repositories..." color="purple-168-text" size="large" />
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
      <div style={{ maxWidth: '900px', margin: '30px auto' }}>
        <div style={{ background: '#1a1a1a', color: '#d0d0d0', padding: '20px', border: '1px solid #333' }}>
          <div style={{ marginBottom: '20px' }}>
            <h1 style={{ margin: '0 0 8px 0', fontSize: '1.4em', color: '#a78bfa' }}>CODE</h1>
            <p style={{ margin: 0, fontSize: '0.9em', color: '#6b7280' }}>
              Open source projects from hackrTV
            </p>
          </div>

          {/* Search and filters */}
          <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', flexWrap: 'wrap', alignItems: 'center' }}>
            <input
              type="text"
              placeholder="Search repositories..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{
                background: '#0d0d0d',
                border: '1px solid #333',
                color: '#d0d0d0',
                padding: '6px 12px',
                fontFamily: "'Courier New', Courier, monospace",
                fontSize: '0.9em',
                flex: '1 1 200px',
                minWidth: '150px'
              }}
            />
            <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
              <button
                onClick={() => setLangFilter(null)}
                style={{
                  background: langFilter === null ? '#7c3aed' : '#252525',
                  color: langFilter === null ? '#fff' : '#888',
                  border: 'none',
                  padding: '4px 10px',
                  cursor: 'pointer',
                  fontFamily: "'Courier New', Courier, monospace",
                  fontSize: '0.8em'
                }}
              >
                All
              </button>
              {languages.map(lang => (
                <button
                  key={lang}
                  onClick={() => setLangFilter(langFilter === lang ? null : lang)}
                  style={{
                    background: langFilter === lang ? '#7c3aed' : '#252525',
                    color: langFilter === lang ? '#fff' : '#888',
                    border: 'none',
                    padding: '4px 10px',
                    cursor: 'pointer',
                    fontFamily: "'Courier New', Courier, monospace",
                    fontSize: '0.8em'
                  }}
                >
                  {lang}
                </button>
              ))}
            </div>
          </div>

          {/* Repo cards */}
          {filtered.length > 0 ? (
            <div style={{ display: 'grid', gap: '12px' }}>
              {filtered.map(repo => (
                <Link
                  key={repo.slug}
                  to={`/code/${repo.slug}`}
                  style={{ textDecoration: 'none', color: 'inherit' }}
                >
                  <div style={{
                    background: '#0d0d0d',
                    padding: '16px 20px',
                    borderLeft: '3px solid #6366f1',
                    transition: 'border-color 0.15s',
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                      <h3 style={{ margin: 0, color: '#a78bfa', fontSize: '1.1em' }}>
                        {repo.name}
                      </h3>
                      <div style={{ display: 'flex', gap: '12px', alignItems: 'center', fontSize: '0.8em', color: '#6b7280', flexShrink: 0 }}>
                        {repo.stargazers_count > 0 && (
                          <span>★ {repo.stargazers_count}</span>
                        )}
                        <span>{formatDate(repo.github_pushed_at)}</span>
                      </div>
                    </div>
                    {repo.description && (
                      <p style={{ margin: '0 0 10px 0', color: '#9ca3af', fontSize: '0.9em', lineHeight: '1.5' }}>
                        {repo.description}
                      </p>
                    )}
                    {repo.language && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8em' }}>
                        <span style={{
                          width: '10px',
                          height: '10px',
                          borderRadius: '50%',
                          backgroundColor: LANGUAGE_COLORS[repo.language] || '#888',
                          display: 'inline-block'
                        }} />
                        <span style={{ color: '#9ca3af' }}>{repo.language}</span>
                      </div>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div style={{ padding: '60px', textAlign: 'center', background: '#0d0d0d', border: '1px solid #333' }}>
              <p style={{ color: '#6b7280', fontSize: '1.1em' }}>
                {search || langFilter ? 'No matching repositories found.' : 'No repositories available yet.'}
              </p>
            </div>
          )}
        </div>
      </div>
    </DefaultLayout>
  )
}
