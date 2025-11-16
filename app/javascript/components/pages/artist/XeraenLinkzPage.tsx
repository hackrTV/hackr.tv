import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const XeraenLinkzPage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>Linkz</legend>
          <div className="mb-20 pl-5 pr-15">
            <a href="https://open.spotify.com/artist/0nDs8RZN66dnOgJKa89FvV?si=G1wzaIddTI6m28g7oGp5cw" className="tui-button" target="_blank" rel="noopener noreferrer">Spotify</a>{' '}
            <a href="https://xeraen.bandcamp.com/" className="tui-button" target="_blank" rel="noopener noreferrer">Bandcamp</a>{' '}
            <a href="https://music.apple.com/us/artist/xeraen/1565857265" className="tui-button" target="_blank" rel="noopener noreferrer">Apple Music</a>{' '}
            <a href="https://soundcloud.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer">SoundCloud</a>
          </div>
          <div className="mb-15 pl-5 pr-15">
            <a href="https://youtube.com/@xeraen" className="tui-button" target="_blank" rel="noopener noreferrer">YouTube</a>{' '}
            <a href="https://x.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer">X.com</a>{' '}
            <a href="https://github.com/xeraen" className="tui-button" target="_blank" rel="noopener noreferrer">GitHub</a>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default XeraenLinkzPage
