import React from 'react'

interface LoadingSpinnerProps {
  message?: string
  size?: 'small' | 'medium' | 'large'
  color?: string
}

const SPINNER_FRAMES = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  message = 'Loading...',
  size = 'medium',
  color = 'cyan-255-text'
}) => {
  const sizeStyles = {
    small: { fontSize: '1em', padding: '1rem' },
    medium: { fontSize: '1.5em', padding: '2rem' },
    large: { fontSize: '2em', padding: '3rem' }
  }
  const [frameIndex, setFrameIndex] = React.useState(0)

  React.useEffect(() => {
    const interval = setInterval(() => {
      setFrameIndex((prev) => (prev + 1) % SPINNER_FRAMES.length)
    }, 80)

    return () => clearInterval(interval)
  }, [])

  return (
    <div
      style={{
        textAlign: 'center',
        ...sizeStyles[size]
      }}
    >
      <span className={color} style={{ marginRight: '0.5rem' }}>
        {SPINNER_FRAMES[frameIndex]}
      </span>
      <span>{message}</span>
    </div>
  )
}

interface LoadingPageProps {
  message?: string
}

export const LoadingPage: React.FC<LoadingPageProps> = ({ message = 'Loading...' }) => {
  return (
    <div className="tui-window" style={{ margin: '2rem auto', maxWidth: '600px', display: 'block' }}>
      <fieldset className="tui-fieldset">
        <legend>LOADING</legend>
        <LoadingSpinner message={message} size="large" />
      </fieldset>
    </div>
  )
}
