import React, { useEffect, useRef, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMobileDetect } from '~/hooks/useMobileDetect'

const routeMap: Record<string, string> = {
  'FM': '/fm',
  'GRID': '/grid',
  'CODEX': '/codex',
  'LOGS': '/logs',
  '0': '/thecyberpulse',
  '1': '/xeraen',
  '2': '/wavelength-zero',
  '3': '/voiceprint',
  '4': '/temporal-blue-drift'
}

interface TerminalLine {
  text: string
  delay: number
  class?: string
  html?: boolean
  keepCursor?: boolean
}

export const TerminalAnimation: React.FC = () => {
  const outputRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const navigate = useNavigate()
  const { isMobile } = useMobileDetect()
  const [inputValue, setInputValue] = useState('')
  const [animationDone, setAnimationDone] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const focusInput = useCallback(() => {
    if (animationDone && inputRef.current) {
      inputRef.current.focus()
    }
  }, [animationDone])

  const handleCommand = useCallback(() => {
    const command = inputValue.trim().toUpperCase()
    if (!command) return

    const route = routeMap[command]
    if (route) {
      navigate(route)
    } else {
      setErrorMessage(`UNKNOWN COMMAND: ${inputValue.trim()}`)
      setInputValue('')
    }
  }, [inputValue, navigate])

  const currentYear = new Date().getFullYear()
  const speedMultiplier = 5

  // Responsive dividers - shorter for mobile
  const doubleLine = isMobile ? '══════════════════════════════════' : '════════════════════════════════════════════════════════════════'
  const singleLine = isMobile ? '──────────────────────────────────' : '─────────────────────────────────────────────────────────────────'

  const lines: TerminalLine[] = [
    { text: doubleLine, delay: 0 },
    { text: '  HACKR.TV BROADCAST SYSTEM v3.14.1592', delay: 300, class: 'terminal-header' },
    { text: '  INITIALIZING TRANSMISSION...', delay: 200 },
    { text: doubleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: '> SYSTEM STATUS: ONLINE', delay: 500, class: 'terminal-prompt' },
    { text: `> YEAR: ${currentYear} (Origin Point)`, delay: 200, class: 'terminal-prompt' },
    { text: `> SIGNAL RANGE: ${currentYear} - ${currentYear + 100}`, delay: 200, class: 'terminal-prompt' },
    { text: '', delay: 500 },
    ...(isMobile ? [
      { text: 'Welcome to hackr.tv - the multimedia', delay: 100 },
      { text: 'Fracture Network platform broadcasting', delay: 100 },
      { text: 'cyberpunk transmissions across time', delay: 100 },
      { text: `and space from ${currentYear + 100}.`, delay: 100 }
    ] : [
      { text: 'Welcome to hackr.tv - the multimedia Fracture Network platform broadcasting', delay: 100 },
      { text: `cyberpunk transmissions across time and space from ${currentYear + 100}.`, delay: 100 }
    ]),
    { text: '', delay: 500 },
    { text: singleLine, delay: 200 },
    { text: 'FEATURED ARTISTS:', delay: 300, class: 'terminal-header' },
    { text: singleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: '[0] <a href="/thecyberpulse" data-route="/thecyberpulse" class="terminal-link">The.CyberPul.se</a>', delay: 200, html: true },
    ...(isMobile ? [
      { text: '    Flagship Standard Bearers of', delay: 100 },
      { text: '    the Hackrs of CyberSpace', delay: 100 }
    ] : [
      { text: '    Flagship Standard Bearers of the Hackrs of CyberSpace,', delay: 100 },
      { text: '    sending pirate broadcasts across time and space', delay: 100 }
    ]),
    { text: '', delay: 200 },
    { text: '[1] <a href="/xeraen" data-route="/xeraen" class="terminal-link">XERAEN</a>', delay: 200, html: true },
    { text: '    Trans-Temporal Operations', delay: 100 },
    { text: '', delay: 200 },
    { text: '[2] <a href="/wavelength-zero" data-route="/wavelength-zero" class="terminal-link">Wavelength Zero</a>', delay: 200, html: true },
    { text: '    Signal disruption collective', delay: 100 },
    { text: '', delay: 200 },
    { text: '[3] <a href="/voiceprint" data-route="/voiceprint" class="terminal-link">Voiceprint</a>', delay: 200, html: true },
    { text: '    Archival resistance records', delay: 100 },
    { text: '', delay: 200 },
    { text: '[4] <a href="/temporal-blue-drift" data-route="/temporal-blue-drift" class="terminal-link">Temporal Blue Drift</a>', delay: 200, html: true },
    { text: '    Love letters across time', delay: 100 },
    { text: '', delay: 500 },
    { text: singleLine, delay: 200 },
    { text: 'PLATFORM SERVICES:', delay: 300, class: 'terminal-header' },
    { text: singleLine, delay: 100 },
    { text: '', delay: 300 },
    { text: isMobile ? '[FM] <a href="/fm" data-route="/fm" class="terminal-link">hackr.fm</a>' : '[FM___] <a href="/fm" data-route="/fm" class="terminal-link">hackr.fm</a>', delay: 200, html: true },
    { text: isMobile ? '     Radio & streaming' : '        Radio & music streaming platform', delay: 100 },
    { text: '', delay: 200 },
    { text: isMobile ? '[GRID] <a href="/grid" data-route="/grid" class="terminal-link">THE PULSE GRID</a>' : '[GRID_] <a href="/grid" data-route="/grid" class="terminal-link">THE PULSE GRID</a>', delay: 200, html: true },
    { text: isMobile ? '       Text-based MUD game' : '        Text-based multiplayer game', delay: 100 },
    { text: '', delay: 200 },
    { text: '[CODEX] <a href="/codex" data-route="/codex" class="terminal-link">The Codex</a>', delay: 200, html: true },
    { text: isMobile ? '        Lore wiki' : '        Lore archive & wiki', delay: 100 },
    { text: '', delay: 200 },
    { text: isMobile ? '[LOGS] <a href="/logs" data-route="/logs" class="terminal-link">Hackr Logs</a>' : '[LOGS_] <a href="/logs" data-route="/logs" class="terminal-link">Hackr Logs</a>', delay: 200, html: true },
    { text: isMobile ? '       Network updates' : '        Updates from the Fracture Network', delay: 100 },
    { text: '', delay: 500 },
    { text: doubleLine, delay: 200 },
    { text: isMobile ? '  SELECT YOUR DESTINATION.' : '  TRANSMISSION READY. SELECT YOUR DESTINATION.', delay: 100 },
    { text: doubleLine, delay: 100 },
    { text: '', delay: 100 },
    { text: '> ', delay: 0, class: 'terminal-prompt', keepCursor: true }
  ]

  useEffect(() => {
    if (!outputRef.current) return

    const renderAllLines = () => {
      if (!outputRef.current) return
      outputRef.current.innerHTML = ''
      lines.forEach((line) => {
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

    // On mobile, skip animation entirely and show all text immediately
    if (isMobile) {
      renderAllLines()
      setAnimationDone(true)
      return
    }

    let lineIndex = 0
    let charIndex = 0
    let typingSpeed = Math.max(1, Math.floor(8 / speedMultiplier))
    let isTyping = true
    let timeoutId: number | null = null

    const finishAnimation = () => {
      setAnimationDone(true)
    }

    const skipAnimation = () => {
      if (!isTyping) return
      isTyping = false
      if (timeoutId) clearTimeout(timeoutId)
      renderAllLines()
      finishAnimation()
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
        finishAnimation()
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

  // When animation completes, remove the last "> " prompt line from the DOM output
  // (it will be replaced by the React-managed interactive prompt line)
  useEffect(() => {
    if (animationDone && outputRef.current) {
      const lastChild = outputRef.current.lastChild as HTMLElement
      if (lastChild && lastChild.textContent?.trim().startsWith('>') && lastChild.textContent.trim().length <= 1) {
        outputRef.current.removeChild(lastChild)
      }
      // Delay focus so the skip keypress doesn't propagate into the input
      requestAnimationFrame(() => {
        if (inputRef.current) {
          inputRef.current.focus()
        }
      })
    }
  }, [animationDone])

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

    const currentOutput = outputRef.current
    currentOutput.addEventListener('click', handleLinkClick)

    return () => {
      currentOutput?.removeEventListener('click', handleLinkClick)
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
          margin: 20px auto 0 auto;
          border: 2px solid #33aa33;
          border-radius: 5px;
          min-height: calc(100vh - 400px);
          max-width: 1200px;
          box-shadow: 0 0 15px rgba(51, 170, 51, 0.2);
          pointer-events: auto;
        }

        @media (max-width: 767px) {
          .terminal-container {
            margin: 5px;
            padding: 12px;
            font-size: 14px;
            min-height: auto;
            overflow-x: hidden;
            word-wrap: break-word;
            overflow-wrap: break-word;
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

        .terminal-input-line {
          display: flex;
          align-items: center;
          position: relative;
          line-height: 1.6;
        }

        .terminal-typed-text {
          color: #33cc33;
          white-space: pre;
        }

        .terminal-hidden-input {
          position: absolute;
          opacity: 0;
          width: 0;
          height: 0;
          padding: 0;
          border: none;
          pointer-events: none;
        }

        .terminal-error {
          color: #ff6633;
          font-weight: bold;
          line-height: 1.6;
          white-space: pre-wrap;
        }
      `}</style>

      <div className="terminal-container" onClick={focusInput}>
        <div ref={outputRef} className="terminal-output"></div>
        {animationDone && (
          <div className="terminal-input-line terminal-prompt">
            <span>{'> '}</span>
            <span className="terminal-typed-text">{inputValue}</span>
            <span className="terminal-cursor"></span>
            <input
              ref={inputRef}
              type="text"
              className="terminal-hidden-input"
              value={inputValue}
              onChange={(e) => {
                setInputValue(e.target.value)
                setErrorMessage(null)
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  handleCommand()
                }
              }}
              autoCapitalize="none"
              autoCorrect="off"
              autoComplete="off"
              spellCheck={false}
            />
          </div>
        )}
        {errorMessage && (
          <div className="terminal-error">{errorMessage}</div>
        )}
      </div>
    </>
  )
}
