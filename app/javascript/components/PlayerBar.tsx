import React, { useState, useEffect, useRef } from 'react'
import { AlbumCover } from './AlbumCover.tsx'
import { PlayPauseButton } from './PlayPauseButton.tsx'
import { TrackInfo } from './TrackInfo.tsx'
import { SeekBar } from './SeekBar.tsx'
import { VolumeControl } from './VolumeControl.tsx'
import { QueuePanel } from './QueuePanel.tsx'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useAudio } from '~/contexts/AudioContext'
import { AddToPlaylistDropdown } from '~/components/playlists/AddToPlaylistDropdown'
import type { TrackData, StationContext } from '~/types/track'

interface PlayerBarProps {
  isPlaying: boolean;
  currentTrack: {
    id: string;
    title: string;
    artist: string;
    coverUrl: string;
  } | null;
  currentTime: number;
  duration: number;
  volume: number;
  stationContext: StationContext | null;
  onPlayPause: () => void;
  onSeekStart: () => void;
  onSeek: (time: number) => void;
  onSeekEnd: () => void;
  onVolumeChange: (volume: number) => void;
  onClose: () => void;
}

export const PlayerBar: React.FC<PlayerBarProps> = ({
  isPlaying,
  currentTrack,
  currentTime,
  duration,
  volume,
  stationContext,
  onPlayPause,
  onSeekStart,
  onSeek,
  onSeekEnd,
  onVolumeChange,
  onClose
}) => {
  const { isLoggedIn } = useGridAuth()
  const { audioPlayerAPI } = useAudio()
  const [showQueue, setShowQueue] = useState(false)
  const [playlist, setPlaylist] = useState<TrackData[]>([])
  const queueRef = useRef<HTMLDivElement>(null)

  // Update playlist when it changes
  useEffect(() => {
    const interval = setInterval(() => {
      if (audioPlayerAPI.current) {
        const currentPlaylist = audioPlayerAPI.current.getPlaylist()
        setPlaylist(currentPlaylist)
      }
    }, 500)

    return () => clearInterval(interval)
  }, [audioPlayerAPI])

  // Close queue when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (queueRef.current && !queueRef.current.contains(event.target as Node)) {
        setShowQueue(false)
      }
    }

    if (showQueue) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => {
        document.removeEventListener('mousedown', handleClickOutside)
      }
    }
  }, [showQueue])

  const handleQueueTrackClick = (track: TrackData) => {
    if (audioPlayerAPI.current) {
      audioPlayerAPI.current.loadTrack(track)
    }
  }

  return (
    <>
      <style>{`
        @keyframes slideInFromLeft {
          from {
            transform: translateX(-100%);
          }
          to {
            transform: translateX(0);
          }
        }
      `}</style>
      <div
        id="audio-player"
        tabIndex={-1}
        style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          background: '#0a0a0a',
          borderTop: '2px solid #7c3aed',
          padding: '15px 20px',
          zIndex: 1000,
          animation: 'slideInFromLeft 0.3s ease-out'
        }}
      >
        <div style={{ maxWidth: '1400px', margin: '0 auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
            {currentTrack?.coverUrl && <AlbumCover coverUrl={currentTrack.coverUrl} />}

            <PlayPauseButton isPlaying={isPlaying} onClick={onPlayPause} />

            <div style={{ flex: 1 }}>
              {stationContext && (
                <div style={{ marginBottom: '2px' }}>
                  <span style={{ color: '#00d9ff', fontSize: '0.85em', fontWeight: 'bold' }}>
                    📻 {stationContext.name}
                  </span>
                </div>
              )}
              <TrackInfo
                title={currentTrack?.title || 'No track loaded'}
                artist={currentTrack?.artist || '—'}
              />
              <SeekBar
                currentTime={currentTime}
                duration={duration}
                onSeekStart={onSeekStart}
                onSeek={onSeek}
                onSeekEnd={onSeekEnd}
                disabled={!!stationContext}
              />
            </div>

            <VolumeControl volume={volume} onVolumeChange={onVolumeChange} />

            {isLoggedIn && currentTrack && (
              <div style={{ marginLeft: '10px' }}>
                <AddToPlaylistDropdown
                  trackId={parseInt(currentTrack.id)}
                  trackTitle={currentTrack.title}
                  direction="up"
                />
              </div>
            )}

            <div ref={queueRef} style={{ position: 'relative' }}>
              <button
                className="tui-button"
                onClick={() => setShowQueue(!showQueue)}
                tabIndex={-1}
                style={{
                  background: showQueue ? '#7c3aed' : '#444',
                  color: showQueue ? '#fff' : '#aaa',
                  marginLeft: '10px'
                }}
                title="Show queue"
              >
                {stationContext ? '☰ Queue' : `☰ Queue (${playlist.length})`}
              </button>

              {showQueue && (
                <div
                  style={{
                    position: 'absolute',
                    bottom: '100%',
                    right: 0,
                    marginBottom: '10px',
                    background: '#0a0a0a',
                    border: '2px solid #7c3aed',
                    borderRadius: '4px',
                    minWidth: '350px',
                    maxWidth: '450px',
                    zIndex: 2000,
                    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.7)'
                  }}
                >
                  <div style={{
                    padding: '12px 15px',
                    borderBottom: '2px solid #7c3aed',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}>
                    <div style={{ color: '#00d9ff', fontWeight: 'bold', fontSize: '0.95em' }}>
                      Up Next
                    </div>
                    <button
                      onClick={() => setShowQueue(false)}
                      className="tui-button"
                      style={{
                        background: 'transparent',
                        color: '#aaa',
                        padding: '2px 8px',
                        fontSize: '0.9em'
                      }}
                    >
                      ✕
                    </button>
                  </div>
                  <QueuePanel
                    playlist={playlist}
                    currentTrackId={currentTrack?.id || null}
                    onTrackClick={handleQueueTrackClick}
                    stationContext={stationContext}
                  />
                </div>
              )}
            </div>

            <button
              id="close-player-btn"
              className="tui-button"
              onClick={onClose}
              tabIndex={-1}
              style={{ background: '#444', color: '#aaa', marginLeft: '10px' }}
            >
              ✕
            </button>
          </div>
        </div>
      </div>
    </>
  )
}
