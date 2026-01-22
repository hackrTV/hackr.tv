import React, { useEffect } from 'react'
import { UplinkPanel } from '~/components/uplink/UplinkPanel'

const HEARTBEAT_KEY = 'uplink_popout_heartbeat'
const HEARTBEAT_INTERVAL = 500 // ms

export const UplinkPopoutPage: React.FC = () => {
  useEffect(() => {
    // Send initial heartbeat
    localStorage.setItem(HEARTBEAT_KEY, Date.now().toString())

    // Send heartbeat periodically so main window knows we're still alive
    const heartbeatInterval = setInterval(() => {
      localStorage.setItem(HEARTBEAT_KEY, Date.now().toString())
    }, HEARTBEAT_INTERVAL)

    // Clean up when window closes
    const handleBeforeUnload = () => {
      localStorage.removeItem(HEARTBEAT_KEY)
    }

    window.addEventListener('beforeunload', handleBeforeUnload)

    return () => {
      clearInterval(heartbeatInterval)
      window.removeEventListener('beforeunload', handleBeforeUnload)
      localStorage.removeItem(HEARTBEAT_KEY)
    }
  }, [])

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: '#0a0a0a',
        display: 'flex',
        flexDirection: 'column'
      }}
    >
      <UplinkPanel defaultChannel="live" livestreamOnly />
    </div>
  )
}

export default UplinkPopoutPage
