export interface TrackData {
  id: string;
  url: string;
  title: string;
  artist: string;
  coverUrl: string;
}

export interface StationContext {
  id: number;
  name: string;
}

export interface ZonePlaylistData {
  id: number;
  name: string;
  description: string | null;
  crossfade_duration_ms: number;
  default_volume: number;
  tracks: TrackData[];
}

export interface AudioPlayerAPI {
  loadTrack: (track: TrackData) => void;
  togglePlayPause: () => void;
  playNext: () => void;
  playPrevious: () => void;
  getCurrentTrackId: () => string | null;
  isPlaying: () => boolean;
  setPlaylist: (tracks: TrackData[], stationContext?: StationContext) => void;
  getPlaylist: () => TrackData[];
  getEffectivePlaylist: () => TrackData[];
  getStationContext: () => StationContext | null;
  refreshPlaylist: () => void;
  refreshUI: () => void;
  toggleShuffle: () => void;
  isShuffle: () => boolean;
}

declare global {
  interface Window {
    audioPlayer?: AudioPlayerAPI;
  }
}
