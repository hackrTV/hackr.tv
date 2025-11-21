import React, { useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMobileDetect } from '~/hooks/useMobileDetect'

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
  const navigate = useNavigate()
  const { isMobile } = useMobileDetect()

  const currentYear = new Date().getFullYear()
  const speedMultiplier = 5

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
    { text: 'Welcome to hackr.tv - the multimedia resistance platform broadcasting', delay: 100 },
    { text: `cyberpunk transmissions across time and space from ${currentYear + 100}.`, delay: 100 },
    { text: '', delay: 500 },
    { text: '─────────────────────────────────────────────────────────────────', delay: 200 },
    { text: 'FEATURED ARTISTS:', delay: 300, class: 'terminal-header' },
    { text: '─────────────────────────────────────────────────────────────────', delay: 100 },
    { text: '', delay: 300 },
    { text: '[0] <a href="/thecyberpulse" data-route="/thecyberpulse" class="terminal-link">The.CyberPul.se</a>', delay: 200, html: true },
    { text: '    Flagship Standard Bearers of the Hackrs of CyberSpace,', delay: 100 },
    { text: '    sending pirate broadcasts across time and space', delay: 100 },
    { text: '', delay: 200 },
    { text: '[1] <a href="/xeraen" data-route="/xeraen" class="terminal-link">XERAEN</a>', delay: 200, html: true },
    { text: '    Trans-Temporal Operations from the future', delay: 100 },
    { text: '', delay: 200 },
    { text: '[2] <a href="/system_rot" data-route="/system_rot" class="terminal-link">System Rot</a>', delay: 200, html: true },
    { text: '    Street-level resistance', delay: 100 },
    { text: '', delay: 200 },
    { text: '[3] <a href="/wavelength_zero" data-route="/wavelength_zero" class="terminal-link">Wavelength Zero</a>', delay: 200, html: true },
    { text: '    Signal disruption collective', delay: 100 },
    { text: '', delay: 200 },
    { text: '[4] <a href="/voiceprint" data-route="/voiceprint" class="terminal-link">Voiceprint</a>', delay: 200, html: true },
    { text: '    Archival resistance records', delay: 100 },
    { text: '', delay: 200 },
    { text: '[5] <a href="/temporal_blue_drift" data-route="/temporal_blue_drift" class="terminal-link">Temporal Blue Drift</a>', delay: 200, html: true },
    { text: '    Love letters across time', delay: 100 },
    { text: '', delay: 500 },
    { text: '─────────────────────────────────────────────────────────────────', delay: 200 },
    { text: 'PLATFORM SERVICES:', delay: 300, class: 'terminal-header' },
    { text: '─────────────────────────────────────────────────────────────────', delay: 100 },
    { text: '', delay: 300 },
    { text: '[FM___] <a href="/fm" data-route="/fm" class="terminal-link">hackr.fm</a>', delay: 200, html: true },
    { text: '        Radio & music streaming platform', delay: 100 },
    { text: '', delay: 200 },
    { text: '[GRID_] <a href="/grid" data-route="/grid" class="terminal-link">THE PULSE GRID</a>', delay: 200, html: true },
    { text: '        Text-based multiplayer game', delay: 100 },
    { text: '', delay: 200 },
    { text: '[CODEX] <a href="/codex" data-route="/codex" class="terminal-link">The Codex</a>', delay: 200, html: true },
    { text: '        Lore archive & wiki', delay: 100 },
    { text: '', delay: 200 },
    { text: '[LOGS_] <a href="/logs" data-route="/logs" class="terminal-link">Hackr Logs</a>', delay: 200, html: true },
    { text: '        Updates from the resistance', delay: 100 },
    { text: '', delay: 500 },
    { text: '════════════════════════════════════════════════════════════════', delay: 200 },
    { text: '  TRANSMISSION READY. SELECT YOUR DESTINATION.', delay: 100 },
    { text: '════════════════════════════════════════════════════════════════', delay: 100 },
    { text: '', delay: 100 },
    { text: '> ', delay: 0, class: 'terminal-prompt', keepCursor: true }
  ]

  useEffect(() => {
    if (!outputRef.current || !cursorRef.current) return

    // On mobile, skip animation entirely and show all text immediately
    if (isMobile) {
      outputRef.current.innerHTML = ''
      lines.forEach((line, index) => {
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

        // Append cursor to the last line
        if (index === lines.length - 1 && cursorRef.current) {
          lineElement.appendChild(cursorRef.current)
        }
      })
      return
    }

    let lineIndex = 0
    let charIndex = 0
    let typingSpeed = Math.max(1, Math.floor(8 / speedMultiplier))
    let isTyping = true
    let timeoutId: number | null = null

    const skipAnimation = () => {
      if (!isTyping) return
      isTyping = false
      if (timeoutId) clearTimeout(timeoutId)

      if (outputRef.current) {
        outputRef.current.innerHTML = ''
        lines.forEach((line, index) => {
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

          // Append cursor to the last line
          if (index === lines.length - 1 && cursorRef.current) {
            lineElement.appendChild(cursorRef.current)
          }
        })
      }

    }

    const typeWriter = () => {
      if (!isTyping || !outputRef.current) return
      if (lineIndex < lines.length) {
        const line = lines[lineIndex]

        if (charIndex === 0 && line.delay > 0) {
          timeoutId = window.setTimeout(typeWriter, line.delay / speedMultiplier)
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
          timeoutId = window.setTimeout(typeWriter, 50 / speedMultiplier)
        }
      } else {
        isTyping = false
        // Keep cursor visible and blinking after animation completes
        // Append cursor to the last line element
        if (cursorRef.current && outputRef.current) {
          const lastLine = outputRef.current.lastChild as HTMLElement
          if (lastLine) {
            lastLine.appendChild(cursorRef.current)
          }
        }
      }
    }

    const handleKeyDown = () => {
      skipAnimation()
    }

    document.addEventListener('keydown', handleKeyDown, { once: true })
    timeoutId = window.setTimeout(typeWriter, 500 / speedMultiplier)

    return () => {
      if (timeoutId) clearTimeout(timeoutId)
      document.removeEventListener('keydown', handleKeyDown)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [speedMultiplier, isMobile])

  // Add click handlers for links to use React Router navigation
  useEffect(() => {
    if (!outputRef.current) return

    const handleLinkClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement
      if (target.tagName === 'A' && target.hasAttribute('data-route')) {
        e.preventDefault()
        const route = target.getAttribute('data-route')
        if (route) {
          navigate(route)
        }
      }
    }

    outputRef.current.addEventListener('click', handleLinkClick)

    return () => {
      outputRef.current?.removeEventListener('click', handleLinkClick)
    }
  }, [navigate])

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
          pointer-events: auto;
        }

        @media (max-width: 767px) {
          .terminal-container {
            margin: 10px;
            padding: 10px;
            overflow-x: auto;
          }
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
          margin-left: 0;
          vertical-align: -2px;
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
      </div>
    </>
  )
}
