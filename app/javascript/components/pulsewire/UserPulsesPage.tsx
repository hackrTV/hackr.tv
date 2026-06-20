import React, { useState, useEffect, useRef } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import type { Pulse } from '../../types/pulse'
import type { ProfileData, ProfileResponse, PinResponse } from '~/types/profile'
import { PulseCard } from './PulseCard'
import { ProfileHeader } from './ProfileHeader'
import { apiJson, ApiError } from '~/utils/apiClient'

interface ProfilePulse extends Pulse {
  is_echo_on_profile?: boolean
}

interface PulsesResponse {
  pulses: Pulse[]
}

export const UserPulsesPage: React.FC = () => {
  const { username } = useParams<{ username: string }>()
  const [profile, setProfile] = useState<ProfileData | null>(null)
  const [isSelf, setIsSelf] = useState(false)
  const [pinnedPulses, setPinnedPulses] = useState<Pulse[]>([])
  const [pulses, setPulses] = useState<ProfilePulse[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)

  useEffect(() => {
    const load = async () => {
      if (!username) return
      setIsLoading(true)
      setError(null)
      setNotFound(false)

      try {
        const [profileData, authoredData, echoedData] = await Promise.all([
          apiJson<ProfileResponse>(`/api/profiles/${encodeURIComponent(username)}`),
          apiJson<PulsesResponse>(`/api/pulses?hackr=${username}&filter=active&per_page=100&include_splices=true`),
          apiJson<PulsesResponse>(`/api/pulses?echoed_by=${username}&filter=active&per_page=100&include_splices=true`)
        ])

        setProfile(profileData.profile)
        setIsSelf(profileData.is_self)
        setPinnedPulses(profileData.profile.pinned_pulses)

        const authoredPulses: ProfilePulse[] = authoredData.pulses.map((p) => ({ ...p, is_echo_on_profile: false }))
        const echoedPulses: ProfilePulse[] = echoedData.pulses
          .filter((p) => p.grid_hackr.hackr_alias.toLowerCase() !== username.toLowerCase())
          .map((p) => ({ ...p, is_echo_on_profile: true }))

        const combined = [...authoredPulses, ...echoedPulses].sort((a, b) =>
          new Date(b.pulsed_at).getTime() - new Date(a.pulsed_at).getTime()
        )

        setPulses(combined)
        setIsLoading(false)
      } catch (err) {
        if (err instanceof ApiError && err.status === 404) {
          setNotFound(true)
        } else {
          setError(err instanceof Error ? err.message : 'Failed to load profile')
        }
        setIsLoading(false)
      }
    }

    load()
  }, [username])

  const applyEcho = (list: ProfilePulse[], pulseId: number, newEchoCount: number, isEchoed: boolean) =>
    list.map((p) => p.id === pulseId ? { ...p, echo_count: newEchoCount, is_echoed_by_current_hackr: isEchoed } : p)

  const handleEchoToggle = (pulseId: number, newEchoCount: number, isEchoed: boolean) => {
    setPulses((prev) => applyEcho(prev, pulseId, newEchoCount, isEchoed))
    setPinnedPulses((prev) => applyEcho(prev as ProfilePulse[], pulseId, newEchoCount, isEchoed))
  }

  const handlePulseCreated = (newPulse: Pulse) => {
    setPulses((prev) => [{ ...newPulse, is_echo_on_profile: false }, ...prev])
  }

  const handlePulseDeleted = (pulseId: number) => {
    setPulses((prev) => prev.filter((p) => p.id !== pulseId))
    setPinnedPulses((prev) => prev.filter((p) => p.id !== pulseId))
  }

  const pinBusyRef = useRef(false)

  const handlePinToggle = async (pulseId: number, currentlyPinned: boolean) => {
    if (pinBusyRef.current) return
    pinBusyRef.current = true
    try {
      const resp = await apiJson<PinResponse>(`/api/pulses/${pulseId}/pin`, {
        method: currentlyPinned ? 'DELETE' : 'POST'
      })
      setPinnedPulses(resp.pinned_pulses)
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to update pin')
    } finally {
      pinBusyRef.current = false
    }
  }

  const handlePinMove = async (pulseId: number, direction: 'up' | 'down') => {
    if (pinBusyRef.current) return
    const ids = pinnedPulses.map((p) => p.id)
    const idx = ids.indexOf(pulseId)
    const swapWith = direction === 'up' ? idx - 1 : idx + 1
    if (idx < 0 || swapWith < 0 || swapWith >= ids.length) return

    const next = [...ids];
    [next[idx], next[swapWith]] = [next[swapWith], next[idx]]

    pinBusyRef.current = true
    try {
      const resp = await apiJson<PinResponse>('/api/profile/pins', {
        method: 'PATCH',
        body: JSON.stringify({ pulse_ids: next })
      })
      setPinnedPulses(resp.pinned_pulses)
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to reorder pins')
    } finally {
      pinBusyRef.current = false
    }
  }

  const handleBioSaved = (bio: string) => {
    setProfile((prev) => prev ? { ...prev, bio } : prev)
  }

  if (isLoading) {
    return (
      <DefaultLayout>
        <div className="white-168-text" style={{ textAlign: 'center', padding: '40px' }}>
          Loading profile...
        </div>
      </DefaultLayout>
    )
  }

  if (notFound) {
    return (
      <DefaultLayout>
        <div className="white-168-text" style={{ maxWidth: '800px', margin: '0 auto', paddingTop: '40px', textAlign: 'center' }}>
          <h1>NO SIGNAL</h1>
          <p>No hackr known as <strong>@{username}</strong> on the WIRE.</p>
          <Link to="/wire" className="btn btn-primary">← Back to the WIRE</Link>
        </div>
      </DefaultLayout>
    )
  }

  if (error || !profile) {
    return (
      <DefaultLayout>
        <div className="red-255-text" style={{ padding: '20px', border: '1px solid #ff0000', marginBottom: '20px' }}>
          {error || 'Profile unavailable'}
        </div>
        <Link to="/wire" className="btn btn-primary">Back to Hotwire</Link>
      </DefaultLayout>
    )
  }

  const pinnedIds = new Set(pinnedPulses.map((p) => p.id))
  const canPin = (pulse: ProfilePulse) => isSelf && !pulse.is_echo_on_profile && pulse.grid_hackr.id === profile.id
  // Pinned pulses render in the PINNED section, not again in the feed.
  const timelinePulses = pulses.filter((p) => !pinnedIds.has(p.id))

  return (
    <DefaultLayout showAsciiArt={false}>
      <div className="user-pulses-page white-168-text" style={{ maxWidth: '800px', margin: '0 auto', paddingTop: '30px' }}>
        <ProfileHeader profile={profile} isSelf={isSelf} onBioSaved={handleBioSaved} />

        {pinnedPulses.length > 0 && (
          <div className="pinned-pulses" style={{
            marginBottom: '24px',
            padding: '16px',
            border: '1px solid rgba(250, 204, 21, 0.35)',
            background: 'rgba(250, 204, 21, 0.04)'
          }}>
            <div style={{ color: '#facc15', letterSpacing: '0.1em', fontSize: '0.8rem', marginBottom: '10px', fontFamily: '\'Courier New\', monospace' }}>
              📌 PINNED
            </div>
            {pinnedPulses.map((pulse, idx) => (
              <PulseCard
                key={`pin-${pulse.id}`}
                pulse={pulse}
                showReplies={false}
                indentSplice={false}
                pinnable={isSelf}
                isPinned
                onPinToggle={handlePinToggle}
                onEchoToggle={handleEchoToggle}
                onPulseDeleted={handlePulseDeleted}
                canMoveUp={isSelf && idx > 0}
                canMoveDown={isSelf && idx < pinnedPulses.length - 1}
                onMoveUp={() => handlePinMove(pulse.id, 'up')}
                onMoveDown={() => handlePinMove(pulse.id, 'down')}
              />
            ))}
          </div>
        )}

        <div style={{ color: '#7a8a9a', letterSpacing: '0.1em', fontSize: '0.8rem', marginBottom: '10px', fontFamily: '\'Courier New\', monospace' }}>
          BROADCASTS
        </div>

        <div className="user-timeline">
          {timelinePulses.length === 0 ? (
            <div className="empty-state">
              <p>{pinnedPulses.length > 0
                ? `@${profile.hackr_alias}'s broadcasts are all pinned above.`
                : `@${profile.hackr_alias} hasn't broadcast any pulses yet.`}</p>
            </div>
          ) : (
            timelinePulses.map((pulse) => (
              <div key={`${pulse.is_echo_on_profile ? 'echo-' : ''}${pulse.id}`}>
                {pulse.is_echo_on_profile && (
                  <div className="echo-indicator" style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    fontSize: '0.9rem',
                    color: '#60a5fa',
                    padding: '8px 15px',
                    marginBottom: '-3px',
                    background: 'rgba(96, 165, 250, 0.1)',
                    borderLeft: '3px solid #60a5fa',
                    borderTop: '1px solid rgba(96, 165, 250, 0.3)',
                    borderRight: '1px solid rgba(96, 165, 250, 0.3)',
                    fontFamily: '\'Courier New\', Courier, monospace'
                  }}>
                    <span style={{ fontSize: '1.1rem' }}>↻</span>
                    <span>@{profile.hackr_alias} echoed</span>
                  </div>
                )}
                {pulse.is_splice && !pulse.is_echo_on_profile && (
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      fontSize: '0.9rem',
                      color: '#a78bfa',
                      padding: '8px 15px',
                      marginBottom: '-3px',
                      background: 'rgba(167, 139, 250, 0.1)',
                      borderLeft: '3px solid #a78bfa',
                      borderTop: '1px solid rgba(167, 139, 250, 0.3)',
                      borderRight: '1px solid rgba(167, 139, 250, 0.3)',
                      fontFamily: '\'Courier New\', Courier, monospace'
                    }}
                  >
                    <span style={{ fontSize: '1.1rem' }}>↩</span>
                    <span>replying to <Link
                      to={`/wire/pulse/${pulse.thread_root_id || pulse.parent_pulse_id}`}
                      style={{ color: '#c4b5fd', textDecoration: 'underline' }}
                    >thread</Link></span>
                  </div>
                )}
                <PulseCard
                  pulse={pulse}
                  indentSplice={false}
                  pinnable={canPin(pulse)}
                  isPinned={pinnedIds.has(pulse.id)}
                  onPinToggle={handlePinToggle}
                  onEchoToggle={handleEchoToggle}
                  onPulseCreated={handlePulseCreated}
                  onPulseDeleted={handlePulseDeleted}
                />
              </div>
            ))
          )}
        </div>

        <div className="back-link" style={{ marginTop: '20px' }}>
          <Link to="/wire">← Back to the WIRE</Link>
        </div>
      </div>
    </DefaultLayout>
  )
}
