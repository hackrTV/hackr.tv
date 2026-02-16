export interface ArtistColorScheme {
  primary: string
  secondary: string
  glow: string
  glowStrong: string
  background: string
  gradient?: string
  accentColors?: string[]
}

const colorSchemes: Record<string, ArtistColorScheme> = {
  xeraen: {
    primary: '#8B00FF',
    secondary: '#6B00CC',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)',
    background: '#0a0a0a'
  },
  thecyberpulse: {
    primary: '#8B00FF',
    secondary: '#9B59B6',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)',
    background: '#0a0a0a'
  },
  'system-rot': {
    primary: '#39ff14',
    secondary: '#2bcc10',
    glow: 'rgba(57, 255, 20, 0.6)',
    glowStrong: 'rgba(57, 255, 20, 0.8)',
    background: '#0a0a0a'
  },
  'wavelength-zero': {
    primary: '#00d9ff',
    secondary: '#0099cc',
    glow: 'rgba(0, 217, 255, 0.6)',
    glowStrong: 'rgba(0, 217, 255, 0.8)',
    background: '#0a0a0a',
    gradient: 'linear-gradient(90deg, #ff0080, #ff8c00, #ffed00, #00ff00, #00d9ff, #8b00ff)',
    accentColors: ['#ff0080', '#ff8c00', '#00ff00', '#00d9ff', '#8b00ff']
  },
  voiceprint: {
    primary: '#00d9ff',
    secondary: '#00aacc',
    glow: 'rgba(0, 217, 255, 0.6)',
    glowStrong: 'rgba(0, 217, 255, 0.8)',
    background: '#0a0a0a'
  },
  'temporal-blue-drift': {
    primary: '#6B9BD1',
    secondary: '#557ca7',
    glow: 'rgba(107, 155, 209, 0.6)',
    glowStrong: 'rgba(107, 155, 209, 0.8)',
    background: '#0a0a0a'
  },
  'heartbreak-havoc': {
    primary: '#ff0066',
    secondary: '#cc0052',
    glow: 'rgba(255, 0, 102, 0.6)',
    glowStrong: 'rgba(255, 0, 102, 0.8)',
    background: '#0a0a0a'
  },
  'apex-overdrive': {
    primary: '#1e90ff',
    secondary: '#1873cc',
    glow: 'rgba(30, 144, 255, 0.6)',
    glowStrong: 'rgba(30, 144, 255, 0.8)',
    background: '#0a0a0a'
  },
  'cipher-protocol': {
    primary: '#00ff9f',
    secondary: '#00cc7f',
    glow: 'rgba(0, 255, 159, 0.6)',
    glowStrong: 'rgba(0, 255, 159, 0.8)',
    background: '#0a0a0a'
  },
  'neon-hearts': {
    primary: '#ff1493',
    secondary: '#cc1076',
    glow: 'rgba(255, 20, 147, 0.6)',
    glowStrong: 'rgba(255, 20, 147, 0.8)',
    background: '#0a0a0a'
  },
  'injection-vector': {
    primary: '#ff6600',
    secondary: '#cc5200',
    glow: 'rgba(255, 102, 0, 0.6)',
    glowStrong: 'rgba(255, 102, 0, 0.8)',
    background: '#0a0a0a'
  },
  blitzbeam: {
    primary: '#ff0080',
    secondary: '#cc0066',
    glow: 'rgba(255, 0, 128, 0.6)',
    glowStrong: 'rgba(255, 0, 128, 0.8)',
    background: '#0a0a0a'
  },
  ethereality: {
    primary: '#e6e6fa',
    secondary: '#b8b8c8',
    glow: 'rgba(230, 230, 250, 0.6)',
    glowStrong: 'rgba(230, 230, 250, 0.8)',
    background: '#0a0a0a'
  },
  offline: {
    primary: '#cd7f32',
    secondary: '#a46528',
    glow: 'rgba(205, 127, 50, 0.6)',
    glowStrong: 'rgba(205, 127, 50, 0.8)',
    background: '#0a0a0a'
  },
  'the-pulse-grid': {
    primary: '#00ffff',
    secondary: '#00cccc',
    glow: 'rgba(0, 255, 255, 0.6)',
    glowStrong: 'rgba(0, 255, 255, 0.8)',
    background: '#0a0a0a'
  }
}

const defaultScheme: ArtistColorScheme = {
  primary: '#8B00FF',
  secondary: '#6B00CC',
  glow: 'rgba(139, 0, 255, 0.6)',
  glowStrong: 'rgba(139, 0, 255, 0.8)',
  background: '#0a0a0a'
}

export function getArtistColors (artistSlug: string): ArtistColorScheme {
  return colorSchemes[artistSlug] || defaultScheme
}
