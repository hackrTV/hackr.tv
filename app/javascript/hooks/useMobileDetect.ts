import { useState, useEffect } from 'react'

interface MobileDetectResult {
  isMobile: boolean
  isTablet: boolean
  isDesktop: boolean
  screenWidth: number
}

/**
 * Hook to detect if user is on mobile, tablet, or desktop
 * Uses window.matchMedia for responsive breakpoints
 *
 * Breakpoints:
 * - Mobile: < 768px
 * - Tablet: >= 768px and < 1024px
 * - Desktop: >= 1024px
 */
export const useMobileDetect = (): MobileDetectResult => {
  const [detection, setDetection] = useState<MobileDetectResult>(() => {
    // Initialize with current window size (SSR-safe)
    if (typeof window === 'undefined') {
      return {
        isMobile: false,
        isTablet: false,
        isDesktop: true,
        screenWidth: 1024
      }
    }

    const width = window.innerWidth
    return {
      isMobile: width < 768,
      isTablet: width >= 768 && width < 1024,
      isDesktop: width >= 1024,
      screenWidth: width
    }
  })

  useEffect(() => {
    // Skip if window is not available (SSR)
    if (typeof window === 'undefined') return

    const mobileQuery = window.matchMedia('(max-width: 767px)')
    const tabletQuery = window.matchMedia('(min-width: 768px) and (max-width: 1023px)')
    const desktopQuery = window.matchMedia('(min-width: 1024px)')

    const updateDetection = () => {
      const width = window.innerWidth
      setDetection({
        isMobile: mobileQuery.matches,
        isTablet: tabletQuery.matches,
        isDesktop: desktopQuery.matches,
        screenWidth: width
      })
    }

    // Add listeners
    mobileQuery.addEventListener('change', updateDetection)
    tabletQuery.addEventListener('change', updateDetection)
    desktopQuery.addEventListener('change', updateDetection)

    // Also listen to window resize for screenWidth updates
    window.addEventListener('resize', updateDetection)

    // Initial check
    updateDetection()

    // Cleanup
    return () => {
      mobileQuery.removeEventListener('change', updateDetection)
      tabletQuery.removeEventListener('change', updateDetection)
      desktopQuery.removeEventListener('change', updateDetection)
      window.removeEventListener('resize', updateDetection)
    }
  }, [])

  return detection
}
