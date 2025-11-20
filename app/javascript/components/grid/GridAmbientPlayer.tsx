import React, { useRef, useEffect, useState, useCallback } from 'react';
import { ZonePlaylistData, TrackData } from '../../types/track';
import { AudioFader } from '../../utils/audioFader';

interface GridAmbientPlayerProps {
  playlist: ZonePlaylistData | null;
  muted: boolean;
  volume: number;
  onMutedChange: (muted: boolean) => void;
  onVolumeChange: (volume: number) => void;
  onTrackChange?: (track: TrackData | null) => void;
}

export const GridAmbientPlayer: React.FC<GridAmbientPlayerProps> = ({
  playlist,
  muted,
  volume,
  onMutedChange,
  onVolumeChange,
  onTrackChange,
}) => {
  const audioARef = useRef<HTMLAudioElement>(null);
  const audioBRef = useRef<HTMLAudioElement>(null);
  const faderRef = useRef<AudioFader>(new AudioFader());

  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [activeElement, setActiveElement] = useState<'A' | 'B'>('A');
  const [isPlaying, setIsPlaying] = useState(false);

  // Store the playlist and current track data
  const playlistRef = useRef<ZonePlaylistData | null>(null);

  // Initialize with a random starting track when playlist changes
  useEffect(() => {
    if (!playlist || playlist.tracks.length === 0) {
      setIsPlaying(false);
      return;
    }

    // Only restart if this is a different playlist
    if (playlistRef.current?.id !== playlist.id) {
      playlistRef.current = playlist;
      const randomIndex = Math.floor(Math.random() * playlist.tracks.length);
      setCurrentIndex(randomIndex);
      // Set volume to playlist default if user hasn't customized it
      if (volume === 0.35) {
        onVolumeChange(playlist.default_volume);
      }
      setActiveElement('A');

      // Start playing the first track
      if (audioARef.current) {
        const track = playlist.tracks[randomIndex];
        if (track.url) {
          audioARef.current.src = track.url;
          audioARef.current.volume = muted ? 0 : volume;
          audioARef.current.play().catch((e) => {
            console.error('Failed to start Grid ambient audio:', e);
          });
          setIsPlaying(true);
          onTrackChange?.(track);
        }
      }
    }
  }, [playlist, muted, volume, onVolumeChange, onTrackChange]);

  // Handle mute changes
  useEffect(() => {
    const activeAudio = activeElement === 'A' ? audioARef.current : audioBRef.current;
    if (activeAudio) {
      activeAudio.volume = muted ? 0 : volume;
    }
  }, [muted, activeElement, volume]);

  // Handle track end and crossfade to next track
  const handleTrackEnded = useCallback(() => {
    if (!playlistRef.current || playlistRef.current.tracks.length === 0) return;

    const nextIndex = (currentIndex + 1) % playlistRef.current.tracks.length;
    const nextTrack = playlistRef.current.tracks[nextIndex];

    if (!nextTrack.url) {
      // Skip tracks without audio files
      setCurrentIndex(nextIndex);
      handleTrackEnded();
      return;
    }

    const currentAudio = activeElement === 'A' ? audioARef.current : audioBRef.current;
    const nextAudio = activeElement === 'A' ? audioBRef.current : audioARef.current;

    if (!currentAudio || !nextAudio) return;

    // Load the next track
    nextAudio.src = nextTrack.url;
    nextAudio.volume = 0;

    // Start playing the next track
    nextAudio.play().then(() => {
      // Crossfade between tracks
      const crossfadeDuration = playlistRef.current?.crossfade_duration_ms || 5000;

      faderRef.current.crossFade(
        currentAudio,
        nextAudio,
        muted ? 0 : volume,
        {
          duration: crossfadeDuration,
          onComplete: () => {
            // Switch active element
            setActiveElement(activeElement === 'A' ? 'B' : 'A');
            setCurrentIndex(nextIndex);
            onTrackChange?.(nextTrack);
          },
        }
      );
    }).catch((e) => {
      console.error('Failed to crossfade to next track:', e);
      setCurrentIndex(nextIndex);
    });
  }, [currentIndex, activeElement, muted, volume, onTrackChange]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      faderRef.current.destroy();
      if (audioARef.current) {
        audioARef.current.pause();
        audioARef.current.src = '';
      }
      if (audioBRef.current) {
        audioBRef.current.pause();
        audioBRef.current.src = '';
      }
    };
  }, []);

  if (!playlist) {
    return null;
  }

  return (
    <>
      <audio
        ref={audioARef}
        onEnded={handleTrackEnded}
        preload="auto"
      />
      <audio
        ref={audioBRef}
        onEnded={handleTrackEnded}
        preload="auto"
      />
    </>
  );
};
