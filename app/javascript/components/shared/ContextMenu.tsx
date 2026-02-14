import React, { useLayoutEffect, useState } from 'react'

export interface ContextMenuItem {
  label: string
  onClick?: () => void
  icon?: string
  disabled?: boolean
  separator?: boolean
  header?: boolean
}

interface ContextMenuProps {
  x: number
  y: number
  items: ContextMenuItem[]
  onClose: () => void
  menuRef: React.RefObject<HTMLDivElement | null>
}

export const ContextMenu: React.FC<ContextMenuProps> = ({ x, y, items, onClose, menuRef }) => {
  const [adjustedPos, setAdjustedPos] = useState({ x, y })

  useLayoutEffect(() => {
    if (!menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    const vw = window.innerWidth
    const vh = window.innerHeight

    let ax = x
    let ay = y

    if (x + rect.width > vw) {
      ax = x - rect.width
    }
    if (y + rect.height > vh) {
      ay = y - rect.height
    }
    // Clamp to viewport edges
    if (ax < 0) ax = 0
    if (ay < 0) ay = 0

    setAdjustedPos({ x: ax, y: ay })
  }, [x, y, menuRef])

  return (
    <div
      ref={menuRef}
      role="menu"
      style={{
        position: 'fixed',
        top: adjustedPos.y,
        left: adjustedPos.x,
        background: '#0a0a0a',
        border: '2px solid #7c3aed',
        borderRadius: '4px',
        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.5)',
        zIndex: 10000,
        minWidth: '200px',
        padding: '4px 0',
        fontFamily: 'inherit'
      }}
    >
      {items.map((item, i) => {
        if (item.separator) {
          return (
            <div
              key={i}
              style={{
                height: '1px',
                background: '#333',
                margin: '4px 0'
              }}
            />
          )
        }

        if (item.header) {
          return (
            <div
              key={i}
              style={{
                padding: '6px 12px',
                color: '#00d9ff',
                fontSize: '0.8em',
                fontWeight: 'bold',
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
                cursor: 'default',
                userSelect: 'none'
              }}
            >
              {item.label}
            </div>
          )
        }

        return (
          <div
            key={i}
            role="menuitem"
            onClick={() => {
              if (item.disabled) return
              item.onClick?.()
              onClose()
            }}
            onMouseEnter={(e) => {
              if (!item.disabled) {
                e.currentTarget.style.backgroundColor = 'rgba(124, 58, 237, 0.15)'
                e.currentTarget.style.color = '#fff'
              }
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = 'transparent'
              e.currentTarget.style.color = item.disabled ? '#555' : '#ccc'
            }}
            style={{
              padding: '6px 12px',
              color: item.disabled ? '#555' : '#ccc',
              cursor: item.disabled ? 'default' : 'pointer',
              fontSize: '0.9em',
              whiteSpace: 'nowrap',
              userSelect: 'none',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}
          >
            {item.icon && <span style={{ width: '16px', textAlign: 'center' }}>{item.icon}</span>}
            {item.label}
          </div>
        )
      })}
    </div>
  )
}
