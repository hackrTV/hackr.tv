import React, { useState, useEffect } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'

export const GridVerifyPage: React.FC = () => {
  const { token } = useParams<{ token: string }>()
  const navigate = useNavigate()
  const { verifyToken, completeRegistration } = useGridAuth()

  const [email, setEmail] = useState<string | null>(null)
  const [hackrAlias, setHackrAlias] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [tokenValid, setTokenValid] = useState(false)

  useEffect(() => {
    const checkToken = async () => {
      if (!token) {
        setError('No verification token provided.')
        setLoading(false)
        return
      }

      const result = await verifyToken(token)

      if (result.valid && result.email) {
        setTokenValid(true)
        setEmail(result.email)
      } else {
        setError(result.error || 'Invalid verification link.')
      }

      setLoading(false)
    }

    checkToken()
  }, [token, verifyToken])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!token) return

    setError(null)
    setSubmitting(true)

    const result = await completeRegistration(token, hackrAlias, password, passwordConfirmation)

    if (result.success) {
      navigate('/grid')
    } else {
      setError(result.error || 'Registration failed')
    }

    setSubmitting(false)
  }

  if (loading) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: VERIFICATION</legend>
            <div className="center" style={{ margin: '50px 0' }}>
              <p style={{ fontSize: '1.2em' }}>VERIFYING TOKEN...</p>
            </div>
          </fieldset>
        </div>
      </GridLayout>
    )
  }

  if (!tokenValid) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: VERIFICATION</legend>

            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>VERIFICATION FAILED</p>
              <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
            </div>

            <div className="center" style={{ margin: '30px 0' }}>
              <p style={{ margin: '20px 0', color: '#999' }}>
                The verification link may have expired or already been used.
              </p>
              <Link to="/grid/register" className="tui-button purple-168">
                REGISTER AGAIN
              </Link>
            </div>
          </fieldset>
        </div>
      </GridLayout>
    )
  }

  return (
    <GridLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">THE PULSE GRID :: COMPLETE REGISTRATION</legend>

          {error && (
            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>ERROR</p>
              <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
            </div>
          )}

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2em', letterSpacing: '0.1em', margin: 0 }}>
              ALMOST THERE
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.1em' }}>
              Email verified: <span className="green-255-text">{email}</span>
            </p>
            <p style={{ margin: '10px 0', color: '#ccc' }}>
              Choose your alias and set a password to complete registration.
            </p>
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
                disabled={submitting}
                style={{ width: '100%' }}
              />
              <small className="gray-text" style={{ display: 'block', marginTop: '5px' }}>
                This will be your identity in THE PULSE GRID.<br />Minimum 6 characters.
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
                disabled={submitting}
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
                disabled={submitting}
                style={{ width: '100%' }}
              />
            </div>

            <div className="center" style={{ margin: '30px 0' }}>
              <button
                type="submit"
                className="tui-button purple-168"
                disabled={submitting}
                style={{ fontSize: '1.1em', padding: '10px 30px' }}
              >
                {submitting ? 'JOINING...' : 'JOIN GRID'}
              </button>
            </div>
          </form>
        </fieldset>
      </div>
    </GridLayout>
  )
}
