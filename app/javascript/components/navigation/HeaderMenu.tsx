import React, { useState, useRef, useEffect } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'
import { useTerminal } from '~/contexts/TerminalContext'
import { useAppSettings } from '~/contexts/AppSettingsContext'

export const HeaderMenu: React.FC = () => {
  const { hackr, isLoggedIn, disconnect, hasFeature } = useGridAuth()
  const { pathname } = useLocation()
  const isActive = (path: string) => path === '/' ? pathname === '/' : pathname === path || pathname.startsWith(path + '/')
  const { isMobile } = useMobileDetect()
  const { mobileMenuOpen, setMobileMenuOpen } = useMobileMenu()
  const { openTerminal } = useTerminal()
  const { isWorldFeedVisible } = useAppSettings()
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
      window.location.href = '/grid/login'
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
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                <a href="/" className={`mobile-menu-item${isActive('/') ? ' active' : ''}`}>
                  <span className="purple-168-text">0</span> / hackr.tv
                </a>
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                <a href="/schedule" className={`mobile-menu-item${isActive('/schedule') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span> schedule
                </a>
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                {isWorldFeedVisible && (
                  <a href="/feed" className={`mobile-menu-item${isActive('/feed') ? ' active' : ''}`}>
                    <span className="purple-168-text">/</span> feed
                  </a>
                )}
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
                <a href="/thecyberpulse" className={`mobile-menu-item${isActive('/thecyberpulse') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </a>
                <a href="/thecyberpulse/bio" className={`mobile-menu-item${isActive('/thecyberpulse/bio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>bio
                </a>
                <a href="/thecyberpulse/releases" className={`mobile-menu-item${isActive('/thecyberpulse/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </a>
                <a href="/thecyberpulse/vidz" className={`mobile-menu-item${isActive('/thecyberpulse/vidz') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>vidz
                </a>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">2. XERAEN.NET</div>
                <a href="/xeraen" className={`mobile-menu-item${isActive('/xeraen') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </a>
                <a href="/xeraen/bio" className={`mobile-menu-item${isActive('/xeraen/bio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>bio
                </a>
                <a href="/xeraen/releases" className={`mobile-menu-item${isActive('/xeraen/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </a>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">3. HACKR.FM</div>
                <a href="/fm" className={`mobile-menu-item${isActive('/fm') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>root
                </a>
                <a href="/fm/radio" className={`mobile-menu-item${isActive('/fm/radio') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>radio
                </a>
                <a href="/fm/releases" className={`mobile-menu-item${isActive('/fm/releases') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>releases
                </a>
                <a href="/vault" className={`mobile-menu-item${isActive('/vault') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>vault
                </a>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">4. FNET</div>
                <a href="/f/net" className={`mobile-menu-item${isActive('/f/net') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>fracture network
                </a>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">5. WIRE</div>
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                <a href="/wire" className={`mobile-menu-item${isActive('/wire') ? ' active' : ''}`}>
                  <span className="purple-168-text">/</span>hotwire
                </a>
              </div>

              {isLoggedIn && (
                <div className="mobile-menu-section">
                  <div className="mobile-menu-section-title">6. UPLINK</div>
                  <a href="/uplink" className={`mobile-menu-item${isActive('/uplink') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                    <span className="purple-168-text">/</span>transmit
                  </a>
                </div>
              )}

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">MORE</div>
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                <a href="/timeline" className={`mobile-menu-item${isActive('/timeline') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span> Timeline
                </a>
                {/* Hotwire-migrated path — full page load (plain anchor) */}
                <a href="/codex" className={`mobile-menu-item${isActive('/codex') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span> Codex
                </a>
                {isLoggedIn && (
                  // Hotwire-migrated path — full page load (plain anchor)
                  <a href="/handbook" className={`mobile-menu-item${isActive('/handbook') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                    <span className="purple-168-text">9</span> Handbook
                  </a>
                )}
                {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
                <a href="/logs" className={`mobile-menu-item${isActive('/logs') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">{isLoggedIn ? '10' : '8'}</span> Logs
                </a>
              </div>

              <div className="mobile-menu-section">
                <div className="mobile-menu-section-title">{isLoggedIn ? '11' : '9'}. THE PULSE GRID</div>
                <Link to="/grid" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                  <span className="purple-168-text">/</span>grid
                </Link>
                {!isLoggedIn && (
                  <>
                    <a href="/grid/login" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`}>
                      <span className="purple-168-text">/</span>login
                    </a>
                    <a href="/grid/register" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`}>
                      <span className="purple-168-text">/</span>register
                    </a>
                  </>
                )}
                {isLoggedIn && (
                  <>
                    <a href="/grid/identity" className={`mobile-menu-item${isActive('/grid') ? ' active' : ''}`}>
                      <span className="purple-168-text">/</span>identity
                    </a>
                    {hasFeature('tactical_grid') && (
                      <Link to="/grid/1337" className={`mobile-menu-item${isActive('/grid/1337') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                        <span className="purple-168-text">/</span>tactical
                      </Link>
                    )}
                    <Link to="/achievements" className={`mobile-menu-item${isActive('/achievements') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>achievements
                    </Link>
                    <Link to="/missions" className={`mobile-menu-item${isActive('/missions') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>missions
                    </Link>
                    <Link to="/schematics" className={`mobile-menu-item${isActive('/schematics') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>schematics
                    </Link>
                    <Link to="/loadout" className={`mobile-menu-item${isActive('/loadout') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>loadout
                    </Link>
                    <Link to="/deck" className={`mobile-menu-item${isActive('/deck') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>deck
                    </Link>
                    <a href="/fm/playlists" className={`mobile-menu-item${isActive('/fm') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>playlists
                    </a>
                    {/* Hotwire-migrated path — full page load (plain anchor) */}
                    <a href="/code" className={`mobile-menu-item${isActive('/code') ? ' active' : ''}`} onClick={() => setMobileMenuOpen(false)}>
                      <span className="purple-168-text">/</span>code
                    </a>
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
                  {/* Hotwire-migrated path — full page load (plain anchor) */}
                  <a href="/">
                    <span className="purple-168-text">/</span>root
                  </a>
                </li>
                <li>
                  {/* Hotwire-migrated path — full page load (plain anchor) */}
                  <a href="/schedule" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>schedule
                  </a>
                </li>
                {isWorldFeedVisible && (
                  <li>
                    {/* Hotwire-migrated path — full page load (plain anchor) */}
                    <a href="/feed">
                      <span className="purple-168-text">/</span>feed
                    </a>
                  </li>
                )}
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
                  <a href="/thecyberpulse" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </a>
                </li>
                <li>
                  <a href="/thecyberpulse/bio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>bio
                  </a>
                </li>
                <li>
                  <a href="/thecyberpulse/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </a>
                </li>
                <li>
                  <a href="/thecyberpulse/vidz" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>vidz
                  </a>
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
                  <a href="/xeraen" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </a>
                </li>
                <li>
                  <a href="/xeraen/bio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>bio
                  </a>
                </li>
                <li>
                  <a href="/xeraen/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </a>
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
                  <a href="/fm" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>root
                  </a>
                </li>
                <li>
                  <a href="/fm/radio" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>radio
                  </a>
                </li>
                <li>
                  <a href="/fm/releases" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>releases
                  </a>
                </li>
                <li>
                  <a href="/vault" onClick={closeDropdown}>
                    <span className="purple-168-text">/</span>vault
                  </a>
                </li>
              </ul>
            </div>
          </li>

          {/* 4: FNet */}
          <li className={`header-nav-item${isActive('/f/net') ? ' active' : ''}`}>
            <a href="/f/net">
              <span className="purple-168-text">4</span> FNet&nbsp;
            </a>
          </li>

          {/* 5: WIRE — Hotwire-migrated path, full page load (plain anchor) */}
          <li className={`header-nav-item${isActive('/wire') ? ' active' : ''}`}>
            <a href="/wire">
              <span className="purple-168-text">5</span> WIRE&nbsp;
            </a>
          </li>

          {/* Uplink (logged in only) — Hotwire-migrated path, full page load (plain anchor) */}
          {isLoggedIn && (
            <li className={`header-nav-item${isActive('/uplink') ? ' active' : ''}`}>
              <a href="/uplink">
                <span className="purple-168-text">6</span> Uplink&nbsp;
              </a>
            </li>
          )}

          {/* Timeline — Hotwire-migrated path, full page load (plain anchor) */}
          <li className={`header-nav-item${isActive('/timeline') ? ' active' : ''}`}>
            <a href="/timeline">
              <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span> Timeline&nbsp;
            </a>
          </li>

          {/* Codex — Hotwire-migrated path, full page load (plain anchor) */}
          <li className={`header-nav-item${isActive('/codex') ? ' active' : ''}`}>
            <a href="/codex">
              <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span> Codex&nbsp;
            </a>
          </li>

          {/* Handbook (logged in only) */}
          {isLoggedIn && (
            <li className={`header-nav-item${isActive('/handbook') ? ' active' : ''}`}>
              {/* Hotwire-migrated path — full page load (plain anchor) */}
              <a href="/handbook">
                <span className="purple-168-text">9</span> Handbook&nbsp;
              </a>
            </li>
          )}

          {/* Logs — Hotwire-migrated path, full page load (plain anchor) */}
          <li className={`header-nav-item${isActive('/logs') ? ' active' : ''}`}>
            <a href="/logs">
              <span className="purple-168-text">{isLoggedIn ? '10' : '8'}</span> Logs&nbsp;
            </a>
          </li>

          {/* THE PULSE GRID */}
          <li className={`header-dropdown${isActive('/grid') || isActive('/code') || isActive('/achievements') || isActive('/missions') || isActive('/schematics') || isActive('/loadout') || isActive('/deck') ? ' active' : ''}`} onClick={() => toggleDropdown('grid')}>
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
                      <a href="/grid/login">
                        <span className="purple-168-text">/</span>login
                      </a>
                    </li>
                    <li>
                      <a href="/grid/register">
                        <span className="purple-168-text">/</span>register
                      </a>
                    </li>
                  </>
                )}
                {isLoggedIn && (
                  <>
                    {hasFeature('tactical_grid') && (
                      <li>
                        <Link to="/grid/1337" onClick={closeDropdown}>
                          <span className="purple-168-text">/</span>tactical
                        </Link>
                      </li>
                    )}
                    <li>
                      <a href="/grid/identity">
                        <span className="purple-168-text">/</span>identity
                      </a>
                    </li>
                    <li>
                      <Link to="/achievements" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>achievements
                      </Link>
                    </li>
                    <li>
                      <Link to="/missions" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>missions
                      </Link>
                    </li>
                    <li>
                      <Link to="/schematics" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>schematics
                      </Link>
                    </li>
                    <li>
                      <Link to="/loadout" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>loadout
                      </Link>
                    </li>
                    <li>
                      <Link to="/deck" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>deck
                      </Link>
                    </li>
                    <li>
                      <a href="/fm/playlists" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>playlists
                      </a>
                    </li>
                    <li>
                      {/* Hotwire-migrated path — full page load (plain anchor) */}
                      <a href="/code" onClick={closeDropdown}>
                        <span className="purple-168-text">/</span>code
                      </a>
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
