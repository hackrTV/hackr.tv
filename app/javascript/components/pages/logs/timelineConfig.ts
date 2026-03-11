export const TIMELINE_ORDER = ['2120s', 'pre_fracture', 'govcorp_files', '2020s']

export interface TimelineInfo {
  count: number
  min_year: number | null
  max_year: number | null
}

export type TimelineSummary = Record<string, TimelineInfo>

export const TIMELINE_CONFIG: Record<string, { name: string; subtitle: string }> = {
  '2120s': {
    name: 'THE FRACTURE NETWORK',
    subtitle: 'Transmissions from the Fracture Network'
  },
  'pre_fracture': {
    name: 'PRE-FRACTURE',
    subtitle: 'Before the Chronology Fracture'
  },
  'govcorp_files': {
    name: 'GOVCORP FILES',
    subtitle: 'Intercepted GovCorp communications'
  },
  '2020s': {
    name: 'THE LISTENERS',
    subtitle: 'Signals received in the present day'
  }
}

export const formatEra = (info: TimelineInfo): string => {
  if (info.min_year == null || info.max_year == null) return ''
  if (info.min_year === info.max_year) return `${info.min_year}`
  return `${info.min_year}–${info.max_year}`
}
