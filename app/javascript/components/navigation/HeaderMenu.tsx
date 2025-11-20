import React from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'

export const HeaderMenu: React.FC = () => {
  const { hackr, isLoggedIn, disconnect } = useGridAuth()
  const navigate = useNavigate()

  const handleDisconnect = async (e: React.MouseEvent) => {
    e.preventDefault()
    if (confirm('Disconnect from THE PULSE GRID?')) {
      await disconnect()
      navigate('/grid/login')
    }
  }

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
                <a href="https://www.youtube.com/watch?v=YgD4oNPpGv4&list=PLLRgY_tjdreyU4_WtrQnkZ6D8ur41GrpC" target="_blank" rel="noopener noreferrer">
                  <span className="purple-168-text">/</span>streamz
                </a>
              </li>
              <li>
                <a href="https://www.youtube.com/@TheCyberPulse/videos" target="_blank" rel="noopener noreferrer">
                  <span className="purple-168-text">/</span>vidz
                </a>
              </li>
            </ul>
          </div>
        </li>

        {/* 2: XERAEN */}
        <li className="tui-dropdown">
          <span className="purple-168-text">2</span>&nbsp;XERAEN&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              <li>
                <Link to="/xeraen/">
                  <span className="purple-168-text">/</span>root
                </Link>
              </li>
              <li>
                <Link to="/xeraen/trackz">
                  <span className="purple-168-text">/</span>trackz
                </Link>
              </li>
              <li>
                <a href="https://www.youtube.com/watch?v=GYSH0mDteR4&list=PLnBws134IvTRZCeazlMukr-gq24eIWCf4" target="_blank" rel="noopener noreferrer">
                  <span className="purple-168-text">/</span>vidz
                </a>
              </li>
              <li>
                <Link to="/xeraen/linkz">
                  <span className="purple-168-text">/</span>linkz
                </Link>
              </li>
            </ul>
          </div>
        </li>

        {/* 3: hackr.fm */}
        <li className="tui-dropdown">
          <span className="purple-168-text">3</span>&nbsp;hackr.fm&nbsp;
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

        {/* 4: THE PULSE GRID */}
        <li className="tui-dropdown">
          <span className="purple-168-text">4</span>&nbsp;THE PULSE GRID (pre-alpha)&nbsp;
          <div className="tui-dropdown-content">
            <ul>
              {isLoggedIn ? (
                <>
                  <li>
                    <Link to="/grid">
                      <span className="purple-168-text">/</span>grid
                    </Link>
                  </li>
                  <li>
                    <a href="#" onClick={handleDisconnect}>
                      <span className="purple-168-text">/</span>disconnect
                    </a>
                  </li>
                </>
              ) : (
                <>
                  <li>
                    <Link to="/grid">
                      <span className="purple-168-text">/</span>grid
                    </Link>
                  </li>
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
