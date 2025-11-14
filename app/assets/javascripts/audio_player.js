// Audio Player - Global music player for hackr.fm
(function() {
  // Check if audio player exists on this page
  const player = document.getElementById('audio-player');
  if (!player) return; // Exit early if no player on this page

  const audio = document.getElementById('audio-element');
  const playPauseBtn = document.getElementById('play-pause-btn');
  const seekBar = document.getElementById('seek-bar');
  const volumeControl = document.getElementById('volume-control');
  const currentTimeEl = document.getElementById('current-time');
  const durationEl = document.getElementById('duration');
  const trackTitleEl = document.getElementById('track-title');
  const trackArtistEl = document.getElementById('track-artist');
  const closePlayerBtn = document.getElementById('close-player-btn');
  const playerCover = document.getElementById('player-cover');
  const coverOverlay = document.getElementById('cover-overlay');
  const coverOverlayImg = document.getElementById('cover-overlay-img');

  let currentTrackUrl = null;
  let currentTrackId = null;
  let pendingPlayHandler = null;

  // Format time helper
  function formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  // Update now playing UI
  function updateNowPlayingUI(trackId, isPlaying) {
    // Clear all previous highlighting and reset all buttons
    document.querySelectorAll('.track-row').forEach(function(row) {
      row.style.background = '';
      const titleEl = row.querySelector('.track-title-clickable');
      if (titleEl) {
        titleEl.style.color = '#ccc';
        const indicator = titleEl.querySelector('.now-playing-indicator');
        if (indicator) indicator.style.display = 'none';
      }
      const playBtn = row.querySelector('.play-track-btn');
      if (playBtn) {
        playBtn.textContent = '► PLAY';
        playBtn.style.background = '#7c3aed';
        playBtn.style.color = 'white';
      }
    });

    // Highlight the current track
    if (trackId) {
      const currentRow = document.querySelector('.track-row[data-track-id="' + trackId + '"]');
      if (currentRow) {
        currentRow.style.background = 'rgba(124, 58, 237, 0.15)';
        const titleEl = currentRow.querySelector('.track-title-clickable');
        if (titleEl) {
          titleEl.style.color = '#a78bfa';
          const indicator = titleEl.querySelector('.now-playing-indicator');
          if (indicator) indicator.style.display = 'inline';
        }
        const playBtn = currentRow.querySelector('.play-track-btn');
        if (playBtn) {
          playBtn.textContent = isPlaying ? '❚❚ PAUSE' : '► PLAY';
          playBtn.style.background = isPlaying ? '#9333ea' : '#7c3aed';
          playBtn.style.color = isPlaying ? '#00d9ff' : 'white';
        }
      }
    }
  }

  // Load and play track
  function loadTrack(url, title, artist, trackId, coverUrl) {
    // Remove any pending play handler from previous track loads
    if (pendingPlayHandler) {
      audio.removeEventListener('canplay', pendingPlayHandler);
      pendingPlayHandler = null;
    }

    currentTrackUrl = url;
    currentTrackId = trackId;

    trackTitleEl.textContent = title;
    trackArtistEl.textContent = artist;

    // Update cover image
    if (coverUrl) {
      playerCover.src = coverUrl;
      playerCover.style.display = 'block';
    } else {
      playerCover.style.display = 'none';
    }

    player.style.display = 'block';
    playPauseBtn.textContent = '❚❚ PAUSE';
    updateNowPlayingUI(trackId, true);

    // Load the audio and play when ready
    audio.src = url;
    audio.load();

    // Wait for audio to be ready, then play
    pendingPlayHandler = function() {
      // Only play if this is still the current track
      if (currentTrackId === trackId) {
        audio.play().catch(function(error) {
          console.error('Playback failed:', error);
          playPauseBtn.textContent = '► PLAY';
          updateNowPlayingUI(trackId, false);
        });
      }
      audio.removeEventListener('canplay', pendingPlayHandler);
      pendingPlayHandler = null;
    };

    audio.addEventListener('canplay', pendingPlayHandler);
  }

  // Play/Pause button in player bar
  playPauseBtn.addEventListener('click', function() {
    if (audio.paused) {
      audio.play().catch(function(error) {
        console.error('Playback failed:', error);
        playPauseBtn.textContent = '► PLAY';
        updateNowPlayingUI(currentTrackId, false);
      });
      playPauseBtn.textContent = '❚❚ PAUSE';
      updateNowPlayingUI(currentTrackId, true);
    } else {
      audio.pause();
      playPauseBtn.textContent = '► PLAY';
      updateNowPlayingUI(currentTrackId, false);
    }
  });

  // Update seek bar as track plays
  audio.addEventListener('timeupdate', function() {
    if (audio.duration) {
      const progress = (audio.currentTime / audio.duration) * 100;
      seekBar.value = progress;
      currentTimeEl.textContent = formatTime(audio.currentTime);
    }
  });

  // Update duration when metadata loads
  audio.addEventListener('loadedmetadata', function() {
    durationEl.textContent = formatTime(audio.duration);
    seekBar.value = 0;
  });

  // Seek when user drags the seek bar
  seekBar.addEventListener('input', function() {
    if (audio.duration) {
      const seekTime = (seekBar.value / 100) * audio.duration;
      audio.currentTime = seekTime;
    }
  });

  // Volume control
  volumeControl.addEventListener('input', function() {
    audio.volume = volumeControl.value / 100;
  });

  // Set initial volume
  audio.volume = 0.7;

  // Close player
  closePlayerBtn.addEventListener('click', function() {
    audio.pause();
    player.style.display = 'none';
    currentTrackUrl = null;
    currentTrackId = null;
    updateNowPlayingUI(null, false);
  });

  // Track ended - auto-play next track
  audio.addEventListener('ended', function() {
    // Find all playable tracks (with audio files)
    const playableTracks = Array.from(document.querySelectorAll('.track-title-clickable'));

    if (playableTracks.length === 0) {
      playPauseBtn.textContent = '► PLAY';
      updateNowPlayingUI(null, false);
      currentTrackId = null;
      return;
    }

    // Find current track index
    let currentIndex = -1;
    for (let i = 0; i < playableTracks.length; i++) {
      if (playableTracks[i].dataset.trackId === currentTrackId) {
        currentIndex = i;
        break;
      }
    }

    // Get next track (wrap around to start if at end)
    let nextIndex = (currentIndex + 1) % playableTracks.length;
    const nextTrack = playableTracks[nextIndex];

    // Load and play the next track
    const url = nextTrack.dataset.trackUrl;
    const title = nextTrack.dataset.trackTitle;
    const artist = nextTrack.dataset.trackArtist;
    const trackId = nextTrack.dataset.trackId;
    const coverUrl = nextTrack.dataset.coverUrl;
    loadTrack(url, title, artist, trackId, coverUrl);
  });

  // Attach click handlers to all play/pause buttons (if they exist)
  document.querySelectorAll('.play-track-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      const trackId = btn.dataset.trackId;

      // If clicking the currently playing track's button, toggle play/pause
      if (trackId === currentTrackId && !audio.paused) {
        audio.pause();
        playPauseBtn.textContent = '► PLAY';
        updateNowPlayingUI(currentTrackId, false);
      } else if (trackId === currentTrackId && audio.paused) {
        audio.play().catch(function(error) {
          console.error('Playback failed:', error);
          playPauseBtn.textContent = '► PLAY';
          updateNowPlayingUI(currentTrackId, false);
        });
        playPauseBtn.textContent = '❚❚ PAUSE';
        updateNowPlayingUI(currentTrackId, true);
      } else {
        // Load and play a different track
        const url = btn.dataset.trackUrl;
        const title = btn.dataset.trackTitle;
        const artist = btn.dataset.trackArtist;
        const coverUrl = btn.dataset.coverUrl;
        loadTrack(url, title, artist, trackId, coverUrl);
      }
    });
  });

  // Attach click handlers to all clickable track titles (if they exist)
  document.querySelectorAll('.track-title-clickable').forEach(function(titleEl) {
    titleEl.addEventListener('click', function() {
      const trackId = titleEl.dataset.trackId;

      // If clicking the currently playing track's title, toggle play/pause
      if (trackId === currentTrackId && !audio.paused) {
        audio.pause();
        playPauseBtn.textContent = '► PLAY';
        updateNowPlayingUI(currentTrackId, false);
      } else if (trackId === currentTrackId && audio.paused) {
        audio.play().catch(function(error) {
          console.error('Playback failed:', error);
          playPauseBtn.textContent = '► PLAY';
          updateNowPlayingUI(currentTrackId, false);
        });
        playPauseBtn.textContent = '❚❚ PAUSE';
        updateNowPlayingUI(currentTrackId, true);
      } else {
        // Load and play a different track
        const url = titleEl.dataset.trackUrl;
        const title = titleEl.dataset.trackTitle;
        const artist = titleEl.dataset.artistName;
        const coverUrl = titleEl.dataset.coverUrl;
        loadTrack(url, title, artist, trackId, coverUrl);
      }
    });
  });

  // Attach click handlers to entire track rows (if they exist)
  document.querySelectorAll('.track-row').forEach(function(row) {
    row.addEventListener('click', function(e) {
      // Don't trigger if clicking the button directly (it has its own handler)
      if (e.target.closest('.play-track-btn')) {
        return;
      }

      const titleEl = row.querySelector('.track-title-clickable');
      if (!titleEl) return; // Skip rows without audio files

      const trackId = titleEl.dataset.trackId;

      // Toggle play/pause if clicking the currently playing track
      if (trackId === currentTrackId && !audio.paused) {
        audio.pause();
        playPauseBtn.textContent = '► PLAY';
        updateNowPlayingUI(currentTrackId, false);
      } else if (trackId === currentTrackId && audio.paused) {
        audio.play().catch(function(error) {
          console.error('Playback failed:', error);
          playPauseBtn.textContent = '► PLAY';
          updateNowPlayingUI(currentTrackId, false);
        });
        playPauseBtn.textContent = '❚❚ PAUSE';
        updateNowPlayingUI(currentTrackId, true);
      } else {
        // Load and play a different track
        const url = titleEl.dataset.trackUrl;
        const title = titleEl.dataset.trackTitle;
        const artist = titleEl.dataset.trackArtist;
        const coverUrl = titleEl.dataset.coverUrl;
        loadTrack(url, title, artist, trackId, coverUrl);
      }
    });
  });

  // Track search/filter functionality (if search input exists)
  const searchInput = document.getElementById('track-search');
  if (searchInput) {
    const visibleCountEl = document.getElementById('visible-count');
    const allRows = document.querySelectorAll('.track-row');

    function applyFilter() {
      const query = searchInput.value.toLowerCase().trim();
      let visibleCount = 0;

      allRows.forEach(function(row) {
        const trackName = row.dataset.trackName || '';
        const artistName = row.dataset.artistName || '';
        const albumName = row.dataset.albumName || '';
        const genre = row.dataset.genre || '';

        // Check if query matches track, artist, album name, or genre
        const matches = trackName.includes(query) ||
                       artistName.includes(query) ||
                       albumName.includes(query) ||
                       genre.includes(query);

        if (matches || query === '') {
          row.style.display = '';
          visibleCount++;
        } else {
          row.style.display = 'none';
        }
      });

      // Update visible count
      if (visibleCountEl) {
        visibleCountEl.textContent = visibleCount;
      }
    }

    searchInput.addEventListener('input', applyFilter);

    // Apply filter on page load if search input has a value
    if (searchInput.value) {
      applyFilter();
    }

    // Keyboard shortcut: Tab to focus search and select all text
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Tab') {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
    });
  }

  // Cover image hover overlay
  if (playerCover && coverOverlay) {
    playerCover.addEventListener('mouseenter', function() {
      if (playerCover.src && playerCover.style.display !== 'none') {
        coverOverlayImg.src = playerCover.src;
        coverOverlay.style.display = 'block';
      }
    });

    playerCover.addEventListener('mouseleave', function() {
      coverOverlay.style.display = 'none';
    });

    // Also hide overlay when mouse moves away from the general player area
    player.addEventListener('mouseleave', function() {
      coverOverlay.style.display = 'none';
    });
  }

  // Keyboard shortcut: Spacebar to pause/resume playback
  document.addEventListener('keydown', function(e) {
    // Only handle spacebar if audio is loaded and not typing in search box
    if (e.key === ' ' && currentTrackId && e.target !== searchInput) {
      e.preventDefault(); // Prevent page scroll

      if (audio.paused) {
        audio.play().catch(function(error) {
          console.error('Playback failed:', error);
          playPauseBtn.textContent = '► PLAY';
          updateNowPlayingUI(currentTrackId, false);
        });
        playPauseBtn.textContent = '❚❚ PAUSE';
        updateNowPlayingUI(currentTrackId, true);
      } else {
        audio.pause();
        playPauseBtn.textContent = '► PLAY';
        updateNowPlayingUI(currentTrackId, false);
      }
    }
  });
})();
