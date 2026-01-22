import React, { useEffect } from 'react'

interface LiveStreamEmbedProps {
  url: string
  title?: string
  artistName?: string
  sideContent?: React.ReactNode
  theaterMode?: boolean
  onTheaterModeToggle?: () => void
}

export const LiveStreamEmbed: React.FC<LiveStreamEmbedProps> = ({
  url,
  title,
  artistName,
  sideContent,
  theaterMode = false,
  onTheaterModeToggle
}) => {
  // Handle escape key to exit theater mode
  useEffect(() => {
    if (!theaterMode) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && onTheaterModeToggle) {
        onTheaterModeToggle()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [theaterMode, onTheaterModeToggle])

  // Prevent body scroll in theater mode
  useEffect(() => {
    if (theaterMode) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => {
      document.body.style.overflow = ''
    }
  }, [theaterMode])

  const theaterButton = onTheaterModeToggle && (
    <button
      onClick={onTheaterModeToggle}
      title={theaterMode ? 'Exit theater mode (Esc)' : 'Theater mode'}
      style={{
        position: 'absolute',
        right: '10px',
        top: '50%',
        transform: 'translateY(-50%)',
        background: 'rgba(0, 0, 0, 0.6)',
        border: '1px solid #00ff00',
        color: '#00ff00',
        padding: '6px 10px',
        fontSize: '0.75rem',
        cursor: 'pointer',
        fontFamily: 'Terminus, monospace',
        zIndex: 10
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = 'rgba(0, 255, 0, 0.2)'
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = 'rgba(0, 0, 0, 0.6)'
      }}
    >
      {theaterMode ? '[x] EXIT' : '[=] THEATER'}
    </button>
  )

  // Theater mode: full screen overlay
  if (theaterMode) {
    return (
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: '#000',
        zIndex: 9999,
        display: 'flex',
        flexDirection: 'column'
      }}>
        {/* Compact header */}
        <div style={{
          background: 'linear-gradient(90deg, #001a00 0%, #003300 50%, #001a00 100%)',
          borderBottom: '2px solid #00ff00',
          padding: '8px 16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '16px',
          position: 'relative',
          flexShrink: 0
        }}>
          {artistName && (
            <span style={{ color: '#fff', fontSize: '1em', fontWeight: 'bold' }}>
              {artistName}
            </span>
          )}

          <h1 style={{
            fontSize: '1.1em',
            margin: 0,
            fontWeight: 'bold',
            letterSpacing: '0.1em'
          }}>
            {artistName && <span style={{ color: '#888', fontWeight: 'normal' }}>is </span>}
            <span style={{ color: '#00ff00', textShadow: '0 0 20px #00ff00' }}>LIVE</span>
          </h1>

          {title && (
            <span style={{ color: '#888', fontSize: '0.9em' }}>
              {title}
            </span>
          )}

          {theaterButton}
        </div>

        {/* Video + Chat container */}
        <div style={{
          flex: 1,
          display: 'flex',
          gap: '0',
          minHeight: 0
        }}>
          {/* Video */}
          <div style={{
            flex: sideContent ? '1 1 auto' : '1 1 100%',
            minWidth: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#000'
          }}>
            <div style={{
              width: '100%',
              height: '100%',
              maxHeight: '100%',
              position: 'relative'
            }}>
              <iframe
                src={url}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  height: '100%',
                  border: 'none'
                }}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowFullScreen
                title={title || 'Live Stream'}
              />
            </div>
          </div>

          {/* Chat sidebar */}
          {sideContent && (
            <div style={{
              flex: '0 0 380px',
              borderLeft: '2px solid #333',
              display: 'flex',
              flexDirection: 'column',
              minHeight: 0
            }}>
              {sideContent}
            </div>
          )}
        </div>

        <style>{`
          @keyframes pulse-wave {
            0% { left: -100%; }
            100% { left: 100%; }
          }
        `}</style>
      </div>
    )
  }

  // Normal mode
  return (
    <div style={{
      width: '100%',
      maxWidth: '1400px',
      margin: '0 auto',
      padding: '4px 20px 20px'
    }}>
      {/* LIVE Indicator */}
      <div style={{
        background: 'linear-gradient(90deg, #001a00 0%, #003300 50%, #001a00 100%)',
        border: '2px solid #00ff00',
        padding: '10px 20px',
        marginBottom: '16px',
        textAlign: 'center',
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '16px',
        flexWrap: 'wrap'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: '-100%',
          width: '100%',
          height: '100%',
          background: 'linear-gradient(90deg, transparent, rgba(0, 255, 0, 0.2), transparent)',
          animation: 'pulse-wave 3s linear infinite'
        }} />

        {artistName && (
          <p style={{
            color: '#fff',
            fontSize: '1.1em',
            margin: 0,
            fontWeight: 'bold'
          }}>
            {artistName}
          </p>
        )}

        <h1 style={{
          fontSize: '1.5em',
          margin: 0,
          fontWeight: 'bold',
          letterSpacing: '0.1em'
        }}>
          {artistName && <span style={{ color: '#888', fontWeight: 'normal' }}>is </span>}
          <span style={{ color: '#00ff00', textShadow: '0 0 20px #00ff00, 0 0 40px #00ff00' }}>LIVE NOW</span>
        </h1>

        {title && (
          <p style={{
            color: '#aaa',
            fontSize: '1em',
            margin: 0
          }}>
            {title}
          </p>
        )}

        {theaterButton}
      </div>

      {/* Stream Embed + Side Content */}
      <div style={{
        display: 'flex',
        gap: '16px',
        alignItems: 'stretch'
      }}>
        <div style={{
          flex: sideContent ? '1 1 65%' : '1 1 100%',
          minWidth: 0,
          position: 'relative'
        }}>
          <div style={{
            position: 'relative',
            paddingBottom: '56.25%', // 16:9 aspect ratio
            height: 0,
            overflow: 'hidden',
            background: '#000',
            border: '3px solid #7c3aed',
            boxShadow: '0 0 30px rgba(124, 58, 237, 0.5)'
          }}>
            <iframe
              src={url}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: '100%',
                border: 'none'
              }}
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowFullScreen
              title={title || 'Live Stream'}
            />
          </div>
        </div>
        {sideContent && (
          <div style={{
            flex: '0 0 350px',
            position: 'relative'
          }}>
            <div style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              overflow: 'hidden'
            }}>
              {sideContent}
            </div>
          </div>
        )}
      </div>

      <style>{`
        @keyframes pulse-wave {
          0% { left: -100%; }
          100% { left: 100%; }
        }
      `}</style>
    </div>
  )
}
