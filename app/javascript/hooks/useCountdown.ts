import { useState, useEffect, useCallback } from 'react'

const EXPIRY_SEC = 3600

/**
 * Returns a countdown string for a target ISO timestamp.
 * - "> 1hr": "in 2h 14m"
 * - "< 1hr": "in 47m 12s"
 * - "<= 0 && < 1hr past": "STARTING SOON!"
 * - "> 1hr past or null": "" (expired)
 */
export const useCountdown = (targetIso: string | null): string => {
  const computeDisplay = useCallback(() => {
    if (!targetIso) return ''
    const diffSec = Math.floor((new Date(targetIso).getTime() - Date.now()) / 1000)

    if (diffSec <= -EXPIRY_SEC) return ''
    if (diffSec <= 0) return 'STARTING SOON!'

    const hours = Math.floor(diffSec / 3600)
    const minutes = Math.floor((diffSec % 3600) / 60)
    const seconds = diffSec % 60

    return hours > 0
      ? `in ${hours}h ${minutes}m`
      : `in ${minutes}m ${seconds}s`
  }, [targetIso])

  const [display, setDisplay] = useState(computeDisplay)

  useEffect(() => {
    setDisplay(computeDisplay())

    if (!targetIso) return

    const id = window.setInterval(() => {
      const value = computeDisplay()
      setDisplay(value)
      // Stop when expired
      if (value === '') window.clearInterval(id)
    }, 1000)

    return () => window.clearInterval(id)
  }, [targetIso, computeDisplay])

  return display
}
