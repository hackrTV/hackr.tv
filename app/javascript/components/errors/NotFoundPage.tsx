import React from 'react'
import { Link } from 'react-router-dom'
import { useTerminal } from '~/contexts/TerminalContext'

export const NotFoundPage: React.FC = () => {
  const { openTerminal } = useTerminal()
  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        backgroundColor: '#000000'
      }}
    >
      <div
        style={{
          border: '2px solid #00ff00',
          padding: '20px',
          maxWidth: '800px',
          width: '100%',
          boxShadow: '0 0 20px rgba(0, 255, 0, 0.3)'
        }}
      >
        <div
          style={{
            borderBottom: '2px solid #00ff00',
            paddingBottom: '10px',
            marginBottom: '20px',
            color: '#ffffff',
            fontWeight: 'bold'
          }}
        >
          hackr.tv:~$ cat /var/log/errors/404.log
        </div>

        <pre
          style={{
            color: '#00ff00',
            lineHeight: 1.2,
            overflowX: 'auto',
            margin: '20px 0'
          }}
        >
          {` _  _    ___  _  _
| || |  / _ \\| || |
| || |_| | | | || |_
|__   _| | | |__   _|
   | | | |_| |  | |
   |_|  \\___/   |_|
`}
        </pre>

        <div
          style={{
            color: '#ff0000',
            fontSize: '0.9em',
            margin: '20px 0'
          }}
        >
          [ERROR] HTTP 404 - Resource Not Found
        </div>

        <div
          style={{
            color: '#ffffff',
            lineHeight: 1.6,
            margin: '20px 0'
          }}
        >
          The requested page does not exist on this server.
          <br /><br />
          Possible causes:
          <br />
          &nbsp;&nbsp;• URL may be mistyped
          <br />
          &nbsp;&nbsp;• Resource may have been moved or deleted
          <br />
          &nbsp;&nbsp;• Link may be outdated
          <br /><br />
          Quick navigation:
          <br />
          &nbsp;&nbsp;• <Link to="/" style={{ color: '#00ff00', textDecoration: 'underline' }}>Return to hackr.tv origin</Link>
          <br />
          &nbsp;&nbsp;• <a href="#" onClick={(e) => { e.preventDefault(); openTerminal() }} style={{ color: '#22d3ee', textDecoration: 'underline' }}>Access the Terminal</a>
          <br />
          &nbsp;&nbsp;• <Link to="/fm/pulse_vault" style={{ color: '#00ff00', textDecoration: 'underline' }}>Plumb the Pulse Vault</Link>
          <br />
          &nbsp;&nbsp;• <Link to="/fm/radio" style={{ color: '#00ff00', textDecoration: 'underline' }}>Listen to Hackr Radio Chronocasts</Link>
          <br />
          &nbsp;&nbsp;• <Link to="/grid" style={{ color: '#00ff00', textDecoration: 'underline' }}>Enter THE PULSE GRID</Link>
        </div>

        <div style={{ marginTop: '20px', color: '#00ff00' }}>
          hackr.tv:~$ <span style={{ animation: 'blink 1s infinite' }}>█</span>
        </div>

        <style>{`
          @keyframes blink {
            0%, 49% { opacity: 1; }
            50%, 100% { opacity: 0; }
          }
        `}</style>
      </div>
    </div>
  )
}
