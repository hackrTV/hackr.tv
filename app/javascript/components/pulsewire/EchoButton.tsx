import React, { useState } from 'react'
import type { Pulse } from '../../types/pulse'

interface EchoButtonProps {
  pulse: Pulse
  onEchoToggle?: (pulseId: number, newEchoCount: number, isEchoed: boolean) => void
}

export const EchoButton: React.FC<EchoButtonProps> = ({ pulse, onEchoToggle }) => {
  const [isEchoed, setIsEchoed] = useState(pulse.is_echoed_by_current_hackr)
  const [echoCount, setEchoCount] = useState(pulse.echo_count)
  const [isAnimating, setIsAnimating] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const handleEcho = async (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()

    if (isLoading) return

    setIsLoading(true)

    try {
      const response = await fetch(`/api/pulses/${pulse.id}/echo`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include'
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to echo pulse')
      }

      // Update local state
      const newEchoCount = data.echo_count
      const newIsEchoed = data.echoed

      setIsEchoed(newIsEchoed)
      setEchoCount(newEchoCount)

      // Trigger ripple animation
      if (newIsEchoed) {
        setIsAnimating(true)
        setTimeout(() => setIsAnimating(false), 600)
      }

      // Notify parent
      if (onEchoToggle) {
        onEchoToggle(pulse.id, newEchoCount, newIsEchoed)
      }
    } catch (err) {
      console.error('Echo error:', err)
      // Revert on error
      setIsEchoed(pulse.is_echoed_by_current_hackr)
      setEchoCount(pulse.echo_count)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <button
      className={`echo-button ${isEchoed ? 'echoed' : ''} ${isAnimating ? 'animating' : ''}`}
      onClick={handleEcho}
      disabled={isLoading}
      title={isEchoed ? 'Remove echo' : 'Echo this pulse'}
    >
      <span className="echo-icon">⟳</span>
      {echoCount > 0 && <span className="echo-count">{echoCount}</span>}
    </button>
  )
}
