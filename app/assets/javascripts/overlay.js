// OBS Overlay Real-time Updates via Action Cable
// This file depends on ActionCable being loaded from CDN in the overlay layout

(function() {
  'use strict';

  // ========================================
  // RANDOM FLICKER SYSTEM
  // ========================================
  function FlickerManager() {
    this.elements = [];
    this.running = false;
  }

  FlickerManager.prototype.init = function() {
    // Find all flickerable elements
    this.elements = document.querySelectorAll(
      '.overlay-now-playing, .overlay-pulse, .overlay-grid-activity, ' +
      '.overlay-lower-third, .overlay-codex, .overlay-alert.active, ' +
      '.now-playing-label, .grid-hackr-name, .overlay-pulse-hackr, ' +
      '.tui-frame-top, .tui-frame-bottom, .ticker-content, .scene-title'
    );

    if (this.elements.length > 0) {
      this.running = true;
      this.scheduleNextFlicker();
    }
  };

  FlickerManager.prototype.scheduleNextFlicker = function() {
    if (!this.running) return;

    var self = this;
    // Random delay between 800ms and 4000ms
    var delay = 800 + Math.random() * 3200;

    setTimeout(function() {
      self.triggerRandomFlicker();
      self.scheduleNextFlicker();
    }, delay);
  };

  FlickerManager.prototype.triggerRandomFlicker = function() {
    if (this.elements.length === 0) return;

    // Pick a random element
    var index = Math.floor(Math.random() * this.elements.length);
    var element = this.elements[index];

    // Skip if element is not visible
    if (!element.offsetParent && !element.closest('.overlay-body')) return;

    // Randomly choose flicker intensity
    var flickerClass = Math.random() > 0.7 ? 'flicker-hard' : 'flicker';

    // Apply flicker
    element.classList.add(flickerClass);

    // Remove after animation completes
    setTimeout(function() {
      element.classList.remove('flicker', 'flicker-hard');
    }, 200);

    // Occasionally trigger a second flicker on a nearby element
    if (Math.random() > 0.8 && this.elements.length > 1) {
      var secondIndex = (index + 1) % this.elements.length;
      var secondElement = this.elements[secondIndex];

      setTimeout(function() {
        secondElement.classList.add('flicker');
        setTimeout(function() {
          secondElement.classList.remove('flicker');
        }, 100);
      }, 50);
    }
  };

  FlickerManager.prototype.refresh = function() {
    // Re-scan for elements (useful after DOM updates)
    this.elements = document.querySelectorAll(
      '.overlay-now-playing, .overlay-pulse, .overlay-grid-activity, ' +
      '.overlay-lower-third, .overlay-codex, .overlay-alert.active, ' +
      '.now-playing-label, .grid-hackr-name, .overlay-pulse-hackr, ' +
      '.tui-frame-top, .tui-frame-bottom, .ticker-content, .scene-title'
    );
  };

  FlickerManager.prototype.stop = function() {
    this.running = false;
  };

  // OverlayManager class for handling real-time updates
  function OverlayManager() {
    this.consumer = null;
    this.subscription = null;
    this.pulseWireSubscription = null;
  }

  OverlayManager.prototype.init = function() {
    var self = this;

    // Check if ActionCable is available
    if (typeof ActionCable === 'undefined') {
      console.warn('[Overlay] ActionCable not loaded, real-time updates disabled');
      return;
    }

    // Create Action Cable consumer
    this.consumer = ActionCable.createConsumer();

    // Subscribe to overlay updates channel
    this.subscription = this.consumer.subscriptions.create('OverlayChannel', {
      connected: function() {
        console.log('[Overlay] Connected to OverlayChannel');
      },
      disconnected: function() {
        console.log('[Overlay] Disconnected from OverlayChannel');
      },
      received: function(data) {
        self.handleOverlayUpdate(data);
      }
    });

    // Subscribe to PulseWire for pulsewire overlay
    if (document.getElementById('pulsewire-overlay')) {
      this.pulseWireSubscription = this.consumer.subscriptions.create('PulseWireChannel', {
        connected: function() {
          console.log('[Overlay] Connected to PulseWireChannel');
        },
        disconnected: function() {
          console.log('[Overlay] Disconnected from PulseWireChannel');
        },
        received: function(data) {
          self.handlePulseWireUpdate(data);
        }
      });
    }
  };

  OverlayManager.prototype.handleOverlayUpdate = function(data) {
    console.log('[Overlay] Received update:', data.type);

    switch (data.type) {
      case 'now_playing_changed':
        this.updateNowPlaying(data.data);
        break;
      case 'new_alert':
        this.showAlert(data.data);
        break;
      case 'ticker_updated':
        this.updateTicker(data.data);
        break;
      case 'lower_third_updated':
        this.updateLowerThird(data.data);
        break;
    }
  };

  OverlayManager.prototype.updateNowPlaying = function(data) {
    var overlay = document.getElementById('now-playing-overlay');
    if (!overlay) return;

    overlay.dataset.trackId = data.track_id || '';

    // Determine state: playing, paused, or idle
    var headerText = '┤ STANDBY ├';
    var labelText = 'IDLE';
    var placeholderChar = '·';

    if (data.playing) {
      if (data.paused) {
        headerText = '┤ PAUSED ├';
        labelText = 'PAUSED';
        placeholderChar = '║';
      } else {
        headerText = '┤ NOW PLAYING ├';
        labelText = 'PLAYING';
        placeholderChar = '♪';
      }
    }

    // Update the TUI frame header
    var frameTop = overlay.querySelector('.tui-frame-top');
    if (frameTop) {
      frameTop.textContent = headerText;
    }

    // Update content
    var container = overlay.querySelector('.now-playing-inner');
    if (!container) return;

    if (data.playing) {
      container.innerHTML =
        (data.album_cover
          ? '<img src="' + this.escapeHtml(data.album_cover) + '" alt="" class="now-playing-cover">'
          : '<div class="now-playing-cover-placeholder">' + placeholderChar + '</div>') +
        '<div class="now-playing-info">' +
          '<span class="now-playing-label">' + labelText + '</span>' +
          '<span class="now-playing-title">' + this.escapeHtml(data.title) + '</span>' +
          '<span class="now-playing-artist">' + this.escapeHtml(data.artist) + '</span>' +
          (data.album ? '<span class="now-playing-album">└─ ' + this.escapeHtml(data.album) + '</span>' : '') +
        '</div>';

      // Update overlay class for styling
      overlay.classList.remove('is-playing', 'is-paused', 'is-idle');
      overlay.classList.add(data.paused ? 'is-paused' : 'is-playing');
    } else {
      container.innerHTML =
        '<div class="now-playing-cover-placeholder">·</div>' +
        '<div class="now-playing-info">' +
          '<span class="now-playing-label">IDLE</span>' +
          '<span class="now-playing-title">Awaiting signal...</span>' +
        '</div>';

      overlay.classList.remove('is-playing', 'is-paused', 'is-idle');
      overlay.classList.add('is-idle');
    }

    // Refresh flicker manager to pick up new elements
    if (window.flickerManager) {
      window.flickerManager.refresh();
    }
  };

  OverlayManager.prototype.showAlert = function(data) {
    var overlay = document.getElementById('alert-overlay');
    if (!overlay) return;

    // Get icon for alert type (wrapped in brackets for TUI style)
    var icons = {
      subscriber: '[★]',
      donation: '[$]',
      raid: '[⚡]',
      follow: '[+]',
      custom: '[!]'
    };
    var icon = icons[data.alert_type] || '[!]';

    // Update content with TUI frame
    overlay.innerHTML =
      '<div class="tui-alert-frame">' +
        '<div class="alert-icon">' + icon + '</div>' +
        (data.title ? '<div class="alert-title">' + this.escapeHtml(data.title) + '</div>' : '') +
        (data.message ? '<div class="alert-message">' + this.escapeHtml(data.message) + '</div>' : '') +
      '</div>';

    // Show alert
    overlay.classList.add('active');
    overlay.dataset.alertId = data.id;

    // Refresh flicker manager
    if (window.flickerManager) {
      window.flickerManager.refresh();
    }

    // Auto-hide after 10 seconds
    setTimeout(function() {
      overlay.classList.remove('active');
    }, 10000);
  };

  OverlayManager.prototype.updateTicker = function(data) {
    var ticker = document.querySelector('#ticker-' + data.slug + '-overlay');
    if (!ticker) return;

    var content = ticker.querySelector('.ticker-content');
    if (content) {
      // Use span separators for TUI style
      content.innerHTML = this.escapeHtml(data.content) +
        '<span class="ticker-separator"></span>' +
        this.escapeHtml(data.content) +
        '<span class="ticker-separator"></span>' +
        this.escapeHtml(data.content);
    }

    // Update animation direction
    ticker.classList.remove('ticker-scroll-left', 'ticker-scroll-right');
    ticker.classList.add('ticker-scroll-' + data.direction);

    // Update speed (recalculate duration)
    var charCount = data.content.length;
    var baseDuration = Math.max((charCount * 10) / data.speed, 10);
    ticker.style.setProperty('--ticker-duration', baseDuration + 's');

    // Show/hide based on active state
    ticker.style.display = data.active ? '' : 'none';
  };

  OverlayManager.prototype.updateLowerThird = function(data) {
    var overlay = document.querySelector('#lower-third-overlay[data-slug="' + data.slug + '"]');
    if (!overlay) return;

    var primary = overlay.querySelector('.lower-third-primary');
    var secondary = overlay.querySelector('.lower-third-secondary');

    if (primary) primary.textContent = data.primary_text;
    if (secondary) {
      if (data.secondary_text) {
        secondary.textContent = data.secondary_text;
        secondary.style.display = '';
      } else {
        secondary.style.display = 'none';
      }
    }

    // Update logo if present
    var logo = overlay.querySelector('.lower-third-logo');
    if (logo && data.logo_url) {
      logo.src = data.logo_url;
    }

    // Show/hide based on active state
    overlay.style.display = data.active ? '' : 'none';
  };

  OverlayManager.prototype.handlePulseWireUpdate = function(data) {
    var overlay = document.getElementById('pulsewire-overlay');
    if (!overlay) return;

    switch (data.type) {
      case 'new_pulse':
        this.addPulse(data.pulse);
        break;
      case 'pulse_deleted':
      case 'pulse_dropped':
        this.removePulse(data.pulse_id);
        break;
    }
  };

  OverlayManager.prototype.addPulse = function(pulse) {
    var overlay = document.getElementById('pulsewire-overlay');
    if (!overlay) return;

    // Create new pulse element (@ prefix added via CSS ::before)
    var pulseEl = document.createElement('div');
    pulseEl.className = 'overlay-pulse';
    pulseEl.dataset.pulseId = pulse.id;
    pulseEl.innerHTML =
      '<div class="overlay-pulse-header">' +
        '<span class="overlay-pulse-hackr">' + this.escapeHtml(pulse.grid_hackr ? pulse.grid_hackr.hackr_alias : 'Unknown') + '</span>' +
        '<span class="overlay-pulse-time">[just now]</span>' +
      '</div>' +
      '<div class="overlay-pulse-content">' + this.escapeHtml(pulse.content) + '</div>';

    // Insert after the header, not at the very top
    var header = overlay.querySelector('.tui-header');
    var firstPulse = overlay.querySelector('.overlay-pulse');
    if (header && firstPulse) {
      overlay.insertBefore(pulseEl, firstPulse);
    } else if (header) {
      header.insertAdjacentElement('afterend', pulseEl);
    } else {
      overlay.insertBefore(pulseEl, overlay.firstChild);
    }

    // Remove oldest pulse if we have more than 5
    var pulses = overlay.querySelectorAll('.overlay-pulse');
    if (pulses.length > 5) {
      pulses[pulses.length - 1].remove();
    }

    // Refresh flicker manager to include new element
    if (window.flickerManager) {
      window.flickerManager.refresh();
    }
  };

  OverlayManager.prototype.removePulse = function(pulseId) {
    var overlay = document.getElementById('pulsewire-overlay');
    if (!overlay) return;

    var pulse = overlay.querySelector('.overlay-pulse[data-pulse-id="' + pulseId + '"]');
    if (pulse) {
      pulse.remove();
    }
  };

  OverlayManager.prototype.escapeHtml = function(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  };

  // Initialize when DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    // Initialize overlay manager for real-time updates
    window.overlayManager = new OverlayManager();
    window.overlayManager.init();

    // Initialize random flicker system
    window.flickerManager = new FlickerManager();
    window.flickerManager.init();
  });
})();
