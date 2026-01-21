export interface UplinkHackr {
  id: number
  hackr_alias: string
  role: string
  is_squelched?: boolean
  is_blackouted?: boolean
}

export interface ChatChannel {
  slug: string
  name: string
  description: string
  is_active: boolean
  requires_livestream: boolean
  currently_available: boolean
  accessible: boolean
  slow_mode_seconds: number
  minimum_role: string
}

export interface Packet {
  id: number
  content: string
  created_at: string
  dropped: boolean
  grid_hackr: UplinkHackr
  hackr_stream_id: number | null
}

export interface UplinkMessage {
  type: 'new_packet' | 'packet_dropped' | 'packet_restored' | 'initial_packets' | 'presence_update'
  packet?: Packet
  packets?: Packet[]
  packet_id?: number
  channel?: string
  count?: number
  presence_count?: number
}

export interface StreamStatusMessage {
  type: 'stream_status' | 'stream_live' | 'stream_ended'
  is_live: boolean
  stream: StreamInfo | null
}

export interface StreamInfo {
  id: number
  title: string | null
  artist: string | null
  started_at: string | null
}

export interface ChannelsResponse {
  channels: ChatChannel[]
  current_hackr: UplinkHackr | null
}

export interface ChannelResponse {
  channel: ChatChannel
  current_hackr: UplinkHackr | null
}

export interface PacketsResponse {
  packets: Packet[]
  channel: string
  current_hackr: UplinkHackr | null
}

export interface CreatePacketResponse {
  success: boolean
  message?: string
  packet?: Packet
  error?: string
  wait_seconds?: number
}

export interface ModerationLogEntry {
  id: number
  action: string
  reason: string | null
  duration_minutes: number | null
  created_at: string
  actor: {
    id: number
    hackr_alias: string
  }
  target: {
    id: number
    hackr_alias: string
  } | null
  chat_message_id: number | null
}

export interface ModerationLogResponse {
  logs: ModerationLogEntry[]
  meta: {
    total: number
    page: number
    per_page: number
    total_pages: number
  }
}
