import React, { useState } from 'react'
import type { ProfileData } from '~/types/profile'
import { BIO_MAX } from '~/types/profile'
import { BioText } from '../shared/BioText'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

const ROLE_COLORS: Record<string, string> = {
  admin: '#ff4444',
  operator: '#c084fc',
  operative: '#22d3ee'
}

const formatJoinDate = (iso: string): string =>
  new Date(iso).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })

const formatWatch = (seconds: number): string => {
  if (!seconds || seconds < 60) return '—'
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

const formatLastActive = (iso: string): string => {
  const mins = Math.floor((Date.now() - new Date(iso).getTime()) / 60000)
  if (mins < 5) return 'online now'
  if (mins < 60) return `active ${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `active ${hrs}h ago`
  return `active ${Math.floor(hrs / 24)}d ago`
}

const isOnlineNow = (iso: string | null): boolean =>
  !!iso && (Date.now() - new Date(iso).getTime()) < 5 * 60000

interface ProfileHeaderProps {
  profile: ProfileData
  isSelf: boolean
  onBioSaved: (bio: string) => void
}

export const ProfileHeader: React.FC<ProfileHeaderProps> = ({ profile, isSelf, onBioSaved }) => {
  const { updateProfile } = useGridAuthContext()
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState(profile.bio ?? '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)

  const roleColor = ROLE_COLORS[profile.role] ?? '#888'

  const startEdit = () => {
    setDraft(profile.bio ?? '')
    setError(null)
    setEditing(true)
  }

  const save = async () => {
    setSaving(true)
    setError(null)
    const result = await updateProfile(draft)
    setSaving(false)
    if (result.success) {
      onBioSaved(draft)
      setEditing(false)
    } else {
      setError(result.error || 'Failed to save bio.')
    }
  }

  const share = async () => {
    try {
      await navigator.clipboard.writeText(`${window.location.origin}/@${profile.hackr_alias}`)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // Clipboard unavailable — silently ignore.
    }
  }

  const s = profile.stats
  const tiles: Array<{ label: string, value: number | string }> = [
    { label: 'WIRE PULSES', value: s.pulses },
    { label: 'ECHOES', value: s.echoes_received },
    { label: 'PACKETS', value: s.packets },
    { label: 'ACHIEVEMENTS', value: s.achievements },
    { label: 'BREACHES', value: s.breaches_completed },
    { label: 'WATCH TIME', value: formatWatch(s.watch_seconds) }
  ]

  return (
    <div style={{
      border: '1px solid #2a3a4a',
      background: 'rgba(10,20,30,0.6)',
      padding: '24px',
      marginBottom: '24px',
      fontFamily: '\'Courier New\', monospace'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
        <h1 style={{ margin: 0, fontSize: '2em', color: '#fff' }}>@{profile.hackr_alias}</h1>
        <span style={{ border: `1px solid ${roleColor}`, color: roleColor, padding: '2px 8px', fontSize: '0.7em', letterSpacing: '0.1em', textTransform: 'uppercase' }}>
          {profile.role}
        </span>
        <span style={{ border: '1px solid #facc15', color: '#facc15', padding: '2px 8px', fontSize: '0.7em', letterSpacing: '0.1em' }}>
          CL{profile.clearance}
        </span>
        <button
          onClick={share}
          style={{ marginLeft: 'auto', background: 'none', border: '1px solid #2a3a4a', color: '#22d3ee', padding: '4px 10px', cursor: 'pointer', fontFamily: 'inherit', fontSize: '0.8em' }}
        >
          {copied ? 'COPIED ✓' : '⧉ SHARE'}
        </button>
      </div>

      <div style={{ marginTop: '6px', color: '#7a8a9a', fontSize: '0.85em', display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
        <span>MEMBER SINCE {formatJoinDate(profile.joined_at)}</span>
        {profile.last_active_at && (
          <span style={{ color: isOnlineNow(profile.last_active_at) ? '#34d399' : '#7a8a9a' }}>
            ● {formatLastActive(profile.last_active_at)}
          </span>
        )}
      </div>

      <div style={{ marginTop: '16px' }}>
        {editing ? (
          <div>
            <textarea
              value={draft}
              onChange={(e) => setDraft(e.target.value.slice(0, BIO_MAX))}
              rows={4}
              autoFocus
              style={{ width: '100%', resize: 'vertical', fontFamily: 'inherit', background: '#0a141e', color: '#e0e0e0', border: '1px solid #2a3a4a', padding: '8px', boxSizing: 'border-box' }}
            />
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '8px' }}>
              <button onClick={save} disabled={saving} style={{ background: '#22d3ee', color: '#0a0a0a', border: 'none', padding: '6px 14px', cursor: saving ? 'not-allowed' : 'pointer', fontFamily: 'inherit', fontWeight: 'bold' }}>
                {saving ? 'SAVING...' : 'SAVE'}
              </button>
              <button onClick={() => setEditing(false)} disabled={saving} style={{ background: 'none', color: '#888', border: '1px solid #2a3a4a', padding: '6px 14px', cursor: 'pointer', fontFamily: 'inherit' }}>
                CANCEL
              </button>
              <span style={{ color: draft.length >= BIO_MAX ? '#ff4444' : '#666', fontSize: '0.8em', marginLeft: 'auto' }}>
                {draft.length}/{BIO_MAX}
              </span>
            </div>
            {error && <p style={{ color: '#ff4444', margin: '8px 0 0' }}>{error}</p>}
          </div>
        ) : (
          <div style={{ color: '#c0d0e0', lineHeight: 1.5 }}>
            {profile.bio
              ? <BioText>{profile.bio}</BioText>
              : <span style={{ color: '#566b7a', fontStyle: 'italic' }}>{isSelf ? 'No bio yet — broadcast something about yourself.' : 'No bio on record.'}</span>}
            {isSelf && (
              <button onClick={startEdit} style={{ marginLeft: '10px', background: 'none', border: 'none', color: '#22d3ee', cursor: 'pointer', fontFamily: 'inherit', fontSize: '0.8em' }}>
                ✎ EDIT
              </button>
            )}
          </div>
        )}
      </div>

      <div style={{ marginTop: '20px', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(110px, 1fr))', gap: '10px' }}>
        {tiles.map((t) => (
          <div key={t.label} style={{ border: '1px solid #1f2f3f', background: 'rgba(20,30,40,0.5)', padding: '10px', textAlign: 'center' }}>
            <div style={{ color: '#fff', fontSize: '1.4em', fontWeight: 'bold' }}>{t.value}</div>
            <div style={{ color: '#7a8a9a', fontSize: '0.65em', letterSpacing: '0.08em', marginTop: '4px' }}>{t.label}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
