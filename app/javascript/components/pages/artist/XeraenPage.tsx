import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { EmbeddedTrack } from '~/components/EmbeddedTrack'
import { YouTubePlayer } from '~/components/YouTubePlayer'

const XeraenPage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>Latest Release!</legend>
          <div>
            <EmbeddedTrack trackId="encrypted-shroud" />
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
