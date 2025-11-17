import React from 'react'
import { Link } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'

export const FooterMenu: React.FC = () => {
  const { hackr } = useGridAuth()

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
              <span className="purple-168-text">0</span> hackr.tv&nbsp;
            </Link>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <Link to="/thecyberpulse">
              <span className="purple-168-text">1</span> The.CyberPul.se&nbsp;
            </Link>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <Link to="/xeraen">
              <span className="purple-168-text">2</span> XERAEN&nbsp;
            </Link>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <Link to="/fm/radio">
              <span className="purple-168-text">3</span> hackr.fm&nbsp;
            </Link>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <Link to="/grid">
              <span className="purple-168-text">4</span> THE PULSE GRID (pre-alpha)&nbsp;
            </Link>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <Link to="/logs">
              <span className="purple-168-text">5</span> Hackr Logs&nbsp;
            </Link>
          </li>
          {hackr?.role === 'admin' && (
            <>
              <span className="tui-statusbar-divider"></span>
              <li>
                <a href="/root">
                  <span className="red-255-text">6</span> /root <span className="red-255-text">[ADMIN]</span>&nbsp;
                </a>
              </li>
            </>
          )}
          <span className="tui-statusbar-divider"></span>
          <li>
            <a href="https://ashlinn.net" target="_blank" rel="noopener noreferrer">
              <span className="purple-168-text">{hackr?.role === 'admin' ? '7' : '6'}</span> Ashlinn&nbsp;
            </a>
          </li>
          <span className="tui-statusbar-divider"></span>
          <li>
            <a href="https://michaelk.net" target="_blank" rel="noopener noreferrer">
              <span className="purple-168-text">{hackr?.role === 'admin' ? '8' : '7'}</span> MichaelK&nbsp;
            </a>
          </li>
        </ul>
      </div>
    </>
  )
}
