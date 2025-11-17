import React from 'react'
import type { TrackData } from '~/types/track'

interface QueuePanelProps {
  playlist: TrackData[]
  currentTrackId: string | null
  onTrackClick: (track: TrackData) => void
}

export const QueuePanel: React.FC<QueuePanelProps> = ({
  playlist,
  currentTrackId,
  onTrackClick
}) => {
  if (playlist.length === 0) {
    return (
      <div style={{ padding: '20px', textAlign: 'center', color: '#666' }}>
        No tracks in queue
      </div>
    )
  }

  // Find current track index
  const currentIndex = playlist.findIndex(track => track.id === currentTrackId)

  // Get current track and next 3 tracks
  const queueTracks: Array<{ track: TrackData; position: 'current' | 'next' }> = []

  if (currentIndex !== -1) {
    // Add current track
    queueTracks.push({ track: playlist[currentIndex], position: 'current' })

    // Add next 3 tracks (or fewer if at end of playlist)
    for (let i = 1; i <= 3; i++) {
      const nextIndex = (currentIndex + i) % playlist.length
      if (nextIndex !== currentIndex || playlist.length === 1) {
        queueTracks.push({ track: playlist[nextIndex], position: 'next' })
      }
      // Stop if we've wrapped around to the current track
      if (nextIndex === currentIndex) break
    }
  }

  return (
    <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
      {queueTracks.map(({ track, position }, index) => (
        <div
          key={`${track.id}-${index}`}
          onClick={() => onTrackClick(track)}
          style={{
            padding: '10px 15px',
            borderBottom: '1px solid #333',
            cursor: 'pointer',
            background: position === 'current' ? 'rgba(124, 58, 237, 0.15)' : 'transparent',
            transition: 'background 0.2s'
          }}
          onMouseEnter={(e) => {
            if (position !== 'current') {
              e.currentTarget.style.background = 'rgba(124, 58, 237, 0.08)'
            }
          }}
          onMouseLeave={(e) => {
            if (position !== 'current') {
              e.currentTarget.style.background = 'transparent'
            }
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            {track.coverUrl && (
              <img
                src={track.coverUrl}
                alt={track.title}
                style={{
                  width: '40px',
                  height: '40px',
                  objectFit: 'cover',
                  border: '1px solid #555'
                }}
              />
            )}
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '2px' }}>
                {position === 'current' && (
                  <span style={{ color: '#7c3aed', fontSize: '0.9em' }}>▶</span>
                )}
                <div
                  style={{
                    color: position === 'current' ? '#a78bfa' : '#ccc',
                    fontWeight: position === 'current' ? 'bold' : 'normal',
                    fontSize: '0.9em',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap'
                  }}
                >
                  {track.title}
                </div>
              </div>
              <div
                style={{
                  color: '#888',
                  fontSize: '0.8em',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap'
                }}
              >
                {track.artist}
              </div>
            </div>
            {position === 'current' && (
              <div style={{ color: '#7c3aed', fontSize: '0.75em', fontWeight: 'bold' }}>
                NOW PLAYING
              </div>
            )}
            {position === 'next' && index <= 3 && (
              <div style={{ color: '#666', fontSize: '0.75em' }}>
                UP NEXT
              </div>
            )}
          </div>
        </div>
      ))}

      {playlist.length > 4 && (
        <div style={{ padding: '10px 15px', color: '#666', fontSize: '0.85em', textAlign: 'center', borderBottom: '1px solid #333' }}>
          + {playlist.length - Math.min(4, queueTracks.length)} more tracks in queue
        </div>
      )}
    </div>
  )
}
