import React, { useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'

/**
 * Redirects paths with uppercase letters to their lowercase equivalents.
 * Excludes paths with case-sensitive tokens.
 */
export const LowercaseRedirect: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation()
  const navigate = useNavigate()

  useEffect(() => {
    const { pathname, search, hash } = location

    // Skip paths with case-sensitive tokens
    if (pathname.startsWith('/shared/') || pathname.startsWith('/grid/verify/') || pathname.startsWith('/grid/reset_password/')) {
      return
    }

    const lowercasePath = pathname.toLowerCase()

    if (pathname !== lowercasePath) {
      navigate(lowercasePath + search + hash, { replace: true })
    }
  }, [location, navigate])

  return <>{children}</>
}
