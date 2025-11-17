import { useState, useEffect, useCallback } from 'react'

const STORAGE_KEY = 'grid_command_history'
const MAX_HISTORY = 100

export const useCommandHistory = () => {
  // Initialize history from sessionStorage on mount (lazy initialization)
  const [history, setHistory] = useState<string[]>(() => {
    const stored = sessionStorage.getItem(STORAGE_KEY)
    if (stored) {
      try {
        const parsed = JSON.parse(stored)
        if (Array.isArray(parsed)) {
          return parsed
        }
      } catch (err) {
        console.error('Failed to parse command history from storage:', err)
      }
    }
    return []
  })
  const [historyIndex, setHistoryIndex] = useState<number>(-1)
  const [currentDraft, setCurrentDraft] = useState<string>('')

  // Save history to sessionStorage whenever it changes
  useEffect(() => {
    if (history.length > 0) {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(history))
    }
  }, [history])

  // Add a command to history
  const addCommand = useCallback((command: string) => {
    if (!command.trim()) return

    setHistory(prev => {
      // Don't add if it's the same as the last command
      if (prev.length > 0 && prev[prev.length - 1] === command) {
        return prev
      }

      const newHistory = [...prev, command]

      // Keep only the last MAX_HISTORY commands
      if (newHistory.length > MAX_HISTORY) {
        return newHistory.slice(-MAX_HISTORY)
      }

      return newHistory
    })

    // Reset index after adding
    setHistoryIndex(-1)
    setCurrentDraft('')
  }, [])

  // Navigate backward through history (up arrow)
  const navigateUp = useCallback((currentInput: string) => {
    if (history.length === 0) return currentInput

    // Save current input as draft if we're starting to navigate
    if (historyIndex === -1) {
      setCurrentDraft(currentInput)
    }

    const newIndex = historyIndex === -1 ? history.length - 1 : Math.max(0, historyIndex - 1)
    setHistoryIndex(newIndex)

    return history[newIndex]
  }, [history, historyIndex])

  // Navigate forward through history (down arrow)
  const navigateDown = useCallback((currentInput: string) => {
    if (history.length === 0 || historyIndex === -1) return currentInput

    const newIndex = historyIndex + 1

    if (newIndex >= history.length) {
      // Reached the end, restore draft
      setHistoryIndex(-1)
      return currentDraft
    }

    setHistoryIndex(newIndex)
    return history[newIndex]
  }, [history, historyIndex, currentDraft])

  // Clear history
  const clearHistory = useCallback(() => {
    setHistory([])
    setHistoryIndex(-1)
    setCurrentDraft('')
    sessionStorage.removeItem(STORAGE_KEY)
  }, [])

  return {
    history,
    addCommand,
    navigateUp,
    navigateDown,
    clearHistory
  }
}
