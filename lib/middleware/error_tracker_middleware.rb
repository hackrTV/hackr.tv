# frozen_string_literal: true

# Rack middleware that captures unhandled exceptions for error tracking.
# Re-raises after tracking so Rails default error handling still fires.
class ErrorTrackerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception # rubocop:disable Lint/RescueException
    # Skip non-application exceptions (signals, system exits)
    raise if exception.is_a?(SystemExit) || exception.is_a?(SignalException)

    track_exception(exception, env)
    raise
  end

  private

  def track_exception(exception, env)
    context = ErrorTracker::RequestSanitizer.from_env(env)

    # Read hackr identity from session — no DB query during exception handling
    # to avoid cascade failures when the DB itself is the problem.
    hackr_id = env["rack.session"]&.fetch(:grid_hackr_id, nil)
    context[:hackr_id] = hackr_id if hackr_id

    ErrorTracker.track(exception, context: context)
  rescue => e
    Rails.logger.error "[ErrorTrackerMiddleware] Failed to track: #{e.message}"
  end
end
