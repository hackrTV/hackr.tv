import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { SeekBar } from './SeekBar'

describe('SeekBar', () => {
  const defaultProps = {
    currentTime: 30,
    duration: 180,
    onSeekStart: vi.fn(),
    onSeek: vi.fn(),
    onSeekEnd: vi.fn()
  }

  it('renders current time and duration', () => {
    render(<SeekBar {...defaultProps} />)

    expect(screen.getByText('0:30')).toBeInTheDocument()
    expect(screen.getByText('3:00')).toBeInTheDocument()
  })

  it('displays correct progress value', () => {
    render(<SeekBar {...defaultProps} />)

    const seekBar = screen.getByRole('slider')
    // 30 / 180 * 100 = 16.67%
    expect(seekBar).toHaveValue('16.666666666666664')
  })

  it('handles zero duration gracefully', () => {
    render(<SeekBar {...defaultProps} duration={0} currentTime={0} />)

    const times = screen.getAllByText('0:00')
    expect(times).toHaveLength(2) // current time and duration
    const seekBar = screen.getByRole('slider')
    expect(seekBar).toHaveValue('0')
  })

  it('formats time correctly for different values', () => {
    const { rerender } = render(<SeekBar {...defaultProps} currentTime={0} duration={0} />)

    const times = screen.getAllByText('0:00')
    expect(times).toHaveLength(2)

    rerender(<SeekBar {...defaultProps} currentTime={65} duration={125} />)
    expect(screen.getByText('1:05')).toBeInTheDocument()
    expect(screen.getByText('2:05')).toBeInTheDocument()
  })

  it('calls onSeekStart on mouse down', async () => {
    const user = userEvent.setup()
    render(<SeekBar {...defaultProps} />)

    const seekBar = screen.getByRole('slider')
    await user.pointer({ target: seekBar, keys: '[MouseLeft>]' })

    expect(defaultProps.onSeekStart).toHaveBeenCalledTimes(1)
  })

  it('calls onSeek when value changes', async () => {
    const onSeek = vi.fn()
    render(<SeekBar {...defaultProps} onSeek={onSeek} />)

    const seekBar = screen.getByRole('slider') as HTMLInputElement

    // Change the value using fireEvent (proper React event)
    fireEvent.change(seekBar, { target: { value: '50' } })

    expect(onSeek).toHaveBeenCalled()
  })

  it('calls onSeekEnd on mouse up', async () => {
    const user = userEvent.setup()
    render(<SeekBar {...defaultProps} />)

    const seekBar = screen.getByRole('slider')
    await user.pointer([
      { target: seekBar, keys: '[MouseLeft>]' },
      { keys: '[/MouseLeft]' }
    ])

    expect(defaultProps.onSeekEnd).toHaveBeenCalled()
  })

  it('handles NaN values in formatTime', () => {
    render(<SeekBar {...defaultProps} currentTime={NaN} duration={NaN} />)

    const times = screen.getAllByText('0:00')
    expect(times).toHaveLength(2)
  })
})
