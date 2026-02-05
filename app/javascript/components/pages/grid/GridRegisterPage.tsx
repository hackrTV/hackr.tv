import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'

export const GridRegisterPage: React.FC = () => {
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const { requestRegistration } = useGridAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await requestRegistration(email)

    if (result.success) {
      setSuccess(true)
    } else {
      setError(result.error || 'Failed to send verification email')
    }

    setLoading(false)
  }

  if (success) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: REGISTRATION</legend>

            <div className="center" style={{ margin: '30px 0' }}>
              <h1 className="green-255-text" style={{ fontSize: '2.5em', letterSpacing: '0.1em', margin: 0 }}>
                CHECK YOUR INBOX
              </h1>
              <p style={{ margin: '20px 0', fontSize: '1.2em', lineHeight: '1.6' }}>
                A verification link has been sent to<br />
                <span className="cyan-255-text" style={{ fontWeight: 'bold' }}>{email}</span>
              </p>
              <p style={{ margin: '20px 0', color: '#ccc' }}>
                Click the link in the email to complete your registration and join the Fracture Network.
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
          </fieldset>
        </div>
      </GridLayout>
    )
  }

  return (
    <GridLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">THE PULSE GRID :: REGISTRATION</legend>

          {error && (
            <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
              <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>ERROR</p>
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
              <label htmlFor="email" className="white-text" style={{ display: 'block', marginBottom: '8px', fontWeight: 'bold', letterSpacing: '0.05em' }}>
                EMAIL ADDRESS
              </label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="tui-input"
                placeholder="Enter your email"
                required
                autoFocus
                disabled={loading}
                style={{ width: '100%' }}
              />
              <small className="gray-text" style={{ display: 'block', marginTop: '5px' }}>
                We'll send you a verification link to complete registration.
              </small>
            </div>

            <div className="center" style={{ margin: '30px 0' }}>
              <button
                type="submit"
                className="tui-button purple-168"
                disabled={loading}
                style={{ fontSize: '1.1em', padding: '10px 30px' }}
              >
                {loading ? 'SENDING...' : 'SEND VERIFICATION'}
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
