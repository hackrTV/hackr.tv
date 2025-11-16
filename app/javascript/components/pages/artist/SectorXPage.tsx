import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const SectorXPage: React.FC = () => {
  return (
    <DefaultLayout>
      <div className="tui-window ml-10">
        <fieldset className="tui-fieldset">
          <legend>Coming Soon!</legend>
          <div>
            Keep your hackr eyes peeled!
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default SectorXPage
