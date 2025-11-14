// Track Table Integration - Bridges vanilla JS track table with React Audio Player
(function() {
  // Wait for both DOM and React to be ready
  function initTrackTable() {
    // Attach click handlers to all play/pause buttons
    document.querySelectorAll('.play-track-btn').forEach(function(btn) {
      btn.addEventListener('click', function(e) {
        e.stopPropagation(); // Prevent row handler from also firing

        if (window.audioPlayer) {
          const trackId = btn.dataset.trackId;
          const currentTrackId = window.audioPlayer.getCurrentTrackId();

          // If clicking the currently playing track's button, toggle play/pause
          if (trackId === currentTrackId) {
            window.audioPlayer.togglePlayPause();
          } else {
            // Load and play a different track
            const trackData = {
              id: trackId,
              url: btn.dataset.trackUrl,
              title: btn.dataset.trackTitle,
              artist: btn.dataset.trackArtist,
              coverUrl: btn.dataset.coverUrl || '',
            };
            window.audioPlayer.loadTrack(trackData);
          }
        } else {
          console.warn('React Audio Player not ready yet');
        }
      });
    });

    // Attach click handlers to all clickable track titles
    document.querySelectorAll('.track-title-clickable').forEach(function(titleEl) {
      titleEl.addEventListener('click', function(e) {
        e.stopPropagation(); // Prevent row handler from also firing

        if (window.audioPlayer) {
          const trackId = titleEl.dataset.trackId;
          const currentTrackId = window.audioPlayer.getCurrentTrackId();

          // If clicking the currently playing track's title, toggle play/pause
          if (trackId === currentTrackId) {
            window.audioPlayer.togglePlayPause();
          } else {
            // Load and play a different track
            const trackData = {
              id: trackId,
              url: titleEl.dataset.trackUrl,
              title: titleEl.dataset.trackTitle,
              artist: titleEl.dataset.trackArtist,
              coverUrl: titleEl.dataset.coverUrl || '',
            };
            window.audioPlayer.loadTrack(trackData);
          }
        } else {
          console.warn('React Audio Player not ready yet');
        }
      });
    });

    // Attach click handlers to entire track rows
    document.querySelectorAll('.track-row').forEach(function(row) {
      row.addEventListener('click', function(e) {
        // Don't trigger if clicking the button or title (they have their own handlers)
        if (e.target.closest('.play-track-btn') || e.target.closest('.track-title-clickable')) {
          return;
        }

        const titleEl = row.querySelector('.track-title-clickable');
        if (!titleEl) return; // Skip rows without audio files

        if (window.audioPlayer) {
          const trackId = titleEl.dataset.trackId;
          const currentTrackId = window.audioPlayer.getCurrentTrackId();

          // If clicking the currently playing track's row, toggle play/pause
          if (trackId === currentTrackId) {
            window.audioPlayer.togglePlayPause();
          } else {
            // Load and play a different track
            const trackData = {
              id: trackId,
              url: titleEl.dataset.trackUrl,
              title: titleEl.dataset.trackTitle,
              artist: titleEl.dataset.trackArtist,
              coverUrl: titleEl.dataset.coverUrl || '',
            };
            window.audioPlayer.loadTrack(trackData);
          }
        } else {
          console.warn('React Audio Player not ready yet');
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
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initTrackTable);
  } else {
    initTrackTable();
  }
})();
