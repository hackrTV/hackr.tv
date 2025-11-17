import React, { Component, ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
  errorInfo: React.ErrorInfo | null
}

export class ErrorBoundary extends Component<Props, State> {
  constructor (props: Props) {
    super(props)
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    }
  }

  static getDerivedStateFromError (_error: Error): Partial<State> {
    return { hasError: true }
  }

  componentDidCatch (error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo)
    this.setState({
      error,
      errorInfo
    })
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null
    })
    window.location.href = '/'
  }

  render () {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <div className="tui-window red-255-border" style={{ margin: '2rem auto', maxWidth: '800px' }}>
          <fieldset className="tui-fieldset">
            <legend>ERROR</legend>
            <div style={{ padding: '1rem' }}>
              <p className="red-255-text" style={{ marginBottom: '1rem' }}>
                <strong>⚠ SYSTEM ERROR DETECTED</strong>
              </p>
              <p style={{ marginBottom: '1rem' }}>
                An unexpected error occurred. This has been logged for investigation.
              </p>

              {this.state.error && (
                <div className="tui-window" style={{ marginBottom: '1rem', padding: '0.5rem' }}>
                  <pre style={{ fontSize: '0.85em', overflow: 'auto' }}>
                    {this.state.error.toString()}
                  </pre>
                </div>
              )}

              <div style={{ marginTop: '1.5rem' }}>
                <button
                  className="tui-button red-255-border"
                  onClick={this.handleReset}
                  style={{ marginRight: '1rem' }}
                >
                  ← Return to Home
                </button>
                <button
                  className="tui-button"
                  onClick={() => window.location.reload()}
                >
                  ↻ Reload Page
                </button>
              </div>

              {process.env.NODE_ENV === 'development' && this.state.errorInfo && (
                <details style={{ marginTop: '1.5rem' }}>
                  <summary style={{ cursor: 'pointer' }}>Component Stack Trace</summary>
                  <pre style={{ fontSize: '0.75em', overflow: 'auto', marginTop: '0.5rem' }}>
                    {this.state.errorInfo.componentStack}
                  </pre>
                </details>
              )}
            </div>
          </fieldset>
        </div>
      )
    }

    return this.props.children
  }
}
