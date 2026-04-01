import React from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'

export const FooterMenu: React.FC = () => {
  const { hackr, isLoggedIn } = useGridAuth()
  const { isMobile } = useMobileDetect()
  const { pathname } = useLocation()
  const isActive = (path: string) => path === '/' ? pathname === '/' : pathname === path || pathname.startsWith(path + '/')

  // Don't render footer menu on mobile
  if (isMobile) return null

  return (
    <>
      <style>{`
        .tui-statusbar ul li:hover {
          background-color: rgb(0, 168, 0);
        }
        .tui-statusbar ul li.active {
          background-color: rgba(124, 58, 237, 0.5);
        }
      `}</style>
      <div className="tui-statusbar">
        <ul>
          <li className={isActive('/') ? 'active' : undefined}>
            <Link to="/">
              <span className="purple-168-text">0</span>&nbsp;hackr.tv&nbsp;
            </Link>
          </li>
          <li className={isActive('/thecyberpulse') ? 'active' : undefined}>
            <Link to="/thecyberpulse">
              <span className="purple-168-text">1</span>&nbsp;The.CyberPul.se&nbsp;
            </Link>
          </li>
          <li className={isActive('/xeraen') ? 'active' : undefined}>
            <Link to="/xeraen">
              <span className="purple-168-text">2</span>&nbsp;XERAEN.net&nbsp;
            </Link>
          </li>
          <li className={isActive('/fm') || isActive('/vault') ? 'active' : undefined}>
            <Link to="/fm">
              <span className="purple-168-text">3</span>&nbsp;hackr.fm&nbsp;
            </Link>
          </li>
          <li className={isActive('/f/net') ? 'active' : undefined}>
            <Link to="/f/net">
              <span className="purple-168-text">4</span>&nbsp;FNet&nbsp;
            </Link>
          </li>
          <li className={isActive('/wire') ? 'active' : undefined}>
            <Link to="/wire">
              <span className="purple-168-text">5</span>&nbsp;WIRE&nbsp;
            </Link>
          </li>
          {isLoggedIn && (
            <li className={isActive('/uplink') ? 'active' : undefined}>
              <Link to="/uplink">
                <span className="purple-168-text">6</span>&nbsp;Uplink&nbsp;
              </Link>
            </li>
          )}
          <li className={isActive('/timeline') ? 'active' : undefined}>
            <Link to="/timeline">
              <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span>&nbsp;Timeline&nbsp;
            </Link>
          </li>
          <li className={isActive('/codex') ? 'active' : undefined}>
            <Link to="/codex">
              <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span>&nbsp;Codex&nbsp;
            </Link>
          </li>
          <li className={isActive('/logs') ? 'active' : undefined}>
            <Link to="/logs">
              <span className="purple-168-text">{isLoggedIn ? '9' : '8'}</span>&nbsp;Logs&nbsp;
            </Link>
          </li>
          <li className={isActive('/grid') || isActive('/code') ? 'active' : undefined}>
            <Link to="/grid">
              <span className="purple-168-text">{isLoggedIn ? '10' : '9'}</span>&nbsp;THE PULSE GRID&nbsp;
            </Link>
          </li>
          {hackr?.role === 'admin' && (
            <li>
              <a href="/root">
                <span className="red-255-text">11</span>&nbsp;/root <span className="red-255-text">[ADMIN]</span>&nbsp;
              </a>
            </li>
          )}
        </ul>
      </div>
    </>
  )
}
