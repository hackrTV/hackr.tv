export interface TrackData {
  id: string;
  url: string;
  title: string;
  artist: string;
  coverUrl: string;
}

export interface AudioPlayerAPI {
  loadTrack: (track: TrackData) => void;
  togglePlayPause: () => void;
  getCurrentTrackId: () => string | null;
  isPlaying: () => boolean;
  setPlaylist: (tracks: TrackData[]) => void;
  getPlaylist: () => TrackData[];
  refreshPlaylist: () => void;
  refreshUI: () => void;
}

declare global {
  interface Window {
    audioPlayer?: AudioPlayerAPI;
  }
}
