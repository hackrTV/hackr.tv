import { useState, useEffect } from 'react'
import { apiJson } from '~/utils/apiClient'
import type { HandbookTree } from '~/types/handbook'

let cachedTree: HandbookTree | null = null
let fetchPromise: Promise<HandbookTree> | null = null

async function fetchHandbookTree (): Promise<HandbookTree> {
  if (cachedTree !== null) return cachedTree
  if (fetchPromise !== null) return fetchPromise

  fetchPromise = apiJson<HandbookTree>('/api/handbook')
    .then(data => {
      cachedTree = data
      fetchPromise = null
      return data
    })
    .catch(err => {
      fetchPromise = null
      throw err
    })

  return fetchPromise
}

export function useHandbookTree () {
  const [tree, setTree] = useState<HandbookTree | null>(() => cachedTree)
  const [loading, setLoading] = useState(() => !cachedTree)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (cachedTree !== null) return

    let mounted = true
    fetchHandbookTree()
      .then(data => {
        if (mounted) {
          setTree(data)
          setLoading(false)
        }
      })
      .catch(err => {
        if (mounted) {
          console.error('Failed to load handbook tree:', err)
          setError(err?.message || 'Failed to load handbook')
          setLoading(false)
        }
      })
    return () => { mounted = false }
  }, [])

  return { tree, loading, error }
}

export function invalidateHandbookTree (): void {
  cachedTree = null
}
