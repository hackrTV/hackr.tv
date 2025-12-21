import { useGridAuthContext } from '~/contexts/GridAuthContext'

// Re-export types for backward compatibility
export type { GridHackr, GridRoom } from '~/contexts/GridAuthContext'

/**
 * Hook to access grid authentication state and methods.
 * Uses shared context to avoid multiple API calls and re-renders.
 */
export const useGridAuth = () => {
  return useGridAuthContext()
}
