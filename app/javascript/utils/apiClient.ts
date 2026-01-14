export class ApiError extends Error {
  status: number
  body?: unknown

  constructor (message: string, status: number, body?: unknown) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }
}

const defaultHeaders: HeadersInit = {
  'X-Requested-With': 'XMLHttpRequest'
}

export const apiFetch = async (input: RequestInfo | URL, init: RequestInit = {}) => {
  const headers = new Headers(init.headers || {})
  Object.entries(defaultHeaders).forEach(([key, value]) => {
    if (!headers.has(key)) {
      headers.set(key, value)
    }
  })

  if (init.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }

  const response = await fetch(input, {
    credentials: 'include',
    ...init,
    headers
  })

  if (!response.ok) {
    let errorBody: unknown
    let message = response.statusText || 'Request failed'

    try {
      const contentType = response.headers?.get?.('content-type') || ''
      if (contentType.includes('application/json')) {
        errorBody = await response.json()
        if (typeof errorBody === 'object' && errorBody !== null && 'error' in errorBody) {
          const payload = errorBody as { error?: string }
          if (payload.error) {
            message = payload.error
          }
        }
      } else {
        errorBody = await response.text()
      }
    } catch (err) {
      console.warn('Failed to parse API error response', err)
    }

    throw new ApiError(message, response.status, errorBody)
  }

  return response
}

export const apiJson = async <T>(input: RequestInfo | URL, init: RequestInit = {}) => {
  const response = await apiFetch(input, init)
  if (response.status === 204) {
    return null as T
  }

  const contentType = response.headers?.get?.('content-type') || ''
  if (contentType.includes('application/json')) {
    return response.json() as Promise<T>
  }

  return response.text() as unknown as T
}
