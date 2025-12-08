import React from 'react'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { describe, it, expect } from 'vitest'
import { CodexText } from './CodexText'

const renderWithRouter = (component: React.ReactNode) => {
  return render(<BrowserRouter>{component}</BrowserRouter>)
}

describe('CodexText', () => {
  it('renders plain text without links unchanged', () => {
    renderWithRouter(<CodexText>This is plain text with no links.</CodexText>)
    expect(screen.getByText('This is plain text with no links.')).toBeInTheDocument()
  })

  it('converts [[Entry Name]] syntax to links', () => {
    renderWithRouter(<CodexText>Learn about [[GovCorp]] today.</CodexText>)

    const link = screen.getByRole('link', { name: 'GovCorp' })
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/codex/govcorp')
  })

  it('handles multiple links in one text', () => {
    renderWithRouter(
      <CodexText>The [[Fracture Network]] fights [[GovCorp]] control.</CodexText>
    )

    const fractureLink = screen.getByRole('link', { name: 'Fracture Network' })
    const govcorpLink = screen.getByRole('link', { name: 'GovCorp' })

    expect(fractureLink).toHaveAttribute('href', '/codex/fracture-network')
    expect(govcorpLink).toHaveAttribute('href', '/codex/govcorp')
  })

  it('supports custom display text with pipe syntax', () => {
    renderWithRouter(
      <CodexText>Meet [[XERAEN|the legendary hackr]] from the future.</CodexText>
    )

    const link = screen.getByRole('link', { name: 'the legendary hackr' })
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/codex/xeraen')
  })

  it('preserves text before, between, and after links', () => {
    renderWithRouter(
      <CodexText>Before [[GovCorp]] middle [[XERAEN]] after.</CodexText>
    )

    expect(screen.getByText(/Before/)).toBeInTheDocument()
    expect(screen.getByText(/middle/)).toBeInTheDocument()
    expect(screen.getByText(/after\./)).toBeInTheDocument()
  })

  it('applies className when provided', () => {
    const { container } = renderWithRouter(
      <CodexText className="custom-class">Text with [[GovCorp]] link.</CodexText>
    )

    expect(container.querySelector('.custom-class')).toBeInTheDocument()
  })

  it('applies style when provided', () => {
    const { container } = renderWithRouter(
      <CodexText style={{ color: 'red' }}>Text with [[GovCorp]] link.</CodexText>
    )

    const span = container.querySelector('span')
    expect(span).toHaveStyle({ color: 'rgb(255, 0, 0)' })
  })

  it('generates correct slugs for various entry names', () => {
    renderWithRouter(
      <CodexText>
        [[The Pulse Grid]] and [[PRISM]] are connected.
      </CodexText>
    )

    expect(screen.getByRole('link', { name: 'The Pulse Grid' })).toHaveAttribute(
      'href',
      '/codex/the-pulse-grid'
    )
    expect(screen.getByRole('link', { name: 'PRISM' })).toHaveAttribute(
      'href',
      '/codex/prism'
    )
  })

  it('adds codex-link class to generated links', () => {
    renderWithRouter(<CodexText>Check out [[GovCorp]] info.</CodexText>)

    const link = screen.getByRole('link', { name: 'GovCorp' })
    expect(link).toHaveClass('codex-link')
  })

  it('handles mixed content with JSX expressions', () => {
    const futureYear = 2125
    renderWithRouter(
      <CodexText>
        In {futureYear}, [[XERAEN]] broadcasts from [[GovCorp]] territory.
      </CodexText>
    )

    expect(screen.getByText(/2125/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'XERAEN' })).toHaveAttribute('href', '/codex/xeraen')
    expect(screen.getByRole('link', { name: 'GovCorp' })).toHaveAttribute('href', '/codex/govcorp')
  })

  it('handles numbers in children array', () => {
    const year = 2025
    renderWithRouter(
      <CodexText>
        Year {year} marks the beginning.
      </CodexText>
    )

    expect(screen.getByText(/2025/)).toBeInTheDocument()
    expect(screen.getByText(/marks the beginning/)).toBeInTheDocument()
  })
})
