import React from 'react'
import { Link } from 'react-router-dom'
import type { Pulse } from '../../types/pulse'
import { PulseCard } from './PulseCard'

interface ThreadViewProps {
  thread: Pulse[]
  rootPulse: Pulse
  onEchoToggle?: (pulseId: number, newEchoCount: number, isEchoed: boolean) => void
  onPulseCreated?: (pulse: Pulse) => void
  onPulseDeleted?: (pulseId: number) => void
}

export const ThreadView: React.FC<ThreadViewProps> = ({
  thread,
  rootPulse: _rootPulse,
  onEchoToggle,
  onPulseCreated,
  onPulseDeleted
}) => {
  // Sort thread by pulsed_at ascending (oldest first for conversations)
  const sortedThread = [...thread].sort((a, b) =>
    new Date(a.pulsed_at).getTime() - new Date(b.pulsed_at).getTime()
  )

  // Build hierarchy for nested display
  const buildHierarchy = (pulses: Pulse[]) => {
    const pulseMap = new Map<number, Pulse & { children: Pulse[] }>()

    // Initialize all pulses with empty children array
    pulses.forEach(pulse => {
      pulseMap.set(pulse.id, { ...pulse, children: [] })
    })

    const rootPulses: (Pulse & { children: Pulse[] })[] = []

    // Build parent-child relationships
    pulses.forEach(pulse => {
      const pulseWithChildren = pulseMap.get(pulse.id)!

      if (pulse.parent_pulse_id) {
        const parent = pulseMap.get(pulse.parent_pulse_id)
        if (parent) {
          parent.children.push(pulseWithChildren)
        } else {
          // Parent not in thread (shouldn't happen), add to roots
          rootPulses.push(pulseWithChildren)
        }
      } else {
        rootPulses.push(pulseWithChildren)
      }
    })

    return rootPulses
  }

  const hierarchy = buildHierarchy(sortedThread)

  const renderPulseTree = (pulse: Pulse & { children: Pulse[] }, depth: number = 0) => {
    return (
      <div key={pulse.id} className="thread-item" style={{ marginLeft: `${depth * 20}px` }}>
        <div className="thread-connector" />
        <PulseCard
          pulse={pulse}
          showThread={false}
          showReplies={false}
          onEchoToggle={onEchoToggle}
          onPulseCreated={onPulseCreated}
          onPulseDeleted={onPulseDeleted}
        />
        {pulse.children.length > 0 && (
          <div className="thread-replies">
            {pulse.children.map(child => renderPulseTree(child, depth + 1))}
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="thread-view">
      <div className="thread-header">
        <h2>Thread</h2>
        <div className="thread-stats">
          {thread.length} {thread.length === 1 ? 'pulse' : 'pulses'}
        </div>
      </div>

      <div className="back-link" style={{ marginBottom: '20px', marginTop: '10px' }}>
        <Link to="/wire">← Back to the Wire</Link>
      </div>

      <div className="thread-container">
        {hierarchy.map(pulse => renderPulseTree(pulse))}
      </div>
    </div>
  )
}
