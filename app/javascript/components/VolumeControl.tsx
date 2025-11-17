import React from 'react'

interface VolumeControlProps {
  volume: number;
  onVolumeChange: (volume: number) => void;
}

export const VolumeControl: React.FC<VolumeControlProps> = ({ volume, onVolumeChange }) => {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onVolumeChange(Number(e.target.value) / 100)
  }

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
      <label htmlFor="volume-control" style={{ color: '#888', fontSize: '0.9em' }}>
        Volume:
      </label>
      <input
        type="range"
        id="volume-control"
        min="0"
        max="100"
        value={volume * 100}
        onChange={handleChange}
        tabIndex={-1}
        style={{
          width: '100px',
          height: '6px',
          background: '#333',
          borderRadius: '3px',
          outline: 'none',
          WebkitAppearance: 'none'
        }}
      />
    </div>
  )
}
