import React, { useState, useRef, useEffect } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'
import { useTerminal } from '~/contexts/TerminalContext'

export const HeaderMenu: React.FC = () => {
  const { hackr, isLoggedIn, disconnect } = useGridAuth()
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const isActive = (path: string) => path === '/' ? pathname === '/' : pathname === path || pathname.startsWith(path + '/')
  const { isMobile } = useMobileDetect()
  const { mobileMenuOpen, setMobileMenuOpen } = useMobileMenu()
  const { openTerminal } = useTerminal()
  const [openDropdown, setOpenDropdown] = useState<string | null>(null)
  const menuRef = useRef<HTMLElement>(null)

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOpenDropdown(null)
      }
    }

    if (openDropdown) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [openDropdown])

  const handleDisconnect = async (e: React.MouseEvent) => {
    e.preventDefault()
    if (confirm('Disconnect from THE PULSE GRID?')) {
      await disconnect()
      navigate('/grid/login')
    }
  }

  const toggleDropdown = (name: string) => {
    setOpenDropdown(openDropdown === name ? null : name)
  }

  const closeDropdown = () => {
    setOpenDropdown(null)
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
          .mobile-menu-item:active,
          .mobile-menu-item.active {
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
                <Link to="/" className={`mobile-menu-item${isActive('/') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
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
                <Link to="/thecyberpulse" className={`mobile-menu-item${isActive('/thecyberpulse') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </Link>
                <Link to="/thecyberpulse/bio" className={`mobile-menu-item${isActive('/thecyberpulse/bio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>bio
                </Link>
                <Link to="/thecyberpulse/releases" className={`mobile-menu-item${isActive('/thecyberpulse/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </Link>
                <Link to="/thecyberpulse/vidz" className={`mobile-menu-item${isActive('/thecyberpulse/vidz') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>vidz
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">2. XERAEN.NET</div>
                <Link to="/xeraen" className={`mobile-menu-item${isActive('/xeraen') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </Link>
                <Link to="/xeraen/bio" className={`mobile-menu-item${isActive('/xeraen/bio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>bio
                </Link>
                <Link to="/xeraen/releases" className={`mobile-menu-item${isActive('/xeraen/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">3. HACKR.FM</div>
                <Link to="/fm" className={`mobile-menu-item${isActive('/fm') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </Link>
                <Link to="/fm/radio" className={`mobile-menu-item${isActive('/fm/radio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>radio
                </Link>
                <Link to="/fm/releases" className={`mobile-menu-item${isActive('/fm/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </Link>
                <Link to="/vault" className={`mobile-menu-item${isActive('/vault') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>vault
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">4. FNET</div>
                <Link to="/f/net" className={`mobile-menu-item${isActive('/f/net') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>fracture network
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">5. WIRE</div>
                <Link to="/wire" className={`mobile-menu-item${isActive('/wire') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>hotwire
                </Link>
              </div>

              {isLoggedIn && (
                <div className="mobile-menu-section">
                  <div className="mobile-menu-section-title">6. UPLINK</div>
                  <Link to="/uplink" className={`mobile-menu-item${isActive('/uplink') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                    <span className="purple-168-text">/</span>transmit
                  </Link>
                </div>
              )}

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">MORE</div>
                <Link to="/timeline" className={`mobile-menu-item${isActive('/timeline') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span> Timeline
                </Link>
                <Link to="/codex" className={`mobile-menu-item${isActive('/codex') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span> Codex
                </Link>
                {isLoggedIn && (
                  <Link to="/handbook" className={`mobile-menu-item${isActive('/handbook') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                    <span className="purple-168-text">9</span> Handbook
                  </Link>
                )}
                <Link to="/logs" className={`mobile-menu-item${isActive('/logs') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '10' : '8'}</span> Logs
                </Link>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">{isLoggedIn ? '11' : '9'}. THE PULSE GRID</div>
                <Link to="/grid" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>grid
                </Link>
                {!isLoggedIn && (
                  <>
                    <Link to="/grid/login" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>login
                    </Link>
                    <Link to="/grid/register" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>register
                    </Link>
                  </>
                )}
                {isLoggedIn && (
                  <>
                    <Link to="/grid/identity" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>identity
                    </Link>
                    <Link to="/achievements" className={`mobile-menu-item${isActive('/achievements') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>achievements
                    </Link>
                    <Link to="/fm/playlists" className={`mobile-menu-item${isActive('/fm') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>playlists
                    </Link>
                    <Link to="/code" className={`mobile-menu-item${isActive('/code') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>code
                    </Link>
                  </>
                )}
                {hackr?.role === 'admin' && (
                  <a href="/root" className="mobile-menu-item">
                    <span className="red-255-text">12</span> /root
                  </a>
                )}
              </div>

              <div className="mobile-menu-section">
                {isLoggedIn && (
                  <a
                    href="#"
                    className="mobile-menu-item"
                    style={{ color: '#dc2626' }}
                    title="Disconnect"
                    aria-label="Disconnect"
                    onClick={(e) => {
                      handleDisconnect(e)
                      setMobileMenuOpen(false)
                    }}
                  >
                    × DC
                  </a>
                )}
              </div>
            </div>
          </div>
        )}
      </>
    )
  }

  // Desktop version - click-based dropdowns
  return (
    <>
      <style>{`
        .header-dropdown {
          position: relative;
          display: inline-block;
          cursor: pointer;
          user-select: none;
          padding: 1px 3px;
        }
        .header-dropdown:hover {
          background-color: rgb(0, 168, 0);
        }
        .header-dropdown-content {
          display: none;
          position: absolute;
          top: 100%;
          left: 0;
          background-color: rgb(168, 168, 168);
          min-width: 200px;
          padding: 6px;
          z-index: 9999;
        }
        .header-dropdown-content.open {
          display: block;
        }
        .header-dropdown-content ul {
          border: 2px black solid;
          list-style: none;
          margin: 0;
          padding: 0;
        }
        .header-dropdown-content ul li {
          display: block;
          margin: 6px;
        }
        .header-dropdown-content ul li a {
          display: block;
          color: black;
          text-decoration: none;
          padding: 2px 4px;
        }
        .header-dropdown-content ul li a:hover {
          background-color: rgb(0, 168, 0);
        }
        .header-nav-item {
          display: inline-block;
          margin-left: 10px;
          padding: 1px 3px;
        }
        .header-nav-item:hover {
          background-color: rgb(0, 168, 0);
        }
        .header-nav-item.active {
          background-color: rgba(124, 58, 237, 0.5);
        }
        .header-nav-item.active a {
          color: black;
        }
        .header-nav-item a {
          display: block;
          color: black;
          text-decoration: none;
        }
        .header-dropdown.active {
          background-color: rgba(124, 58, 237, 0.5);
        }
      `}</style>
      <nav className="tui-nav" ref={menuRef}>
        <ul style={{ listStyle: 'none', margin: 0, padding: 0 }}>
          {/* 0: hackr.tv */}
          <li className={`header-dropdown${isActive('/') ? ' active' : ''}`} onClick={() => toggleDropdown('hackrtv')}>
            <span className="purple-168-text">0</span>&nbsp;hackr.tv&nbsp;
            <div className={`header-dropdown-content ${openDropdown === 'hackrtv' ? 'open' : ''}`}>
              <ul>
                <li>
                  <Link to="/" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </Link>
                </li>
                <li>
                  <a href="#" onClick={(e) => { e.preventDefault(); closeDropdown(); openTerminal() }}>
                    <span className="purple-168-text">&gt;</span>terminal
                  </a>
                </li>
              </ul>
            </div>
          </li>

          {/* 1: The.CyberPul.se */}
          <li className={`header-dropdown${isActive('/thecyberpulse') ? ' active' : ''}`} onClick={() => toggleDropdown('cyberpulse')}>
            <span className="purple-168-text">1</span>&nbsp;The.CyberPul.se&nbsp;
            <div className={`header-dropdown-content ${openDropdown === 'cyberpulse' ? 'open' : ''}`}>
              <ul>
                <li>
                  <Link to="/thecyberpulse" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </Link>
                </li>
                <li>
                  <Link to="/thecyberpulse/bio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>bio
                  </Link>
                </li>
                <li>
                  <Link to="/thecyberpulse/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </Link>
                </li>
                <li>
                  <Link to="/thecyberpulse/vidz" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>vidz
                  </Link>
                </li>
              </ul>
            </div>
          </li>

          {/* 2: XERAEN.net */}
          <li className={`header-dropdown${isActive('/xeraen') ? ' active' : ''}`} onClick={() => toggleDropdown('xeraen')}>
            <span className="purple-168-text">2</span>&nbsp;XERAEN.net&nbsp;
            <div className={`header-dropdown-content ${openDropdown === 'xeraen' ? 'open' : ''}`}>
              <ul>
                <li>
                  <Link to="/xeraen" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </Link>
                </li>
                <li>
                  <Link to="/xeraen/bio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>bio
                  </Link>
                </li>
                <li>
                  <Link to="/xeraen/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </Link>
                </li>
              </ul>
            </div>
          </li>

          {/* 3: hackr.fm */}
          <li className={`header-dropdown${isActive('/fm') || isActive('/vault') ? ' active' : ''}`} onClick={() => toggleDropdown('hackrfm')}>
            <span className="purple-168-text">3</span>&nbsp;hackr.fm&nbsp;
            <div className={`header-dropdown-content ${openDropdown === 'hackrfm' ? 'open' : ''}`}>
              <ul>
                <li>
                  <Link to="/fm" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </Link>
                </li>
                <li>
                  <Link to="/fm/radio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>radio
                  </Link>
                </li>
                <li>
                  <Link to="/fm/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </Link>
                </li>
                <li>
                  <Link to="/vault" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>vault
                  </Link>
                </li>
              </ul>
            </div>
          </li>

          {/* 4: FNet */}
          <li className={`header-nav-item${isActive('/f/net') ? ' active' : ''}`}>
            <Link to="/f/net">
              <span className="purple-168-text">4</span> FNet&nbsp;
            </Link>
          </li>

          {/* 5: WIRE */}
          <li className={`header-nav-item${isActive('/wire') ? ' active' : ''}`}>
            <Link to="/wire">
              <span className="purple-168-text">5</span> WIRE&nbsp;
            </Link>
          </li>

          {/* Uplink (logged in only) */}
          {isLoggedIn && (
            <li className={`header-nav-item${isActive('/uplink') ? ' active' : ''}`}>
              <Link to="/uplink">
                <span className="purple-168-text">6</span> Uplink&nbsp;
              </Link>
            </li>
          )}

          {/* Timeline */}
          <li className={`header-nav-item${isActive('/timeline') ? ' active' : ''}`}>
            <Link to="/timeline">
              <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span> Timeline&nbsp;
            </Link>
          </li>

          {/* Codex */}
          <li className={`header-nav-item${isActive('/codex') ? ' active' : ''}`}>
            <Link to="/codex">
              <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span> Codex&nbsp;
            </Link>
          </li>

          {/* Handbook (logged in only) */}
          {isLoggedIn && (
            <li className={`header-nav-item${isActive('/handbook') ? ' active' : ''}`}>
              <Link to="/handbook">
                <span className="purple-168-text">9</span> Handbook&nbsp;
              </Link>
            </li>
          )}

          {/* Logs */}
          <li className={`header-nav-item${isActive('/logs') ? ' active' : ''}`}>
            <Link to="/logs">
              <span className="purple-168-text">{isLoggedIn ? '10' : '8'}</span> Logs&nbsp;
            </Link>
          </li>

          {/* THE PULSE GRID */}
          <li className={`header-dropdown${isActive('/grid') || isActive('/code') || isActive('/achievements') ? ' active' : ''}`} onClick={() => toggleDropdown('grid')}>
            <span className="purple-168-text">{isLoggedIn ? '11' : '9'}</span>&nbsp;THE PULSE GRID&nbsp;
            <div className={`header-dropdown-content ${openDropdown === 'grid' ? 'open' : ''}`}>
              <ul>
                <li>
                  <Link to="/grid" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>grid
                  </Link>
                </li>
                {!isLoggedIn && (
                  <>
                    <li>
                      <Link to="/grid/login" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>login
                      </Link>
                    </li>
                    <li>
                      <Link to="/grid/register" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>register
                      </Link>
                    </li>
                  </>
                )}
                {isLoggedIn && (
                  <>
                    <li>
                      <Link to="/grid/identity" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>identity
                      </Link>
                    </li>
                    <li>
                      <Link to="/achievements" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>achievements
                      </Link>
                    </li>
                    <li>
                      <Link to="/fm/playlists" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>playlists
                      </Link>
                    </li>
                    <li>
                      <Link to="/code" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>code
                      </Link>
                    </li>
                  </>
                )}
              </ul>
            </div>
          </li>

          {/* Admin (only show if user is admin) */}
          {hackr?.role === 'admin' && (
            <li className="header-nav-item">
              <a href="/root">
                <span className="red-255-text">12</span> /root
              </a>
            </li>
          )}

          {/* Disconnect (only show if logged in) */}
          {isLoggedIn && (
            <li className="header-nav-item">
              <a href="#" onClick={handleDisconnect} style={{ color: '#dc2626' }} title="Disconnect" aria-label="Disconnect">
                <span>×</span> DC&nbsp;
              </a>
            </li>
          )}
        </ul>
      </nav>
    </>
  )
}
