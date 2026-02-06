import React, { useState } from 'react'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const IdentityPage: React.FC = () => {
  const { hackr } = useGridAuth()
  const { requestPasswordReset } = useGridAuthContext()
  const [message, setMessage] = useState<string | null>(null)
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [loading, setLoading] = useState(false)

  const handleChangePassword = async () => {
    setLoading(true)
    setMessage(null)
    try {
      const result = await requestPasswordReset()
      if (result.success) {
        setMessageType('success')
        setMessage(result.message || 'Password reset email sent. Check your inbox.')
      } else {
        setMessageType('error')
        setMessage(result.error || 'Failed to send password reset email.')
      }
    } catch {
      setMessageType('error')
      setMessage('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <GridLayout>
      <div className="tui-window white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block', background: '#1a1a2e', border: '1px solid #4a4a6a' }}>
        <fieldset style={{ borderColor: '#4a4a6a' }}>
          <legend className="center">IDENTITY</legend>

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
              IDENTITY
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.2em' }}>HACKR SETTINGS</p>
          </div>

          <div style={{ margin: '20px 0', padding: '15px', border: '1px solid #4a4a6a' }}>
            <p style={{ margin: '0 0 10px 0' }}>
              <span className="cyan-255-text">ALIAS:</span> {hackr?.hackr_alias}
            </p>
            <p style={{ margin: 0 }}>
              <span className="cyan-255-text">ROLE:</span> {hackr?.role}
            </p>
          </div>

          <div className="center" style={{ margin: '30px 0' }}>
            <button
              onClick={handleChangePassword}
              disabled={loading}
              className="tui-button"
              style={{
                background: '#00ff00',
                color: '#0a0a0a',
                border: 'none',
                padding: '10px 30px',
                fontFamily: '\'Courier New\', monospace',
                fontWeight: 'bold',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.6 : 1
              }}
            >
              {loading ? 'SENDING...' : 'CHANGE PASSWORD'}
            </button>

            {message && (
              <p style={{
                margin: '15px 0 0 0',
                color: messageType === 'success' ? '#00ff00' : '#ff4444'
              }}>
                {message}
              </p>
            )}
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}
