import React from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'
import { useTerminal } from '~/contexts/TerminalContext'

export const HeaderMenu: React.FC = () => {
  const { hackr, isLoggedIn, disconnect } = useGridAuth()
  const navigate = useNavigate()
  const { isMobile } = useMobileDetect()
  const { mobileMenuOpen, setMobileMenuOpen } = useMobileMenu()
  const { openTerminal } = useTerminal()

  const handleDisconnect = async (e: React.MouseEvent) => {
    e.preventDefault()
    if (confirm('Disconnect from THE PULSE GRID?')) {
      await disconnect()
      navigate('/grid/login')
    }
  }

  // Mobile version - collapsed menu
  if (isMobile) {
    return (
      <>
        <style>{`
          .mobile-menu-toggle {
            background: #0a0a0a;
            border: 2px solid #7c3aed;
            color: #7c3aed;
            padding: 8px 16px;
            font-family: 'Courier New', Courier, monospace;
            font-size: 16px;
            cursor: pointer;
            margin: 0;
            font-weight: bold;
          }
          .mobile-menu-toggle:active {
            background: #7c3aed;
            color: #0a0a0a;
          }
          .mobile-menu-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.9);
            z-index: 9999;
            overflow-y: auto;
            padding: 20px;
          }
          .mobile-menu-container {
            background: #0a0a0a;
            border: 2px solid #7c3aed;
            padding: 20px;
            max-width: 600px;
            margin: 0 auto;
          }
          .mobile-menu-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #7c3aed;
          }
          .mobile-menu-title {
            color: #7c3aed;
            font-family: 'Courier New', Courier, monospace;
            font-size: 18px;
            font-weight: bold;
          }
          .mobile-menu-close {
            background: none;
            border: 2px solid #ef4444;
            color: #ef4444;
            padding: 4px 12px;
            font-family: 'Courier New', Courier, monospace;
            font-size: 16px;
            cursor: pointer;
            font-weight: bold;
          }
          .mobile-menu-section {
            margin-bottom: 20px;
          }
          .mobile-menu-section-title {
            color: #5cb3cc;
            font-family: 'Courier New', Courier, monospace;
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 8px;
          }
          .mobile-menu-item {
            color: #ccc;
            font-family: 'Courier New', Courier, monospace;
            font-size: 14px;
            padding: 8px 12px;
            display: block;
            text-decoration: none;
            border-left: 3px solid transparent;
          }
          .mobile-menu-item:active {
            background: rgba(124, 58, 237, 0.2);
            border-left: 3px solid #7c3aed;
          }
          .mobile-menu-item .purple-168-text {
            color: #a78bfa;
          }
          .mobile-menu-item .red-255-text {
            color: #ef4444;
          }
        `}</style>

        <div style={{ padding: '5px 10px', position: 'relative', zIndex: 1000 }}>
          <button
            className="mobile-menu-toggle"
            onClick={() => setMobileMenuOpen(true)}
          >
            [≡] MENU
          </button>
        </div>

        {mobileMenuOpen && (
          <div className="mobile-menu-overlay" onClick={() => setMobileMenuOpen(false)}>
            <div className="mobile-menu-container" onClick={(e) => e.stopPropagation()}>
              <div className="mobile-menu-header">
                <div className="mobile-menu-title">[ NAVIGATION ]</div>
                <button
                  className="mobile-menu-close"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  [X]
                </button>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">MAIN</div>
                <Link to="/" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">0</span> / hackr.tv
                </Link>
                <button
                  className="mobile-menu-item"
                  onClick={() => {
                    setMobileMenuOpen(false)
                    openTerminal()
                  }}
                  style={{ background: 'none', border: 'none', width: '100%', textAlign: 'left', cursor: 'pointer' }}
                >
                  <span className="purple-168-text">&gt;</span> /terminal
                </button>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">1. THE.CYBERPUL.SE</div>
                <Link to="/thecyberpulse" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </Link>
                <Link to="/thecyberpulse/trackz" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>trackz
                </Link>
                <Link to="/thecyberpulse/vidz" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>vidz
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">2. HACKR.FM</div>
                <Link to="/fm/radio" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>radio
                </Link>
                <Link to="/fm/pulse_vault" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>pulse_vault
                </Link>
                <Link to="/fm/bands" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>bands
                </Link>
                {isLoggedIn && (
                  <Link to="/fm/playlists" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                    <span className="purple-168-text">/</span>playlists
                  </Link>
                )}
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">3. THE PULSE GRID</div>
                <Link to="/grid" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>grid
                </Link>
                {isLoggedIn ? (
                  <a
                    href="#"
                    className="mobile-menu-item"
                    onClick={(e) => {
                      handleDisconnect(e)
                      setMobileMenuOpen(false)
                    }}
                  >
                    <span className="purple-168-text">/</span>disconnect
                  </a>
                ) : (
                  <>
                    <Link to="/grid/login" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>login
                    </Link>
                    <Link to="/grid/register" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>register
                    </Link>
                  </>
                )}
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">4. The WIRE</div>
                <Link to="/wire" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>hotwire
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">MORE</div>
                <Link to="/codex" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">5</span> The Codex
                </Link>
                <Link to="/logs" className="mobile-menu-item" onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">6</span> Hackr Logs
                </Link>
                {hackr?.role === 'admin' && (
                  <a href="/root" className="mobile-menu-item">
                    <span className="red-255-text">7</span> /root <span className="red-255-text">[ADMIN]</span>
                  </a>
                )}
              </div>
            </div>
          </div>
        )}
      </>
    )
  }

  // Desktop version - full menu with dropdowns
  return (
    <nav className="tui-nav">
      <ul>
        {/* 0: hackr.tv */}
        <li className="tui-dropdown">
          <span className="purple-168-text">0</span>&nbsp;hackr.tv&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              <li>
                <Link to="/">
                  <span className="purple-168-text">/</span>root
                </Link>
              </li>
              <li>
                <a href="#" onClick={(e) => { e.preventDefault(); openTerminal(); }}>
                  <span className="purple-168-text">&gt;</span>terminal
                </a>
              </li>
            </ul>
          </div>
        </li>

        {/* 1: The.CyberPul.se */}
        <li className="tui-dropdown">
          <span className="purple-168-text">1</span>&nbsp;The.CyberPul.se&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              <li>
                <Link to="/thecyberpulse">
                  <span className="purple-168-text">/</span>root
                </Link>
              </li>
              <li>
                <Link to="/thecyberpulse/trackz">
                  <span className="purple-168-text">/</span>trackz
                </Link>
              </li>
              <li>
                <Link to="/thecyberpulse/vidz">
                  <span className="purple-168-text">/</span>vidz
                </Link>
              </li>
            </ul>
          </div>
        </li>

        {/* 2: hackr.fm */}
        <li className="tui-dropdown">
          <span className="purple-168-text">2</span>&nbsp;hackr.fm&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              <li>
                <Link to="/fm/radio">
                  <span className="purple-168-text">/</span>radio
                </Link>
              </li>
              <li>
                <Link to="/fm/pulse_vault">
                  <span className="purple-168-text">/</span>pulse_vault
                </Link>
              </li>
              <li>
                <Link to="/fm/bands">
                  <span className="purple-168-text">/</span>bands
                </Link>
              </li>
              {isLoggedIn && (
                <li>
                  <Link to="/fm/playlists">
                    <span className="purple-168-text">/</span>playlists
                  </Link>
                </li>
              )}
            </ul>
          </div>
        </li>

        {/* 3: THE PULSE GRID */}
        <li className="tui-dropdown">
          <span className="purple-168-text">3</span>&nbsp;THE PULSE GRID&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              <li>
                <Link to="/grid">
                  <span className="purple-168-text">/</span>grid
                </Link>
              </li>
              {isLoggedIn ? (
                <li>
                  <a href="#" onClick={handleDisconnect}>
                    <span className="purple-168-text">/</span>disconnect
                  </a>
                </li>
              ) : (
                <>
                  <li>
                    <Link to="/grid/login">
                      <span className="purple-168-text">/</span>login
                    </Link>
                  </li>
                  <li>
                    <Link to="/grid/register">
                      <span className="purple-168-text">/</span>register
                    </Link>
                  </li>
                </>
              )}
            </ul>
          </div>
        </li>

        {/* 4: The WIRE */}
        <li>
          <Link to="/wire">
            <span className="purple-168-text">4</span> The WIRE&nbsp;
          </Link>
        </li>

        {/* 5: The Codex */}
        <li>
          <Link to="/codex">
            <span className="purple-168-text">5</span> The Codex&nbsp;
          </Link>
        </li>

        {/* 6: Hackr Logs */}
        <li>
          <Link to="/logs">
            <span className="purple-168-text">6</span> Hackr Logs&nbsp;
          </Link>
        </li>

        {/* 7: Admin (only show if user is admin) */}
        {hackr?.role === 'admin' && (
          <li>
            <a href="/root">
              <span className="red-255-text">7</span> /root <span className="red-255-text">[ADMIN]</span>&nbsp;
            </a>
          </li>
        )}
      </ul>
    </nav>
  )
}
