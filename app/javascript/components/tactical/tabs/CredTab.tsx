import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'
import { useTactical } from '../TacticalContext'

interface CacheData {
  address: string
  nickname: string | null
  balance: number
  is_default: boolean
  abandoned: boolean
}

interface CredResponse {
  caches: CacheData[]
  total_balance: number
  debt: number
}

function formatCred (amount: number): string {
  return amount.toLocaleString('en-US')
}

export const CredTab: React.FC<{ refreshToken: number; onCommand?: (cmd: string) => void }> = ({ refreshToken, onCommand }) => {
  const { executing } = useTactical()
  const [data, setData] = useState<CredResponse | null>(null)
  const [nicknameTarget, setNicknameTarget] = useState<string | null>(null)
  const [nicknameInput, setNicknameInput] = useState('')
  const [transferFrom, setTransferFrom] = useState<CacheData | null>(null)
  const [transferTo, setTransferTo] = useState('')
  const [transferCustom, setTransferCustom] = useState(false)
  const [transferAmount, setTransferAmount] = useState('')

  useEffect(() => {
    apiJson<CredResponse>('/api/grid/cred').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  return (
    <div style={{ fontSize: '0.8em', maxWidth: '50%' }}>
      {/* Summary */}
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
        <span style={{ color: '#fbbf24' }}>Total CRED</span>
        <span style={{ color: '#34d399' }}>{formatCred(data.total_balance)}</span>
      </div>
      {data.debt > 0 && (
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
          <span style={{ color: '#f87171' }}>GovCorp Debt</span>
          <span style={{ color: '#f87171' }}>-{formatCred(data.debt)}</span>
        </div>
      )}
      <div style={{ height: '1px', background: '#333', margin: '8px 0' }} />

      {/* Create cache button */}
      <button
        onClick={() => onCommand?.('cache create')}
        disabled={executing}
        style={{
          background: '#1a1a1a',
          border: '1px solid #34d399',
          borderRadius: '3px',
          padding: '3px 10px',
          color: '#34d399',
          fontSize: '0.85em',
          cursor: executing ? 'not-allowed' : 'pointer',
          opacity: executing ? 0.5 : 1,
          fontFamily: '\'Courier New\', monospace',
          marginBottom: '8px'
        }}
      >
        + NEW CACHE
      </button>

      {/* Caches */}
      {data.caches.length === 0 ? (
        <div style={{ color: '#555' }}>No caches.</div>
      ) : (
        data.caches.map(cache => (
          <div
            key={cache.address}
            style={{
              padding: '6px 0',
              borderBottom: '1px solid #1a1a1a',
              opacity: cache.abandoned ? 0.5 : 1,
              breakInside: 'avoid'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <div>
                <span style={{ color: '#34d399' }}>{cache.address}</span>
                {cache.nickname && (
                  <span style={{ color: '#a78bfa', marginLeft: '8px' }}>{cache.nickname}</span>
                )}
              </div>
              <span style={{ color: '#34d399', whiteSpace: 'nowrap' }}>{formatCred(cache.balance)} CRED</span>
            </div>
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '2px' }}>
              {cache.is_default && (
                <span style={{ color: '#22d3ee', fontSize: '0.85em' }}>DEFAULT</span>
              )}
              {cache.abandoned && (
                <span style={{ color: '#f87171', fontSize: '0.85em' }}>ABANDONED</span>
              )}
              {!cache.abandoned && (
                <>
                  <button
                    onClick={() => { setNicknameTarget(cache.address); setNicknameInput(cache.nickname || '') }}
                    style={{
                      background: 'none', border: 'none', color: '#666', fontSize: '0.85em',
                      cursor: 'pointer', padding: 0, fontFamily: '\'Courier New\', monospace',
                      textDecoration: 'underline'
                    }}
                  >
                    rename
                  </button>
                  {cache.balance > 0 && (
                    <button
                      onClick={() => { setTransferFrom(cache); setTransferTo(''); setTransferCustom(false); setTransferAmount('') }}
                      style={{
                        background: 'none', border: 'none', color: '#666', fontSize: '0.85em',
                        cursor: 'pointer', padding: 0, fontFamily: '\'Courier New\', monospace',
                        textDecoration: 'underline'
                      }}
                    >
                      send
                    </button>
                  )}
                </>
              )}
            </div>
          </div>
        ))
      )}

      {data.debt > 0 && (
        <>
          <div style={{ height: '1px', background: '#333', margin: '8px 0' }} />
          <div style={{ color: '#f87171', fontSize: '0.85em' }}>
            50% CRED income garnished until debt cleared.
          </div>
        </>
      )}

      {/* Nickname modal */}
      {nicknameTarget && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(0,0,0,0.7)'
          }}
          onClick={() => setNicknameTarget(null)}
        >
          <div
            style={{
              background: '#1a1a1a',
              border: '1px solid #444',
              borderRadius: '6px',
              padding: '24px 28px',
              maxWidth: '420px',
              fontFamily: '\'Courier New\', monospace'
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{ color: '#a78bfa', fontWeight: 'bold', fontSize: '1.1em', marginBottom: '12px' }}>
              SET NICKNAME
            </div>
            <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '16px' }}>
              <span style={{ color: '#34d399' }}>{nicknameTarget}</span>
            </div>
            <input
              type="text"
              value={nicknameInput}
              onChange={e => {
                const val = e.target.value.replace(/[^a-zA-Z0-9_-]/g, '')
                setNicknameInput(val)
              }}
              onKeyDown={e => {
                if (e.key === 'Enter' && nicknameInput.trim()) {
                  onCommand?.(`cache name ${nicknameTarget} ${nicknameInput.trim()}`)
                  setNicknameTarget(null)
                }
              }}
              maxLength={20}
              placeholder="letters, numbers, hyphens, underscores"
              autoFocus
              style={{
                width: '100%',
                background: '#111',
                border: '1px solid #444',
                borderRadius: '3px',
                padding: '8px 10px',
                color: '#d0d0d0',
                fontSize: '0.95em',
                fontFamily: '\'Courier New\', monospace',
                marginBottom: '16px',
                boxSizing: 'border-box'
              }}
            />
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setNicknameTarget(null)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >
                CANCEL
              </button>
              <button
                onClick={() => {
                  if (nicknameInput.trim()) {
                    onCommand?.(`cache name ${nicknameTarget} ${nicknameInput.trim()}`)
                    setNicknameTarget(null)
                  }
                }}
                disabled={executing}
                style={{
                  background: executing ? '#333' : '#a78bfa',
                  color: executing ? '#666' : '#0a0a0a', border: 'none',
                  padding: '8px 20px', fontSize: '0.9em',
                  cursor: executing ? 'not-allowed' : 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >
                SET
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Transfer modal */}
      {transferFrom && data && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(0,0,0,0.7)'
          }}
          onClick={() => setTransferFrom(null)}
        >
          <div
            style={{
              background: '#1a1a1a',
              border: '1px solid #444',
              borderRadius: '6px',
              padding: '24px 28px',
              maxWidth: '420px', minWidth: '320px',
              fontFamily: '\'Courier New\', monospace'
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{ color: '#fbbf24', fontWeight: 'bold', fontSize: '1.1em', marginBottom: '12px' }}>
              SEND CRED
            </div>
            <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '16px' }}>
              From: <span style={{ color: '#34d399' }}>{transferFrom.nickname || transferFrom.address}</span>
              <span style={{ color: '#666', marginLeft: '8px' }}>({formatCred(transferFrom.balance)} available)</span>
            </div>

            <div style={{ marginBottom: '10px' }}>
              <label style={{ color: '#888', fontSize: '0.85em', display: 'block', marginBottom: '4px' }}>Amount</label>
              <input
                type="text"
                value={transferAmount}
                onChange={e => setTransferAmount(e.target.value.replace(/[^0-9]/g, ''))}
                placeholder="0"
                autoFocus
                style={{
                  width: '100%', background: '#111', border: '1px solid #444', borderRadius: '3px',
                  padding: '8px 10px', color: '#d0d0d0', fontSize: '0.95em',
                  fontFamily: '\'Courier New\', monospace', boxSizing: 'border-box'
                }}
              />
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ color: '#888', fontSize: '0.85em', display: 'block', marginBottom: '4px' }}>To (address or nickname)</label>
              <select
                value={transferCustom ? '__custom__' : transferTo}
                onChange={e => {
                  if (e.target.value === '__custom__') {
                    setTransferCustom(true)
                    setTransferTo('')
                  } else {
                    setTransferCustom(false)
                    setTransferTo(e.target.value)
                  }
                }}
                style={{
                  width: '100%', background: '#111', border: '1px solid #444', borderRadius: '3px',
                  padding: '8px 10px', color: '#d0d0d0', fontSize: '0.95em',
                  fontFamily: '\'Courier New\', monospace', boxSizing: 'border-box'
                }}
              >
                <option value="">Select destination...</option>
                {data.caches
                  .filter(c => c.address !== transferFrom.address && !c.abandoned)
                  .map(c => (
                    <option key={c.address} value={c.nickname || c.address}>
                      {c.nickname ? `${c.nickname} (${c.address})` : c.address}
                    </option>
                  ))
                }
                <option value="__custom__">Other address...</option>
              </select>
              {transferCustom && (
                <input
                  type="text"
                  value={transferTo}
                  onChange={e => setTransferTo(e.target.value)}
                  placeholder="CACHE-XXXX-XXXX or nickname"
                  autoFocus
                  style={{
                    width: '100%', background: '#111', border: '1px solid #444', borderRadius: '3px',
                    padding: '8px 10px', color: '#d0d0d0', fontSize: '0.95em', marginTop: '6px',
                    fontFamily: '\'Courier New\', monospace', boxSizing: 'border-box'
                  }}
                />
              )}
            </div>

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setTransferFrom(null)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >
                CANCEL
              </button>
              <button
                disabled={!transferAmount || !transferTo || executing}
                onClick={() => {
                  const fromArg = transferFrom.is_default ? '' : ` from ${transferFrom.nickname || transferFrom.address}`
                  onCommand?.(`cache send ${transferAmount} ${transferTo}${fromArg}`)
                  setTransferFrom(null)
                }}
                style={{
                  background: (!transferAmount || !transferTo || executing) ? '#333' : '#fbbf24',
                  color: '#0a0a0a', border: 'none',
                  padding: '8px 20px', fontSize: '0.9em',
                  cursor: (!transferAmount || !transferTo || executing) ? 'not-allowed' : 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >
                SEND
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
