import React, { useState, useEffect, useCallback } from 'react'
import { Link } from 'react-router-dom'
import type { Pulse } from '../../types/pulse'
import { EchoButton } from './EchoButton'
import { PulseComposer } from './PulseComposer'
import { transformHtmlLinks, hasCodexLinks } from '../../utils/codexLinks'

interface PulseCardProps {
  pulse: Pulse
  showThread?: boolean
  showReplies?: boolean
  nestLevel?: number
  onEchoToggle?: (pulseId: number, newEchoCount: number, isEchoed: boolean) => void
  onPulseCreated?: (pulse: Pulse) => void
  onPulseDeleted?: (pulseId: number) => void
}

export const PulseCard: React.FC<PulseCardProps> = ({
  pulse,
  showThread = true,
  showReplies = true,
  nestLevel = 0,
  onEchoToggle,
  onPulseCreated,
  onPulseDeleted
}) => {
  const [showReplyForm, setShowReplyForm] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [replies, setReplies] = useState<Pulse[]>([])
  const [isLoadingReplies, setIsLoadingReplies] = useState(false)
  const [showRepliesSection, setShowRepliesSection] = useState(false)

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'just now'
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    if (diffDays < 7) return `${diffDays}d ago`

    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  }

  const handleDelete = async () => {
    if (!confirm('Delete this pulse? This action cannot be undone.')) {
      return
    }

    setIsDeleting(true)

    try {
      const response = await fetch(`/api/pulses/${pulse.id}`, {
        method: 'DELETE',
        credentials: 'include'
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Failed to delete pulse')
      }

      if (onPulseDeleted) {
        onPulseDeleted(pulse.id)
      }
    } catch (err) {
      console.error('Delete error:', err)
      alert(err instanceof Error ? err.message : 'Failed to delete pulse')
    } finally {
      setIsDeleting(false)
    }
  }

  const handleReplyCreated = (newPulse: Pulse) => {
    setShowReplyForm(false)
    // Add reply to local state
    setReplies(prev => [...prev, newPulse])
    setShowRepliesSection(true)
    if (onPulseCreated) {
      onPulseCreated(newPulse)
    }
  }

  const fetchReplies = useCallback(async () => {
    if (isLoadingReplies || replies.length > 0) return

    setIsLoadingReplies(true)
    try {
      const response = await fetch(`/api/pulses?parent_pulse_id=${pulse.id}&filter=active&per_page=100`, {
        credentials: 'include'
      })

      if (!response.ok) {
        throw new Error('Failed to load replies')
      }

      const data = await response.json()
      setReplies(data.pulses)
    } catch (err) {
      console.error('Failed to fetch replies:', err)
    } finally {
      setIsLoadingReplies(false)
    }
  }, [pulse.id, isLoadingReplies, replies.length])

  // Auto-load replies only at the first nesting level
  useEffect(() => {
    if (showReplies && pulse.splice_count > 0 && !showRepliesSection && nestLevel === 0) {
      setShowRepliesSection(true)
      fetchReplies()
    }
  }, [pulse.splice_count, nestLevel, showReplies, showRepliesSection, fetchReplies])

  const handleToggleReplies = () => {
    if (!showRepliesSection) {
      setShowRepliesSection(true)
      if (replies.length === 0) {
        fetchReplies()
      }
    } else {
      setShowRepliesSection(false)
    }
  }

  return (
    <div className={`pulse-card ${pulse.signal_dropped ? 'signal-dropped' : ''} ${pulse.is_splice ? 'is-splice' : ''}`}>
      <div className="pulse-header">
        <Link to={`/wire/${pulse.grid_hackr.hackr_alias}`} className="hackr-link">
          <span className="hackr-alias">@{pulse.grid_hackr.hackr_alias}</span>
          {pulse.grid_hackr.role === 'admin' && <span className="admin-badge">ADMIN</span>}
        </Link>
        <span className="pulse-timestamp">{formatTimestamp(pulse.pulsed_at)}</span>
      </div>

      <div className="pulse-content">
        {pulse.signal_dropped ? (
          <div className="signal-dropped-notice">
            <span className="glitch">[ SIGNAL DROPPED BY GOVCORP ]</span>
            {pulse.signal_dropped_at && (
              <div className="dropped-timestamp">
                Moderated: {formatTimestamp(pulse.signal_dropped_at)}
              </div>
            )}
          </div>
        ) : hasCodexLinks(pulse.content) ? (
          <p dangerouslySetInnerHTML={{ __html: transformHtmlLinks(pulse.content, undefined, 'codex-link') }} />
        ) : (
          <p>{pulse.content}</p>
        )}
      </div>

      {!pulse.signal_dropped && (
        <div className="pulse-actions">
          <EchoButton pulse={pulse} onEchoToggle={onEchoToggle} />

          {pulse.current_hackr_is_logged_in && (
            <button
              className="splice-button"
              onClick={() => setShowReplyForm(!showReplyForm)}
              title="Splice into thread"
            >
              <span className="splice-icon">↩</span>
              {pulse.splice_count > 0 && <span className="splice-count">{pulse.splice_count}</span>}
            </button>
          )}

          {showThread && pulse.thread_root_id && (
            <Link to={`/wire/pulse/${pulse.thread_root_id}`} className="thread-link">
              View thread
            </Link>
          )}

          {showThread && !pulse.is_splice && pulse.splice_count > 0 && showReplies && (
            <button
              onClick={handleToggleReplies}
              className="thread-link"
              style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
            >
              {showRepliesSection ? '▼' : '▶'} {pulse.splice_count} {pulse.splice_count === 1 ? 'reply' : 'replies'}
            </button>
          )}

          {showThread && !pulse.is_splice && pulse.splice_count > 0 && !showReplies && (
            <Link to={`/wire/pulse/${pulse.id}`} className="thread-link">
              View {pulse.splice_count} {pulse.splice_count === 1 ? 'reply' : 'replies'}
            </Link>
          )}

          {pulse.current_hackr_is_admin && (
            <button
              className="delete-button"
              onClick={handleDelete}
              disabled={isDeleting}
              title="Delete pulse"
            >
              ×
            </button>
          )}
        </div>
      )}

      {showReplyForm && (
        <div className="pulse-reply-form">
          <PulseComposer
            parentPulseId={pulse.id}
            placeholder={`Splice into ${pulse.grid_hackr.hackr_alias}'s pulse...`}
            onPulseCreated={handleReplyCreated}
            autoFocus
          />
        </div>
      )}

      {showRepliesSection && showReplies && (
        <div className="pulse-replies" style={{ marginTop: '15px' }}>
          {isLoadingReplies && (
            <div style={{ padding: '10px', color: '#888', fontSize: '0.9rem' }}>
              Loading replies...
            </div>
          )}
          {replies.map(reply => (
            <PulseCard
              key={reply.id}
              pulse={reply}
              showThread={showThread}
              showReplies={nestLevel < 2}
              nestLevel={nestLevel + 1}
              onEchoToggle={onEchoToggle}
              onPulseCreated={onPulseCreated}
              onPulseDeleted={onPulseDeleted}
            />
          ))}
        </div>
      )}
    </div>
  )
}
