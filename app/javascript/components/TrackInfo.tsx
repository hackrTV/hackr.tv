import React from 'react'

interface TrackInfoProps {
  title: string;
  artist: string;
  compact?: boolean;
}

export const TrackInfo: React.FC<TrackInfoProps> = ({ title, artist, compact = false }) => {
  if (compact) {
    return (
      <div style={{
        marginBottom: '3px',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis'
      }}>
        <span id="track-title" style={{ color: '#a78bfa', fontWeight: 'bold', fontSize: '0.85em' }}>
          {title}
        </span>
        <span style={{ color: '#666', fontSize: '0.85em' }}> - </span>
        <span id="track-artist" style={{ color: '#888', fontSize: '0.85em' }}>
          {artist}
        </span>
      </div>
    )
  }

  return (
    <div style={{ marginBottom: '5px' }}>
      <span id="track-title" style={{ color: '#a78bfa', fontWeight: 'bold' }}>
        {title}
      </span>
      <span style={{ color: '#666' }}> - </span>
      <span id="track-artist" style={{ color: '#888' }}>
        {artist}
      </span>
    </div>
  )
}
