import React, { useState, useRef, KeyboardEvent } from 'react'
import { useCommandHistory } from '~/hooks/useCommandHistory'

interface CommandInputProps {
  onSubmit: (command: string) => void
  disabled?: boolean
}

export const CommandInput: React.FC<CommandInputProps> = ({ onSubmit, disabled = false }) => {
  const [input, setInput] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const { addCommand, navigateUp, navigateDown } = useCommandHistory()

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      const newValue = navigateUp(input)
      setInput(newValue)
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      const newValue = navigateDown(input)
      setInput(newValue)
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (input.trim() && !disabled) {
      addCommand(input.trim())
      onSubmit(input.trim())
      setInput('')
      inputRef.current?.focus()
    }
  }

  return (
    <>
      <form onSubmit={handleSubmit} id="command-form">
        <div style={{ display: 'flex', gap: '8px', marginBottom: '6px' }}>
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Enter command (type 'help' for commands)"
            autoFocus
            autoComplete="off"
            disabled={disabled}
            style={{
              flex: 1,
              background: '#262626',
              color: '#e0e0e0',
              border: '1px solid #4b5563',
              padding: '6px 10px',
              fontFamily: 'monospace',
              fontSize: '0.9em',
              borderRadius: '3px',
            }}
          />
          <button
            type="submit"
            disabled={disabled}
            style={{
              background: '#7c3aed',
              color: 'white',
              border: 'none',
              padding: '6px 16px',
              fontSize: '0.85em',
              cursor: disabled ? 'not-allowed' : 'pointer',
              borderRadius: '3px',
              fontWeight: 'bold',
              opacity: disabled ? 0.5 : 1,
            }}
          >
            EXECUTE
          </button>
        </div>
      </form>
      <div
        style={{
          fontSize: '0.75em',
          color: '#9ca3af',
          lineHeight: '1.3',
        }}
      >
        Commands: look, go [dir], take/drop [item], say [msg], talk/ask [npc], inventory, who, help, clear
        <span style={{ marginLeft: '10px', color: '#666' }}>|</span>
        <span style={{ marginLeft: '10px' }}>↑/↓ for history</span>
      </div>
    </>
  )
}
