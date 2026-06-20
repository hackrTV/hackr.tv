import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useGridAuthContext } from '~/contexts/GridAuthContext'
import { BIO_MAX } from '~/types/profile'

export const IdentityPage: React.FC = () => {
  const { hackr } = useGridAuth()
  const { requestPasswordReset, requestEmailChange, updateProfile } = useGridAuthContext()
  const [message, setMessage] = useState<string | null>(null)
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [loading, setLoading] = useState(false)
  const [newEmail, setNewEmail] = useState('')
  const [emailLoading, setEmailLoading] = useState(false)
  const [emailMessage, setEmailMessage] = useState<string | null>(null)
  const [emailMessageType, setEmailMessageType] = useState<'success' | 'error'>('success')
  const [bio, setBio] = useState(hackr?.bio ?? '')
  const [bioSaving, setBioSaving] = useState(false)
  const [bioMessage, setBioMessage] = useState<string | null>(null)
  const [bioMessageType, setBioMessageType] = useState<'success' | 'error'>('success')

  // Sync local bio when the hackr loads or changes elsewhere.
  useEffect(() => {
    setBio(hackr?.bio ?? '')
  }, [hackr?.bio])

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

  const handleSaveBio = async (e: React.FormEvent) => {
    e.preventDefault()
    setBioSaving(true)
    setBioMessage(null)
    try {
      const result = await updateProfile(bio)
      if (result.success) {
        setBioMessageType('success')
        setBioMessage('Bio updated.')
      } else {
        setBioMessageType('error')
        setBioMessage(result.error || 'Failed to update bio.')
      }
    } catch {
      setBioMessageType('error')
      setBioMessage('Network error. Please try again.')
    } finally {
      setBioSaving(false)
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

          <form onSubmit={handleSaveBio} style={{ margin: '20px 0', padding: '15px', border: '1px solid #4a4a6a' }}>
            <p className="cyan-255-text" style={{ margin: '0 0 15px 0', fontWeight: 'bold', letterSpacing: '0.05em' }}>
              BIO
            </p>
            <textarea
              value={bio}
              onChange={(e) => setBio(e.target.value.slice(0, BIO_MAX))}
              placeholder="Broadcast a short bio to the WIRE. @mention other hackrs to link them."
              rows={4}
              disabled={bioSaving}
              className="tui-input"
              style={{ width: '100%', resize: 'vertical', fontFamily: '\'Courier New\', monospace' }}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '10px', flexWrap: 'wrap', gap: '10px' }}>
              <span style={{ color: bio.length >= BIO_MAX ? '#ff4444' : '#888', fontSize: '0.85em' }}>
                {bio.length}/{BIO_MAX}
              </span>
              <button
                type="submit"
                disabled={bioSaving}
                className="tui-button"
                style={{
                  background: '#00ff00',
                  color: '#0a0a0a',
                  border: 'none',
                  padding: '10px 20px',
                  fontFamily: '\'Courier New\', monospace',
                  fontWeight: 'bold',
                  cursor: bioSaving ? 'not-allowed' : 'pointer',
                  opacity: bioSaving ? 0.6 : 1
                }}
              >
                {bioSaving ? 'SAVING...' : 'SAVE BIO'}
              </button>
            </div>
            {bioMessage && (
              <p style={{ margin: '10px 0 0 0', color: bioMessageType === 'success' ? '#00ff00' : '#ff4444' }}>
                {bioMessage}
              </p>
            )}
          </form>

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
                  fontFamily: '\'Courier New\', monospace',
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

          <div style={{ margin: '20px 0', padding: '15px', border: '1px solid #4a4a6a' }}>
            <p className="cyan-255-text" style={{ margin: '0 0 15px 0', fontWeight: 'bold', letterSpacing: '0.05em' }}>
              TWO-FACTOR AUTHENTICATION
            </p>
            <p style={{ margin: '0 0 15px 0' }}>
              {hackr?.otp_enabled
                ? <span style={{ color: '#00ff00' }}>[ ACTIVE ]</span>
                : <span style={{ color: '#888' }}>[ INACTIVE ]</span>
              }
            </p>
            <Link
              to="/grid/identity/two-factor"
              className="tui-button"
              style={{
                background: '#00ff00',
                color: '#0a0a0a',
                border: 'none',
                padding: '10px 20px',
                fontFamily: '\'Courier New\', monospace',
                fontWeight: 'bold',
                textDecoration: 'none',
                display: 'inline-block'
              }}
            >
              MANAGE 2FA
            </Link>
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
              {loading ? 'SENDING...' : 'RESET CREDENTIALS'}
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
