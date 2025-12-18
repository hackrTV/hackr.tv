import { useEffect, useRef, useCallback, useState } from 'react'
import { useLocation } from 'react-router-dom'
import type { AudioPlayerAPI } from '~/types/track'

declare global {
  interface Window {
    audioPlayer?: AudioPlayerAPI
    hackr?: HackrAPI
  }
}

interface HackrAPI {
  terminal: () => string
  help: () => string
}

interface UseTerminalAccessOptions {
  idleTimeout?: number // milliseconds before idle takeover (default: 120000 = 2 min)
  enableIdleTakeover?: boolean
}

// Konami code sequence: ↑ ↑ ↓ ↓ ← → ← → B A
const KONAMI_CODE = [
  'ArrowUp', 'ArrowUp',
  'ArrowDown', 'ArrowDown',
  'ArrowLeft', 'ArrowRight',
  'ArrowLeft', 'ArrowRight',
  'KeyB', 'KeyA'
]

export const useTerminalAccess = (options: UseTerminalAccessOptions = {}) => {
  const { idleTimeout = 120000, enableIdleTakeover = true } = options
  const location = useLocation()

  const [isTerminalOpen, setIsTerminalOpen] = useState(false)

  const konamiIndex = useRef(0)
  const typeBuffer = useRef('')
  const typeTimeout = useRef<number | null>(null)
  const idleTimer = useRef<number | null>(null)

  const openTerminal = useCallback(() => {
    setIsTerminalOpen(true)
  }, [])

  const closeTerminal = useCallback(() => {
    setIsTerminalOpen(false)
  }, [])

  const toggleTerminal = useCallback(() => {
    setIsTerminalOpen(prev => !prev)
  }, [])

  // Check if user is in an input field
  const isInInputField = useCallback((target: EventTarget | null): boolean => {
    if (!target || !(target instanceof HTMLElement)) return false
    return (
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.isContentEditable
    )
  }, [])

  // Reset idle timer on any activity
  const resetIdleTimer = useCallback(() => {
    if (!enableIdleTakeover) return

    if (idleTimer.current) {
      clearTimeout(idleTimer.current)
    }

    idleTimer.current = window.setTimeout(() => {
      // Don't trigger if:
      // - Terminal is already open
      // - On grid (don't interrupt gameplay)
      // - Audio is playing
      const isOnGrid = location.pathname.startsWith('/grid')
      const isAudioPlaying = window.audioPlayer?.isPlaying?.() ?? false

      if (!isOnGrid && !isAudioPlaying) {
        openTerminal()
      }
    }, idleTimeout)
  }, [enableIdleTakeover, idleTimeout, location.pathname, openTerminal])

  useEffect(() => {
    // Expose hackr.terminal() in the console
    const hackrApi: HackrAPI = {
      terminal: () => {
        openTerminal()
        return '> Accessing terminal...'
      },
      help: () => {
        return `
hackr.tv Console API
====================
hackr.terminal() - Open the terminal
hackr.help()     - Show this help message

Easter eggs:
- Press Ctrl+\` to toggle terminal
- Type "/terminal" anywhere on the page
- Enter the Konami code (↑↑↓↓←→←→BA)
- Wait 2 minutes idle for the terminal to drop down
        `.trim()
      }
    }

    window.hackr = hackrApi

    const handleKeyDown = (e: KeyboardEvent) => {
      const inInput = isInInputField(e.target)

      // Reset idle timer on any keypress (but not if terminal is open)
      if (!isTerminalOpen) {
        resetIdleTimer()
      }

      // Ctrl+` shortcut to toggle (works everywhere except inputs)
      if (!inInput && e.key === '`' && e.ctrlKey) {
        e.preventDefault()
        toggleTerminal()
        return
      }

      // Konami code detection (works even in inputs for fun)
      if (e.code === KONAMI_CODE[konamiIndex.current]) {
        konamiIndex.current++
        if (konamiIndex.current === KONAMI_CODE.length) {
          konamiIndex.current = 0
          openTerminal()
        }
      } else if (e.code !== KONAMI_CODE[konamiIndex.current]) {
        // Only reset if it's an arrow key or B/A (ignore other keys)
        const isKonamiKey = e.code.startsWith('Arrow') || e.code === 'KeyB' || e.code === 'KeyA'
        if (isKonamiKey) {
          konamiIndex.current = 0
        }
      }

      // Type-to-navigate detection (only when not in input and terminal not open)
      // Requires "/" prefix to avoid conflicting with type-to-filter
      if (!inInput && !isTerminalOpen && e.key.length === 1) {
        // Clear previous timeout
        if (typeTimeout.current) {
          clearTimeout(typeTimeout.current)
        }

        // Add character to buffer
        typeBuffer.current += e.key.toLowerCase()

        // Check if buffer contains "/terminal"
        if (typeBuffer.current.includes('/terminal')) {
          typeBuffer.current = ''
          openTerminal()
          return
        }

        // Keep only last 12 characters to prevent memory buildup
        if (typeBuffer.current.length > 12) {
          typeBuffer.current = typeBuffer.current.slice(-12)
        }

        // Clear buffer after 3 seconds of no typing
        typeTimeout.current = window.setTimeout(() => {
          typeBuffer.current = ''
        }, 3000)
      }
    }

    const handleMouseMove = () => {
      if (!isTerminalOpen) {
        resetIdleTimer()
      }
    }

    const handleClick = () => {
      if (!isTerminalOpen) {
        resetIdleTimer()
      }
    }

    const handleScroll = () => {
      if (!isTerminalOpen) {
        resetIdleTimer()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('click', handleClick)
    document.addEventListener('scroll', handleScroll)

    // Start idle timer
    if (!isTerminalOpen) {
      resetIdleTimer()
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('click', handleClick)
      document.removeEventListener('scroll', handleScroll)

      if (typeTimeout.current) {
        clearTimeout(typeTimeout.current)
      }
      if (idleTimer.current) {
        clearTimeout(idleTimer.current)
      }

      // Clean up global API
      delete window.hackr
    }
  }, [openTerminal, toggleTerminal, resetIdleTimer, isInInputField, isTerminalOpen])

  return {
    isTerminalOpen,
    openTerminal,
    closeTerminal,
    toggleTerminal
  }
}
