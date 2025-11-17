import React, { useState, useEffect } from 'react'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface RadioStation {
  name: string
  slug: string
  description: string
  genre: string
  stream_url: string
  color: string
}

export const RadioPage: React.FC = () => {
  const [stations, setStations] = useState<RadioStation[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [currentStation, setCurrentStation] = useState<{ name: string; genre: string } | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const audioRef = React.useRef<HTMLAudioElement>(null)
  const [volume, setVolume] = useState(70)

  useEffect(() => {
    fetch('/api/radio_stations')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load stations')
        return res.json()
      })
      .then(data => {
        setStations(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  const currentYear = new Date().getFullYear()

  const tuneIn = (streamUrl: string, stationName: string, genre: string) => {
    if (!audioRef.current) return

    audioRef.current.src = streamUrl
    setCurrentStation({ name: stationName, genre })
    setIsPlaying(true)

    audioRef.current.play().catch((error) => {
      console.error('Error playing stream:', error)
      alert('Error: Unable to connect to radio stream. Please check the stream URL.')
    })
  }

  const stopRadio = () => {
    if (!audioRef.current) return

    audioRef.current.pause()
    audioRef.current.currentTime = 0
    audioRef.current.src = ''
    setIsPlaying(false)
    setCurrentStation(null)
  }

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newVolume = parseInt(e.target.value)
    setVolume(newVolume)
    if (audioRef.current) {
      audioRef.current.volume = newVolume / 100
    }
  }

  React.useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume / 100
    }
  }, [volume])

  return (
    <FmLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '1200px' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">hackr.fm :: RADIO</legend>

          <div>
            <h2 className="cyan-255-text" style={{ textAlign: 'center', marginBottom: '15px' }}>
              [:: RESISTANCE RADIO STATIONS ::]
            </h2>

            {loading && <LoadingSpinner message="Tuning radio frequencies..." color="cyan-255-text" />}
            {error && <p style={{ textAlign: 'center', padding: '40px', color: '#ff5555' }}>Error: {error}</p>}

            {!loading && !error && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
                {stations.map((station) => {
                  const isSectorX = station.slug === 'sector_x'

                  if (isSectorX) {
                    return (
                      <div key={station.slug} className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #444' }}>
                        <fieldset style={{ borderColor: '#555' }}>
                          <legend style={{ color: '#14b8a6' }}>{station.name}</legend>

                          <div style={{ padding: '15px' }}>
                            <p style={{ marginBottom: '10px', color: '#888' }}>
                              <strong>Genre:</strong> <span style={{ color: '#aaa' }}>{station.genre}</span>
                            </p>
                            <p style={{ marginBottom: '15px', lineHeight: '1.6', color: '#999' }}>
                              {station.description.replace('2125', (currentYear + 100).toString())}
                            </p>

                            {station.stream_url ? (
                              <button
                                className="tui-button tune-in-btn"
                                onClick={() => tuneIn(station.stream_url, station.name, station.genre)}
                                style={{ width: '100%', background: '#14b8a6', color: 'white' }}
                              >
                                ► TUNE IN
                              </button>
                            ) : (
                              <button
                                className="tui-button"
                                style={{ width: '100%', opacity: 0.5, cursor: 'not-allowed' }}
                                disabled
                              >
                                [COMING SOON]
                              </button>
                            )}
                          </div>
                        </fieldset>
                      </div>
                    )
                  }

                  return (
                    <div key={station.slug} className={`tui-window ${station.color} white-text`}>
                      <fieldset className={`${station.color}-border`}>
                        <legend>{station.name}</legend>

                        <div style={{ padding: '15px' }}>
                          <p style={{ marginBottom: '10px' }}>
                            <strong>Genre:</strong> {station.genre}
                          </p>
                          <p style={{ marginBottom: '15px', lineHeight: '1.6' }}>
                            {station.description.replace('2125', (currentYear + 100).toString())}
                          </p>

                          {station.stream_url ? (
                            <button
                              className={`tui-button tune-in-btn ${station.color}`}
                              onClick={() => tuneIn(station.stream_url, station.name, station.genre)}
                              style={{ width: '100%' }}
                            >
                              ► TUNE IN
                            </button>
                          ) : (
                            <button
                              className="tui-button"
                              style={{ width: '100%', opacity: 0.5, cursor: 'not-allowed' }}
                              disabled
                            >
                              [COMING SOON]
                            </button>
                          )}
                        </div>
                      </fieldset>
                    </div>
                  )
                })}
              </div>
            )}

            <div style={{ marginTop: '30px', padding: '20px', background: '#1a1a1a', border: '1px solid #444' }}>
              <h3 className="cyan-255-text" style={{ marginBottom: '10px' }}>[:: BROADCAST INFO ::]</h3>
              <p style={{ lineHeight: '1.6', color: '#ccc' }}>
                hackr.fm Radio transmits 24/7 from undisclosed locations across THE PULSE GRID.
                Each station is a beacon of resistance, broadcasting truth through the digital noise.
                Select a station above to begin streaming.
              </p>
            </div>
          </div>
        </fieldset>
      </div>

      {/* Radio Player */}
      {isPlaying && currentStation && (
        <div style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          background: '#0a0a0a',
          borderTop: '2px solid #00d9ff',
          padding: '15px 20px',
          zIndex: 1000
        }}>
          <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
              <button
                className="tui-button"
                onClick={stopRadio}
                style={{ background: '#00d9ff', color: '#000', minWidth: '80px', fontWeight: 'bold' }}
              >
                ■ STOP
              </button>

              <div style={{ flex: 1 }}>
                <div style={{ marginBottom: '5px' }}>
                  <span style={{ color: '#00d9ff', fontWeight: 'bold' }}>● LIVE</span>
                  <span style={{ color: '#666', margin: '0 10px' }}>|</span>
                  <span style={{ color: '#00d9ff', fontWeight: 'bold' }}>{currentStation.name}</span>
                </div>
                <div>
                  <span style={{ color: '#888', fontSize: '0.9em' }}>Genre: </span>
                  <span style={{ color: '#aaa', fontSize: '0.9em' }}>{currentStation.genre}</span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <span style={{ color: '#888', fontSize: '0.9em' }}>Volume:</span>
                <input
                  type="range"
                  min="0"
                  max="100"
                  value={volume}
                  onChange={handleVolumeChange}
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

              <button
                className="tui-button"
                onClick={stopRadio}
                style={{ background: '#444', color: '#aaa' }}
              >
                ✕
              </button>
            </div>
          </div>
        </div>
      )}

      <audio ref={audioRef} preload="none" />

      <style>{`
        input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 14px;
          height: 14px;
          background: #00d9ff;
          cursor: pointer;
          border-radius: 50%;
        }

        input[type="range"]::-moz-range-thumb {
          width: 14px;
          height: 14px;
          background: #00d9ff;
          cursor: pointer;
          border-radius: 50%;
          border: none;
        }
      `}</style>
    </FmLayout>
  )
}
