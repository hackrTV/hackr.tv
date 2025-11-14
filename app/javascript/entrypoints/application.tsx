import React from 'react';
import { createRoot } from 'react-dom/client';
import { AudioPlayer } from '~/components/AudioPlayer.tsx';

// Mount React AudioPlayer component when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const rootElement = document.getElementById('react-audio-player-root');

  if (rootElement) {
    const root = createRoot(rootElement);
    root.render(
      <React.StrictMode>
        <AudioPlayer />
      </React.StrictMode>
    );
  }
});
