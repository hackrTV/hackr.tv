import React, { useEffect, useState } from 'react'
import { useAudio } from '~/contexts/AudioContext'
import type { TrackData } from '~/types/track'
import { apiJson } from '~/utils/apiClient'

interface EmbeddedTrackProps {
  trackId: string
}

export const EmbeddedTrack: React.FC<EmbeddedTrackProps> = ({ trackId }) => {
  const { audioPlayerAPI } = useAudio()
  const [trackData, setTrackData] = useState<TrackData | null>(null)
  const [isCurrentTrack, setIsCurrentTrack] = useState(false)
  const [isPlayerPlaying, setIsPlayerPlaying] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Fetch track data
  useEffect(() => {
    interface ApiTrack {
      id: number
      title: string
      audio_url: string | null
      artist: { name: string }
      release?: { cover_url: string | null; cover_urls?: { thumbnail: string; standard: string; full: string } }
    }

    const fetchTrack = async () => {
      try {
        setLoading(true)
        const data = await apiJson<ApiTrack>(`/api/tracks/${trackId}`)

        // Transform API response to TrackData format
        const track: TrackData = {
          id: data.id.toString(),
          url: data.audio_url || '',
          title: data.title,
          artist: data.artist.name,
          coverUrl: data.release?.cover_url || '',
          coverUrls: data.release?.cover_urls
        }

        setTrackData(track)
        setError(null)
      } catch (err) {
        console.error('Error fetching track:', err)
        setError(err instanceof Error ? err.message : 'Failed to load track')
      } finally {
        setLoading(false)
      }
    }

    fetchTrack()
  }, [trackId])

  // Check if this track is currently playing
  useEffect(() => {
    const checkPlayingStatus = () => {
      if (!audioPlayerAPI.current || !trackData) return

      const currentId = audioPlayerAPI.current.getCurrentTrackId()
      const playing = audioPlayerAPI.current.isPlaying()

      setIsCurrentTrack(currentId === trackData.id)
      setIsPlayerPlaying(playing)
    }

    // Check initially
    checkPlayingStatus()

    // Check periodically (in case player state changes)
    const interval = setInterval(checkPlayingStatus, 500)
    return () => clearInterval(interval)
  }, [audioPlayerAPI, trackData])

  const handlePlay = () => {
    if (!audioPlayerAPI.current || !trackData) return

    if (isCurrentTrack && isPlayerPlaying) {
      // If this track is playing, pause it
      audioPlayerAPI.current.togglePlayPause()
    } else if (isCurrentTrack && !isPlayerPlaying) {
      // If this track is paused, resume it
      audioPlayerAPI.current.togglePlayPause()
    } else {
      // Load and play this track
      audioPlayerAPI.current.loadTrack(trackData)
    }
  }

  if (loading) {
    return (
      <div className="embedded-track-player" style={{
        border: '2px solid #7c3aed',
        padding: '20px',
        marginBottom: '20px',
        background: 'rgba(124, 58, 237, 0.05)'
      }}>
        <div style={{ color: '#a78bfa', textAlign: 'center' }}>Loading track...</div>
      </div>
    )
  }

  if (error || !trackData) {
    return (
      <div className="embedded-track-player" style={{
        border: '2px solid #ef4444',
        padding: '20px',
        marginBottom: '20px',
        background: 'rgba(239, 68, 68, 0.05)'
      }}>
        <div style={{ color: '#ef4444', textAlign: 'center' }}>
          {error || 'Track not found'}
        </div>
      </div>
    )
  }

  const buttonText = isCurrentTrack && isPlayerPlaying ? '❚❚ PAUSE' : '► PLAY'
  const buttonColor = isCurrentTrack && isPlayerPlaying ? '#9333ea' : '#7c3aed'
  const textColor = isCurrentTrack && isPlayerPlaying ? '#00d9ff' : 'white'

  return (
    <div className="embedded-track-player" style={{
      border: '2px solid #7c3aed',
      padding: '20px',
      marginBottom: '20px',
      background: isCurrentTrack ? '#2d1b4e' : '#1a1a1a',
      display: 'flex',
      alignItems: 'center',
      gap: '20px'
    }}>
      {/* Album Cover */}
      {trackData.coverUrl && (
        <div style={{
          flexShrink: 0,
          width: '100px',
          height: '100px',
          border: '2px solid #7c3aed',
          overflow: 'hidden'
        }}>
          <img
            src={trackData.coverUrls?.standard || trackData.coverUrl}
            alt={`${trackData.title} cover`}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              display: 'block'
            }}
          />
        </div>
      )}

      {/* Track Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: isCurrentTrack ? '#a78bfa' : '#fff',
          fontSize: '18px',
          fontWeight: 'bold',
          marginBottom: '8px',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap'
        }}>
          {trackData.title}
        </div>
        <div style={{
          color: '#a78bfa',
          fontSize: '14px',
          marginBottom: '12px',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap'
        }}>
          {trackData.artist}
        </div>

        {/* Play Button */}
        <button
          onClick={handlePlay}
          disabled={!trackData.url}
          style={{
            background: trackData.url ? buttonColor : '#666',
            color: textColor,
            border: 'none',
            padding: '10px 20px',
            fontSize: '14px',
            fontWeight: 'bold',
            cursor: trackData.url ? 'pointer' : 'not-allowed',
            transition: 'all 0.2s',
            fontFamily: 'monospace'
          }}
          onMouseEnter={(e) => {
            if (trackData.url) {
              e.currentTarget.style.background = '#9333ea'
            }
          }}
          onMouseLeave={(e) => {
            if (trackData.url) {
              e.currentTarget.style.background = buttonColor
            }
          }}
        >
          {trackData.url ? buttonText : 'NO AUDIO FILE'}
        </button>
      </div>
    </div>
  )
}
