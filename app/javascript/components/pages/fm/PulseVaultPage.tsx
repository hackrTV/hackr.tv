import React, { useState, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { TrackTable } from '~/components/audio/TrackTable'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface Track {
  id: number
  title: string
  artist: { name: string }
  album: { name: string; cover_url: string | null }
  audio_url: string | null
}

export const PulseVaultPage: React.FC = () => {
  const [searchParams] = useSearchParams()
  const [tracks, setTracks] = useState<Track[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Get initial filter from URL query parameter
  const initialFilter = searchParams.get('filter') || ''

  useEffect(() => {
    apiJson<Track[]>('/api/tracks')
      .then(data => {
        setTracks(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Unknown error')
        setLoading(false)
      })
  }, [])

  return (
    <FmLayout>
      <div className="tui-window white-text" style={{ maxWidth: '1400px', margin: '0 auto', display: 'block', background: '#1a1a1a', border: '2px solid #666' }}>
        <fieldset style={{ borderColor: '#666' }}>
          <legend className="center" style={{ color: '#a78bfa' }}>hackr.fm :: PULSE VAULT</legend>

          <div>
            <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#a78bfa' }}>
              [:: MUSIC DISCOVERY :: ALL TRACKS ::]
            </h2>

            <div style={{ marginBottom: '30px', padding: '15px', background: '#0a0a0a', border: '1px solid #444' }}>
              <p style={{ color: '#999', textAlign: 'center' }}>
                {loading ? 'Loading...' : `${tracks.length} / ${tracks.length} tracks available for streaming | Browse by artist, discover by genre, experience the resistance`}
              </p>
            </div>

            {loading && <LoadingSpinner message="Loading tracks from the Pulse Vault..." color="purple-168-text" />}
            {error && <p style={{ textAlign: 'center', color: '#ff5555' }}>Error: {error}</p>}
            {!loading && !error && <TrackTable tracks={tracks} initialFilter={initialFilter} />}
          </div>
        </fieldset>
      </div>
    </FmLayout>
  )
}
