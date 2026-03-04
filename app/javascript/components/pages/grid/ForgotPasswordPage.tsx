import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const { forgotPassword } = useGridAuthContext()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await forgotPassword(email)

    if (result.success) {
      setSuccess(true)
    } else {
      setError(result.error || 'Failed to send reset email')
    }

    setLoading(false)
  }

  if (success) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: RECOVERY</legend>

            <div className="center" style={{ margin: '30px 0' }}>
              <h1 className="green-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
                CHECK YOUR INBOX
              </h1>
              <p style={{ margin: '20px 0', fontSize: '1.2em', lineHeight: '1.6' }}>
                If an account exists for<br />
                <span className="cyan-255-text" style={{ fontWeight: 'bold' }}>{email}</span>
              </p>
              <p style={{ margin: '20px 0', color: '#ccc' }}>
                a password reset link has been sent. Click it to set a new password.
              </p>
              <p style={{ margin: '20px 0', color: '#bbb', fontSize: '0.9em' }}>
                The link expires in 24 hours.
              </p>
            </div>

            <hr style={{ borderColor: '#00ffff', margin: '30px 0' }} />

            <div className="center" style={{ margin: '20px 0' }}>
              <p className="white-text" style={{ marginBottom: '10px' }}>DIDN'T RECEIVE IT?</p>
              <button
                onClick={() => setSuccess(false)}
                className="tui-button purple-168"
              >
                TRY AGAIN
              </button>
            </div>

            <div className="center" style={{ margin: '20px 0' }}>
              <Link to="/grid/login" className="tui-button green-168">BACK TO LOGIN</Link>
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
          <legend className="center">THE PULSE GRID :: RECOVERY</legend>

          {error && (
            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>ERROR</p>
              <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
            </div>
          )}

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
              RECOVER ACCESS
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1.2em' }}>RESET YOUR CREDENTIALS</p>
          </div>

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '20px' }}>
              <label htmlFor="email" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                EMAIL ADDRESS
              </label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="tui-input"
                placeholder="Enter your registered email"
                required
                autoFocus
                disabled={loading}
                style={{ width: '100%' }}
              />
              <small className="gray-text" style={{ display: 'block', marginTop: '5px' }}>
                We'll send you a link to reset your password.
              </small>
            </div>

            <div className="center" style={{ margin: '30px 0' }}>
              <button
                type="submit"
                className="tui-button purple-168"
                disabled={loading}
                style={{ fontSize: '1.1em', padding: '10px 30px' }}
              >
                {loading ? 'SENDING...' : 'SEND RESET LINK'}
              </button>
            </div>
          </form>

          <hr style={{ borderColor: '#00ffff', margin: '30px 0' }} />

          <div className="center" style={{ margin: '20px 0' }}>
            <p className="white-text" style={{ marginBottom: '10px' }}>REMEMBER YOUR CREDENTIALS?</p>
            <Link to="/grid/login" className="tui-button green-168">BACK TO LOGIN</Link>
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}
