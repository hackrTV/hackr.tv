import React, { useEffect, useRef } from 'react'

interface TerminalModalProps {
  isOpen: boolean
  onClose: () => void
}

export const TerminalModal: React.FC<TerminalModalProps> = ({ isOpen, onClose }) => {
  const iframeRef = useRef<HTMLIFrameElement>(null)

  // Handle Escape key to close
  useEffect(() => {
    if (!isOpen) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => {
      document.body.style.overflow = ''
    }
  }, [isOpen])

  return (
    <>
      <style>{`
        .terminal-modal-backdrop {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.85);
          z-index: 99998;
          opacity: 0;
          visibility: hidden;
          pointer-events: none;
          transition: opacity 0.3s ease, visibility 0.3s ease;
        }

        .terminal-modal-backdrop.open {
          opacity: 1;
          visibility: visible;
          pointer-events: auto;
        }

        .terminal-modal-container {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          height: 95vh;
          max-height: 1000px;
          z-index: 99999;
          transform: translateY(-100%);
          pointer-events: none;
          transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);
          display: flex;
          flex-direction: column;
        }

        .terminal-modal-container.open {
          transform: translateY(0);
          pointer-events: auto;
        }

        .terminal-modal-header {
          background: #1a1a1a;
          border-bottom: 2px solid #a78bfa;
          padding: 8px 15px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          flex-shrink: 0;
        }

        .terminal-modal-title {
          color: #a78bfa;
          font-family: 'Courier New', monospace;
          font-size: 14px;
          font-weight: bold;
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .terminal-modal-title::before {
          content: '>';
          color: #22d3ee;
          animation: terminal-blink 1s infinite;
        }

        @keyframes terminal-blink {
          0%, 49% { opacity: 1; }
          50%, 100% { opacity: 0; }
        }

        .terminal-modal-close {
          background: none;
          border: 1px solid #ef4444;
          color: #ef4444;
          padding: 4px 12px;
          font-family: 'Courier New', monospace;
          font-size: 12px;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .terminal-modal-close:hover {
          background: #ef4444;
          color: #0a0a0a;
        }

        .terminal-modal-hints {
          color: #6b7280;
          font-family: 'Courier New', monospace;
          font-size: 11px;
          display: flex;
          gap: 15px;
        }

        .terminal-modal-hints kbd {
          background: #333;
          padding: 2px 6px;
          border-radius: 3px;
          color: #a78bfa;
        }

        .terminal-modal-body {
          flex: 1;
          background: #0a0a0a;
          overflow: hidden;
        }

        .terminal-modal-iframe {
          width: 100%;
          height: 100%;
          border: none;
          background: #0a0a0a;
        }

        .terminal-modal-handle {
          height: 4px;
          background: linear-gradient(90deg, #a78bfa, #22d3ee, #a78bfa);
          cursor: pointer;
          flex-shrink: 0;
        }

        @media (max-width: 767px) {
          .terminal-modal-container {
            height: 90vh;
          }

          .terminal-modal-hints {
            display: none;
          }

          .terminal-modal-header {
            padding: 6px 10px;
          }

          .terminal-modal-title {
            font-size: 12px;
          }
        }
      `}</style>

      {/* Backdrop */}
      <div
        className={`terminal-modal-backdrop ${isOpen ? 'open' : ''}`}
        onClick={onClose}
      />

      {/* Modal Container */}
      <div className={`terminal-modal-container ${isOpen ? 'open' : ''}`}>
        <div className="terminal-modal-header">
          <div className="terminal-modal-title">
            TERMINAL ACCESS
          </div>
          <div className="terminal-modal-hints">
            <span><kbd>ESC</kbd> close</span>
            <span><kbd>Ctrl+`</kbd> toggle</span>
          </div>
          <button className="terminal-modal-close" onClick={onClose}>
            [X] CLOSE
          </button>
        </div>

        <div className="terminal-modal-body">
          {isOpen && (
            <iframe
              ref={iframeRef}
              src="/terminal"
              className="terminal-modal-iframe"
              title="Terminal Access"
            />
          )}
        </div>

        <div className="terminal-modal-handle" onClick={onClose} />
      </div>
    </>
  )
}
