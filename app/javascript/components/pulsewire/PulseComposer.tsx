import React, { useState, useRef, useEffect } from 'react'
import type { Pulse } from '../../types/pulse'

interface PulseComposerProps {
  onPulseCreated?: (pulse: Pulse) => void
  parentPulseId?: number | null
  placeholder?: string
  autoFocus?: boolean
}

export const PulseComposer: React.FC<PulseComposerProps> = ({
  onPulseCreated,
  parentPulseId = null,
  placeholder = 'Broadcast on the WIRE...',
  autoFocus = false
}) => {
  const [content, setContent] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const charLimit = 256
  const charsRemaining = charLimit - content.length
  const isOverLimit = charsRemaining < 0

  useEffect(() => {
    if (autoFocus && textareaRef.current) {
      textareaRef.current.focus()
    }
  }, [autoFocus])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!content.trim() || isOverLimit || isSubmitting) {
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      const response = await fetch('/api/pulses', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({
          pulse: {
            content: content.trim(),
            parent_pulse_id: parentPulseId
          }
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to broadcast pulse')
      }

      // Success - clear form and notify parent
      setContent('')
      if (onPulseCreated && data.pulse) {
        onPulseCreated(data.pulse)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to broadcast pulse')
      console.error('PulseComposer error:', err)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    // Cmd/Ctrl + Enter to submit
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault()
      const formEvent = new Event('submit', { bubbles: true, cancelable: true })
      e.currentTarget.form?.dispatchEvent(formEvent)
    }
  }

  return (
    <div className="pulse-composer">
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <textarea
            ref={textareaRef}
            className="form-control pulse-input"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            rows={3}
            disabled={isSubmitting}
            maxLength={charLimit + 50} // Allow typing beyond limit to show error
          />
          <div className="pulse-composer-footer">
            <span className={`char-count ${isOverLimit ? 'over-limit' : charsRemaining < 20 ? 'warning' : ''}`}>
              {charsRemaining} / {charLimit}
            </span>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={!content.trim() || isOverLimit || isSubmitting}
            >
              {isSubmitting ? 'Broadcasting...' : parentPulseId ? 'Splice' : 'Broadcast'}
            </button>
          </div>
        </div>
        {error && (
          <div className="alert alert-error">
            {error}
          </div>
        )}
      </form>
    </div>
  )
}
