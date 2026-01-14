import React, { useEffect, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { TerminalAnimation } from '~/components/terminal/TerminalAnimation'
import { LiveStreamEmbed } from '~/components/LiveStreamEmbed'
import { apiJson } from '~/utils/apiClient'

interface StreamData {
  is_live: boolean
  artist?: {
    id: number
    name: string
    slug: string
  }
  title?: string
  live_url?: string
  vod_url?: string
  started_at?: string
}

export const HomePage: React.FC = () => {
  const [streamData, setStreamData] = useState<StreamData | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchStreamStatus = async () => {
    try {
      const data = await apiJson<StreamData>('/api/hackr_stream')
      setStreamData(data)
    } catch (error) {
      console.error('Failed to fetch stream status:', error)
      setStreamData({ is_live: false })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchStreamStatus()

    // Poll every 30 seconds to check for stream changes
    const interval = setInterval(fetchStreamStatus, 30000)

    return () => clearInterval(interval)
  }, [])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '60vh',
          color: '#888'
        }}>
          Loading...
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      {streamData?.is_live && streamData.live_url ? (
        <LiveStreamEmbed
          url={streamData.live_url}
          title={streamData.title}
          artistName={streamData.artist?.name}
        />
      ) : (
        <TerminalAnimation />
      )}
    </DefaultLayout>
  )
}
