import type { Pulse } from './pulse'

// Max bio length — mirrors the model validation (validates :bio, maximum: 512).
export const BIO_MAX = 512

export interface ProfileStats {
  pulses: number
  echoes_received: number
  packets: number
  achievements: number
  breaches_completed: number
  watch_seconds: number
}

export interface ProfileData {
  id: number
  hackr_alias: string
  role: string
  bio: string | null
  clearance: number
  joined_at: string
  last_active_at: string | null
  stats: ProfileStats
  pinned_pulses: Pulse[]
}

export interface ProfileResponse {
  profile: ProfileData
  is_self: boolean
}

export interface PinResponse {
  success: boolean
  error?: string
  pinned_pulses: Pulse[]
}
