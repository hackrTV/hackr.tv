import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const SectorXPage: React.FC = () => {
  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
          background: '#0a0a0a',
          border: '2px solid #14b8a6',
          boxShadow: '0 0 30px rgba(20, 184, 166, 0.6)'
        }}
      >
        <fieldset style={{ borderColor: '#14b8a6' }}>
          <legend
            className="center"
            style={{
              color: '#14b8a6',
              textShadow: '0 0 15px rgba(20, 184, 166, 0.8)',
              letterSpacing: '3px'
            }}
          >
            SECTOR X
          </legend>
          <div style={{ padding: '40px', textAlign: 'center' }}>
            <p style={{ color: '#14b8a6', fontSize: '1.2em', marginBottom: '15px' }}>
              [:: COMING SOON ::]
            </p>
            <p style={{ color: '#888' }}>
              Keep your hackr eyes peeled!
            </p>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default SectorXPage
