import React, { useEffect, useRef, useState } from 'react'

interface YouTubePlayerProps {
  videoId: string
  width?: number
  height?: number
}

// YouTube Player types
interface YTPlayer {
  playVideo: () => void
  pauseVideo: () => void
  destroy: () => void
}

interface YTPlayerEvent {
  target: YTPlayer
}

// Extend Window interface to include YouTube API
declare global {
  interface Window {
    YT: {
      Player: new (element: HTMLElement, config: Record<string, unknown>) => YTPlayer
      PlayerState?: {
        PLAYING: number
        PAUSED: number
      }
    }
    onYouTubeIframeAPIReady: () => void
  }
}

export const YouTubePlayer: React.FC<YouTubePlayerProps> = ({
  videoId,
  width = 560,
  height = 315
}) => {
  const playerRef = useRef<HTMLDivElement>(null)
  const [player, setPlayer] = useState<YTPlayer | null>(null)
  const [showThumbnail, setShowThumbnail] = useState(true)
  const isAPIReadyRef = useRef(false)

  // Load YouTube IFrame API
  useEffect(() => {
    // Check if API is already loaded
    if (window.YT && window.YT.Player) {
      isAPIReadyRef.current = true
      return
    }

    // Load the API script
    const tag = document.createElement('script')
    tag.src = 'https://www.youtube.com/iframe_api'
    const firstScriptTag = document.getElementsByTagName('script')[0]
    firstScriptTag.parentNode?.insertBefore(tag, firstScriptTag)

    // Set up callback for when API is ready
    window.onYouTubeIframeAPIReady = () => {
      isAPIReadyRef.current = true
    }

    return () => {
      // Clean up
      delete window.onYouTubeIframeAPIReady
    }
  }, [])

  // Create player when API is ready and user clicks play
  const initializePlayer = () => {
    if (!isAPIReadyRef.current || !playerRef.current || player) return

    const newPlayer = new window.YT.Player(playerRef.current, {
      height: String(height),
      width: String(width),
      videoId: videoId,
      playerVars: {
        autoplay: 1,
        controls: 1,
        modestbranding: 1,
        rel: 0
      },
      events: {
        onReady: (event: YTPlayerEvent) => {
          event.target.playVideo()
        }
      }
    })

    setPlayer(newPlayer)
    setShowThumbnail(false)
  }

  const handlePlayClick = () => {
    if (player) {
      player.playVideo()
      setShowThumbnail(false)
    } else {
      initializePlayer()
    }
  }

  return (
    <div
      style={{
        position: 'relative',
        width: `${width}px`,
        height: `${height}px`,
        maxWidth: '100%',
        background: '#000'
      }}
    >
      {showThumbnail && (
        <div
          onClick={handlePlayClick}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            cursor: 'pointer',
            backgroundImage: `url(https://img.youtube.com/vi/${videoId}/maxresdefault.jpg)`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 2
          }}
        >
          <div
            style={{
              width: '80px',
              height: '80px',
              background: 'rgba(0, 0, 0, 0.8)',
              border: '3px solid #7c3aed',
              borderRadius: '4px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all 0.3s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#7c3aed'
              e.currentTarget.style.transform = 'scale(1.1)'
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'rgba(0, 0, 0, 0.8)'
              e.currentTarget.style.transform = 'scale(1)'
            }}
          >
            <div
              style={{
                width: 0,
                height: 0,
                borderLeft: '25px solid #fff',
                borderTop: '15px solid transparent',
                borderBottom: '15px solid transparent',
                marginLeft: '5px'
              }}
            />
          </div>
        </div>
      )}

      <div
        ref={playerRef}
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          zIndex: 1
        }}
      />
    </div>
  )
}
