import React from 'react'

export const InventoryTab: React.FC<{ refreshToken: number }> = ({ refreshToken: _refreshToken }) => {
  return (
    <div style={{ color: '#555', fontSize: '0.8em', padding: '8px 0' }}>
      <div style={{ color: '#666', marginBottom: '4px' }}>INVENTORY</div>
      <div>Use &apos;inventory&apos; command in terminal for now.</div>
      <div style={{ color: '#444', marginTop: '8px', fontSize: '0.9em' }}>API endpoint pending.</div>
    </div>
  )
}
