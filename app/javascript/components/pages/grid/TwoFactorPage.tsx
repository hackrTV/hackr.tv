import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuthContext } from '~/contexts/GridAuthContext'

type Phase = 'loading' | 'disabled' | 'setup' | 'confirm' | 'backup_codes' | 'enabled' | 'disable' | 'regenerate'

export const TwoFactorPage: React.FC = () => {
  const { hackr, totpSetup, totpEnable, totpDisable, totpStatus, checkAuth, regenerateBackupCodes } = useGridAuthContext()

  const [phase, setPhase] = useState<Phase>('loading')
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  // Setup phase state
  const [secret, setSecret] = useState('')
  const [qrSvg, setQrSvg] = useState('')
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')

  // Backup codes (shown once)
  const [backupCodes, setBackupCodes] = useState<string[]>([])
  const [backupCodesRemaining, setBackupCodesRemaining] = useState(0)

  // Disable phase state
  const [disablePassword, setDisablePassword] = useState('')
  const [disableCode, setDisableCode] = useState('')

  // Regenerate phase state
  const [regenPassword, setRegenPassword] = useState('')
  const [regenCode, setRegenCode] = useState('')

  useEffect(() => {
    totpStatus().then(status => {
      if (status.enabled) {
        setBackupCodesRemaining(status.backup_codes_remaining)
        setPhase('enabled')
      } else {
        setPhase('disabled')
      }
    })
  }, [totpStatus])

  const handleSetup = async () => {
    setError(null)
    setLoading(true)

    const result = await totpSetup()
    if (result.success && result.secret && result.qr_svg) {
      setSecret(result.secret)
      setQrSvg(result.qr_svg)
      setPhase('setup')
    } else {
      setError(result.error || 'Setup failed.')
    }

    setLoading(false)
  }

  const handleEnable = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await totpEnable(password, secret, code)
    if (result.success && result.backup_codes) {
      setBackupCodes(result.backup_codes)
      setPhase('backup_codes')
      setPassword('')
      setCode('')
    } else {
      setError(result.error || 'Enable failed.')
    }

    setLoading(false)
  }

  const handleBackupCodesSaved = async () => {
    setBackupCodes([])
    await checkAuth()
    const status = await totpStatus()
    setBackupCodesRemaining(status.backup_codes_remaining)
    setPhase('enabled')
  }

  const handleDisable = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await totpDisable(disablePassword, disableCode)
    if (result.success) {
      setMessage('Two-factor authentication disabled.')
      setDisablePassword('')
      setDisableCode('')
      await checkAuth()
      setPhase('disabled')
    } else {
      setError(result.error || 'Disable failed.')
    }

    setLoading(false)
  }

  const handleRegenerate = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const result = await regenerateBackupCodes(regenPassword, regenCode)
    if (result.success && result.backup_codes) {
      setBackupCodes(result.backup_codes)
      setRegenPassword('')
      setRegenCode('')
      setPhase('backup_codes')
    } else {
      setError(result.error || 'Regeneration failed.')
    }

    setLoading(false)
  }

  return (
    <GridLayout>
      <div className="tui-window white-text" style={{ maxWidth: '600px', margin: '50px auto', display: 'block', background: '#1a1a2e', border: '1px solid #4a4a6a' }}>
        <fieldset style={{ borderColor: '#4a4a6a' }}>
          <legend className="center">TWO-FACTOR AUTH</legend>

          <div className="center" style={{ margin: '30px 0' }}>
            <h1 className="cyan-255-text" style={{ fontSize: '2em', letterSpacing: '0.1em', margin: 0 }}>
              TWO-FACTOR AUTHENTICATION
            </h1>
            <p style={{ margin: '10px 0', fontSize: '1em' }}>
              HACKR: {hackr?.hackr_alias}
            </p>
          </div>

          {error && (
            <div style={{ background: '#330000', border: '1px solid #ff4444', padding: '10px', margin: '0 0 20px 0' }}>
              <p style={{ margin: 0, color: '#ff4444' }}>{error}</p>
            </div>
          )}

          {message && (
            <p style={{ color: '#00ff00', margin: '0 0 20px 0' }}>{message}</p>
          )}

          {/* --- LOADING --- */}
          {phase === 'loading' && (
            <div className="center" style={{ padding: '30px 0' }}>
              <p>Loading 2FA status...</p>
            </div>
          )}

          {/* --- DISABLED: Show enable button --- */}
          {phase === 'disabled' && (
            <div style={{ padding: '15px', border: '1px solid #4a4a6a', margin: '20px 0' }}>
              <p style={{ margin: '0 0 15px 0' }}>
                <span className="cyan-255-text">STATUS:</span> INACTIVE
              </p>
              <p style={{ margin: '0 0 20px 0', color: '#aaa', fontSize: '0.9em' }}>
                Add an extra layer of security to your account. You will need an authenticator app
                (Google Authenticator, Authy, or similar).
              </p>
              <div className="center">
                <button
                  onClick={handleSetup}
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
                  {loading ? 'GENERATING...' : 'ENABLE TWO-FACTOR AUTH'}
                </button>
              </div>
            </div>
          )}

          {/* --- SETUP: Show QR code and secret --- */}
          {phase === 'setup' && (
            <div style={{ padding: '15px', border: '1px solid #4a4a6a', margin: '20px 0' }}>
              <p className="cyan-255-text" style={{ margin: '0 0 15px 0', fontWeight: 'bold' }}>
                STEP 1: SCAN QR CODE
              </p>
              <p style={{ margin: '0 0 15px 0', color: '#aaa', fontSize: '0.9em' }}>
                Scan this QR code with your authenticator app:
              </p>

              <div className="center" style={{ margin: '20px 0', background: '#fff', padding: '15px', display: 'inline-block' }}>
                <div dangerouslySetInnerHTML={{ __html: qrSvg }} style={{ lineHeight: 0 }} />
              </div>

              <p style={{ margin: '20px 0 5px 0', color: '#aaa', fontSize: '0.85em' }}>
                Or enter this secret manually:
              </p>
              <div style={{ background: '#0a0a1a', padding: '10px', border: '1px solid #4a4a6a', fontFamily: '\'Courier New\', monospace', letterSpacing: '0.15em', wordBreak: 'break-all' }}>
                {secret}
              </div>

              <p className="cyan-255-text" style={{ margin: '25px 0 15px 0', fontWeight: 'bold' }}>
                STEP 2: VERIFY CODE
              </p>

              <form onSubmit={handleEnable}>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="2fa_password" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    CONFIRM PASSWORD
                  </label>
                  <input
                    type="password"
                    id="2fa_password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="tui-input"
                    placeholder="Enter your password"
                    required
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="2fa_code" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    AUTHENTICATOR CODE
                  </label>
                  <input
                    type="text"
                    id="2fa_code"
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    className="tui-input"
                    placeholder="6-digit code"
                    maxLength={6}
                    autoComplete="one-time-code"
                    required
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div className="center" style={{ margin: '20px 0' }}>
                  <button
                    type="submit"
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
                    {loading ? 'VERIFYING...' : 'ACTIVATE 2FA'}
                  </button>
                  <button
                    type="button"
                    onClick={() => { setPhase('disabled'); setError(null) }}
                    style={{
                      background: 'transparent',
                      color: '#888',
                      border: '1px solid #4a4a6a',
                      padding: '10px 20px',
                      fontFamily: '\'Courier New\', monospace',
                      cursor: 'pointer',
                      marginLeft: '10px'
                    }}
                  >
                    CANCEL
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* --- BACKUP CODES: Show once after enable --- */}
          {phase === 'backup_codes' && (
            <div style={{ padding: '15px', border: '1px solid #4a4a6a', margin: '20px 0' }}>
              <div style={{ background: '#331100', border: '1px solid #ff8800', padding: '10px', marginBottom: '20px' }}>
                <p style={{ margin: 0, color: '#ff8800', fontWeight: 'bold' }}>
                  ⚠ SAVE THESE BACKUP CODES — SHOWN ONCE ONLY
                </p>
                <p style={{ margin: '5px 0 0 0', color: '#ffaa44', fontSize: '0.85em' }}>
                  If you lose access to your authenticator app, use these codes to log in.
                  Each code can only be used once.
                </p>
              </div>

              <div style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '8px',
                background: '#0a0a1a',
                padding: '15px',
                border: '1px solid #4a4a6a',
                fontFamily: '\'Courier New\', monospace',
                fontSize: '1.1em',
                letterSpacing: '0.1em'
              }}>
                {backupCodes.map((code, i) => (
                  <div key={i} style={{ padding: '5px 0' }}>
                    {code}
                  </div>
                ))}
              </div>

              <div className="center" style={{ margin: '25px 0 10px 0' }}>
                <button
                  onClick={handleBackupCodesSaved}
                  className="tui-button"
                  style={{
                    background: '#00ff00',
                    color: '#0a0a0a',
                    border: 'none',
                    padding: '10px 30px',
                    fontFamily: '\'Courier New\', monospace',
                    fontWeight: 'bold',
                    cursor: 'pointer'
                  }}
                >
                  I HAVE SAVED THESE CODES
                </button>
              </div>
            </div>
          )}

          {/* --- ENABLED: Show status + disable option --- */}
          {phase === 'enabled' && (
            <div style={{ padding: '15px', border: '1px solid #4a4a6a', margin: '20px 0' }}>
              <p style={{ margin: '0 0 10px 0' }}>
                <span className="cyan-255-text">STATUS:</span>{' '}
                <span style={{ color: '#00ff00' }}>ACTIVE</span>
              </p>
              <p style={{ margin: '0 0 20px 0' }}>
                <span className="cyan-255-text">BACKUP CODES REMAINING:</span> {backupCodesRemaining}
              </p>

              <div className="center" style={{ display: 'flex', gap: '10px', justifyContent: 'center', flexWrap: 'wrap' }}>
                <button
                  onClick={() => { setPhase('regenerate'); setError(null); setMessage(null) }}
                  style={{
                    background: 'transparent',
                    color: '#00ffff',
                    border: '1px solid #00ffff',
                    padding: '10px 20px',
                    fontFamily: '\'Courier New\', monospace',
                    fontWeight: 'bold',
                    cursor: 'pointer'
                  }}
                >
                  REGENERATE BACKUP CODES
                </button>
                <button
                  onClick={() => { setPhase('disable'); setError(null); setMessage(null) }}
                  style={{
                    background: 'transparent',
                    color: '#ff4444',
                    border: '1px solid #ff4444',
                    padding: '10px 20px',
                    fontFamily: '\'Courier New\', monospace',
                    fontWeight: 'bold',
                    cursor: 'pointer'
                  }}
                >
                  DISABLE TWO-FACTOR AUTH
                </button>
              </div>
            </div>
          )}

          {/* --- REGENERATE: Password + TOTP confirmation --- */}
          {phase === 'regenerate' && (
            <div style={{ padding: '15px', border: '1px solid #00ffff', margin: '20px 0' }}>
              <p className="cyan-255-text" style={{ margin: '0 0 10px 0', fontWeight: 'bold' }}>
                REGENERATE BACKUP CODES
              </p>
              <p style={{ margin: '0 0 15px 0', color: '#aaa', fontSize: '0.9em' }}>
                This will invalidate all existing backup codes and generate 8 new ones.
              </p>
              <form onSubmit={handleRegenerate}>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="regen_password" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    PASSWORD
                  </label>
                  <input
                    type="password"
                    id="regen_password"
                    value={regenPassword}
                    onChange={(e) => setRegenPassword(e.target.value)}
                    className="tui-input"
                    placeholder="Enter your password"
                    required
                    autoFocus
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="regen_code" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    AUTHENTICATOR CODE
                  </label>
                  <input
                    type="text"
                    id="regen_code"
                    value={regenCode}
                    onChange={(e) => setRegenCode(e.target.value)}
                    className="tui-input"
                    placeholder="6-digit code"
                    maxLength={6}
                    autoComplete="one-time-code"
                    required
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div className="center" style={{ margin: '20px 0' }}>
                  <button
                    type="submit"
                    disabled={loading}
                    className="tui-button"
                    style={{
                      background: '#00ffff',
                      color: '#0a0a0a',
                      border: 'none',
                      padding: '10px 30px',
                      fontFamily: '\'Courier New\', monospace',
                      fontWeight: 'bold',
                      cursor: loading ? 'not-allowed' : 'pointer',
                      opacity: loading ? 0.6 : 1
                    }}
                  >
                    {loading ? 'REGENERATING...' : 'REGENERATE CODES'}
                  </button>
                  <button
                    type="button"
                    onClick={() => { setPhase('enabled'); setError(null) }}
                    style={{
                      background: 'transparent',
                      color: '#888',
                      border: '1px solid #4a4a6a',
                      padding: '10px 20px',
                      fontFamily: '\'Courier New\', monospace',
                      cursor: 'pointer',
                      marginLeft: '10px'
                    }}
                  >
                    CANCEL
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* --- DISABLE: Password + TOTP confirmation --- */}
          {phase === 'disable' && (
            <div style={{ padding: '15px', border: '1px solid #ff4444', margin: '20px 0' }}>
              <p className="cyan-255-text" style={{ margin: '0 0 15px 0', fontWeight: 'bold' }}>
                DISABLE TWO-FACTOR AUTHENTICATION
              </p>
              <form onSubmit={handleDisable}>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="disable_password" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    PASSWORD
                  </label>
                  <input
                    type="password"
                    id="disable_password"
                    value={disablePassword}
                    onChange={(e) => setDisablePassword(e.target.value)}
                    className="tui-input"
                    placeholder="Enter your password"
                    required
                    autoFocus
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div style={{ marginBottom: '15px' }}>
                  <label htmlFor="disable_code" className="white-text" style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', fontSize: '0.9em' }}>
                    AUTHENTICATOR CODE
                  </label>
                  <input
                    type="text"
                    id="disable_code"
                    value={disableCode}
                    onChange={(e) => setDisableCode(e.target.value)}
                    className="tui-input"
                    placeholder="6-digit code"
                    maxLength={6}
                    autoComplete="one-time-code"
                    required
                    disabled={loading}
                    style={{ width: '100%' }}
                  />
                </div>
                <div className="center" style={{ margin: '20px 0' }}>
                  <button
                    type="submit"
                    disabled={loading}
                    style={{
                      background: '#ff4444',
                      color: '#fff',
                      border: 'none',
                      padding: '10px 30px',
                      fontFamily: '\'Courier New\', monospace',
                      fontWeight: 'bold',
                      cursor: loading ? 'not-allowed' : 'pointer',
                      opacity: loading ? 0.6 : 1
                    }}
                  >
                    {loading ? 'DISABLING...' : 'CONFIRM DISABLE'}
                  </button>
                  <button
                    type="button"
                    onClick={() => { setPhase('enabled'); setError(null) }}
                    style={{
                      background: 'transparent',
                      color: '#888',
                      border: '1px solid #4a4a6a',
                      padding: '10px 20px',
                      fontFamily: '\'Courier New\', monospace',
                      cursor: 'pointer',
                      marginLeft: '10px'
                    }}
                  >
                    CANCEL
                  </button>
                </div>
              </form>
            </div>
          )}

          <div className="center" style={{ margin: '20px 0' }}>
            <Link to="/grid/identity" style={{ color: '#00ffff' }}>← BACK TO IDENTITY</Link>
          </div>
        </fieldset>
      </div>
    </GridLayout>
  )
}

export default TwoFactorPage
