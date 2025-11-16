import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface Album {
  id: number
  name: string
  slug: string
  release_date: string | null
  cover_url: string | null
}

interface Track {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  featured: boolean
  album: Album | null
  audio_url: string | null
  streaming_links?: Record<string, string>
}

interface Artist {
  id: number
  name: string
  slug: string
  genre: string
  tracks: Track[]
}

const TrackListPage: React.FC = () => {
  const location = useLocation()
  const [artist, setArtist] = useState<Artist | null>(null)
  const [loading, setLoading] = useState(true)

  // Extract artist slug from pathname (e.g., /xeraen/trackz -> xeraen)
  const artistSlug = location.pathname.split('/')[1]

  useEffect(() => {
    if (!artistSlug) return

    fetch(`/api/artists/${artistSlug}`)
      .then(res => res.json())
      .then(data => {
        setArtist(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching artist:', error)
        setLoading(false)
      })
  }, [artistSlug])

  if (loading) {
    return (
      <DefaultLayout>
        <div className="tui-window ml-10">
          <LoadingSpinner message="Loading tracks..." color="green-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (!artist) {
    return (
      <DefaultLayout>
        <div className="tui-window ml-10">
          <fieldset className="tui-fieldset">
            <legend>Artist Not Found</legend>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  const tracks = artist.tracks || []
  const artistDisplayName = artist.name === 'XERAEN' ? 'XERAEN' : 'The.CyberPul.se'

  const formatPlatformName = (platform: string) => {
    return platform.replace('_', ' ').split(' ').map(word =>
      word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ')
  }

  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>{artistDisplayName} - Trackz</legend>
          <div className="pl-5 pt-5">
            {tracks.length === 0 ? (
              <p className="white-168-text">No trackz available yet. Check back soon for new releases!</p>
            ) : (
              tracks.map((track) => (
                <div key={track.id} className="mb-11">
                  <div className="tui-divider"></div>
                  <div className="mt-6">
                    <h2 className="black-168-text green-168">
                      <Link
                        to={`/${artistSlug}/trackz/${track.slug}`}
                        className="tui-link"
                      >
                        {track.title}
                        {track.featured && (
                          <span className="white-168-text black-168">
                            &nbsp;Featured Release!&nbsp;
                          </span>
                        )}
                        &nbsp;
                      </Link>
                    </h2>
                    <p className="gray-168-text">
                      {track.album?.name}
                      {track.album?.name && ' '}
                      {track.album && `(${(track.album as any).album_type?.toUpperCase() || 'ALBUM'})`}
                      {track.album?.release_date && ` • ${track.album.release_date}`}
                      {track.duration && ` • ${track.duration}`}
                    </p>
                    {track.streaming_links && Object.keys(track.streaming_links).length > 0 && (
                      <div className="mt-5">
                        {Object.entries(track.streaming_links).map(([platform, url]) => (
                          <a
                            key={platform}
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="tui-button mr-5"
                          >
                            {formatPlatformName(platform)}
                          </a>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackListPage
