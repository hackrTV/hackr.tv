import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface Album {
  id: number
  name: string
  slug: string
  album_type: string | null
  release_date: string | null
  description: string | null
  cover_url: string | null
}

interface Artist {
  id: number
  name: string
  slug: string
  genre: string
}

interface Track {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  featured: boolean
  release_date: string | null
  lyrics: string | null
  streaming_links: Record<string, string> | null
  videos: Record<string, string> | null
  artist: Artist
  album: Album | null
  audio_url: string | null
}

const TrackDetailPage: React.FC = () => {
  const location = useLocation()
  const [track, setTrack] = useState<Track | null>(null)
  const [loading, setLoading] = useState(true)

  // Extract artist slug and track slug from pathname
  // e.g., /xeraen/trackz/encrypted-shroud -> artistSlug: xeraen, trackSlug: encrypted-shroud
  const pathParts = location.pathname.split('/')
  const artistSlug = pathParts[1]
  const trackSlug = pathParts[3]

  useEffect(() => {
    if (!trackSlug) return

    fetch(`/api/tracks/${trackSlug}`)
      .then(res => res.json())
      .then(data => {
        setTrack(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching track:', error)
        setLoading(false)
      })
  }, [trackSlug])

  if (loading) {
    return (
      <DefaultLayout>
        <div className="tui-window white-168-text">
          <LoadingSpinner message="Loading track details..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (!track) {
    return (
      <DefaultLayout>
        <div className="tui-window white-168-text">
          <fieldset className="tui-fieldset">
            <legend>Track Not Found</legend>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  const titleize = (str: string) => {
    return str.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
  }

  return (
    <DefaultLayout>
      <div className="tui-window white-168-text">
        <fieldset className="tui-fieldset">
          <legend>{track.title}</legend>

          <p><strong>Artist:</strong> {track.artist.name}</p>

          {track.album && (
            <p><strong>Album:</strong> {track.album.name}</p>
          )}

          {track.album?.album_type && (
            <p><strong>Album Type:</strong> {track.album.album_type.toUpperCase()}</p>
          )}

          {track.release_date && (
            <p><strong>Release Date:</strong> {track.release_date}</p>
          )}

          {track.duration && (
            <p><strong>Duration:</strong> {track.duration}</p>
          )}

          {track.streaming_links && Object.keys(track.streaming_links).length > 0 && (
            <>
              <br />
              <p><strong>Streaming Links:</strong></p>
              <ul>
                {Object.entries(track.streaming_links).map(([platform, url]) => (
                  <li key={platform}>
                    <a href={url} className="tui-link" target="_blank" rel="noopener noreferrer">
                      {titleize(platform)}
                    </a>
                  </li>
                ))}
              </ul>
            </>
          )}

          {track.videos && Object.keys(track.videos).length > 0 && (
            <>
              <br />
              <p><strong>Videos:</strong></p>
              <ul>
                {Object.entries(track.videos).map(([type, url]) => (
                  <li key={type}>
                    <a href={url} className="tui-link" target="_blank" rel="noopener noreferrer">
                      {titleize(type)} Video
                    </a>
                  </li>
                ))}
              </ul>
            </>
          )}

          {track.lyrics && (
            <>
              <br />
              <p><strong>Lyrics:</strong></p>
              <pre className="white-168-text">{track.lyrics}</pre>
            </>
          )}

          <br />
          <p>
            <Link to={`/${artistSlug}/trackz`} className="tui-link">
              ← Back to all tracks
            </Link>
          </p>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackDetailPage
