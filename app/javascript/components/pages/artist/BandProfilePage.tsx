import React, { useState, useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import BandProfileLayout from '~/components/layouts/BandProfileLayout'
import { bandProfiles } from './bandProfileConfig'
import { apiFetch, apiJson } from '~/utils/apiClient'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useHackrScopedDedupSet } from '~/hooks/useHackrScopedDedup'

interface Track {
  id: number
  title: string
  track_number: number | null
  duration: string | null
}

interface Artist {
  id: number
  name: string
  slug: string
  tracks: Track[]
}

const BandProfilePage: React.FC = () => {
  const location = useLocation()
  const { hackr } = useGridAuth()
  const [artist, setArtist] = useState<Artist | null>(null)
  const [loading, setLoading] = useState(true)

  // Extract slug from pathname (e.g., /system-rot -> system-rot)
  const slug = location.pathname.substring(1)
  const config = bandProfiles[slug]

  useEffect(() => {
    if (!config) return

    apiJson<Artist>(`/api/artists/${slug}`)
      .then(data => {
        setArtist(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching artist:', error)
        setLoading(false)
      })
  }, [slug, config])

  // Credit the bio view once both the artist and auth have resolved —
  // handles the case where /api/grid/current_hackr returns AFTER the
  // artist API. Dedup set is scoped to hackr.id so a logout/login swap
  // in the same SPA session does not silence the new user's credit.
  const creditedSlugsRef = useHackrScopedDedupSet<string>(hackr?.id)
  useEffect(() => {
    if (!hackr || !artist?.slug) return
    if (creditedSlugsRef.current.has(artist.slug)) return
    creditedSlugsRef.current.add(artist.slug)
    apiFetch(`/api/artists/${encodeURIComponent(artist.slug)}/bio_viewed`, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }, [hackr, artist?.slug, creditedSlugsRef])

  if (!config) {
    return <div>Band not found</div>
  }

  if (loading || !artist) {
    return (
      <BandProfileLayout
        artistName={config.name}
        artistSlug={slug}
        colorScheme={config.colorScheme}
        filterName={config.filterName}
      />
    )
  }

  return (
    <BandProfileLayout
      artistName={config.name}
      artistSlug={slug}
      colorScheme={config.colorScheme}
      filterName={config.filterName}
      intro={config.renderIntro()}
      releaseSection={config.renderReleaseSection()}
      philosophySection={config.renderPhilosophy()}
    />
  )
}

export default BandProfilePage
