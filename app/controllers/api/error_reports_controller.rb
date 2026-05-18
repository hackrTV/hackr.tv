# frozen_string_literal: true

module Api
  class ErrorReportsController < ApplicationController
    # sendBeacon does not send CSRF tokens — null_session accepts the
    # request without inheriting session state (current_hackr may be nil).
    protect_from_forgery with: :null_session

    # POST /api/error_report
    def create
      ErrorTracker.track_frontend(
        payload: error_params,
        request: request,
        hackr: current_hackr
      )

      # Always return success — never expose internal state to callers
      render json: {success: true}, status: :ok
    end

    private

    def error_params
      params.permit(:message, :source, :lineno, :colno, :stack, :type, :url)
    end
  end
end
