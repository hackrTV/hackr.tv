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
            {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
            <a href="/">
              <span className="purple-168-text">0</span>&nbsp;hackr.tv&nbsp;
            </a>
          </li>
          <li className={isActive('/thecyberpulse') ? 'active' : undefined}>
            <a href="/thecyberpulse">
              <span className="purple-168-text">1</span>&nbsp;The.CyberPul.se&nbsp;
            </a>
          </li>
          <li className={isActive('/xeraen') ? 'active' : undefined}>
            <a href="/xeraen">
              <span className="purple-168-text">2</span>&nbsp;XERAEN.net&nbsp;
            </a>
          </li>
          <li className={isActive('/fm') || isActive('/vault') ? 'active' : undefined}>
            <a href="/fm">
              <span className="purple-168-text">3</span>&nbsp;hackr.fm&nbsp;
            </a>
          </li>
          <li className={isActive('/f/net') ? 'active' : undefined}>
            <a href="/f/net">
              <span className="purple-168-text">4</span>&nbsp;FNet&nbsp;
            </a>
          </li>
          <li className={isActive('/wire') ? 'active' : undefined}>
            {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
            <a href="/wire">
              <span className="purple-168-text">5</span>&nbsp;WIRE&nbsp;
            </a>
          </li>
          {isLoggedIn && (
            <li className={isActive('/uplink') ? 'active' : undefined}>
              <Link to="/uplink">
                <span className="purple-168-text">6</span>&nbsp;Uplink&nbsp;
              </Link>
            </li>
          )}
          <li className={isActive('/timeline') ? 'active' : undefined}>
            {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
            <a href="/timeline">
              <span className="purple-168-text">{isLoggedIn ? '7' : '6'}</span>&nbsp;Timeline&nbsp;
            </a>
          </li>
          <li className={isActive('/codex') ? 'active' : undefined}>
            {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
            <a href="/codex">
              <span className="purple-168-text">{isLoggedIn ? '8' : '7'}</span>&nbsp;Codex&nbsp;
            </a>
          </li>
          <li className={isActive('/logs') ? 'active' : undefined}>
            {/* Hotwire-migrated path — full page load (plain anchor, not <Link>) */}
            <a href="/logs">
              <span className="purple-168-text">{isLoggedIn ? '9' : '8'}</span>&nbsp;Logs&nbsp;
            </a>
          </li>
          <li className={isActive('/grid') || isActive('/code') ? 'active' : undefined}>
            <Link to="/grid">
              <span className="purple-168-text">{isLoggedIn ? '10' : '9'}</span>&nbsp;THE PULSE GRID&nbsp;
            </Link>
          </li>
          {hackr?.role === 'admin' && (
            <li>
              <a href="/root">
                <span className="red-255-text">11</span>&nbsp;/root
              </a>
            </li>
          )}
        </ul>
      </div>
    </>
  )
}
