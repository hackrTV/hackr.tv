import React, { useState, useRef, useEffect } from 'react'

interface PacketInputProps {
  onSubmit: (content: string) => Promise<{ success: boolean; error?: string; wait_seconds?: number }>
  disabled?: boolean
  slowModeSeconds?: number
  placeholder?: string
}

export const PacketInput: React.FC<PacketInputProps> = ({
  onSubmit,
  disabled = false,
  slowModeSeconds = 0,
  placeholder = 'Transmit a packet...'
}) => {
  const [content, setContent] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [cooldown, setCooldown] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const cooldownRef = useRef<number | null>(null)

  const MAX_LENGTH = 512

  // Clear cooldown timer on unmount
  useEffect(() => {
    return () => {
      if (cooldownRef.current) {
        window.clearInterval(cooldownRef.current)
      }
    }
  }, [])

  const startCooldown = (seconds: number) => {
    setCooldown(seconds)

    if (cooldownRef.current) {
      window.clearInterval(cooldownRef.current)
    }

    cooldownRef.current = window.setInterval(() => {
      setCooldown(prev => {
        if (prev <= 1) {
          if (cooldownRef.current) {
            window.clearInterval(cooldownRef.current)
          }
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!content.trim() || isSubmitting || disabled || cooldown > 0) {
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      const result = await onSubmit(content.trim())

      if (result.success) {
        setContent('')
        if (slowModeSeconds > 0) {
          startCooldown(slowModeSeconds)
        }
        inputRef.current?.focus()
      } else {
        setError(result.error || 'Failed to send packet')
        if (result.wait_seconds) {
          startCooldown(result.wait_seconds)
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send packet')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSubmit(e)
    }
  }

  const charCount = content.length
  const isOverLimit = charCount > MAX_LENGTH
  const isNearLimit = charCount > MAX_LENGTH * 0.9

  return (
    <div className="packet-input" style={{ padding: '12px', backgroundColor: '#111' }}>
      {error && (
        <div
          style={{
            padding: '8px 12px',
            marginBottom: '8px',
            backgroundColor: 'rgba(255, 0, 0, 0.1)',
            border: '1px solid #ff5555',
            color: '#ff5555',
            fontSize: '0.85rem'
          }}
        >
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
        <div style={{ flex: 1, position: 'relative' }}>
          <input
            ref={inputRef}
            type="text"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={disabled ? 'Log in to transmit' : placeholder}
            disabled={disabled || isSubmitting || cooldown > 0}
            maxLength={MAX_LENGTH + 10} // Allow slight overflow for UX, validate on submit
            style={{
              width: '100%',
              padding: '10px 12px',
              paddingRight: '60px',
              backgroundColor: '#0a0a0a',
              border: `1px solid ${isOverLimit ? '#ff5555' : '#333'}`,
              color: '#ccc',
              fontFamily: 'Terminus, monospace',
              fontSize: '0.9rem',
              outline: 'none'
            }}
          />

          <span
            style={{
              position: 'absolute',
              right: '10px',
              top: '50%',
              transform: 'translateY(-50%)',
              fontSize: '0.7rem',
              color: isOverLimit ? '#ff5555' : isNearLimit ? '#ffaa00' : '#555'
            }}
          >
            {charCount}/{MAX_LENGTH}
          </span>
        </div>

        <button
          type="submit"
          disabled={disabled || isSubmitting || isOverLimit || !content.trim() || cooldown > 0}
          style={{
            padding: '10px 20px',
            backgroundColor: cooldown > 0 ? '#333' : '#7c3aed',
            border: 'none',
            color: cooldown > 0 ? '#666' : '#fff',
            fontFamily: 'Terminus, monospace',
            fontSize: '0.85rem',
            cursor: disabled || isSubmitting || isOverLimit || !content.trim() || cooldown > 0
              ? 'not-allowed'
              : 'pointer',
            opacity: disabled || isSubmitting || isOverLimit || !content.trim() ? 0.5 : 1,
            transition: 'background-color 0.2s'
          }}
        >
          {cooldown > 0 ? `${cooldown}s` : isSubmitting ? '...' : 'TX'}
        </button>
      </form>

      {slowModeSeconds > 0 && (
        <div
          style={{
            marginTop: '4px',
            fontSize: '0.7rem',
            color: '#555',
            textAlign: 'right'
          }}
        >
          Slow mode: {slowModeSeconds}s between packets
        </div>
      )}
    </div>
  )
}
