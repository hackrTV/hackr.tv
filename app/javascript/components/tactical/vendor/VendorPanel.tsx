import React, { useState, useEffect, useCallback } from 'react'
import { apiJson } from '~/utils/apiClient'
import { ShopData, ShopListing, InventoryItem, InventoryResponse } from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'

interface VendorPanelProps {
  visible: boolean
  refreshToken: number
  onCommand: (cmd: string) => void
  onClose: () => void
}

type PanelSection = 'buy' | 'sell'

interface PendingTx {
  type: 'buy' | 'sell'
  name: string
  rarity_color: string
  unitPrice: number
  qty: number
  maxQty: number
}

export const VendorPanel: React.FC<VendorPanelProps> = ({
  visible, refreshToken, onCommand, onClose
}) => {
  const { executing } = useTactical()
  const [isRendered, setIsRendered] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [shopData, setShopData] = useState<ShopData | null>(null)
  const [inventoryData, setInventoryData] = useState<InventoryItem[]>([])
  const [section, setSection] = useState<PanelSection>('buy')
  const [pendingTx, setPendingTx] = useState<PendingTx | null>(null)
  const [buyQty, setBuyQty] = useState<Record<number, number>>({})

  // Slide animation: mount first, then open; close first, then unmount
  // Double-rAF ensures browser paints the closed state before transitioning to open
  useEffect(() => {
    if (visible) {
      setIsRendered(true) // eslint-disable-line react-hooks/set-state-in-effect -- must mount before animating
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

  // Fetch shop data when panel is rendered
  useEffect(() => {
    if (isRendered) {
      apiJson<ShopData>('/api/grid/shop').then(setShopData).catch(console.error)
    }
  }, [refreshToken, isRendered])

  // Fetch inventory for sell section when panel is rendered
  useEffect(() => {
    if (isRendered) {
      apiJson<InventoryResponse>('/api/grid/inventory').then(data => {
        const sellable = data.groups
          .flatMap(g => g.items)
          .filter(i => i.sell_price && i.sell_price > 0)
        setInventoryData(sellable)
      }).catch(console.error)
    }
  }, [refreshToken, isRendered])

  // Reset buy quantities when panel closes or shop data refreshes
  useEffect(() => {
    if (!visible) setBuyQty({})
  }, [visible])

  useEffect(() => {
    setBuyQty({})
  }, [shopData])

  const handleBuyClick = useCallback((listing: ShopListing) => {
    const qty = buyQty[listing.id] || 1
    const stockMax = listing.stock ?? 99
    const affordMax = listing.price > 0 ? Math.floor((shopData?.balance ?? 0) / listing.price) : stockMax
    setPendingTx({
      type: 'buy',
      name: listing.name,
      rarity_color: listing.rarity_color,
      unitPrice: listing.price,
      qty: Math.min(qty, stockMax, affordMax),
      maxQty: Math.min(stockMax, affordMax)
    })
  }, [buyQty, shopData])

  const handleSellClick = useCallback((item: InventoryItem) => {
    setPendingTx({
      type: 'sell',
      name: item.name,
      rarity_color: item.rarity_color,
      unitPrice: item.sell_price || 0,
      qty: 1,
      maxQty: item.quantity
    })
  }, [])

  const handleConfirm = useCallback(() => {
    if (!pendingTx) return
    const qtyPart = pendingTx.qty > 1 ? `${pendingTx.qty} ` : ''
    onCommand(`${pendingTx.type} ${qtyPart}${pendingTx.name}`)
    setPendingTx(null)
  }, [pendingTx, onCommand])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onClose()
  }, [onClose])

  if (!isRendered) return null

  return (
    <>
      {/* Backdrop — click-outside to close */}
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
          top: 0,
          right: 0,
          bottom: 0,
          width: '50%',
          zIndex: 30,
          transform: isOpen ? 'translateX(0%)' : 'translateX(100%)',
          transition: 'transform 300ms ease-out',
          display: 'flex',
          flexDirection: 'column',
          background: '#0d0d0d',
          borderLeft: '2px solid #fbbf24',
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
            <span style={{ color: '#fbbf24', fontWeight: 'bold', fontSize: '0.8em', letterSpacing: '1px' }}>
              VENDOR
            </span>
            {shopData && (
              <>
                <span style={{ color: '#444', margin: '0 8px' }}>::</span>
                <span style={{ color: '#d0d0d0', fontSize: '0.8em' }}>{shopData.vendor_name}</span>
                {shopData.shop_type === 'black_market' && (
                  <span style={{ color: '#f87171', fontSize: '0.65em', marginLeft: '8px' }}>BLACK MARKET</span>
                )}
              </>
            )}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {shopData && (
              <span style={{ color: '#fbbf24', fontSize: '0.7em' }}>
                {shopData.balance} CRED
              </span>
            )}
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
        </div>

        {/* Section tabs */}
        <div style={{
          display: 'flex',
          borderBottom: '1px solid #333',
          background: '#0f0f0f',
          flexShrink: 0
        }}>
          {(['buy', 'sell'] as const).map(s => (
            <button
              key={s}
              onClick={() => setSection(s)}
              style={{
                flex: 1,
                background: section === s ? '#1a1a1a' : 'transparent',
                color: section === s ? (s === 'buy' ? '#34d399' : '#fbbf24') : '#666',
                border: 'none',
                borderBottom: section === s ? `2px solid ${s === 'buy' ? '#34d399' : '#fbbf24'}` : '2px solid transparent',
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

        {/* Content */}
        <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden', padding: '8px 10px' }}>
          {section === 'buy' ? (
            <BuySection
              shopData={shopData}
              buyQty={buyQty}
              setBuyQty={setBuyQty}
              onBuy={handleBuyClick}
              executing={executing}
            />
          ) : (
            <SellSection
              items={inventoryData}
              onSell={handleSellClick}
              executing={executing}
            />
          )}
        </div>
      </div>

      {/* Confirm modal */}
      {pendingTx && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(0,0,0,0.7)'
          }}
          onClick={() => setPendingTx(null)}
        >
          <div
            style={{
              background: '#1a1a1a',
              border: `1px solid ${pendingTx.type === 'buy' ? '#34d399' : '#fbbf24'}`,
              borderRadius: '6px',
              padding: '24px 28px',
              maxWidth: '420px',
              fontFamily: '\'Courier New\', monospace'
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{
              color: pendingTx.type === 'buy' ? '#34d399' : '#fbbf24',
              fontWeight: 'bold',
              fontSize: '1.1em',
              letterSpacing: '1px',
              marginBottom: '16px'
            }}>
              {pendingTx.type === 'buy' ? 'CONFIRM PURCHASE' : 'CONFIRM SALE'}
            </div>

            <div style={{ marginBottom: '8px' }}>
              <span style={{ color: pendingTx.rarity_color, fontSize: '1.05em' }}>{pendingTx.name}</span>
              {pendingTx.qty > 1 && (
                <span style={{ color: '#6b7280', marginLeft: '8px', fontSize: '0.9em' }}>x{pendingTx.qty}</span>
              )}
            </div>

            {/* Quantity adjuster in modal */}
            {pendingTx.maxQty > 1 && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                <span style={{ color: '#888', fontSize: '0.85em' }}>Qty:</span>
                <button
                  onClick={() => setPendingTx(p => p && p.qty > 1 ? { ...p, qty: p.qty - 1 } : p)}
                  disabled={pendingTx.qty <= 1}
                  style={{
                    background: '#222', border: '1px solid #444', borderRadius: '3px',
                    color: pendingTx.qty <= 1 ? '#444' : '#d0d0d0', padding: '2px 8px',
                    cursor: pendingTx.qty <= 1 ? 'not-allowed' : 'pointer',
                    fontFamily: '\'Courier New\', monospace', fontSize: '0.9em'
                  }}
                >-</button>
                <span style={{ color: '#d0d0d0', fontSize: '0.95em', minWidth: '24px', textAlign: 'center' }}>
                  {pendingTx.qty}
                </span>
                <button
                  onClick={() => setPendingTx(p => p && p.qty < p.maxQty ? { ...p, qty: p.qty + 1 } : p)}
                  disabled={pendingTx.qty >= pendingTx.maxQty}
                  style={{
                    background: '#222', border: '1px solid #444', borderRadius: '3px',
                    color: pendingTx.qty >= pendingTx.maxQty ? '#444' : '#d0d0d0', padding: '2px 8px',
                    cursor: pendingTx.qty >= pendingTx.maxQty ? 'not-allowed' : 'pointer',
                    fontFamily: '\'Courier New\', monospace', fontSize: '0.9em'
                  }}
                >+</button>
              </div>
            )}

            <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '20px' }}>
              {pendingTx.type === 'buy'
                ? <>Cost: <span style={{ color: '#f87171' }}>{pendingTx.unitPrice * pendingTx.qty} CRED</span></>
                : <>You receive: <span style={{ color: '#34d399' }}>{pendingTx.unitPrice * pendingTx.qty} CRED</span></>
              }
            </div>

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setPendingTx(null)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >CANCEL</button>
              <button
                onClick={handleConfirm}
                disabled={executing}
                style={{
                  background: executing ? '#333' : (pendingTx.type === 'buy' ? '#34d399' : '#fbbf24'),
                  color: executing ? '#666' : '#0a0a0a', border: 'none',
                  padding: '8px 20px', fontSize: '0.9em',
                  cursor: executing ? 'not-allowed' : 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >{pendingTx.type === 'buy' ? 'BUY' : 'SELL'}</button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

// --- BUY section ---

const BuySection: React.FC<{
  shopData: ShopData | null
  buyQty: Record<number, number>
  setBuyQty: React.Dispatch<React.SetStateAction<Record<number, number>>>
  onBuy: (listing: ShopListing) => void
  executing: boolean
}> = ({ shopData, buyQty, setBuyQty, onBuy, executing }) => {
  if (!shopData) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>
  if (shopData.listings.length === 0) return <div style={{ color: '#555', fontSize: '0.8em' }}>Nothing for sale.</div>

  return (
    <div style={{ fontSize: '0.75em' }}>
      {shopData.listings.map(listing => {
        const qty = buyQty[listing.id] || 1
        const maxQty = listing.stock ?? 99
        const totalPrice = listing.price * qty
        const canAfford = totalPrice <= shopData.balance

        return (
          <div key={listing.id} style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '5px 0',
            borderBottom: '1px solid #1a1a1a'
          }}>
            <div style={{ flex: 1, minWidth: 0, overflow: 'hidden' }}>
              <div style={{
                color: listing.rarity_color,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'
              }}>
                {listing.name}
              </div>
              <div style={{ display: 'flex', gap: '8px', fontSize: '0.9em', color: '#888' }}>
                <span style={{ color: listing.rarity_color }}>[{listing.rarity_label}]</span>
                <span style={{ color: canAfford ? '#34d399' : '#f87171' }}>{listing.price} CRED</span>
                <span>{listing.stock === null ? '∞' : listing.out_of_stock ? 'OUT' : listing.stock}</span>
              </div>
            </div>

            {!listing.out_of_stock && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '3px', flexShrink: 0 }}>
                {maxQty > 1 && (
                  <>
                    <button
                      onClick={() => setBuyQty(prev => ({ ...prev, [listing.id]: Math.max(1, qty - 1) }))}
                      disabled={qty <= 1}
                      style={qtyBtnStyle(qty <= 1)}
                    >-</button>
                    <span style={{ color: '#d0d0d0', fontSize: '0.9em', minWidth: '18px', textAlign: 'center' }}>
                      {qty}
                    </span>
                    <button
                      onClick={() => setBuyQty(prev => ({ ...prev, [listing.id]: Math.min(maxQty, qty + 1) }))}
                      disabled={qty >= maxQty}
                      style={qtyBtnStyle(qty >= maxQty)}
                    >+</button>
                  </>
                )}
                <button
                  onClick={() => onBuy(listing)}
                  disabled={!canAfford || executing}
                  style={{
                    background: canAfford && !executing ? '#34d399' : '#333',
                    color: canAfford && !executing ? '#0a0a0a' : '#666',
                    border: 'none',
                    borderRadius: '3px',
                    padding: '3px 8px',
                    fontSize: '0.9em',
                    cursor: canAfford ? 'pointer' : 'not-allowed',
                    fontWeight: 'bold',
                    fontFamily: '\'Courier New\', monospace',
                    marginLeft: '4px'
                  }}
                >BUY</button>
              </div>
            )}

            {listing.out_of_stock && (
              <span style={{ color: '#f87171', fontSize: '0.85em', flexShrink: 0 }}>OUT</span>
            )}
          </div>
        )
      })}
    </div>
  )
}

// --- SELL section ---

const SellSection: React.FC<{
  items: InventoryItem[]
  onSell: (item: InventoryItem) => void
  executing: boolean
}> = ({ items, onSell, executing }) => {
  if (items.length === 0) return <div style={{ color: '#555', fontSize: '0.8em' }}>Nothing to sell.</div>

  return (
    <div style={{ fontSize: '0.75em' }}>
      {items.map(item => (
        <div key={item.id} style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '5px 0',
          borderBottom: '1px solid #1a1a1a'
        }}>
          <div style={{ flex: 1, minWidth: 0, overflow: 'hidden' }}>
            <div style={{
              color: item.rarity_color,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'
            }}>
              {item.name}
            </div>
            <div style={{ display: 'flex', gap: '8px', fontSize: '0.9em' }}>
              <span style={{ color: item.rarity_color }}>[{item.rarity_label}]</span>
              {item.quantity > 1 && <span style={{ color: '#6b7280' }}>x{item.quantity}</span>}
              <span style={{ color: '#34d399' }}>{item.sell_price ?? 0} CRED</span>
            </div>
          </div>

          <button
            onClick={() => onSell(item)}
            disabled={executing}
            style={{
              background: executing ? '#333' : '#fbbf24',
              color: executing ? '#666' : '#0a0a0a',
              border: 'none',
              borderRadius: '3px',
              padding: '3px 8px',
              fontSize: '0.9em',
              cursor: executing ? 'not-allowed' : 'pointer',
              fontWeight: 'bold',
              fontFamily: '\'Courier New\', monospace',
              flexShrink: 0
            }}
          >SELL</button>
        </div>
      ))}
    </div>
  )
}

function qtyBtnStyle (disabled: boolean): React.CSSProperties {
  return {
    background: '#222',
    border: '1px solid #444',
    borderRadius: '3px',
    color: disabled ? '#444' : '#d0d0d0',
    padding: '1px 6px',
    cursor: disabled ? 'not-allowed' : 'pointer',
    fontFamily: '\'Courier New\', monospace',
    fontSize: '0.85em'
  }
}
