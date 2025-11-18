import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { YouTubePlayer } from '~/components/YouTubePlayer'

const TheCyberPulsePage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>What is The.CyberPul.se?</legend>
          <div className="pl-5 pt-5">
            <YouTubePlayer videoId="MWSjCJQhr1o" width={560} height={315} />
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TheCyberPulsePage
