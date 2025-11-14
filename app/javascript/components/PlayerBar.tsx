import React from 'react'
import { AlbumCover } from './AlbumCover.tsx'
import { PlayPauseButton } from './PlayPauseButton.tsx'
import { TrackInfo } from './TrackInfo.tsx'
import { SeekBar } from './SeekBar.tsx'
import { VolumeControl } from './VolumeControl.tsx'

interface PlayerBarProps {
  isPlaying: boolean;
  currentTrack: {
    title: string;
    artist: string;
    coverUrl: string;
  } | null;
  currentTime: number;
  duration: number;
  volume: number;
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
  onPlayPause,
  onSeekStart,
  onSeek,
  onSeekEnd,
  onVolumeChange,
  onClose
}) => {
  return (
    <div
      id="audio-player"
      style={{
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        background: '#0a0a0a',
        borderTop: '2px solid #7c3aed',
        padding: '15px 20px',
        zIndex: 1000
      }}
    >
      <div style={{ maxWidth: '1400px', margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          {currentTrack?.coverUrl && <AlbumCover coverUrl={currentTrack.coverUrl} />}

          <PlayPauseButton isPlaying={isPlaying} onClick={onPlayPause} />

          <div style={{ flex: 1 }}>
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
            />
          </div>

          <VolumeControl volume={volume} onVolumeChange={onVolumeChange} />

          <button
            id="close-player-btn"
            className="tui-button"
            onClick={onClose}
            style={{ background: '#444', color: '#aaa' }}
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  )
}
