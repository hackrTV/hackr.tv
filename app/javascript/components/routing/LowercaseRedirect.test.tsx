import React from 'react'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { LowercaseRedirect } from './LowercaseRedirect'

// Track navigation calls
const mockNavigate = vi.fn()

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate
  }
})

describe('LowercaseRedirect', () => {
  beforeEach(() => {
    mockNavigate.mockClear()
  })

  const renderWithRouter = (initialPath: string) => {
    return render(
      <MemoryRouter initialEntries={[initialPath]}>
        <LowercaseRedirect>
          <Routes>
            <Route path="*" element={<div>Content</div>} />
          </Routes>
        </LowercaseRedirect>
      </MemoryRouter>
    )
  }

  it('renders children without redirecting when path is lowercase', () => {
    renderWithRouter('/fm/radio')
    expect(screen.getByText('Content')).toBeInTheDocument()
    expect(mockNavigate).not.toHaveBeenCalled()
  })

  it('redirects uppercase paths to lowercase', () => {
    renderWithRouter('/FM/Radio')
    expect(mockNavigate).toHaveBeenCalledWith('/fm/radio', { replace: true })
  })

  it('redirects mixed case paths to lowercase', () => {
    renderWithRouter('/TheCyberPulse')
    expect(mockNavigate).toHaveBeenCalledWith('/thecyberpulse', { replace: true })
  })

  it('preserves query parameters when redirecting', () => {
    renderWithRouter('/FM/Radio?station=pulse')
    expect(mockNavigate).toHaveBeenCalledWith('/fm/radio?station=pulse', { replace: true })
  })

  it('preserves hash fragments when redirecting', () => {
    renderWithRouter('/FM/Radio#section')
    expect(mockNavigate).toHaveBeenCalledWith('/fm/radio#section', { replace: true })
  })

  it('does not redirect /shared/ paths (case-sensitive tokens)', () => {
    renderWithRouter('/shared/AbCdEf123')
    expect(mockNavigate).not.toHaveBeenCalled()
  })

  it('does not redirect /grid/verify/ paths (case-sensitive tokens)', () => {
    renderWithRouter('/grid/verify/AbCdEf123XyZ')
    expect(mockNavigate).not.toHaveBeenCalled()
  })

  it('redirects band profile paths to lowercase', () => {
    renderWithRouter('/System-Rot')
    expect(mockNavigate).toHaveBeenCalledWith('/system-rot', { replace: true })
  })

  it('redirects grid paths to lowercase', () => {
    renderWithRouter('/Grid/Login')
    expect(mockNavigate).toHaveBeenCalledWith('/grid/login', { replace: true })
  })

  it('redirects codex paths to lowercase', () => {
    renderWithRouter('/Codex/XERAEN')
    expect(mockNavigate).toHaveBeenCalledWith('/codex/xeraen', { replace: true })
  })

  it('redirects wire paths to lowercase', () => {
    renderWithRouter('/Wire/XERAEN')
    expect(mockNavigate).toHaveBeenCalledWith('/wire/xeraen', { replace: true })
  })

  it('handles root path without redirecting', () => {
    renderWithRouter('/')
    expect(mockNavigate).not.toHaveBeenCalled()
  })
})
