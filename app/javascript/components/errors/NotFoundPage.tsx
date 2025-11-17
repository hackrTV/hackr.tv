import React from 'react'
import { Link } from 'react-router-dom'

export const NotFoundPage: React.FC = () => {
  return (
    <div className="tui-window cyan-255-border" style={{ margin: '2rem auto', maxWidth: '800px' }}>
      <fieldset className="tui-fieldset">
        <legend>404 NOT FOUND</legend>
        <div style={{ padding: '2rem', textAlign: 'center' }}>
          <pre style={{ fontSize: '1.5em', marginBottom: '1.5rem' }}>
            {`    ___   ___   ___
   /   \\ /   \\ /   \\
  | 4 | | 0 | | 4 |
   \\___/ \\___/ \\___/`}
          </pre>

          <p className="cyan-255-text" style={{ marginBottom: '1rem', fontSize: '1.2em' }}>
            <strong>SIGNAL LOST</strong>
          </p>

          <p style={{ marginBottom: '2rem' }}>
            The requested resource could not be found in the grid.
            <br />
            It may have been moved, deleted, or never existed.
          </p>

          <div className="tui-divider"></div>

          <p style={{ margin: '2rem 0 1rem 0' }}>
            <strong>SUGGESTED ACTIONS:</strong>
          </p>

          <div style={{ textAlign: 'left', maxWidth: '500px', margin: '0 auto' }}>
            <ul style={{ listStyle: 'none', padding: 0 }}>
              <li style={{ marginBottom: '0.5rem' }}>
                <Link to="/" className="cyan-255-text">
                  → Return to Home
                </Link>
              </li>
              <li style={{ marginBottom: '0.5rem' }}>
                <Link to="/fm/pulse-vault" className="cyan-255-text">
                  → Browse Pulse Vault
                </Link>
              </li>
              <li style={{ marginBottom: '0.5rem' }}>
                <Link to="/fm/radio" className="cyan-255-text">
                  → Listen to Radio
                </Link>
              </li>
              <li style={{ marginBottom: '0.5rem' }}>
                <Link to="/grid" className="cyan-255-text">
                  → Enter THE PULSE GRID
                </Link>
              </li>
            </ul>
          </div>

          <div className="tui-divider" style={{ marginTop: '2rem' }}></div>

          <p style={{ marginTop: '1.5rem', fontSize: '0.85em', opacity: 0.7 }}>
            Error Code: 404 | Resource Not Found
          </p>
        </div>
      </fieldset>
    </div>
  )
}
