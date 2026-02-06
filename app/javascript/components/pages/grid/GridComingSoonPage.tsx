import React from 'react'

export const GridComingSoonPage: React.FC = () => {
  return (
    <div style={{
      minHeight: '100vh',
      background: '#0a0a0a',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'monospace',
      color: '#a78bfa',
      padding: '20px',
      textAlign: 'center'
    }}>
      <div style={{ marginBottom: '30px', fontSize: '0.9em', color: '#444', letterSpacing: '2px' }}>
        ╔══════════════════════════════════════╗
      </div>

      <h1 style={{
        fontSize: '1.8em',
        fontWeight: 'bold',
        color: '#a78bfa',
        marginBottom: '16px',
        letterSpacing: '3px',
        textTransform: 'uppercase'
      }}>
        THE PULSE GRID
      </h1>

      <p style={{
        fontSize: '1.1em',
        color: '#c084fc',
        marginBottom: '8px'
      }}>
        will open soon
      </p>

      <p style={{
        fontSize: '0.85em',
        color: '#666',
        marginBottom: '30px'
      }}>
        // access pending
      </p>

      <div style={{ marginBottom: '30px', fontSize: '0.9em', color: '#444', letterSpacing: '2px' }}>
        ╚══════════════════════════════════════╝
      </div>

      <a
        href="/"
        style={{
          color: '#4ade80',
          textDecoration: 'none',
          fontSize: '0.85em',
          letterSpacing: '1px',
          padding: '8px 16px',
          border: '1px solid #333',
          borderRadius: '2px'
        }}
      >
        ← hackr.tv
      </a>
    </div>
  )
}

export default GridComingSoonPage
