import React from 'react'

interface PlayPauseButtonProps {
  isPlaying: boolean;
  onClick: () => void;
  size?: 'small' | 'normal';
}

export const PlayPauseButton: React.FC<PlayPauseButtonProps> = ({ isPlaying, onClick, size = 'normal' }) => {
  const isSmall = size === 'small'

  return (
    <button
      id="play-pause-btn"
      className="tui-button"
      onClick={onClick}
      tabIndex={-1}
      style={{
        background: '#7c3aed',
        color: 'white',
        minWidth: isSmall ? '44px' : '80px',
        padding: isSmall ? '4px 8px' : undefined,
        fontSize: isSmall ? '0.9em' : undefined
      }}
    >
      {isSmall ? (isPlaying ? '❚❚' : '►') : (isPlaying ? '❚❚ PAUSE' : '► PLAY')}
    </button>
  )
}
