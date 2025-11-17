import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

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
          <div>
            <iframe
              width="560"
              height="315"
              src="https://www.youtube.com/embed/GYSH0mDteR4?si=zvFKx_qoVLzmV3kZ"
              title="YouTube video player"
              frameBorder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              referrerPolicy="strict-origin-when-cross-origin"
              allowFullScreen
            />
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default XeraenPage
