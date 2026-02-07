import React, { useState } from 'react'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const IdentityPage: React.FC = () => {
  const { hackr } = useGridAuth()
  const { requestPasswordReset, requestEmailChange } = useGridAuthContext()
  const [message, setMessage] = useState<string | null>(null)
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [loading, setLoading] = useState(false)
  const [newEmail, setNewEmail] = useState('')
  const [emailLoading, setEmailLoading] = useState(false)
  const [emailMessage, setEmailMessage] = useState<string | null>(null)
  const [emailMessageType, setEmailMessageType] = useState<'success' | 'error'>('success')

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

  const handleChangeEmail = async (e: React.FormEvent) => {
    e.preventDefault()
    setEmailLoading(true)
    setEmailMessage(null)
    try {
      const result = await requestEmailChange(newEmail)
      if (result.success) {
        setEmailMessageType('success')
        setEmailMessage(result.message || 'Verification email sent. Check your inbox.')
        setNewEmail('')
      } else {
        setEmailMessageType('error')
        setEmailMessage(result.error || 'Failed to send verification email.')
      }
    } catch {
      setEmailMessageType('error')
      setEmailMessage('Network error. Please try again.')
    } finally {
      setEmailLoading(false)
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
            <p style={{ margin: '0 0 10px 0' }}>
              <span className="cyan-255-text">EMAIL:</span> {hackr?.email || 'N/A'}
            </p>
            <p style={{ margin: 0 }}>
              <span className="cyan-255-text">ROLE:</span> {hackr?.role}
            </p>
          </div>

          <div style={{ margin: '20px 0', padding: '15px', border: '1px solid #4a4a6a' }}>
            <p className="cyan-255-text" style={{ margin: '0 0 15px 0', fontWeight: 'bold', letterSpacing: '0.05em' }}>
              CHANGE EMAIL
            </p>
            <form onSubmit={handleChangeEmail} style={{ display: 'flex', gap: '10px', alignItems: 'flex-start', flexWrap: 'wrap' }}>
              <input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="New email address"
                required
                disabled={emailLoading}
                className="tui-input"
                style={{ flex: 1, minWidth: '200px' }}
              />
              <button
                type="submit"
                disabled={emailLoading}
                className="tui-button"
                style={{
                  background: '#00ff00',
                  color: '#0a0a0a',
                  border: 'none',
                  padding: '10px 20px',
                  fontFamily: "'Courier New', monospace",
                  fontWeight: 'bold',
                  cursor: emailLoading ? 'not-allowed' : 'pointer',
                  opacity: emailLoading ? 0.6 : 1
                }}
              >
                {emailLoading ? 'SENDING...' : 'CHANGE EMAIL'}
              </button>
            </form>
            {emailMessage && (
              <p style={{
                margin: '10px 0 0 0',
                color: emailMessageType === 'success' ? '#00ff00' : '#ff4444'
              }}>
                {emailMessage}
              </p>
            )}
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
                fontFamily: "'Courier New', monospace",
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
