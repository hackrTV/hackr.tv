import React, { useRef, useEffect } from 'react'
import { Packet } from './Packet'
import type { Packet as PacketType, UplinkHackr } from '../../types/uplink'

interface PacketListProps {
  packets: PacketType[]
  currentHackr: UplinkHackr | null
  onDrop?: (packetId: number) => void
  autoScroll?: boolean
}

export const PacketList: React.FC<PacketListProps> = ({
  packets,
  currentHackr,
  onDrop,
  autoScroll = true
}) => {
  const listRef = useRef<HTMLDivElement>(null)
  const isAtBottomRef = useRef(true)

  // Check if user is at bottom of scroll
  const checkIfAtBottom = () => {
    if (!listRef.current) return true
    const { scrollTop, scrollHeight, clientHeight } = listRef.current
    // Consider "at bottom" if within 50px of bottom
    return scrollHeight - scrollTop - clientHeight < 50
  }

  // Handle scroll event
  const handleScroll = () => {
    isAtBottomRef.current = checkIfAtBottom()
  }

  // Auto-scroll to bottom when new packets arrive (if user was at bottom)
  useEffect(() => {
    if (autoScroll && isAtBottomRef.current && listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight
    }
  }, [packets, autoScroll])

  // Initial scroll to bottom
  useEffect(() => {
    if (listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight
    }
  }, [])

  return (
    <div
      ref={listRef}
      className="packet-list"
      onScroll={handleScroll}
      style={{
        flex: 1,
        overflowY: 'auto',
        backgroundColor: '#0a0a0a',
        borderTop: '1px solid #333',
        borderBottom: '1px solid #333'
      }}
    >
      {packets.length === 0 ? (
        <div
          style={{
            padding: '40px 20px',
            textAlign: 'center',
            color: '#555'
          }}
        >
          <p style={{ margin: 0 }}>No packets yet. Be the first to transmit.</p>
        </div>
      ) : (
        packets.map(packet => (
          <Packet
            key={packet.id}
            packet={packet}
            currentHackr={currentHackr}
            onDrop={onDrop}
          />
        ))
      )}
    </div>
  )
}
