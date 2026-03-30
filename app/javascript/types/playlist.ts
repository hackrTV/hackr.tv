export interface Artist {
  id: number
  name: string
  slug: string
}

export interface CoverUrls {
  thumbnail: string
  standard: string
  full: string
}

export interface Release {
  id: number
  name: string
  slug: string
  cover_url: string | null
  cover_urls?: CoverUrls
}

export interface Track {
  id: number  // This is the playlist_track.id (join table ID) - needed for deletion
  track_id: number  // This is the actual track.id
  title: string
  slug: string
  track_number: number
  duration: string | null
  position: number
  artist: Artist
  release: Release | null
  audio_url: string | null
}

export interface PlaylistTrack {
  id: number
  playlist_id: number
  track_id: number
  position: number
  track: Track
}

export interface Playlist {
  id: number
  name: string
  description: string | null
  is_public: boolean
  share_token: string
  created_at: string
  track_count: number
  tracks?: Track[]
}

export interface PlaylistSummary {
  id: number
  name: string
  description: string | null
  is_public: boolean
  share_token: string
  created_at: string
  track_count: number
}

export interface SharedPlaylist {
  id: number
  name: string
  description: string | null
  created_at: string
  track_count: number
  owner: {
    hackr_alias: string
  }
  tracks: Track[]
}
