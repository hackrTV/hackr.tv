# frozen_string_literal: true

require_relative "../../lib/middleware/error_tracker_middleware"

# Mount error tracking middleware early in the stack so it catches
# unhandled exceptions from all downstream middleware and the app.
Rails.application.config.middleware.insert_before(
  ActionDispatch::ShowExceptions,
  ErrorTrackerMiddleware
)
