const artistProfilePaths: Record<string, string> = {
  'xeraen': '/xeraen',
  'thecyberpulse': '/thecyberpulse',
  'system_rot': '/system_rot',
  'wavelength_zero': '/wavelength_zero',
  'voiceprint': '/voiceprint',
  'temporal_blue_drift': '/temporal_blue_drift',
  'injection_vector': '/injection_vector',
  'cipher_protocol': '/cipher_protocol',
  'blitzbeam': '/blitzbeam',
  'apex_overdrive': '/apex_overdrive',
  'ethereality': '/ethereality',
  'neon_hearts': '/neon_hearts',
  'offline': '/offline',
  'heartbreak_havoc': '/heartbreak_havoc'
}

export function getArtistProfilePath(slug: string): string {
  return artistProfilePaths[slug] || ''
}
