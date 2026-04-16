// Shape of /api/grid/missions response and related SPA types.

export type MissionStatus = 'active' | 'completed' | 'available'

export interface MissionObjective {
  id: number
  position: number
  objective_type: string
  label: string
  target_slug: string | null
  target_count: number
}

export interface MissionReward {
  id: number
  reward_type: 'xp' | 'cred' | 'faction_rep' | 'item_grant' | 'grant_achievement'
  amount: number
  target_slug: string | null
  quantity: number
}

export interface MissionGates {
  clearance_met: boolean
  prereq_met: boolean
  rep_met: boolean
}

export interface Mission {
  slug: string
  name: string
  description: string | null
  repeatable: boolean
  arc: { slug: string; name: string } | null
  giver: { name: string; room_id: number | null; room_slug: string | null } | null
  prereq_slug: string | null
  min_clearance: number
  min_rep: { faction_slug: string; value: number } | null
  objectives: MissionObjective[]
  rewards: MissionReward[]
  gates?: MissionGates
}

export interface ObjectiveProgress {
  objective_id: number
  progress: number
  target_count: number
  completed: boolean
}

export interface HackrMission {
  id: number
  status: 'active' | 'completed'
  accepted_at: string
  completed_at: string | null
  turn_in_count: number
  mission: Mission
  objective_progress?: ObjectiveProgress[]
  ready_to_turn_in?: boolean
}

export interface MissionsIndexResponse {
  active: HackrMission[]
  completed: HackrMission[]
  available: Mission[]
}
