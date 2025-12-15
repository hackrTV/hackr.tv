import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, act } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { GridGamePage } from './GridGamePage'

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(() => null),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn()
}
Object.defineProperty(window, 'localStorage', { value: localStorageMock })

// Mock matchMedia for useMobileDetect hook
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
})

// Mock react-router-dom navigate
const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate
  }
})

// Mock useGridAuth
const mockDisconnect = vi.fn()
vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => ({
    hackr: {
      id: 1,
      hackr_alias: 'TestHackr',
      role: 'operative',
      current_room: { id: 1, name: 'Test Room' }
    },
    loading: false,
    disconnect: mockDisconnect
  })
}))

// Store the onEvent callback for testing
let capturedOnEvent: ((event: unknown) => void) | null = null

vi.mock('~/hooks/useActionCable', () => ({
  useActionCable: ({ onEvent }: { onEvent: (event: unknown) => void }) => {
    capturedOnEvent = onEvent
    return { isConnected: true, reconnect: vi.fn() }
  }
}))

// Mock fetch for API calls
const mockFetch = vi.fn()
global.fetch = mockFetch

describe('GridGamePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    capturedOnEvent = null

    // Default fetch mock for initial look command
    mockFetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({
        success: true,
        output: 'You are in Test Room.',
        room_id: 1,
        current_room: { id: 1, name: 'Test Room' }
      })
    })
  })

  const renderComponent = () => {
    return render(
      <MemoryRouter>
        <GridGamePage />
      </MemoryRouter>
    )
  }

  describe('system_broadcast event handling', () => {
    it('displays system broadcast messages', async () => {
      renderComponent()

      // Wait for component to initialize
      await waitFor(() => {
        expect(capturedOnEvent).not.toBeNull()
      })

      // Simulate receiving a system_broadcast event
      act(() => {
        capturedOnEvent!({
          type: 'system_broadcast',
          message: '[SYSTEM BROADCAST] Server maintenance in 5 minutes',
          sender: 'ADMIN'
        })
      })

      // Check that the broadcast message appears in the output
      await waitFor(() => {
        expect(screen.getByText(/Server maintenance in 5 minutes/)).toBeInTheDocument()
      })
    })

    it('styles system broadcast in red', async () => {
      renderComponent()

      await waitFor(() => {
        expect(capturedOnEvent).not.toBeNull()
      })

      act(() => {
        capturedOnEvent!({
          type: 'system_broadcast',
          message: '[SYSTEM BROADCAST] Important announcement',
          sender: 'ADMIN'
        })
      })

      await waitFor(() => {
        const messageElement = screen.getByText(/Important announcement/)
        // The message should be wrapped in a span with red color
        expect(messageElement.closest('span')).toHaveStyle({ color: '#f87171' })
      })
    })

    it('includes timestamp in system broadcast', async () => {
      renderComponent()

      await waitFor(() => {
        expect(capturedOnEvent).not.toBeNull()
      })

      act(() => {
        capturedOnEvent!({
          type: 'system_broadcast',
          message: '[SYSTEM BROADCAST] Test message',
          sender: 'ADMIN'
        })
      })

      // The output should contain a timestamp in HH:MM format
      await waitFor(() => {
        const output = document.querySelector('[class*="output"]') || document.body
        expect(output.innerHTML).toMatch(/\[\d{2}:\d{2}\]/)
      })
    })
  })

  describe('other event types still work', () => {
    it('handles say events', async () => {
      renderComponent()

      await waitFor(() => {
        expect(capturedOnEvent).not.toBeNull()
      })

      act(() => {
        capturedOnEvent!({
          type: 'say',
          hackr_alias: 'OtherHackr',
          message: 'Hello everyone!'
        })
      })

      await waitFor(() => {
        expect(screen.getByText(/OtherHackr/)).toBeInTheDocument()
        expect(screen.getByText(/Hello everyone!/)).toBeInTheDocument()
      })
    })

    it('handles movement events for arrivals', async () => {
      renderComponent()

      await waitFor(() => {
        expect(capturedOnEvent).not.toBeNull()
      })

      act(() => {
        capturedOnEvent!({
          type: 'movement',
          hackr_alias: 'Visitor',
          direction: 'north',
          to_room_id: 1
        })
      })

      await waitFor(() => {
        expect(screen.getByText(/Visitor enters from the south/)).toBeInTheDocument()
      })
    })
  })
})
