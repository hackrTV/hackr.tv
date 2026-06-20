import React from 'react'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { describe, it, expect } from 'vitest'
import { BioText } from './BioText'

const renderWithRouter = (node: React.ReactNode) => render(<BrowserRouter>{node}</BrowserRouter>)

describe('BioText', () => {
  it('renders plain text unchanged', () => {
    renderWithRouter(<BioText>Just a ghost in the wire.</BioText>)
    expect(screen.getByText('Just a ghost in the wire.')).toBeInTheDocument()
  })

  it('links @mentions to the profile route', () => {
    renderWithRouter(<BioText>shouting out @xeraen today</BioText>)
    const link = screen.getByRole('link', { name: '@xeraen' })
    expect(link).toHaveAttribute('href', '/wire/xeraen')
  })

  it('does not linkify external URLs', () => {
    renderWithRouter(<BioText>visit https://evil.example.com now</BioText>)
    expect(screen.queryByRole('link')).toBeNull()
  })

  it('does not treat an email local-part as a mention', () => {
    renderWithRouter(<BioText>reach me at me@gmail.com anytime</BioText>)
    expect(screen.queryByRole('link')).toBeNull()
  })

  it('only links mentions at a word boundary', () => {
    renderWithRouter(<BioText>email me@host but ping @xeraen</BioText>)
    const links = screen.queryAllByRole('link')
    expect(links).toHaveLength(1)
    expect(links[0]).toHaveAttribute('href', '/wire/xeraen')
  })
})
