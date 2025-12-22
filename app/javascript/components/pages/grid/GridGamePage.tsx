import React, { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { GridLayout } from '~/components/layouts/GridLayout'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useActionCable, GridEvent } from '~/hooks/useActionCable'
import { GameOutput } from '~/components/grid/GameOutput'
import { CommandInput, CommandInputHandle } from '~/components/grid/CommandInput'
import { GridAmbientPlayer } from '~/components/grid/GridAmbientPlayer'
import { ZonePlaylistData, TrackData } from '~/types/track'
import { useMobileDetect } from '~/hooks/useMobileDetect'

const getWelcomeMessage = (isMobile: boolean) => {
  const divider = isMobile
    ? '══════════════════════════════════'
    : '════════════════════════════════════════════════════════════════'

  return `<div style="color: #a78bfa; font-size: 0.9em;">
${divider}
  WELCOME TO THE PULSE GRID
${divider}
Connection established. Type 'help' for commands.
${divider}
   !! <span style="color:#f87171;">WARNING</span> !!
${isMobile ? '     ~~ PRE-ALPHA: DB FLUSHES OCCUR!' : '     ~~ THE PULSE GRID IS IN PRE-ALPHA.'}
${isMobile ? '     ~~ RE-CREATE ACCOUNT IF NEEDED' : '     ~~ FREQUENT DATABASE FLUSHES _WILL_ OCCUR!'}
${isMobile ? '' : '     ~~ JUST RE-CREATE YOUR ACCOUNT IF YOU CANNOT LOGIN LATER'}
   !! <span style="color:#f87171;">WARNING</span> !!
${divider}
</div>`
}

const oppositeDirection = (dir: string): string => {
  const opposites: Record<string, string> = {
    north: 'south',
    south: 'north',
    east: 'west',
    west: 'east',
    up: 'down',
    down: 'up'
  }
  return opposites[dir] || dir
}

export const GridGamePage: React.FC = () => {
  const { hackr, loading: authLoading, disconnect } = useGridAuth()
  const { isMobile } = useMobileDetect()
  const [output, setOutput] = useState<string[]>([])
  const [currentRoomId, setCurrentRoomId] = useState<number | null>(null)
  const [executing, setExecuting] = useState(false)
  const [ambientPlaylist, setAmbientPlaylist] = useState<ZonePlaylistData | null>(null)
  const [currentTrack, setCurrentTrack] = useState<TrackData | null>(null)
  const [ambientMuted, setAmbientMuted] = useState(() => {
    const saved = localStorage.getItem('grid_ambient_muted')
    return saved === 'true'
  })
  const [ambientVolume, setAmbientVolume] = useState(() => {
    const saved = localStorage.getItem('grid_ambient_volume')
    return saved ? parseFloat(saved) : 0.35
  })
  const commandInputRef = useRef<CommandInputHandle>(null)
  const currentPlaylistIdRef = useRef<number | null>(null)
  const initialLoadDoneRef = useRef(false) // Track if initial load has completed
  const navigate = useNavigate()

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!authLoading && !hackr) {
      navigate('/grid/login')
    }
  }, [hackr, authLoading, navigate])

  // Set initial room ID and load initial output
  useEffect(() => {
    if (hackr?.current_room && !initialLoadDoneRef.current) {
      // Mark initial load as starting IMMEDIATELY to prevent duplicate runs
      initialLoadDoneRef.current = true
      setCurrentRoomId(hackr.current_room.id)

      // Add welcome message and initial look command
      const loadInitialOutput = async () => {
        setOutput([getWelcomeMessage(isMobile)])

        // Execute initial look command
        try {
          const response = await fetch('/api/grid/command', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            credentials: 'include',
            body: JSON.stringify({ input: 'look' })
          })

          if (response.ok) {
            const data = await response.json()
            if (data.output && data.output.trim()) {
              setOutput(prev => [...prev, data.output])
            }
            if (data.room_id) {
              setCurrentRoomId(data.room_id)
            }
            // Only update playlist if it's a different one (by ID)
            if (data.current_room?.ambient_playlist) {
              const newPlaylistId = data.current_room.ambient_playlist.id
              if (currentPlaylistIdRef.current !== newPlaylistId) {
                setAmbientPlaylist(data.current_room.ambient_playlist)
                currentPlaylistIdRef.current = newPlaylistId
              }
            }
          }
        } catch (err) {
          console.error('Failed to load initial room:', err)
        }
      }

      loadInitialOutput()
    }
  }, [hackr, isMobile])

  // Handle real-time events from Action Cable
  const handleEvent = useCallback((event: GridEvent) => {
    const timestamp = new Date().toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit'
    })

    let message = ''

    switch (event.type) {
    case 'say':
      message = `\n<span style="color: #a78bfa;">[${event.hackr_alias}]</span>: ${event.message}`
      break

    case 'movement':
      if (event.to_room_id === currentRoomId) {
        message = `\n<span style="color: #22d3ee;">[${timestamp}] ${event.hackr_alias} enters from the ${oppositeDirection(event.direction || '')}.</span>`
      } else if (event.from_room_id === currentRoomId) {
        message = `\n<span style="color: #22d3ee;">[${timestamp}] ${event.hackr_alias} leaves to the ${event.direction}.</span>`
      }
      break

    case 'take':
      message = `\n<span style="color: #fbbf24;">[${timestamp}] ${event.hackr_alias} takes the ${event.item_name}.</span>`
      break

    case 'drop':
      message = `\n<span style="color: #fbbf24;">[${timestamp}] ${event.hackr_alias} drops the ${event.item_name}.</span>`
      break

    case 'system_broadcast':
      message = `\n<span style="color: #f87171; font-weight: bold;">[${timestamp}] ${event.message}</span>`
      break
    }

    if (message) {
      setOutput(prev => [...prev, message])
    }
  }, [currentRoomId])

  // Set up Action Cable subscription
  useActionCable({
    roomId: currentRoomId,
    onEvent: handleEvent,
    enabled: !!hackr && !!currentRoomId
  })

  // Handle command execution
  const handleCommand = async (command: string) => {
    // Handle clear command locally
    if (command.toLowerCase() === 'clear' || command.toLowerCase() === 'cls') {
      setOutput([])
      return
    }

    // Echo the command in cyan
    setOutput(prev => [...prev, `<span style="color: #22d3ee;">&gt; ${command}</span>`])

    setExecuting(true)

    try {
      const response = await fetch('/api/grid/command', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({ input: command })
      })

      if (response.ok) {
        const data = await response.json()

        // Append command output
        if (data.output && data.output.trim()) {
          setOutput(prev => [...prev, data.output])
        }

        // Update room if it changed (and resubscribe will happen automatically)
        if (data.room_id && data.room_id !== currentRoomId) {
          console.log(`Room changed from ${currentRoomId} to ${data.room_id}`)
          setCurrentRoomId(data.room_id)
        }

        // Only update playlist if it's a different one (by ID)
        if (data.current_room?.ambient_playlist) {
          const newPlaylistId = data.current_room.ambient_playlist.id
          if (currentPlaylistIdRef.current !== newPlaylistId) {
            setAmbientPlaylist(data.current_room.ambient_playlist)
            currentPlaylistIdRef.current = newPlaylistId
          }
        }
      } else {
        setOutput(prev => [...prev, '<span style="color: #f87171;">Error: Command execution failed. Please try again.</span>'])
      }
    } catch (err) {
      console.error('Command execution failed:', err)
      setOutput(prev => [...prev, '<span style="color: #f87171;">Error: Network error. Please try again.</span>'])
    } finally {
      setExecuting(false)
    }
  }

  // Handle disconnect
  const handleDisconnect = async () => {
    if (confirm('Disconnect from THE PULSE GRID?')) {
      await disconnect()
      initialLoadDoneRef.current = false // Reset for next login
      navigate('/grid/login')
    }
  }

  // Handle output click - focus command input
  const handleOutputClick = useCallback(() => {
    commandInputRef.current?.focus()
  }, [])

  if (authLoading) {
    return (
      <GridLayout>
        <div style={{ textAlign: 'center', color: '#a78bfa', marginTop: '50px' }}>
          Loading THE PULSE GRID...
        </div>
      </GridLayout>
    )
  }

  if (!hackr) {
    return null // Will redirect to login
  }

  return (
    <GridLayout>
      <div style={{ maxWidth: '1000px', margin: isMobile ? '5px' : '10px auto', background: '#1a1a1a', color: '#d0d0d0', padding: isMobile ? '8px' : '10px' }}>
        <div style={{
          display: 'flex',
          flexDirection: isMobile ? 'column' : 'row',
          justifyContent: 'space-between',
          alignItems: isMobile ? 'stretch' : 'center',
          gap: isMobile ? '8px' : '0',
          marginBottom: '8px',
          paddingBottom: '8px',
          borderBottom: '1px solid #4b5563'
        }}>
          <div style={{ fontSize: isMobile ? '0.85em' : '0.9em' }}>
            <span style={{ color: '#a78bfa', fontWeight: 'bold' }}>{isMobile ? 'GRID' : 'THE PULSE GRID'}</span>
            <span style={{ color: '#666', margin: '0 8px' }}>|</span>
            <span style={{ color: '#e0e0e0' }}>{hackr.hackr_alias}</span>
            {hackr.role === 'admin' && (
              <a href="/root" style={{ color: '#f87171', fontSize: '0.85em', marginLeft: '5px', textDecoration: 'none' }}>[ADMIN]</a>
            )}
          </div>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center', justifyContent: isMobile ? 'space-between' : 'flex-end' }}>
            {ambientPlaylist && (
              <div style={{ fontSize: '0.85em', color: '#888', marginRight: isMobile ? '0' : '8px', display: 'flex', alignItems: 'center', gap: '8px', flex: isMobile ? 1 : 'none', overflow: 'hidden' }}>
                <span style={{ color: '#a78bfa' }}>🎵</span>
                <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: isMobile ? '100px' : 'none' }}>{currentTrack?.title || ambientPlaylist.name}</span>
                {!isMobile && (
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={ambientVolume * 100}
                    onChange={(e) => {
                      const newVolume = parseInt(e.target.value) / 100
                      setAmbientVolume(newVolume)
                      localStorage.setItem('grid_ambient_volume', String(newVolume))
                    }}
                    className="grid-volume-slider"
                    title={`Volume: ${Math.round(ambientVolume * 100)}%`}
                  />
                )}
                <button
                  onClick={() => {
                    const newMuted = !ambientMuted
                    setAmbientMuted(newMuted)
                    localStorage.setItem('grid_ambient_muted', String(newMuted))
                  }}
                  style={{
                    background: 'transparent',
                    color: ambientMuted ? '#666' : '#34d399',
                    border: 'none',
                    padding: '0 4px',
                    fontSize: '1.1em',
                    cursor: 'pointer'
                  }}
                  title={ambientMuted ? 'Unmute ambient music' : 'Mute ambient music'}
                >
                  {ambientMuted ? '🔇' : '🔊'}
                </button>
              </div>
            )}
            <button
              onClick={handleDisconnect}
              style={{
                background: '#dc2626',
                color: 'white',
                border: 'none',
                padding: '4px 12px',
                fontSize: '0.85em',
                cursor: 'pointer',
                borderRadius: '3px',
                flexShrink: 0
              }}
            >
              {isMobile ? 'EXIT' : 'DISCONNECT'}
            </button>
          </div>
        </div>

        <GameOutput output={output} onOutputClick={handleOutputClick} />
        <CommandInput ref={commandInputRef} onSubmit={handleCommand} disabled={executing} />
      </div>

      <GridAmbientPlayer
        playlist={ambientPlaylist}
        muted={ambientMuted}
        volume={ambientVolume}
        onMutedChange={(muted) => {
          setAmbientMuted(muted)
          localStorage.setItem('grid_ambient_muted', String(muted))
        }}
        onVolumeChange={(volume) => {
          setAmbientVolume(volume)
          localStorage.setItem('grid_ambient_volume', String(volume))
        }}
        onTrackChange={setCurrentTrack}
      />
    </GridLayout>
  )
}
