import React from 'react'

interface PlayPauseButtonProps {
  isPlaying: boolean;
  onClick: () => void;
}

export const PlayPauseButton: React.FC<PlayPauseButtonProps> = ({ isPlaying, onClick }) => {
  return (
    <button
      id="play-pause-btn"
      className="tui-button"
      onClick={onClick}
      style={{ background: '#7c3aed', color: 'white', minWidth: '80px' }}
    >
      {isPlaying ? '❚❚ PAUSE' : '► PLAY'}
    </button>
  )
}
