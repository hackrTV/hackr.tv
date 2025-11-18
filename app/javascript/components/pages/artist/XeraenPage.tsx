import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { YouTubePlayer } from '~/components/YouTubePlayer'

const XeraenPage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>Latest Release!</legend>
          <div>
            <iframe
              style={{ border: 0, width: '350px', height: '442px' }}
              src="https://bandcamp.com/EmbeddedPlayer/track=331007821/size=large/bgcol=333333/linkcol=9a64ff/tracklist=false/transparent=true/"
              seamless
              title="XERAEN - Encrypted Shroud on Bandcamp"
            >
              <a href="https://xeraen.bandcamp.com/track/encrypted-shroud">Encrypted Shroud by ＸＥＲＡＥＮ</a>
            </iframe>
          </div>
        </fieldset>
      </div>

      <br />
      <br />

      <div className="tui-window ml-10 mt-10">
        <fieldset className="tui-fieldset">
          <legend>Latest Video!</legend>
          <div className="pl-5 pt-5">
            <YouTubePlayer videoId="GYSH0mDteR4" width={560} height={315} />
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default XeraenPage
