import React from 'react'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { describe, it, expect } from 'vitest'
import { WireText } from './WireText'

const renderWithRouter = (component: React.ReactNode) => {
  return render(<BrowserRouter>{component}</BrowserRouter>)
}

describe('WireText', () => {
  describe('admin poster (links allowed)', () => {
    it('renders plain URL as clickable link', () => {
      renderWithRouter(<WireText posterIsAdmin={true}>Check https://example.com out</WireText>)

      const link = screen.getByRole('link', { name: 'https://example.com' })
      expect(link).toHaveAttribute('href', 'https://example.com')
      expect(link).toHaveAttribute('target', '_blank')
    })

    it('renders markdown link with display text', () => {
      renderWithRouter(<WireText posterIsAdmin={true}>See [my site](https://example.com) here</WireText>)

      const link = screen.getByRole('link', { name: 'my site' })
      expect(link).toHaveAttribute('href', 'https://example.com')
    })

    it('renders codex links alongside URLs', () => {
      renderWithRouter(
        <WireText posterIsAdmin={true}>
          Visit https://example.com and read about [[GovCorp]]
        </WireText>
      )

      const urlLink = screen.getByRole('link', { name: 'https://example.com' })
      expect(urlLink).toHaveAttribute('href', 'https://example.com')

      const codexLink = screen.getByRole('link', { name: 'GovCorp' })
      expect(codexLink).toHaveAttribute('href', '/codex/govcorp')
    })
  })

  describe('non-admin poster (links censored)', () => {
    it('censors plain URL', () => {
      const { container } = renderWithRouter(
        <WireText posterIsAdmin={false}>Check https://example.com out</WireText>
      )

      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
      expect(container.textContent).not.toContain('https://example.com')
    })

    it('censors markdown link', () => {
      const { container } = renderWithRouter(
        <WireText posterIsAdmin={false}>See [my site](https://example.com) here</WireText>
      )

      expect(container.textContent).toContain('[LINK CENSORED BY GOVCORP]')
      expect(container.textContent).not.toContain('my site')
    })

    it('still renders codex links when URLs are censored', () => {
      renderWithRouter(
        <WireText posterIsAdmin={false}>
          Visit https://example.com and read about [[GovCorp]]
        </WireText>
      )

      expect(screen.getByText('[LINK CENSORED BY GOVCORP]')).toBeInTheDocument()

      const codexLink = screen.getByRole('link', { name: 'GovCorp' })
      expect(codexLink).toHaveAttribute('href', '/codex/govcorp')
    })
  })

  describe('plain text (no URLs)', () => {
    it('renders text unchanged', () => {
      renderWithRouter(<WireText posterIsAdmin={false}>Just a normal message</WireText>)
      expect(screen.getByText('Just a normal message')).toBeInTheDocument()
    })

    it('renders codex links in text without URLs', () => {
      renderWithRouter(
        <WireText posterIsAdmin={false}>Learn about [[GovCorp]] today</WireText>
      )

      const link = screen.getByRole('link', { name: 'GovCorp' })
      expect(link).toHaveAttribute('href', '/codex/govcorp')
    })
  })
})
