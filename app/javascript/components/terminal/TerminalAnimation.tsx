import React, { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'

interface TerminalLine {
  text: string
  delay: number
  class?: string
  html?: boolean
  keepCursor?: boolean
}

export const TerminalAnimation: React.FC = () => {
  const outputRef = useRef<HTMLDivElement>(null)
  const cursorRef = useRef<HTMLSpanElement>(null)
  const [isSkipped, setIsSkipped] = useState(false)

  const currentYear = new Date().getFullYear()

  const lines: TerminalLine[] = [
    { text: '════════════════════════════════════════════════════════════════', delay: 0 },
    { text: '  HACKR.TV BROADCAST SYSTEM v3.14.1592', delay: 300, class: 'terminal-header' },
    { text: '  INITIALIZING TRANSMISSION...', delay: 200 },
    { text: '════════════════════════════════════════════════════════════════', delay: 100 },
    { text: '', delay: 300 },
    { text: '> SYSTEM STATUS: ONLINE', delay: 500, class: 'terminal-prompt' },
    { text: `> YEAR: ${currentYear} (Origin Point)`, delay: 200, class: 'terminal-prompt' },
    { text: `> SIGNAL RANGE: ${currentYear} - ${currentYear + 100}`, delay: 200, class: 'terminal-prompt' },
    { text: '', delay: 500 },
    { text: `Welcome to hackr.tv - the multimedia resistance platform broadcasting`, delay: 100 },
    { text: `cyberpunk transmissions across time and space from ${currentYear + 100}.`, delay: 100 },
    { text: '', delay: 500 },
    { text: '─────────────────────────────────────────────────────────────────', delay: 200 },
    { text: 'FEATURED ARTISTS:', delay: 300, class: 'terminal-header' },
    { text: '─────────────────────────────────────────────────────────────────', delay: 100 },
    { text: '', delay: 300 },
    { text: '[0] The.CyberPul.se', delay: 200, html: true },
    { text: '    Flagship Standard Bearers of the Hackrs of CyberSpace,', delay: 100 },
    { text: '    sending pirate broadcasts across time and space', delay: 100 },
    { text: '', delay: 200 },
    { text: '[1] XERAEN', delay: 200, html: true },
    { text: '    Trans-Temporal Operations from the future', delay: 100 },
    { text: '', delay: 200 },
    { text: '[2] System Rot', delay: 200, html: true },
    { text: '    Street-level resistance', delay: 100 },
    { text: '', delay: 200 },
    { text: '[3] Wavelength Zero', delay: 200, html: true },
    { text: '    Signal disruption collective', delay: 100 },
    { text: '', delay: 200 },
    { text: '[4] Voiceprint', delay: 200, html: true },
    { text: '    Archival resistance records', delay: 100 },
    { text: '', delay: 200 },
    { text: '[5] Temporal Blue Drift', delay: 200, html: true },
    { text: '    Love letters across time', delay: 100 },
    { text: '', delay: 500 },
    { text: '─────────────────────────────────────────────────────────────────', delay: 200 },
    { text: 'PLATFORM SERVICES:', delay: 300, class: 'terminal-header' },
    { text: '─────────────────────────────────────────────────────────────────', delay: 100 },
    { text: '', delay: 300 },
    { text: '[FM] hackr.fm', delay: 200, html: true },
    { text: '     Radio & music streaming platform', delay: 100 },
    { text: '', delay: 200 },
    { text: '[GRID] THE PULSE GRID', delay: 200, html: true },
    { text: '       Text-based multiplayer game', delay: 100 },
    { text: '', delay: 200 },
    { text: '[LOGS] Hackr Logs', delay: 200, html: true },
    { text: '       Updates from the resistance', delay: 100 },
    { text: '', delay: 500 },
    { text: '════════════════════════════════════════════════════════════════', delay: 200 },
    { text: '  TRANSMISSION READY. SELECT YOUR DESTINATION.', delay: 100 },
    { text: '════════════════════════════════════════════════════════════════', delay: 100 },
    { text: '', delay: 100 },
    { text: '> _', delay: 0, class: 'terminal-prompt', keepCursor: true }
  ]

  useEffect(() => {
    if (!outputRef.current || !cursorRef.current) return

    let lineIndex = 0
    let charIndex = 0
    let typingSpeed = 8
    let isTyping = true
    let timeoutId: number | null = null

    const skipAnimation = () => {
      if (!isTyping) return
      isTyping = false
      if (timeoutId) clearTimeout(timeoutId)

      if (outputRef.current) {
        outputRef.current.innerHTML = ''
        lines.forEach(line => {
          const lineElement = document.createElement('div')
          if (line.html) {
            lineElement.innerHTML = line.text
          } else {
            lineElement.textContent = line.text
          }
          if (line.class) {
            lineElement.className = line.class
          }
          outputRef.current?.appendChild(lineElement)
        })
      }

      if (cursorRef.current) {
        cursorRef.current.style.display = 'none'
      }
      setIsSkipped(true)
    }

    const typeWriter = () => {
      if (!isTyping || !outputRef.current) return
      if (lineIndex < lines.length) {
        const line = lines[lineIndex]

        if (charIndex === 0 && line.delay > 0) {
          timeoutId = window.setTimeout(typeWriter, line.delay)
          charIndex++
          return
        }

        if (charIndex <= line.text.length) {
          const currentLine = line.text.substring(0, charIndex)

          const lineElement = document.createElement('div')
          if (line.html) {
            lineElement.innerHTML = currentLine
          } else {
            lineElement.textContent = currentLine
          }
          if (line.class) {
            lineElement.className = line.class
          }

          if (outputRef.current.lastChild && charIndex > 1) {
            outputRef.current.removeChild(outputRef.current.lastChild)
          }

          outputRef.current.appendChild(lineElement)
          window.scrollTo(0, document.body.scrollHeight)

          charIndex++
          timeoutId = window.setTimeout(typeWriter, typingSpeed)
        } else {
          lineIndex++
          charIndex = 0
          timeoutId = window.setTimeout(typeWriter, 50)
        }
      } else {
        isTyping = false
        if (cursorRef.current) {
          cursorRef.current.style.display = 'none'
        }
      }
    }

    const handleKeyDown = () => {
      skipAnimation()
    }

    document.addEventListener('keydown', handleKeyDown, { once: true })
    timeoutId = window.setTimeout(typeWriter, 500)

    return () => {
      if (timeoutId) clearTimeout(timeoutId)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [])

  // Render links after animation is done
  const renderContent = () => {
    if (!isSkipped) return null

    return (
      <div className="terminal-links" style={{ marginTop: '20px' }}>
        <p className="terminal-header">Quick Links:</p>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px', marginTop: '10px' }}>
          <Link to="/thecyberpulse" className="terminal-link">The.CyberPul.se</Link>
          <Link to="/xeraen" className="terminal-link">XERAEN</Link>
          <Link to="/fm" className="terminal-link">hackr.fm</Link>
          <Link to="/grid" className="terminal-link">THE PULSE GRID</Link>
          <Link to="/logs" className="terminal-link">Hackr Logs</Link>
        </div>
      </div>
    )
  }

  return (
    <>
      <style>{`
        .terminal-container {
          background: #0a0a0a;
          color: #33cc33;
          font-family: 'Courier New', Courier, monospace;
          padding: 20px;
          margin: 20px 20px 0 20px;
          border: 2px solid #33aa33;
          border-radius: 5px;
          min-height: calc(100vh - 400px);
          max-width: 1200px;
          box-shadow: 0 0 15px rgba(51, 170, 51, 0.2);
        }

        .terminal-output {
          white-space: pre-wrap;
          line-height: 1.6;
        }

        .terminal-cursor {
          display: inline-block;
          width: 10px;
          height: 18px;
          background: #33cc33;
          animation: blink 1s infinite;
          margin-left: 2px;
        }

        @keyframes blink {
          0%, 49% { opacity: 1; }
          50%, 100% { opacity: 0; }
        }

        .terminal-link {
          color: #4db8e8;
          text-decoration: underline;
        }

        .terminal-link:hover {
          color: #66ccff;
        }

        .terminal-prompt {
          color: #5cd65c;
          font-weight: bold;
        }

        .terminal-header {
          color: #5cb3cc;
        }
      `}</style>

      <div className="terminal-container">
        <div ref={outputRef} className="terminal-output"></div>
        <span ref={cursorRef} className="terminal-cursor"></span>
        {renderContent()}
      </div>
    </>
  )
}
