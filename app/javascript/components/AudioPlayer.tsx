import React, { useEffect, useRef, useState, useCallback } from 'react';
import { PlayerBar } from './PlayerBar.tsx';
import type { TrackData, AudioPlayerAPI } from '~/types/track.ts';

export const AudioPlayer: React.FC = () => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [currentTrack, setCurrentTrack] = useState<TrackData | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(0.7);
  const [isVisible, setIsVisible] = useState(false);
  const [isSeeking, setIsSeeking] = useState(false);

  // Handle play/pause
  const handlePlayPause = useCallback(() => {
    if (!audioRef.current) return;

    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().catch((error) => {
        console.error('Playback failed:', error);
        setIsPlaying(false);
      });
      setIsPlaying(true);
    }
  }, [isPlaying]);

  // Load and play track
  const loadTrack = useCallback((track: TrackData) => {
    const audio = audioRef.current;
    if (!audio) return;

    // Pause and reset current playback
    audio.pause();
    setIsPlaying(false);

    // Set new track info
    setCurrentTrack(track);
    setIsVisible(true);

    // Set the new source
    audio.src = track.url;
    audio.load(); // Explicitly load the new source

    // Wait for the audio to be ready, then play
    const onCanPlay = () => {
      audio.play()
        .then(() => {
          setIsPlaying(true);
        })
        .catch((error) => {
          console.error('Playback failed:', error);
          setIsPlaying(false);
        });

      // Remove listener after it fires
      audio.removeEventListener('canplay', onCanPlay);
    };

    audio.addEventListener('canplay', onCanPlay);
  }, []);

  // Expose API to vanilla JS
  useEffect(() => {
    const api: AudioPlayerAPI = {
      loadTrack,
      togglePlayPause: handlePlayPause,
      getCurrentTrackId: () => currentTrack?.id || null,
    };
    window.audioPlayer = api;

    return () => {
      delete window.audioPlayer;
    };
  }, [loadTrack, handlePlayPause, currentTrack]);

  // Update track table UI when current track or playing state changes
  useEffect(() => {
    // Clear all previous highlighting and reset all buttons
    document.querySelectorAll('.track-row').forEach((row) => {
      const rowEl = row as HTMLElement;
      rowEl.style.background = '';

      const titleEl = row.querySelector('.track-title-clickable') as HTMLElement;
      if (titleEl) {
        titleEl.style.color = '#ccc';
        const indicator = titleEl.querySelector('.now-playing-indicator') as HTMLElement;
        if (indicator) indicator.style.display = 'none';
      }

      const playBtn = row.querySelector('.play-track-btn') as HTMLElement;
      if (playBtn) {
        playBtn.textContent = '► PLAY';
        playBtn.style.background = '#7c3aed';
        playBtn.style.color = 'white';
      }
    });

    // Highlight the current track if playing
    if (currentTrack) {
      const currentRow = document.querySelector(`.track-row[data-track-id="${currentTrack.id}"]`) as HTMLElement;
      if (currentRow) {
        currentRow.style.background = 'rgba(124, 58, 237, 0.15)';

        const titleEl = currentRow.querySelector('.track-title-clickable') as HTMLElement;
        if (titleEl) {
          titleEl.style.color = '#a78bfa';
          const indicator = titleEl.querySelector('.now-playing-indicator') as HTMLElement;
          if (indicator) indicator.style.display = 'inline';
        }

        const playBtn = currentRow.querySelector('.play-track-btn') as HTMLElement;
        if (playBtn) {
          playBtn.textContent = isPlaying ? '❚❚ PAUSE' : '► PLAY';
          playBtn.style.background = isPlaying ? '#9333ea' : '#7c3aed';
          playBtn.style.color = isPlaying ? '#00d9ff' : 'white';
        }
      }
    }
  }, [currentTrack, isPlaying]);

  // Handle seek start (when user starts dragging)
  const handleSeekStart = useCallback(() => {
    setIsSeeking(true);
  }, []);

  // Handle seek (while dragging)
  const handleSeek = useCallback((time: number) => {
    if (audioRef.current) {
      audioRef.current.currentTime = time;
      setCurrentTime(time); // Update displayed time immediately
    }
  }, []);

  // Handle seek end (when user releases)
  const handleSeekEnd = useCallback(() => {
    setIsSeeking(false);
  }, []);

  // Handle volume change
  const handleVolumeChange = useCallback((newVolume: number) => {
    setVolume(newVolume);
    if (audioRef.current) {
      audioRef.current.volume = newVolume;
    }
  }, []);

  // Handle close
  const handleClose = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause();
    }
    setIsVisible(false);
    setIsPlaying(false);
    setCurrentTrack(null);
  }, []);

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Spacebar to play/pause (only if not typing in an input)
      if (
        e.key === ' ' &&
        currentTrack &&
        !(e.target instanceof HTMLInputElement) &&
        !(e.target instanceof HTMLTextAreaElement)
      ) {
        e.preventDefault();
        handlePlayPause();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [currentTrack, handlePlayPause]);

  // Audio event handlers
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const handleTimeUpdate = () => {
      // Only update time if not currently seeking to avoid conflicts
      if (!isSeeking) {
        setCurrentTime(audio.currentTime);
      }
    };

    const handleLoadedMetadata = () => setDuration(audio.duration);

    const handleEnded = () => {
      setIsPlaying(false);

      // Auto-play next track
      // Find all playable tracks from the DOM, but only visible ones (not filtered out)
      const allPlayableTracks = Array.from(document.querySelectorAll('.track-title-clickable'));

      // Filter to only visible tracks (parent row is not hidden)
      const visibleTracks = allPlayableTracks.filter((el) => {
        const row = (el as HTMLElement).closest('.track-row') as HTMLElement;
        return row && row.style.display !== 'none';
      });

      if (visibleTracks.length === 0) return;

      // Find current track index in visible tracks
      let currentIndex = -1;
      for (let i = 0; i < visibleTracks.length; i++) {
        const el = visibleTracks[i] as HTMLElement;
        if (el.dataset.trackId === currentTrack?.id) {
          currentIndex = i;
          break;
        }
      }

      // Get next track (wrap around to start if at end)
      const nextIndex = (currentIndex + 1) % visibleTracks.length;
      const nextTrackEl = visibleTracks[nextIndex] as HTMLElement;

      // Extract track data and load it
      const nextTrack: TrackData = {
        id: nextTrackEl.dataset.trackId || '',
        url: nextTrackEl.dataset.trackUrl || '',
        title: nextTrackEl.dataset.trackTitle || '',
        artist: nextTrackEl.dataset.trackArtist || '',
        coverUrl: nextTrackEl.dataset.coverUrl || '',
      };

      loadTrack(nextTrack);
    };

    audio.addEventListener('timeupdate', handleTimeUpdate);
    audio.addEventListener('loadedmetadata', handleLoadedMetadata);
    audio.addEventListener('ended', handleEnded);

    // Set initial volume
    audio.volume = volume;

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate);
      audio.removeEventListener('loadedmetadata', handleLoadedMetadata);
      audio.removeEventListener('ended', handleEnded);
    };
  }, [volume, isSeeking, currentTrack, loadTrack]);

  return (
    <>
      {isVisible && (
        <PlayerBar
          isPlaying={isPlaying}
          currentTrack={currentTrack}
          currentTime={currentTime}
          duration={duration}
          volume={volume}
          onPlayPause={handlePlayPause}
          onSeekStart={handleSeekStart}
          onSeek={handleSeek}
          onSeekEnd={handleSeekEnd}
          onVolumeChange={handleVolumeChange}
          onClose={handleClose}
        />
      )}
      <audio ref={audioRef} id="audio-element" style={{ display: 'none' }} />
    </>
  );
};
