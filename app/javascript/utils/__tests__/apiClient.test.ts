import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { apiFetch, apiJson, ApiError } from '../apiClient'

describe('apiClient', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn())
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  describe('ApiError', () => {
    it('creates error with status and body', () => {
      const error = new ApiError('Not found', 404, { detail: 'Resource missing' })

      expect(error.message).toBe('Not found')
      expect(error.status).toBe(404)
      expect(error.body).toEqual({ detail: 'Resource missing' })
      expect(error.name).toBe('ApiError')
    })

    it('is instance of Error', () => {
      const error = new ApiError('Test', 500)
      expect(error).toBeInstanceOf(Error)
    })
  })

  describe('apiFetch', () => {
    it('includes credentials by default', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200
      })
      vi.stubGlobal('fetch', mockFetch)

      await apiFetch('/api/test')

      expect(mockFetch).toHaveBeenCalledWith('/api/test', expect.objectContaining({
        credentials: 'include'
      }))
    })

    it('sets X-Requested-With header', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200
      })
      vi.stubGlobal('fetch', mockFetch)

      await apiFetch('/api/test')

      const calledHeaders = mockFetch.mock.calls[0][1].headers
      expect(calledHeaders.get('X-Requested-With')).toBe('XMLHttpRequest')
    })

    it('sets Content-Type to JSON when body is present', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200
      })
      vi.stubGlobal('fetch', mockFetch)

      await apiFetch('/api/test', {
        method: 'POST',
        body: JSON.stringify({ data: 'test' })
      })

      const calledHeaders = mockFetch.mock.calls[0][1].headers
      expect(calledHeaders.get('Content-Type')).toBe('application/json')
    })

    it('does not override existing Content-Type header', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200
      })
      vi.stubGlobal('fetch', mockFetch)

      await apiFetch('/api/test', {
        method: 'POST',
        body: 'plain text',
        headers: { 'Content-Type': 'text/plain' }
      })

      const calledHeaders = mockFetch.mock.calls[0][1].headers
      expect(calledHeaders.get('Content-Type')).toBe('text/plain')
    })

    it('returns response on success', async () => {
      const mockResponse = {
        ok: true,
        status: 200,
        json: vi.fn().mockResolvedValue({ success: true })
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      const response = await apiFetch('/api/test')

      expect(response).toBe(mockResponse)
    })

    it('throws ApiError with JSON error message on failure', async () => {
      const mockResponse = {
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        headers: {
          get: vi.fn().mockReturnValue('application/json')
        },
        json: vi.fn().mockResolvedValue({ error: 'Validation failed' })
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await expect(apiFetch('/api/test')).rejects.toThrow(ApiError)

      try {
        await apiFetch('/api/test')
      } catch (error) {
        expect(error).toBeInstanceOf(ApiError)
        expect((error as ApiError).message).toBe('Validation failed')
        expect((error as ApiError).status).toBe(422)
        expect((error as ApiError).body).toEqual({ error: 'Validation failed' })
      }
    })

    it('throws ApiError with statusText when no error field in JSON', async () => {
      const mockResponse = {
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        headers: {
          get: vi.fn().mockReturnValue('application/json')
        },
        json: vi.fn().mockResolvedValue({ details: 'Something went wrong' })
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      try {
        await apiFetch('/api/test')
      } catch (error) {
        expect((error as ApiError).message).toBe('Internal Server Error')
      }
    })

    it('throws ApiError with text body for non-JSON errors', async () => {
      const mockResponse = {
        ok: false,
        status: 503,
        statusText: 'Service Unavailable',
        headers: {
          get: vi.fn().mockReturnValue('text/html')
        },
        text: vi.fn().mockResolvedValue('<html>Error page</html>')
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      try {
        await apiFetch('/api/test')
      } catch (error) {
        expect((error as ApiError).body).toBe('<html>Error page</html>')
      }
    })

    it('handles response parse failures gracefully', async () => {
      const mockResponse = {
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        headers: {
          get: vi.fn().mockReturnValue('application/json')
        },
        json: vi.fn().mockRejectedValue(new Error('Parse error'))
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await expect(apiFetch('/api/test')).rejects.toThrow(ApiError)
    })
  })

  describe('apiJson', () => {
    it('returns parsed JSON on success', async () => {
      const mockResponse = {
        ok: true,
        status: 200,
        headers: {
          get: vi.fn().mockReturnValue('application/json')
        },
        json: vi.fn().mockResolvedValue({ data: 'test' })
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      const result = await apiJson<{ data: string }>('/api/test')

      expect(result).toEqual({ data: 'test' })
    })

    it('returns null for 204 No Content', async () => {
      const mockResponse = {
        ok: true,
        status: 204,
        headers: {
          get: vi.fn().mockReturnValue('')
        }
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      const result = await apiJson('/api/test')

      expect(result).toBeNull()
    })

    it('returns text for non-JSON content type', async () => {
      const mockResponse = {
        ok: true,
        status: 200,
        headers: {
          get: vi.fn().mockReturnValue('text/plain')
        },
        text: vi.fn().mockResolvedValue('Plain text response')
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      const result = await apiJson<string>('/api/test')

      expect(result).toBe('Plain text response')
    })

    it('propagates ApiError from apiFetch', async () => {
      const mockResponse = {
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
        headers: {
          get: vi.fn().mockReturnValue('application/json')
        },
        json: vi.fn().mockResolvedValue({ error: 'Authentication required' })
      }
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await expect(apiJson('/api/test')).rejects.toThrow(ApiError)

      try {
        await apiJson('/api/test')
      } catch (error) {
        expect((error as ApiError).status).toBe(401)
        expect((error as ApiError).message).toBe('Authentication required')
      }
    })
  })
})
