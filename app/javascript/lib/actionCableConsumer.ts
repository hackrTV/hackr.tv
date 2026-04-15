import { createConsumer, Cable } from '@rails/actioncable'

/**
 * Singleton ActionCable consumer. One WebSocket per app session,
 * shared across every channel subscription. Lazy-initialized on
 * first access — module import is side-effect-free.
 *
 * Hooks should subscribe via `getActionCableConsumer().subscriptions.create(...)`
 * and call `.unsubscribe()` on cleanup. Do NOT call `.disconnect()` on
 * the returned cable — other hooks may still be using it. The cable
 * stays up for the lifetime of the page.
 *
 * Migration status: `useAchievementChannel` uses this. Pre-existing
 * hooks (`useActionCable`, `useStreamStatus`, `usePulseWire`,
 * `useUplink`) each still open their own consumer — migrating them
 * is tracked as follow-up work (each has its own reconnect / presence
 * logic that needs careful validation, out of scope for the
 * achievement feature).
 */
let cable: Cable | null = null

export const getActionCableConsumer = (): Cable => {
  if (!cable) {
    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    cable = createConsumer(`${wsProtocol}//${window.location.host}/cable`)
  }
  return cable
}

/**
 * Test-only reset. Disconnects the singleton and clears it so the
 * next test run initializes fresh. Never call from production code.
 */
export const _resetActionCableConsumerForTests = (): void => {
  cable?.disconnect()
  cable = null
}
