import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeSanitize from 'rehype-sanitize'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { EmbeddedTrack } from '~/components/EmbeddedTrack'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'

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
  const { mappings } = useCodexMappings()

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

  const platformOrder = ['bandcamp', 'youtube', 'spotify', 'apple_music', 'soundcloud']

  const titleize = (str: string) => {
    // Special case for YouTube
    if (str.toLowerCase() === 'youtube') {
      return 'YouTube'
    }
    return str.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
  }

  const sortStreamingLinks = (links: Record<string, string>) => {
    return Object.entries(links).sort((a, b) => {
      const indexA = platformOrder.indexOf(a[0].toLowerCase())
      const indexB = platformOrder.indexOf(b[0].toLowerCase())

      if (indexA !== -1 && indexB !== -1) {
        return indexA - indexB
      }
      if (indexA !== -1) return -1
      if (indexB !== -1) return 1
      return 0
    })
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

          <EmbeddedTrack trackId={track.slug} />

          {track.streaming_links && Object.keys(track.streaming_links).length > 0 && (
            <>
              <p><strong>Streaming Links:</strong></p>
              <div style={{ marginTop: '10px', marginBottom: '15px' }}>
                <Link
                  to={`/fm/pulse_vault?filter=${encodeURIComponent(track.title)}`}
                  className="tui-button"
                >
                  Pulse Vault
                </Link>
                {' '}
                {sortStreamingLinks(track.streaming_links).map(([platform, url], index, array) => (
                  <React.Fragment key={platform}>
                    <a
                      href={url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="tui-button"
                    >
                      → {titleize(platform)}
                    </a>
                    {index < array.length - 1 && ' '}
                  </React.Fragment>
                ))}
              </div>
            </>
          )}

          {track.videos && Object.keys(track.videos).length > 0 && (
            <>
              <br />
              <p><strong>Videos:</strong></p>
              <div style={{ marginTop: '10px', marginBottom: '15px' }}>
                {Object.entries(track.videos).map(([type, url], index, array) => (
                  <React.Fragment key={type}>
                    <a
                      href={url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="tui-button"
                    >
                      ▶ {titleize(type)} Video
                    </a>
                    {index < array.length - 1 && ' '}
                  </React.Fragment>
                ))}
              </div>
            </>
          )}

          {track.lyrics && (
            <>
              <br />
              <p><strong>Lyrics:</strong></p>
              <div className="white-168-text" style={{
                whiteSpace: 'pre-wrap',
                fontFamily: 'monospace',
                lineHeight: '1.6'
              }}>
                <ReactMarkdown
                  remarkPlugins={[remarkGfm]}
                  rehypePlugins={[rehypeSanitize]}
                  components={{
                    a: ({ _node, ...props }) => (
                      <a
                        style={{
                          color: '#60a5fa',
                          textDecoration: 'underline'
                        }}
                        {...props}
                      />
                    )
                  }}
                >
                  {transformMarkdownLinks(track.lyrics, mappings)}
                </ReactMarkdown>
              </div>
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
