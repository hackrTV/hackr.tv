export interface GridHackr {
  id: number
  hackr_alias: string
  role: string
}

export interface Pulse {
  id: number
  content: string
  pulsed_at: string
  echo_count: number
  splice_count: number
  signal_dropped: boolean
  signal_dropped_at: string | null
  parent_pulse_id: number | null
  thread_root_id: number | null
  is_splice: boolean
  is_echoed_by_current_hackr: boolean
  current_hackr_is_logged_in: boolean
  current_hackr_is_admin: boolean
  grid_hackr: GridHackr
  created_at: string
  updated_at: string
}

export interface Echo {
  id: number
  echoed_at: string
  hackr: GridHackr
}

export interface PulseResponse {
  pulse: Pulse
  thread: Pulse[]
}

export interface PulsesResponse {
  pulses: Pulse[]
  meta: {
    total: number
    page: number
    per_page: number
    total_pages: number
  }
}

export interface EchoesResponse {
  pulse_id: number
  echo_count: number
  echoes: Echo[]
}

export interface PulseWireMessage {
  type: 'new_pulse' | 'pulse_deleted' | 'pulse_dropped' | 'echo_created' | 'echo_removed'
  pulse?: Pulse
  pulse_id?: number
  hackr_id?: number
  hackr_alias?: string
  echo_count?: number
}
