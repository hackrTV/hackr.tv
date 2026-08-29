// Stream-status types only. The uplink CHAT types that used to live here
// left with the Phase 5 Hotwire migration (chat is server-rendered now);
// these remain because useStreamStatus + LiveNowBanner — still React
// until Phase 6 — consume the StreamStatusChannel payloads.

export interface StreamStatusMessage {
  type: 'stream_status' | 'stream_live' | 'stream_ended' | 'scheduled_stream_updated'
  is_live: boolean
  stream: StreamInfo | null
  next_scheduled: ScheduledStreamInfo | null
}

export interface StreamInfo {
  id: number
  title: string | null
  artist: string | null
  started_at: string | null
}

export interface ScheduledStreamInfo {
  id: number
  title: string | null
  artist: string | null
  artist_slug: string | null
  scheduled_at: string
  display_state: 'upcoming' | 'starting_soon' | 'expired' | 'cancelled' | 'live' | 'ended' | 'unscheduled'
}
