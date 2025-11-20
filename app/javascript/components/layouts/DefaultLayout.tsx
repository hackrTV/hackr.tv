import React, { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'

interface DefaultLayoutProps {
  children: ReactNode
}

export const DefaultLayout: React.FC<DefaultLayoutProps> = ({ children }) => {
  return (
    <div className="black-168">
      {/* Header Navigation Menu */}
      <HeaderMenu />

      <br />

      {/* ASCII Art Header */}
      <div className="ml-10 pl-5 white-168-text">
        <Link to="/" style={{ display: 'inline-block' }}>
          <pre id="greetings" style={{ fontSize: '11px' }}>
            {` __  __                   __            ______  __  __
/\\ \\/\\ \\                 /\\ \\          /\\__  _\\/\\ \\/\\ \\
\\ \\ \\_\\ \\     __      ___\\ \\ \\/'\\   _ _\\/_/\\ \\/\\ \\ \\ \\ \\
 \\ \\  _  \\  /'__\`\\   /'___\\ \\ , <  /\\\`'__\\\\ \\ \\ \\ \\ \\ \\ \\
  \\ \\ \\ \\ \\/\\ \\L\\._/\\ \\__/\\ \\ \\\\\`\\\\ \\ \\/ _\\ \\ \\ \\ \\ \\_/ \\
   \\ \\_\\ \\_\\ \\__/.\\_\\ \\____\\\\ \\_\\ \\_\\ \\_\\/\\_\\ \\_\\ \\ \`\\___/
    \\/_/\\/_/\\/__/\\/_/\\/____/ \\/_/\\/_/\\/_/\\/_/\\/_/  \`\\/__/`}
          </pre>
        </Link>
      </div>

      <br />

      {/* Footer Navigation Menu */}
      <FooterMenu />

      {/* Main Content */}
      <div className="ml-10 mb-20 pb-50">
        {children}
      </div>
    </div>
  )
}
