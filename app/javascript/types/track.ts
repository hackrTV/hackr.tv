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

export interface AudioPlayerAPI {
  loadTrack: (track: TrackData) => void;
  togglePlayPause: () => void;
  getCurrentTrackId: () => string | null;
  isPlaying: () => boolean;
  setPlaylist: (tracks: TrackData[], stationContext?: StationContext) => void;
  getPlaylist: () => TrackData[];
  getStationContext: () => StationContext | null;
  refreshPlaylist: () => void;
  refreshUI: () => void;
}

declare global {
  interface Window {
    audioPlayer?: AudioPlayerAPI;
  }
}
