const artistProfilePaths: Record<string, string> = {
  'xeraen': '/xeraen/bio',
  'thecyberpulse': '/thecyberpulse/bio',
  'system-rot': '/system-rot',
  'wavelength-zero': '/wavelength-zero',
  'voiceprint': '/voiceprint',
  'temporal-blue-drift': '/temporal-blue-drift',
  'injection-vector': '/injection-vector',
  'cipher-protocol': '/cipher-protocol',
  'blitzbeam': '/blitzbeam',
  'apex-overdrive': '/apex-overdrive',
  'ethereality': '/ethereality',
  'neon-hearts': '/neon-hearts',
  'offline': '/offline',
  'heartbreak-havoc': '/heartbreak-havoc'
}

export function getArtistProfilePath (slug: string): string {
  return artistProfilePaths[slug] || ''
}
