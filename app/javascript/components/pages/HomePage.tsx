import React from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { TerminalAnimation } from '~/components/terminal/TerminalAnimation'

export const HomePage: React.FC = () => {
  return (
    <DefaultLayout>
      <TerminalAnimation />
    </DefaultLayout>
  )
}
