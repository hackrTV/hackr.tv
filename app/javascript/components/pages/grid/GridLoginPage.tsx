import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const GridLoginPage: React.FC = () => {
  const [hackrAlias, setHackrAlias] = useState('')
  const [password, setPassword] = useState('')
  const [totpCode, setTotpCode] = useState('')
  const [totpRequired, setTotpRequired] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const { login } = useGridAuth()
  const { verifyTotp } = useGridAuthContext()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await login(hackrAlias, password)

    if (result.requires_totp) {
      setTotpRequired(true)
    } else if (result.success) {
      navigate('/grid')
    } else {
      setError(result.error || 'Login failed')
    }

    setLoading(false)
  }

  const handleTotpSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await verifyTotp(totpCode)

    if (result.success) {
      navigate('/grid')
    } else {
      setError(result.error || 'Invalid code')
    }

    setLoading(false)
  }

  return (
    <GridLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">THE PULSE GRID :: ACCESS</legend>

          {error && (
            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>⚠ ERROR</p>
              <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
            </div>
          )}

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
              THE PULSE GRID
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.2em' }}>
              {totpRequired ? 'TWO-FACTOR VERIFICATION' : 'FRACTURE NETWORK LOGIN'}
            </p>
          </div>

          {totpRequired ? (
            <form onSubmit={handleTotpSubmit}>
              <div style={{ marginBottom: '20px' }}>
                <label htmlFor="totp_code" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                  AUTHENTICATION CODE
                </label>
                <input
                  type="text"
                  id="totp_code"
                  value={totpCode}
                  onChange={(e) => setTotpCode(e.target.value)}
                  className="tui-input"
                  placeholder="6-digit code or backup code"
                  maxLength={10}
                  autoComplete="one-time-code"
                  autoFocus
                  required
                  disabled={loading}
                  style={{ width: '100%' }}
                />
                <p style={{ margin: '8px 0 0 0', fontSize: '0.85em', color: '#888' }}>
                  Enter the code from your authenticator app, or a backup code.
                </p>
              </div>

              <div className="center" style={{ margin: '30px 0' }}>
                <button
                  type="submit"
                  className="tui-button purple-168"
                  disabled={loading}
                  style={{ fontSize: '1.1em', padding: '10px 30px' }}
                >
                  {loading ? 'VERIFYING...' : 'VERIFY'}
                </button>
              </div>
            </form>
          ) : (
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '20px' }}>
                <label htmlFor="hackr_alias" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                  HACKR ALIAS
                </label>
                <input
                  type="text"
                  id="hackr_alias"
                  value={hackrAlias}
                  onChange={(e) => setHackrAlias(e.target.value)}
                  className="tui-input"
                  placeholder="Enter your alias"
                  required
                  autoFocus
                  disabled={loading}
                  style={{ width: '100%' }}
                />
              </div>

              <div style={{ marginBottom: '20px' }}>
                <label htmlFor="password" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                  PASSWORD
                </label>
                <input
                  type="password"
                  id="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="tui-input"
                  placeholder="Enter password"
                  required
                  disabled={loading}
                  style={{ width: '100%' }}
                />
              </div>

              <div className="center" style={{ margin: '30px 0' }}>
                <button
                  type="submit"
                  className="tui-button purple-168"
                  disabled={loading}
                  style={{ fontSize: '1.1em', padding: '10px 30px' }}
                >
                  {loading ? 'CONNECTING...' : 'CONNECT'}
                </button>
              </div>
            </form>
          )}

          <hr style={{ borderColor: '#00ffff', margin: '30px 0' }} />

          <div className="center" style={{ margin: '20px 0' }}>
            <p className="white-text" style={{ marginBottom: '10px' }}>LOST YOUR CREDENTIALS?</p>
            <Link to="/grid/forgot_password" className="tui-button orange-168">RECOVER ACCESS</Link>
          </div>

          <hr style={{ borderColor: '#00ffff', margin: '30px 0' }} />

          <div className="center" style={{ margin: '20px 0' }}>
            <p className="white-text" style={{ marginBottom: '10px' }}>NEW TO THE FRACTURE NETWORK?</p>
            <Link to="/grid/register" className="tui-button green-168">REGISTER AS HACKR</Link>
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}
