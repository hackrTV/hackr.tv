import React, { useState } from 'react'
import { StatsTab } from './tabs/StatsTab'
import { DeckTab } from './tabs/DeckTab'
import { LoadoutTab } from './tabs/LoadoutTab'
import { InventoryTab } from './tabs/InventoryTab'
import { RepTab } from './tabs/RepTab'
import { MissionsTab } from './tabs/MissionsTab'
import { SchematicsTab } from './tabs/SchematicsTab'

type TabKey = 'stats' | 'deck' | 'loadout' | 'inventory' | 'rep' | 'missions' | 'schematics'

const TABS: { key: TabKey; label: string }[] = [
  { key: 'stats', label: 'STATS' },
  { key: 'deck', label: 'DECK' },
  { key: 'loadout', label: 'GEAR' },
  { key: 'inventory', label: 'INV' },
  { key: 'rep', label: 'REP' },
  { key: 'missions', label: 'MISSIONS' },
  { key: 'schematics', label: 'SCHEM' }
]

interface TacticalStatusPanelProps {
  refreshToken: number
  onCommand?: (cmd: string) => void
}

export const TacticalStatusPanel: React.FC<TacticalStatusPanelProps> = ({ refreshToken, onCommand }) => {
  const [activeTab, setActiveTab] = useState<TabKey>('stats')
  const [mountedTabs, setMountedTabs] = useState<Set<TabKey>>(new Set(['stats']))

  const handleTabClick = (key: TabKey) => {
    setActiveTab(key)
    setMountedTabs(prev => {
      if (prev.has(key)) return prev
      const next = new Set(prev)
      next.add(key)
      return next
    })
  }

  const renderTab = (key: TabKey) => {
    if (!mountedTabs.has(key)) return null
    const isActive = key === activeTab

    return (
      <div key={key} style={{ display: isActive ? 'block' : 'none', height: '100%', overflow: 'auto' }}>
        {key === 'stats' && <StatsTab refreshToken={refreshToken} />}
        {key === 'deck' && <DeckTab refreshToken={refreshToken} />}
        {key === 'loadout' && <LoadoutTab refreshToken={refreshToken} />}
        {key === 'inventory' && <InventoryTab refreshToken={refreshToken} />}
        {key === 'rep' && <RepTab refreshToken={refreshToken} />}
        {key === 'missions' && <MissionsTab refreshToken={refreshToken} />}
        {key === 'schematics' && <SchematicsTab refreshToken={refreshToken} onCommand={onCommand} />}
      </div>
    )
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflow: 'hidden' }}>
      <div style={{
        display: 'flex', gap: 0, flexShrink: 0,
        borderBottom: '1px solid #333', background: '#111'
      }}>
        {TABS.map(tab => (
          <button
            key={tab.key}
            onClick={() => handleTabClick(tab.key)}
            style={{
              background: tab.key === activeTab ? '#1a1a1a' : 'transparent',
              color: tab.key === activeTab ? '#22d3ee' : '#666',
              border: 'none',
              borderBottom: tab.key === activeTab ? '2px solid #22d3ee' : '2px solid transparent',
              padding: '6px 10px',
              fontSize: '0.7em',
              fontFamily: '\'Courier New\', monospace',
              cursor: 'pointer',
              fontWeight: tab.key === activeTab ? 'bold' : 'normal',
              letterSpacing: '0.5px'
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>
      <div style={{ flex: 1, minHeight: 0, overflow: 'auto', padding: '8px' }}>
        {TABS.map(tab => renderTab(tab.key))}
      </div>
    </div>
  )
}
