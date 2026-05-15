import React from 'react'
import { NpcDialogueState } from '~/types/zoneMap'
import { sanitizeHtml } from '~/utils/sanitizeHtml'

interface DialogueSectionProps {
  dialogue: NpcDialogueState
  mobName: string
  dialogueOutput: string | null
  onCommand: (cmd: string) => void
}

export const DialogueSection: React.FC<DialogueSectionProps> = ({ dialogue, mobName, dialogueOutput, onCommand }) => {
  if (!dialogue.greeting && dialogue.current_topics.length === 0) {
    return <div style={{ color: '#555', fontSize: '0.8em', padding: '8px 0' }}>This NPC has nothing to say.</div>
  }

  return (
    <div style={{ fontSize: '0.8em' }}>
      {/* Dialogue response — either the captured command output or the greeting at root */}
      {dialogueOutput ? (
        <div
          style={{ marginBottom: '12px' }}
          dangerouslySetInnerHTML={{ __html: sanitizeHtml(dialogueOutput) }}
        />
      ) : dialogue.at_root && dialogue.greeting ? (
        <div style={{ marginBottom: '12px' }}>
          <span style={{ color: '#c084fc' }}>{mobName}</span>
          <span style={{ color: '#444' }}> :: </span>
          <span style={{ color: '#60a5fa' }}>&ldquo;{dialogue.greeting}&rdquo;</span>
        </div>
      ) : null}

      {/* Breadcrumb when deeper in tree */}
      {!dialogue.at_root && (
        <div style={{ marginBottom: '8px' }}>
          <span style={{ color: '#6b7280', fontSize: '0.85em' }}>
            {dialogue.current_path.join(' > ')}
          </span>
        </div>
      )}

      {/* Topic buttons */}
      {dialogue.current_topics.length > 0 && (
        <div style={{ marginBottom: '10px' }}>
          <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: '6px' }}>
            Topics:
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {dialogue.current_topics.map(topic => (
              <button
                key={topic.key}
                onClick={() => onCommand(`ask ${mobName} about ${topic.key}`)}
                style={{
                  background: 'transparent',
                  border: '1px solid #c084fc',
                  borderRadius: '3px',
                  color: '#c084fc',
                  padding: '4px 10px',
                  fontSize: '0.9em',
                  cursor: 'pointer',
                  fontFamily: '\'Courier New\', monospace',
                  transition: 'background 0.15s'
                }}
                onMouseEnter={e => { (e.target as HTMLElement).style.background = '#1a1a2e' }}
                onMouseLeave={e => { (e.target as HTMLElement).style.background = 'transparent' }}
              >
                {topic.key}{topic.has_children ? ' \u203A' : ''}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Navigation buttons */}
      <div style={{ display: 'flex', gap: '8px', marginTop: '8px' }}>
        {!dialogue.at_root && (
          <button
            onClick={() => onCommand(`ask ${mobName} about back`)}
            style={{
              background: 'transparent',
              border: '1px solid #444',
              borderRadius: '3px',
              color: '#888',
              padding: '3px 10px',
              fontSize: '0.85em',
              cursor: 'pointer',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            {'\u2190'} BACK
          </button>
        )}
        {!dialogue.at_root && (
          <button
            onClick={() => onCommand(`talk to ${mobName} again`)}
            style={{
              background: 'transparent',
              border: '1px solid #444',
              borderRadius: '3px',
              color: '#888',
              padding: '3px 10px',
              fontSize: '0.85em',
              cursor: 'pointer',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            RESET
          </button>
        )}
      </div>
    </div>
  )
}
