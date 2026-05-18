# frozen_string_literal: true

require_relative "../../lib/middleware/error_tracker_middleware"

# Mount error tracking middleware inside ShowExceptions so it observes
# app exceptions before ShowExceptions rescues them for error rendering.
Rails.application.config.middleware.insert_after(
  ActionDispatch::ShowExceptions,
  ErrorTrackerMiddleware
)
