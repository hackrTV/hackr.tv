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
}

declare global {
  interface Window {
    audioPlayer?: AudioPlayerAPI;
  }
}
