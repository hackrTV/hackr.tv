import { useRef, useEffect } from 'react'

/**
 * Per-user dedup ref for achievement credit calls. Returns a stable
 * Set ref that is automatically cleared whenever the authenticated
 * hackr id changes (logout, login, A → B swap), so one hackr's prior
 * credits do not suppress another hackr's first credit within the
 * same SPA session.
 */
export const useHackrScopedDedupSet = <T>(hackrId: number | null | undefined) => {
  const ref = useRef<Set<T>>(new Set())
  useEffect(() => {
    ref.current = new Set()
  }, [hackrId])
  return ref
}

/**
 * Boolean variant for pages with a hardcoded single target (e.g. a
 * custom bio page for one artist). Resets to `false` on hackr swap.
 */
export const useHackrScopedDedupFlag = (hackrId: number | null | undefined) => {
  const ref = useRef(false)
  useEffect(() => {
    ref.current = false
  }, [hackrId])
  return ref
}
