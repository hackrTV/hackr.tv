import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const XeraenLinkzPage: React.FC = () => {
  const colorScheme = {
    primary: '#8B00FF',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)'
  }

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
          background: '#0a0a0a',
          border: `2px solid ${colorScheme.primary}`,
          boxShadow: `0 0 30px ${colorScheme.glow}`
        }}
      >
        <fieldset style={{ borderColor: colorScheme.primary }}>
          <legend
            className="center"
            style={{
              color: colorScheme.primary,
              textShadow: `0 0 15px ${colorScheme.glowStrong}`,
              letterSpacing: '3px'
            }}
          >
            XERAEN :: LINKZ
          </legend>
          <div style={{ padding: '30px' }}>
            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              <a href="https://open.spotify.com/artist/0nDs8RZN66dnOgJKa89FvV?si=G1wzaIddTI6m28g7oGp5cw" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: colorScheme.primary, color: 'white' }}>Spotify</a>
              <a href="https://xeraen.bandcamp.com/" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: colorScheme.primary, color: 'white' }}>Bandcamp</a>
              <a href="https://music.apple.com/us/artist/xeraen/1565857265" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: colorScheme.primary, color: 'white' }}>Apple Music</a>
              <a href="https://soundcloud.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: colorScheme.primary, color: 'white' }}>SoundCloud</a>
            </div>
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              <a href="https://youtube.com/@xeraen" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: '#222', color: '#aaa', border: '1px solid #444' }}>YouTube</a>
              <a href="https://x.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: '#222', color: '#aaa', border: '1px solid #444' }}>X.com</a>
              <a href="https://github.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer" style={{ background: '#222', color: '#aaa', border: '1px solid #444' }}>GitHub</a>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default XeraenLinkzPage
