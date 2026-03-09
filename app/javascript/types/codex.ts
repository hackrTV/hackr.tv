export interface CodexEntry {
  id: number
  name: string
  slug: string
  entry_type: 'person' | 'organization' | 'event' | 'location' | 'technology' | 'faction' | 'item' | 'concept'
  summary: string | null
  content?: string
  metadata: Record<string, string>
  position: number | null
  created_at?: string
  updated_at?: string
}

export interface CodexEntrySummary {
  id: number
  name: string
  slug: string
  entry_type: string
  summary: string | null
  position: number | null
  metadata: Record<string, string>
}
