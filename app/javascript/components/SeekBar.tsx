import React from 'react'

interface SeekBarProps {
  currentTime: number;
  duration: number;
  onSeekStart: () => void;
  onSeek: (time: number) => void;
  onSeekEnd: () => void;
  disabled?: boolean;
}

function formatTime (seconds: number): string {
  if (!seconds || isNaN(seconds)) return '0:00'
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

export const SeekBar: React.FC<SeekBarProps> = ({
  currentTime,
  duration,
  onSeekStart,
  onSeek,
  onSeekEnd,
  disabled = false
}) => {
  const progress = duration > 0 ? (currentTime / duration) * 100 : 0

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement> | React.FormEvent<HTMLInputElement>) => {
    if (disabled) return
    const seekTime = (Number(e.currentTarget.value) / 100) * duration
    onSeek(seekTime)
  }

  const handleSeekStart = () => {
    if (!disabled) onSeekStart()
  }

  const handleSeekEnd = () => {
    if (!disabled) onSeekEnd()
  }

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
      <span id="current-time" style={{ color: '#666', fontSize: '0.9em', minWidth: '45px' }}>
        {formatTime(currentTime)}
      </span>
      <input
        type="range"
        id="seek-bar"
        min="0"
        max="100"
        value={progress}
        onMouseDown={handleSeekStart}
        onTouchStart={handleSeekStart}
        onChange={handleSeek}
        onInput={handleSeek}
        onMouseUp={handleSeekEnd}
        onTouchEnd={handleSeekEnd}
        tabIndex={-1}
        disabled={disabled}
        style={{
          flex: 1,
          height: '6px',
          background: '#333',
          borderRadius: '3px',
          outline: 'none',
          WebkitAppearance: 'none',
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.5 : 1
        }}
      />
      <span id="duration" style={{ color: '#666', fontSize: '0.9em', minWidth: '45px' }}>
        {formatTime(duration)}
      </span>
    </div>
  )
}
