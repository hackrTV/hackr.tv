import React, { useState } from 'react'

interface AlbumCoverProps {
  coverUrl: string;
}

export const AlbumCover: React.FC<AlbumCoverProps> = ({ coverUrl }) => {
  const [showOverlay, setShowOverlay] = useState(false)

  if (!coverUrl) return null

  return (
    <>
      <img
        id="player-cover"
        src={coverUrl}
        alt="Album Cover"
        onMouseEnter={() => setShowOverlay(true)}
        onMouseLeave={() => setShowOverlay(false)}
        style={{
          width: '60px',
          height: '60px',
          objectFit: 'cover',
          border: '1px solid #7c3aed',
          cursor: 'pointer'
        }}
      />
      {showOverlay && (
        <div
          id="cover-overlay"
          style={{
            position: 'fixed',
            bottom: '100px',
            left: '20px',
            zIndex: 1001,
            pointerEvents: 'none'
          }}
        >
          <img
            src={coverUrl}
            alt="Album Cover"
            style={{
              width: '300px',
              height: '300px',
              objectFit: 'cover',
              border: '3px solid #7c3aed',
              boxShadow: '0 8px 32px rgba(124, 58, 237, 0.5)'
            }}
          />
        </div>
      )}
    </>
  )
}
