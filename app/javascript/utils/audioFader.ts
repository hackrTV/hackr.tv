/**
 * AudioFader - Utility for smooth audio volume transitions
 * Used by GridAmbientPlayer for crossfading between tracks
 */

export interface FadeOptions {
  duration: number; // Duration in milliseconds
  onComplete?: () => void;
}

export class AudioFader {
  private intervalId: number | null = null;
  private readonly STEP_MS = 50; // Update volume every 50ms for smooth transitions

  /**
   * Fade out an audio element's volume to 0
   * @param element - The HTML audio element to fade out
   * @param options - Fade duration and completion callback
   */
  fadeOut(element: HTMLAudioElement, options: FadeOptions): void {
    this.cancelFade(); // Cancel any existing fade

    const startVolume = element.volume;
    const steps = options.duration / this.STEP_MS;
    const volumeDecrement = startVolume / steps;
    let currentStep = 0;

    this.intervalId = window.setInterval(() => {
      currentStep++;
      const newVolume = Math.max(0, startVolume - volumeDecrement * currentStep);
      element.volume = newVolume;

      if (newVolume <= 0 || currentStep >= steps) {
        this.cancelFade();
        element.volume = 0;
        options.onComplete?.();
      }
    }, this.STEP_MS);
  }

  /**
   * Fade in an audio element's volume from 0 to target volume
   * @param element - The HTML audio element to fade in
   * @param targetVolume - The desired final volume (0.0 - 1.0)
   * @param options - Fade duration and completion callback
   */
  fadeIn(element: HTMLAudioElement, targetVolume: number, options: FadeOptions): void {
    this.cancelFade(); // Cancel any existing fade

    element.volume = 0;
    const steps = options.duration / this.STEP_MS;
    const volumeIncrement = targetVolume / steps;
    let currentStep = 0;

    this.intervalId = window.setInterval(() => {
      currentStep++;
      const newVolume = Math.min(targetVolume, volumeIncrement * currentStep);
      element.volume = newVolume;

      if (newVolume >= targetVolume || currentStep >= steps) {
        this.cancelFade();
        element.volume = targetVolume;
        options.onComplete?.();
      }
    }, this.STEP_MS);
  }

  /**
   * Cross-fade between two audio elements
   * @param fadeOutElement - The audio element to fade out
   * @param fadeInElement - The audio element to fade in
   * @param fadeInTargetVolume - The target volume for the fade-in element
   * @param options - Fade duration and completion callback
   */
  crossFade(
    fadeOutElement: HTMLAudioElement,
    fadeInElement: HTMLAudioElement,
    fadeInTargetVolume: number,
    options: FadeOptions
  ): void {
    // Start both fades simultaneously for true crossfade
    this.fadeOut(fadeOutElement, {
      duration: options.duration,
      onComplete: () => {
        fadeOutElement.pause();
      },
    });

    // Fade in the new track (which should already be playing or about to play)
    fadeInElement.volume = 0;
    const steps = options.duration / this.STEP_MS;
    const volumeIncrement = fadeInTargetVolume / steps;
    let currentStep = 0;

    const fadeInInterval = window.setInterval(() => {
      currentStep++;
      const newVolume = Math.min(fadeInTargetVolume, volumeIncrement * currentStep);
      fadeInElement.volume = newVolume;

      if (newVolume >= fadeInTargetVolume || currentStep >= steps) {
        clearInterval(fadeInInterval);
        fadeInElement.volume = fadeInTargetVolume;
        options.onComplete?.();
      }
    }, this.STEP_MS);
  }

  /**
   * Cancel any active fade operation
   */
  private cancelFade(): void {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  /**
   * Clean up when the fader is no longer needed
   */
  destroy(): void {
    this.cancelFade();
  }
}
