import React, { useState, useEffect, useRef } from 'react'
import { Link, useParams } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

export const GridConfirmEmailChangePage: React.FC = () => {
  const { token } = useParams<{ token: string }>()
  const { confirmEmailChange, checkAuth } = useGridAuthContext()

  const [loading, setLoading] = useState(true)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const hasConfirmed = useRef(false)

  useEffect(() => {
    if (hasConfirmed.current) return
    hasConfirmed.current = true

    const confirm = async () => {
      if (!token) {
        setError('No verification token provided.')
        setLoading(false)
        return
      }

      const result = await confirmEmailChange(token)

      if (result.success) {
        setSuccess(true)
        await checkAuth()
      } else {
        setError(result.error || 'Email change confirmation failed.')
      }

      setLoading(false)
    }

    confirm()
  }, [token, confirmEmailChange])

  if (loading) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: EMAIL CHANGE</legend>
            <div className="center" style={{ margin: '50px 0' }}>
              <p style={{ fontSize: '1.2em' }}>CONFIRMING EMAIL CHANGE...</p>
            </div>
          </fieldset>
        </div>
      </GridLayout>
    )
  }

  if (success) {
    return (
      <GridLayout>
        <div className="tui-window cyan-168 white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block' }}>
          <fieldset className="cyan-168-border">
            <legend className="center">THE PULSE GRID :: EMAIL CHANGE</legend>

            <div className="center" style={{ margin: '30px 0' }}>
              <h1 className="green-255-text" style={{ fontSize: '2em', letterSpacing: '0.1em', margin: 0 }}>
                EMAIL UPDATED
              </h1>
              <p style={{ margin: '15px 0', color: '#ccc' }}>
                Your email address has been changed successfully.
              </p>
              <Link to="/grid/identity" className="tui-button purple-168" style={{ marginTop: '10px' }}>
                BACK TO IDENTITY
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
          <legend className="center">THE PULSE GRID :: EMAIL CHANGE</legend>

          <div style={{ background: '#330000', border: '2px solid #ff0000', padding: '15px', margin: '20px 0', borderRadius: '4px' }}>
            <p className="red-255-text" style={{ margin: 0, fontWeight: 'bold' }}>VERIFICATION FAILED</p>
            <p className="white-text" style={{ margin: '5px 0 0 0' }}>{error}</p>
          </div>

          <div className="center" style={{ margin: '30px 0' }}>
            <p style={{ margin: '20px 0', color: '#999' }}>
              The verification link may have expired or already been used.
            </p>
            <Link to="/grid/identity" className="tui-button purple-168">
              BACK TO IDENTITY
            </Link>
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}
