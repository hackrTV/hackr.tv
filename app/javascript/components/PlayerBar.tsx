import React, { useState, useEffect, useRef } from 'react'
import { AlbumCover } from './AlbumCover.tsx'
import { PlayPauseButton } from './PlayPauseButton.tsx'
import { TrackInfo } from './TrackInfo.tsx'
import { SeekBar } from './SeekBar.tsx'
import { VolumeControl } from './VolumeControl.tsx'
import { QueuePanel } from './QueuePanel.tsx'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useAudio } from '~/contexts/AudioContext'
import { useMobileDetect } from '~/hooks/useMobileDetect'
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
  shuffle: boolean;
  onPlayPause: () => void;
  onNext: () => void;
  onPrevious: () => void;
  onSeekStart: () => void;
  onSeek: (time: number) => void;
  onSeekEnd: () => void;
  onVolumeChange: (volume: number) => void;
  onToggleShuffle: () => void;
  onClose: () => void;
}

export const PlayerBar: React.FC<PlayerBarProps> = ({
  isPlaying,
  currentTrack,
  currentTime,
  duration,
  volume,
  stationContext,
  shuffle,
  onPlayPause,
  onNext,
  onPrevious,
  onSeekStart,
  onSeek,
  onSeekEnd,
  onVolumeChange,
  onToggleShuffle,
  onClose
}) => {
  const { isLoggedIn } = useGridAuth()
  const { audioPlayerAPI } = useAudio()
  const { isMobile } = useMobileDetect()
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
          padding: isMobile ? '10px 12px' : '15px 20px',
          zIndex: 1000,
          animation: 'slideInFromLeft 0.3s ease-out'
        }}
      >
        <div style={{ maxWidth: '1400px', margin: '0 auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: isMobile ? '8px' : '20px' }}>
            {/* Album cover - smaller on mobile */}
            {currentTrack?.coverUrl && (
              <div style={{ flexShrink: 0 }}>
                <AlbumCover coverUrl={currentTrack.coverUrl} size={isMobile ? 40 : undefined} />
              </div>
            )}

            <PlayPauseButton isPlaying={isPlaying} onClick={onPlayPause} size={isMobile ? 'small' : 'normal'} />

            {/* Navigation buttons - hidden on mobile */}
            {!stationContext && !isMobile && (
              <>
                <button
                  className="tui-button"
                  onClick={onPrevious}
                  tabIndex={-1}
                  style={{
                    background: '#444',
                    color: '#aaa',
                    padding: '0',
                    fontSize: '1.3em',
                    minWidth: '25px'
                  }}
                  title="Previous track"
                >
                  ⏮
                </button>
                <button
                  className="tui-button"
                  onClick={onNext}
                  tabIndex={-1}
                  style={{
                    background: '#444',
                    color: '#aaa',
                    padding: '0',
                    fontSize: '1.3em',
                    minWidth: '25px'
                  }}
                  title="Next track"
                >
                  ⏭
                </button>
                <button
                  className="tui-button"
                  onClick={onToggleShuffle}
                  tabIndex={-1}
                  style={{
                    background: shuffle ? '#7c3aed' : '#444',
                    color: shuffle ? '#fff' : '#aaa',
                    padding: '0',
                    fontSize: '0.9em',
                    minWidth: '25px'
                  }}
                  title={shuffle ? 'Shuffle: On' : 'Shuffle: Off'}
                >
                  ⤮
                </button>
              </>
            )}

            {/* Track info and seek bar */}
            <div style={{ flex: 1, minWidth: 0, overflow: 'hidden' }}>
              {stationContext && (
                <div style={{ marginBottom: '2px' }}>
                  <span style={{ color: '#00d9ff', fontSize: isMobile ? '0.75em' : '0.85em', fontWeight: 'bold' }}>
                    📻 {stationContext.name}
                  </span>
                </div>
              )}
              <TrackInfo
                title={currentTrack?.title || 'No track loaded'}
                artist={currentTrack?.artist || '-'}
                compact={isMobile}
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

            {/* Volume control - hidden on mobile */}
            {!isMobile && <VolumeControl volume={volume} onVolumeChange={onVolumeChange} />}

            {/* Add to playlist - hidden on mobile */}
            {!isMobile && isLoggedIn && currentTrack && (
              <div style={{ marginLeft: '10px' }}>
                <AddToPlaylistDropdown
                  trackId={parseInt(currentTrack.id)}
                  trackTitle={currentTrack.title}
                  direction="up"
                />
              </div>
            )}

            {/* Queue button - simplified on mobile */}
            <div ref={queueRef} style={{ position: 'relative' }}>
              <button
                className="tui-button"
                onClick={() => setShowQueue(!showQueue)}
                tabIndex={-1}
                style={{
                  background: showQueue ? '#7c3aed' : '#444',
                  color: showQueue ? '#fff' : '#aaa',
                  marginLeft: isMobile ? '4px' : '10px',
                  padding: isMobile ? '4px 8px' : undefined,
                  fontSize: isMobile ? '0.85em' : undefined
                }}
                title="Show queue"
              >
                {isMobile ? '☰' : (stationContext ? '☰ Queue' : `☰ Queue (${playlist.length})`)}
              </button>

              {showQueue && (
                <div
                  style={{
                    position: 'absolute',
                    bottom: '100%',
                    right: isMobile ? '-50px' : 0,
                    marginBottom: '10px',
                    background: '#0a0a0a',
                    border: '2px solid #7c3aed',
                    borderRadius: '4px',
                    width: isMobile ? 'calc(100vw - 24px)' : undefined,
                    minWidth: isMobile ? undefined : '350px',
                    maxWidth: isMobile ? undefined : '450px',
                    zIndex: 2000,
                    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.7)'
                  }}
                >
                  <div style={{
                    padding: isMobile ? '10px 12px' : '12px 15px',
                    borderBottom: '2px solid #7c3aed',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}>
                    <div style={{ color: '#00d9ff', fontWeight: 'bold', fontSize: isMobile ? '0.85em' : '0.95em' }}>
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
              style={{
                background: '#444',
                color: '#aaa',
                marginLeft: isMobile ? '4px' : '10px',
                padding: isMobile ? '4px 8px' : undefined
              }}
            >
              ✕
            </button>
          </div>
        </div>
      </div>
    </>
  )
}
