import React, { useState, useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import BandProfileLayout from '~/components/layouts/BandProfileLayout'
import { bandProfiles } from './bandProfileConfig'
import { apiJson } from '~/utils/apiClient'

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
