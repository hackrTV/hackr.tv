import React, { useState } from 'react'
import { useParams } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const ResetPasswordPage: React.FC = () => {
  const { token } = useParams<{ token: string }>()
  const { resetPassword } = useGridAuthContext()
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [message, setMessage] = useState<string | null>(null)
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [loading, setLoading] = useState(false)
  const [completed, setCompleted] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!token) return

    setLoading(true)
    setMessage(null)
    try {
      const result = await resetPassword(token, password, passwordConfirmation)
      if (result.success) {
        setMessageType('success')
        setMessage(result.message || 'Password updated successfully.')
        setCompleted(true)
      } else {
        setMessageType('error')
        setMessage(result.error || 'Password reset failed.')
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
          <legend className="center">PASSWORD RESET</legend>

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
              RESET PASSWORD
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.2em' }}>ENTER NEW CREDENTIALS</p>
          </div>

          {completed ? (
            <div className="center" style={{ margin: '30px 0' }}>
              <p style={{ color: '#00ff00', fontSize: '1.1em' }}>{message}</p>
              <a
                href="/grid"
                style={{
                  display: 'inline-block',
                  marginTop: '20px',
                  background: '#00ff00',
                  color: '#0a0a0a',
                  padding: '10px 30px',
                  textDecoration: 'none',
                  fontFamily: "'Courier New', monospace",
                  fontWeight: 'bold'
                }}
              >
                RETURN TO GRID
              </a>
            </div>
          ) : (
            <form onSubmit={handleSubmit} style={{ margin: '20px 0' }}>
              <div style={{ margin: '0 0 15px 0' }}>
                <label style={{ display: 'block', marginBottom: '5px' }}>
                  <span className="cyan-255-text">NEW PASSWORD:</span>
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  minLength={8}
                  style={{
                    width: '100%',
                    background: '#0a0a1e',
                    border: '1px solid #4a4a6a',
                    color: '#00ff00',
                    padding: '8px',
                    fontFamily: "'Courier New', monospace",
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              <div style={{ margin: '0 0 20px 0' }}>
                <label style={{ display: 'block', marginBottom: '5px' }}>
                  <span className="cyan-255-text">CONFIRM PASSWORD:</span>
                </label>
                <input
                  type="password"
                  value={passwordConfirmation}
                  onChange={e => setPasswordConfirmation(e.target.value)}
                  required
                  minLength={8}
                  style={{
                    width: '100%',
                    background: '#0a0a1e',
                    border: '1px solid #4a4a6a',
                    color: '#00ff00',
                    padding: '8px',
                    fontFamily: "'Courier New', monospace",
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              <div className="center">
                <button
                  type="submit"
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
                  {loading ? 'RESETTING...' : 'RESET PASSWORD'}
                </button>
              </div>

              {message && (
                <p className="center" style={{
                  margin: '15px 0 0 0',
                  color: messageType === 'success' ? '#00ff00' : '#ff4444'
                }}>
                  {message}
                </p>
              )}
            </form>
          )}
        </fieldset>
      </div>
    </GridLayout>
  )
}
