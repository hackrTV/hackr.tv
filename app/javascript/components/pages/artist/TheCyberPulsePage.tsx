import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const TheCyberPulsePage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>What is The.CyberPul.se?</legend>
          <div className="pl-5 pt-5">
            <iframe
              width="560"
              height="315"
              src="https://www.youtube-nocookie.com/embed/MWSjCJQhr1o?si=wJSBR8QRjY9Y7xDG"
              title="YouTube video player"
              frameBorder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowFullScreen
            />
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TheCyberPulsePage
