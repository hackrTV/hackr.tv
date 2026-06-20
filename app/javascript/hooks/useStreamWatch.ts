import { useEffect, useRef } from 'react'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface Unsubscribable {
  unsubscribe: () => void
}

/**
 * Accrues livestream watch time for the current hackr by holding a
 * StreamWatchChannel subscription while the stream is live AND the tab
 * is visible. The server credits watch time on a 60s `periodically`
 * tick — the client only opens/closes the subscription. Tearing down on
 * tab-hidden keeps the recorded time ≈ time actually looking at the page
 * (the iframe player itself is opaque, so this is the best signal we get).
 */
export const useStreamWatch = (enabled: boolean): void => {
  const subRef = useRef<Unsubscribable | null>(null)

  useEffect(() => {
    if (!enabled) return

    let cancelled = false

    const open = () => {
      if (subRef.current || cancelled) return
      subRef.current = getActionCableConsumer().subscriptions.create({
        channel: 'StreamWatchChannel'
      }) as unknown as Unsubscribable
    }

    const close = () => {
      subRef.current?.unsubscribe()
      subRef.current = null
    }

    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        open()
      } else {
        close()
      }
    }

    if (document.visibilityState === 'visible') open()
    document.addEventListener('visibilitychange', handleVisibility)

    return () => {
      cancelled = true
      document.removeEventListener('visibilitychange', handleVisibility)
      close()
    }
  }, [enabled])
}
