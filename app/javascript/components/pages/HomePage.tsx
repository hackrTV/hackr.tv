import React, { useEffect, useState, useCallback } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { TerminalAnimation } from '~/components/terminal/TerminalAnimation'
import { LiveStreamEmbed } from '~/components/LiveStreamEmbed'
import { UplinkPanel } from '~/components/uplink/UplinkPanel'
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

const HEARTBEAT_KEY = 'uplink_popout_heartbeat'
const HEARTBEAT_STALE_MS = 2000 // Consider popout dead if no heartbeat for 2 seconds

const isPopoutAlive = (): boolean => {
  const heartbeat = localStorage.getItem(HEARTBEAT_KEY)
  if (!heartbeat) return false
  const lastBeat = parseInt(heartbeat, 10)
  return Date.now() - lastBeat < HEARTBEAT_STALE_MS
}

export const HomePage: React.FC = () => {
  const [streamData, setStreamData] = useState<StreamData | null>(null)
  const [loading, setLoading] = useState(true)
  const [chatPoppedOut, setChatPoppedOut] = useState(isPopoutAlive)
  const [theaterMode, setTheaterMode] = useState(false)

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

  // Check popout heartbeat periodically
  useEffect(() => {
    const checkPopoutStatus = () => {
      setChatPoppedOut(isPopoutAlive())
    }

    // Check frequently to detect when popout closes
    const checkInterval = setInterval(checkPopoutStatus, 500)

    return () => {
      clearInterval(checkInterval)
    }
  }, [])

  const handlePopout = useCallback(() => {
    const popoutWindow = window.open(
      '/uplink/popout',
      'uplink_popout',
      'width=400,height=600,resizable=yes,scrollbars=no'
    )

    if (popoutWindow) {
      // The popout page will start sending heartbeats, which we'll detect
      setChatPoppedOut(true)
    }
  }, [])

  const toggleTheaterMode = useCallback(() => {
    setTheaterMode(prev => !prev)
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
          theaterMode={theaterMode}
          onTheaterModeToggle={toggleTheaterMode}
          sideContent={
            chatPoppedOut ? undefined : (
              <UplinkPanel
                defaultChannel="live"
                livestreamOnly
                allowPopout
                onPopout={handlePopout}
              />
            )
          }
        />
      ) : (
        <TerminalAnimation />
      )}
    </DefaultLayout>
  )
}
