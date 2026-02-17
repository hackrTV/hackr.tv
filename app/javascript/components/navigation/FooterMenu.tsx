import React from 'react'
import { Link } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'

export const FooterMenu: React.FC = () => {
  const { hackr, isLoggedIn } = useGridAuth()
  const { isMobile } = useMobileDetect()

  // Don't render footer menu on mobile
  if (isMobile) return null

  return (
    <>
      <style>{`
        .tui-statusbar ul li:hover {
          background-color: rgb(0, 168, 0);
        }
      `}</style>
      <div className="tui-statusbar">
        <ul>
          <li>
            <Link to="/">
              <span className="purple-168-text">0</span>&nbsp;hackr.tv&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/thecyberpulse">
              <span className="purple-168-text">1</span>&nbsp;The.CyberPul.se&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/xeraen">
              <span className="purple-168-text">2</span>&nbsp;XERAEN&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/fm/radio">
              <span className="purple-168-text">3</span>&nbsp;hackr.fm&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/f/net">
              <span className="purple-168-text">4</span>&nbsp;FNet&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/wire">
              <span className="purple-168-text">5</span>&nbsp;WIRE&nbsp;
            </Link>
          </li>
          {isLoggedIn && (
            <li>
              <Link to="/uplink">
                <span className="purple-168-text">6</span>&nbsp;Uplink&nbsp;
              </Link>
            </li>
          )}
          <li>
            <Link to="/codex">
              <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span>&nbsp;Codex&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/logs">
              <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span>&nbsp;Logs&nbsp;
            </Link>
          </li>
          <li>
            <Link to="/grid">
              <span className="purple-168-text">{isLoggedIn ? '9' : '8'}</span>&nbsp;THE PULSE GRID&nbsp;
            </Link>
          </li>
          {hackr?.role === 'admin' && (
            <li>
              <a href="/root">
                <span className="red-255-text">{isLoggedIn ? '10' : '9'}</span>&nbsp;/root <span className="red-255-text">[ADMIN]</span>&nbsp;
              </a>
            </li>
          )}
        </ul>
      </div>
    </>
  )
}
