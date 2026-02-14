import React, { useState, useEffect, useCallback, useRef } from 'react'

interface ContextMenuState<T> {
  isOpen: boolean
  position: { x: number; y: number }
  data: T | null
}

export function useContextMenu<T> () {
  const [state, setState] = useState<ContextMenuState<T>>({
    isOpen: false,
    position: { x: 0, y: 0 },
    data: null
  })
  const menuRef = useRef<HTMLDivElement>(null)

  const open = useCallback((e: React.MouseEvent, data: T) => {
    e.preventDefault()
    setState({
      isOpen: true,
      position: { x: e.clientX, y: e.clientY },
      data
    })
  }, [])

  const close = useCallback(() => {
    setState(prev => ({ ...prev, isOpen: false, data: null }))
  }, [])

  useEffect(() => {
    if (!state.isOpen) return

    const handleMouseDown = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        close()
      }
    }

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        close()
      }
    }

    document.addEventListener('mousedown', handleMouseDown)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('mousedown', handleMouseDown)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [state.isOpen, close])

  return {
    isOpen: state.isOpen,
    position: state.position,
    data: state.data,
    menuRef,
    open,
    close
  }
}
