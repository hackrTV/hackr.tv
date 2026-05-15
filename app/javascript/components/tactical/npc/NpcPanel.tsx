import React, { useState, useEffect, useCallback, useRef } from 'react'
import { apiJson } from '~/utils/apiClient'
import { NpcData } from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'
import { DialogueSection } from './DialogueSection'
import { MissionsSection } from './MissionsSection'

interface NpcPanelProps {
  visible: boolean
  refreshToken: number
  onCommand: (cmd: string) => Promise<string | undefined>
  onClose: () => void
  selectedMobId: number | null
}

type PanelSection = 'dialogue' | 'missions'

export const NpcPanel: React.FC<NpcPanelProps> = ({
  visible, refreshToken, onCommand, onClose, selectedMobId
}) => {
  const { executing } = useTactical()
  const [isRendered, setIsRendered] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [npcData, setNpcData] = useState<NpcData | null>(null)
  const [section, setSection] = useState<PanelSection>('dialogue')
  const [dialogueOutput, setDialogueOutput] = useState<string | null>(null)
  const initialTalkFired = useRef<number | null>(null)

  // Slide animation: mount first, then open; close first, then unmount
  useEffect(() => {
    if (visible) {
      setIsRendered(true)
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setIsOpen(true))
      })
      return () => cancelAnimationFrame(raf)
    } else {
      setIsOpen(false)
      const timer = setTimeout(() => setIsRendered(false), 300)
      return () => clearTimeout(timer)
    }
  }, [visible])

  // Reset state when panel closes or mob changes
  useEffect(() => {
    setNpcData(null)
    setDialogueOutput(null)
    initialTalkFired.current = null
  }, [visible, selectedMobId])

  // Fetch NPC data when panel is rendered
  useEffect(() => {
    if (isRendered && selectedMobId) {
      apiJson<NpcData>(`/api/grid/npc?mob_id=${selectedMobId}`)
        .then(data => {
          setNpcData(data)
          // Default to DIALOGUE if topics exist, otherwise MISSIONS
          if (data.dialogue.current_topics.length === 0 && !data.dialogue.greeting) {
            setSection('missions')
          }
        })
        .catch(err => { console.error('NPC data fetch failed:', err); setNpcData(null) })
    }
  }, [refreshToken, isRendered, selectedMobId])

  // Fire initial `talk` command for side effects (rep, achievements, progression)
  useEffect(() => {
    if (npcData && initialTalkFired.current !== selectedMobId) {
      initialTalkFired.current = selectedMobId
      if (npcData.dialogue.greeting) {
        onCommand(`talk to ${npcData.mob_name}`)
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps -- only fire once per mob open
  }, [npcData, selectedMobId])

  // Wrap onCommand for dialogue — captures terminal output for rendering in panel
  const handleDialogueCommand = useCallback(async (cmd: string) => {
    const output = await onCommand(cmd)
    if (output) setDialogueOutput(output)
  }, [onCommand])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onClose()
  }, [onClose])

  if (!isRendered) return null

  const hasMissions = (npcData?.available_missions?.length ?? 0) > 0 ||
    (npcData?.active_missions?.length ?? 0) > 0
  const hasDialogue = (npcData?.dialogue.current_topics?.length ?? 0) > 0 ||
    !!npcData?.dialogue.greeting

  return (
    <>
      {/* Backdrop */}
      <div
        onClick={handleBackdropClick}
        style={{
          position: 'absolute',
          inset: 0,
          zIndex: 29,
          background: isOpen ? 'rgba(0,0,0,0.2)' : 'transparent',
          transition: 'background 300ms ease-out'
        }}
      />

      {/* Panel */}
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: '50%',
          zIndex: 30,
          transform: isOpen ? 'translateY(0%)' : 'translateY(100%)',
          transition: 'transform 300ms ease-out',
          display: 'flex',
          flexDirection: 'column',
          background: '#0d0d0d',
          borderTop: '2px solid #c084fc',
          fontFamily: '\'Courier New\', monospace'
        }}
      >
        {/* Header */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '8px 12px',
          background: '#111',
          borderBottom: '1px solid #333',
          flexShrink: 0
        }}>
          <div>
            <span style={{ color: '#c084fc', fontWeight: 'bold', fontSize: '0.8em', letterSpacing: '1px' }}>
              NPC
            </span>
            {npcData && (
              <>
                <span style={{ color: '#444', margin: '0 8px' }}>::</span>
                <span style={{ color: '#d0d0d0', fontSize: '0.8em' }}>{npcData.mob_name}</span>
                {npcData.faction_name && (
                  <span style={{ color: '#6b7280', fontSize: '0.65em', marginLeft: '8px' }}>
                    [{npcData.faction_name}]
                  </span>
                )}
              </>
            )}
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'transparent',
              color: '#888',
              border: '1px solid #444',
              padding: '3px 10px',
              fontSize: '0.7em',
              cursor: 'pointer',
              borderRadius: '3px',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            CLOSE
          </button>
        </div>

        {/* Tabs — only show if both sections have content */}
        {hasDialogue && hasMissions && (
          <div style={{
            display: 'flex',
            borderBottom: '1px solid #333',
            background: '#0f0f0f',
            flexShrink: 0
          }}>
            {(['dialogue', 'missions'] as const).map(s => (
              <button
                key={s}
                onClick={() => setSection(s)}
                style={{
                  flex: 1,
                  background: section === s ? '#1a1a1a' : 'transparent',
                  color: section === s ? '#c084fc' : '#666',
                  border: 'none',
                  borderBottom: section === s ? '2px solid #c084fc' : '2px solid transparent',
                  padding: '6px 10px',
                  fontSize: '0.7em',
                  fontFamily: '\'Courier New\', monospace',
                  cursor: 'pointer',
                  fontWeight: section === s ? 'bold' : 'normal',
                  letterSpacing: '0.5px'
                }}
              >
                {s.toUpperCase()}
              </button>
            ))}
          </div>
        )}

        {/* Content */}
        <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden', padding: '8px 10px' }}>
          {!npcData && (
            <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>
          )}
          {npcData && section === 'dialogue' && (
            <DialogueSection
              dialogue={npcData.dialogue}
              mobName={npcData.mob_name}
              dialogueOutput={dialogueOutput}
              onCommand={handleDialogueCommand}
              executing={executing}
            />
          )}
          {npcData && section === 'missions' && (
            <MissionsSection
              availableMissions={npcData.available_missions}
              activeMissions={npcData.active_missions}
              deliveryItems={npcData.delivery_items}
              mobName={npcData.mob_name}
              onCommand={onCommand}
              executing={executing}
            />
          )}
        </div>
      </div>
    </>
  )
}
