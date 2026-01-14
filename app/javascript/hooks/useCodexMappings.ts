import { useState, useEffect } from 'react'
import { apiJson } from '~/utils/apiClient'

/**
 * Codex slug->name mapping for canonical display
 * e.g., { "xeraen": "XERAEN", "the-pulse-grid": "The Pulse Grid" }
 */
export type CodexMappings = Record<string, string>

// Global cache to avoid fetching on every component mount
let cachedMappings: CodexMappings | null = null
let fetchPromise: Promise<CodexMappings> | null = null

/**
 * Fetches the slug->name mapping for all published Codex entries
 * Results are cached globally to avoid redundant API calls
 */
async function fetchCodexMappings (): Promise<CodexMappings> {
  // Return cached data if available
  if (cachedMappings !== null) {
    return cachedMappings
  }

  // Return in-flight promise if already fetching
  if (fetchPromise !== null) {
    return fetchPromise
  }

  // Fetch the mappings
  fetchPromise = apiJson<CodexMappings>('/api/codex/mappings')
    .then(data => {
      cachedMappings = data
      fetchPromise = null
      return data
    })
    .catch(err => {
      console.error('Error fetching codex mappings:', err)
      fetchPromise = null
      // Return empty mapping on error to avoid breaking links
      return {}
    })

  return fetchPromise
}

/**
 * Hook to load and access Codex slug->name mappings
 *
 * Returns { mappings, loading, error } where:
 * - mappings: The slug->name mapping object (empty during load)
 * - loading: Boolean indicating if still fetching
 * - error: Error message if fetch failed, null otherwise
 *
 * @example
 * const { mappings, loading } = useCodexMappings()
 *
 * if (!loading) {
 *   const canonicalName = mappings['xeraen'] || 'xeraen' // "XERAEN"
 * }
 */
export function useCodexMappings () {
  const [mappings, setMappings] = useState<CodexMappings>(() => cachedMappings || {})
  const [loading, setLoading] = useState(() => !cachedMappings)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Skip fetch if already cached
    if (cachedMappings !== null) {
      return
    }

    // Fetch mappings
    fetchCodexMappings()
      .then(data => {
        setMappings(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load codex mappings:', err)
        setError(err.message || 'Failed to load codex mappings')
        setLoading(false)
      })
  }, [])

  return { mappings, loading, error }
}

/**
 * Preloads the Codex mappings before they're needed
 * Call this on app initialization to avoid loading delays
 */
export function preloadCodexMappings (): void {
  fetchCodexMappings()
}
