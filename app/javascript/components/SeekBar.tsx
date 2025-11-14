import React from 'react';

interface SeekBarProps {
  currentTime: number;
  duration: number;
  onSeekStart: () => void;
  onSeek: (time: number) => void;
  onSeekEnd: () => void;
}

function formatTime(seconds: number): string {
  if (!seconds || isNaN(seconds)) return '0:00';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export const SeekBar: React.FC<SeekBarProps> = ({
  currentTime,
  duration,
  onSeekStart,
  onSeek,
  onSeekEnd,
}) => {
  const progress = duration > 0 ? (currentTime / duration) * 100 : 0;

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement> | React.FormEvent<HTMLInputElement>) => {
    const seekTime = (Number(e.currentTarget.value) / 100) * duration;
    onSeek(seekTime);
  };

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
        onMouseDown={onSeekStart}
        onTouchStart={onSeekStart}
        onChange={handleSeek}
        onInput={handleSeek}
        onMouseUp={onSeekEnd}
        onTouchEnd={onSeekEnd}
        style={{
          flex: 1,
          height: '6px',
          background: '#333',
          borderRadius: '3px',
          outline: 'none',
          WebkitAppearance: 'none',
        }}
      />
      <span id="duration" style={{ color: '#666', fontSize: '0.9em', minWidth: '45px' }}>
        {formatTime(duration)}
      </span>
    </div>
  );
};
