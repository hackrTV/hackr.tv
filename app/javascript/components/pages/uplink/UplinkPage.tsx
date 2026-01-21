import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { UplinkPanel } from '~/components/uplink/UplinkPanel'

export const UplinkPage: React.FC = () => {
  return (
    <DefaultLayout showAsciiArt={false}>
      <div
        className="uplink-page"
        style={{
          maxWidth: '800px',
          margin: '0 auto',
          padding: '20px',
          height: 'calc(100vh - 200px)',
          minHeight: '500px'
        }}
      >
        <UplinkPanel />
      </div>
    </DefaultLayout>
  )
}
