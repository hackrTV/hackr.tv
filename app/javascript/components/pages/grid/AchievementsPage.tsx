import React, { useEffect, useState, useMemo } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface Progress {
  current: number
  target: number
  fraction: number
  completed: boolean
}

interface AchievementRow {
  slug: string
  name: string
  description: string | null
  badge_icon: string | null
  category: string
  trigger_type: string
  xp_reward: number
  cred_reward: number
  earned: boolean
  awarded_at: string | null
  progress: Progress | null
}

interface ApiResponse {
  categories: Record<string, AchievementRow[]>
  summary: {
    total: { total: number; earned: number }
    by_category: Record<string, { total: number; earned: number }>
  }
}

const CATEGORY_ORDER = ['grid', 'music', 'social', 'meta', 'progression']

const CATEGORY_META: Record<string, { label: string; color: string; icon: string }> = {
  grid: { label: 'GRID', color: '#22d3ee', icon: '#' },
  music: { label: 'MUSIC', color: '#f472b6', icon: '%' },
  social: { label: 'SOCIAL', color: '#60a5fa', icon: '~' },
  meta: { label: 'META', color: '#a3e635', icon: '>>' },
  progression: { label: 'PROGRESSION', color: '#c084fc', icon: '▲' }
}

const formatAwardedAt = (iso: string): string => {
  try {
    const d = new Date(iso)
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
  } catch {
    return iso
  }
}

const AchievementsPage: React.FC = () => {
  const [data, setData] = useState<ApiResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeCategory, setActiveCategory] = useState<string>('all')

  useEffect(() => {
    apiJson<ApiResponse>('/api/grid/achievements')
      .then(json => {
        setData(json)
        setLoading(false)
      })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load achievements')
        setLoading(false)
      })
  }, [])

  const visibleCategories = useMemo(() => {
    if (!data) return []
    return CATEGORY_ORDER.filter(cat => (data.categories[cat]?.length || 0) > 0)
  }, [data])

  const rowsToRender = useMemo(() => {
    if (!data) return []
    if (activeCategory === 'all') {
      return visibleCategories.flatMap(cat => data.categories[cat] || [])
    }
    return data.categories[activeCategory] || []
  }, [data, activeCategory, visibleCategories])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading achievements..." color="yellow-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load achievements'}
        </div>
      </DefaultLayout>
    )
  }

  const total = data.summary.total

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 1100, margin: '30px auto' }}>
        <div className="tui-window white-text" style={{ display: 'block', background: '#0a0a0a', border: '2px solid #fbbf24', boxShadow: '0 0 30px rgba(251, 191, 36, 0.3)' }}>
          <fieldset style={{ borderColor: '#fbbf24' }}>
            <legend className="center" style={{ color: '#fbbf24', textShadow: '0 0 15px rgba(251, 191, 36, 0.6)', letterSpacing: 3 }}>
              ACHIEVEMENTS
            </legend>
            <div style={{ padding: 20 }}>
              {/* Totals */}
              <div style={{
                background: '#111',
                border: '1px solid #333',
                padding: '14px 16px',
                marginBottom: 20,
                display: 'flex',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 12
              }}>
                <div>
                  <span style={{ color: '#9ca3af' }}>Earned:</span>{' '}
                  <span style={{ color: '#22d3ee', fontWeight: 'bold' }}>{total.earned}</span>
                  <span style={{ color: '#6b7280' }}> / {total.total}</span>
                </div>
                <div style={{ color: '#fbbf24' }}>
                  {total.total > 0 ? `${Math.round((total.earned / total.total) * 100)}%` : '—'}
                </div>
              </div>

              {/* Category tabs */}
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
                <CategoryTab
                  label={`ALL (${total.earned}/${total.total})`}
                  color="#fbbf24"
                  active={activeCategory === 'all'}
                  onClick={() => setActiveCategory('all')}
                />
                {visibleCategories.map(cat => {
                  const meta = CATEGORY_META[cat]
                  const sum = data.summary.by_category[cat] || { total: 0, earned: 0 }
                  return (
                    <CategoryTab
                      key={cat}
                      label={`${meta?.label || cat.toUpperCase()} (${sum.earned}/${sum.total})`}
                      color={meta?.color || '#9ca3af'}
                      active={activeCategory === cat}
                      onClick={() => setActiveCategory(cat)}
                    />
                  )
                })}
              </div>

              {/* Cards grid */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
                gap: 12
              }}>
                {rowsToRender.map(a => (
                  <AchievementCard key={a.slug} row={a} />
                ))}
              </div>

              {rowsToRender.length === 0 && (
                <div style={{ padding: 40, textAlign: 'center', color: '#6b7280' }}>
                  Nothing in this category yet.
                </div>
              )}
            </div>
          </fieldset>
        </div>
      </div>
    </DefaultLayout>
  )
}

const CategoryTab: React.FC<{ label: string; color: string; active: boolean; onClick: () => void }> = ({ label, color, active, onClick }) => (
  <button
    className="tui-button"
    onClick={onClick}
    style={{
      padding: '6px 14px',
      background: active ? color : '#222',
      color: active ? '#000' : color,
      fontWeight: 'bold',
      border: `1px solid ${color}`,
      cursor: 'pointer',
      boxShadow: 'none',
      fontFamily: 'monospace'
    }}
  >
    {label}
  </button>
)

const AchievementCard: React.FC<{ row: AchievementRow }> = ({ row }) => {
  const meta = CATEGORY_META[row.category] || { label: row.category.toUpperCase(), color: '#9ca3af', icon: '?' }
  const isEarned = row.earned
  const prog = row.progress

  return (
    <div
      style={{
        background: isEarned ? '#1a1a1a' : '#0f0f0f',
        border: `1px solid ${isEarned ? meta.color : '#333'}`,
        padding: 14,
        opacity: isEarned ? 1 : 0.75,
        position: 'relative',
        fontFamily: 'monospace',
        transition: 'border-color 0.2s'
      }}
    >
      {/* Header: badge + name */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, marginBottom: 6 }}>
        <span
          style={{
            color: isEarned ? '#fbbf24' : '#4b5563',
            fontWeight: 'bold',
            minWidth: 28,
            fontSize: '1em'
          }}
        >
          {row.badge_icon || '?'}
        </span>
        <div style={{ flex: 1 }}>
          <div style={{ color: isEarned ? '#22d3ee' : '#6b7280', fontWeight: 'bold', fontSize: '1em' }}>
            {row.name}
          </div>
          <div style={{ color: meta.color, fontSize: '0.7em', letterSpacing: 1 }}>
            [{meta.label}]
          </div>
        </div>
        {isEarned && (
          <span title="Earned" style={{ color: '#34d399', fontWeight: 'bold', fontSize: '1.2em' }}>
            ✓
          </span>
        )}
      </div>

      {/* Description */}
      {row.description && (
        <div style={{ color: isEarned ? '#d0d0d0' : '#6b7280', fontSize: '0.85em', marginBottom: 10, lineHeight: 1.4 }}>
          {row.description}
        </div>
      )}

      {/* Progress bar (cumulative only, not yet earned) */}
      {!isEarned && prog && prog.target > 0 && (
        <div style={{ marginBottom: 8 }}>
          <div style={{ color: '#9ca3af', fontSize: '0.75em', marginBottom: 4, display: 'flex', justifyContent: 'space-between' }}>
            <span>Progress</span>
            <span style={{ color: '#d0d0d0' }}>{prog.current} / {prog.target}</span>
          </div>
          <div style={{ background: '#0a0a0a', border: '1px solid #333', height: 6, overflow: 'hidden' }}>
            <div
              style={{
                width: `${Math.min(100, Math.round(prog.fraction * 100))}%`,
                height: '100%',
                background: meta.color,
                transition: 'width 0.3s'
              }}
            />
          </div>
        </div>
      )}

      {/* Footer: rewards + awarded_at */}
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75em', marginTop: 8, paddingTop: 8, borderTop: '1px solid #2a2a2a' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {row.xp_reward > 0 && (
            <span style={{ color: isEarned ? '#34d399' : '#4b5563' }}>+{row.xp_reward} XP</span>
          )}
          {row.cred_reward > 0 && (
            <span style={{ color: isEarned ? '#fbbf24' : '#4b5563' }}>+{row.cred_reward} CRED</span>
          )}
        </div>
        {isEarned && row.awarded_at && (
          <span style={{ color: '#6b7280' }}>{formatAwardedAt(row.awarded_at)}</span>
        )}
      </div>
    </div>
  )
}

export default AchievementsPage
