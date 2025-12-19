import { useEffect, useRef, useCallback, useState } from 'react'

declare global {
  interface Window {
    hackr?: HackrAPI
  }
}

interface HackrAPI {
  terminal: () => string
  help: () => string
}

// Konami code sequence: ↑ ↑ ↓ ↓ ← → ← → B A
const KONAMI_CODE = [
  'ArrowUp', 'ArrowUp',
  'ArrowDown', 'ArrowDown',
  'ArrowLeft', 'ArrowRight',
  'ArrowLeft', 'ArrowRight',
  'KeyB', 'KeyA'
]

export const useTerminalAccess = () => {
  const [isTerminalOpen, setIsTerminalOpen] = useState(false)

  const konamiIndex = useRef(0)
  const typeBuffer = useRef('')
  const typeTimeout = useRef<number | null>(null)

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
        `.trim()
      }
    }

    window.hackr = hackrApi

    const handleKeyDown = (e: KeyboardEvent) => {
      const inInput = isInInputField(e.target)

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

    document.addEventListener('keydown', handleKeyDown)

    return () => {
      document.removeEventListener('keydown', handleKeyDown)

      if (typeTimeout.current) {
        clearTimeout(typeTimeout.current)
      }

      // Clean up global API
      delete window.hackr
    }
  }, [openTerminal, toggleTerminal, isInInputField, isTerminalOpen])

  return {
    isTerminalOpen,
    openTerminal,
    closeTerminal,
    toggleTerminal
  }
}
