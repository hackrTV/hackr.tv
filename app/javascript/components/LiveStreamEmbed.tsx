import React from 'react'

interface LiveStreamEmbedProps {
  url: string
  title?: string
  artistName?: string
}

export const LiveStreamEmbed: React.FC<LiveStreamEmbedProps> = ({
  url,
  title,
  artistName
}) => {
  return (
    <div style={{
      width: '100%',
      maxWidth: '1400px',
      margin: '0 auto',
      padding: '20px'
    }}>
      {/* LIVE Indicator */}
      <div style={{
        background: 'linear-gradient(90deg, #001a00 0%, #003300 50%, #001a00 100%)',
        border: '2px solid #00ff00',
        padding: '20px',
        marginBottom: '20px',
        textAlign: 'center',
        position: 'relative',
        overflow: 'hidden'
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

        <h1 style={{
          color: '#00ff00',
          fontSize: '3em',
          margin: '0 0 10px 0',
          textShadow: '0 0 20px #00ff00, 0 0 40px #00ff00',
          fontWeight: 'bold',
          letterSpacing: '0.1em'
        }}>
          ⚡ LIVE NOW ⚡
        </h1>

        {artistName && (
          <p style={{
            color: '#fff',
            fontSize: '1.5em',
            margin: '10px 0',
            fontWeight: 'bold'
          }}>
            {artistName}
          </p>
        )}

        {title && (
          <p style={{
            color: '#aaa',
            fontSize: '1.2em',
            margin: '5px 0'
          }}>
            {title}
          </p>
        )}
      </div>

      {/* Stream Embed */}
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

      <style>{`
        @keyframes pulse-wave {
          0% { left: -100%; }
          100% { left: 100%; }
        }
      `}</style>
    </div>
  )
}
