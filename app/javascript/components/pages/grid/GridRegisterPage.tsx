import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'

export const GridRegisterPage: React.FC = () => {
  const [hackrAlias, setHackrAlias] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const { register } = useGridAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await register(hackrAlias, password, passwordConfirmation)

    if (result.success) {
      navigate('/grid')
    } else {
      setError(result.error || 'Registration failed')
    }

    setLoading(false)
  }

  return (
    <GridLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">THE PULSE GRID :: REGISTRATION</legend>

          {error && (
            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>⚠ ERROR</p>
              <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
            </div>
          )}

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
              REGISTER
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.2em' }}>JOIN THE FRACTURE NETWORK</p>
          </div>

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
                placeholder="Choose your alias"
                required
                autoFocus
                disabled={loading}
                style={{ width: '100%' }}
              />
              <small className="gray-text" style={{ display: 'block', marginTop: '5px' }}>
                This will be your identity in THE PULSE GRID.
              </small>
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
                placeholder="Enter secure password"
                required
                disabled={loading}
                style={{ width: '100%' }}
              />
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label htmlFor="password_confirmation" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                CONFIRM PASSWORD
              </label>
              <input
                type="password"
                id="password_confirmation"
                value={passwordConfirmation}
                onChange={(e) => setPasswordConfirmation(e.target.value)}
                className="tui-input"
                placeholder="Re-enter password"
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
                {loading ? 'JOINING...' : 'JOIN GRID'}
              </button>
            </div>
          </form>

          <hr style={{ borderColor: '#00ffff', margin: '30px 0' }} />

          <div className="center" style={{ margin: '20px 0' }}>
            <p className="white-text" style={{ marginBottom: '10px' }}>ALREADY REGISTERED?</p>
            <Link to="/grid/login" className="tui-button green-168">LOG IN</Link>
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}
