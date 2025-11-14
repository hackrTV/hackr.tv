import React from 'react'

interface TrackInfoProps {
  title: string;
  artist: string;
}

export const TrackInfo: React.FC<TrackInfoProps> = ({ title, artist }) => {
  return (
    <div style={{ marginBottom: '5px' }}>
      <span id="track-title" style={{ color: '#a78bfa', fontWeight: 'bold' }}>
        {title}
      </span>
      <span style={{ color: '#666' }}> — </span>
      <span id="track-artist" style={{ color: '#888' }}>
        {artist}
      </span>
    </div>
  )
}
