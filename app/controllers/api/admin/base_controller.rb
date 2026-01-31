module Api
  module Admin
    class BaseController < ApplicationController
      skip_before_action :check_for_redirect
      skip_before_action :check_for_domain_redirect
      skip_forgery_protection

      before_action :authenticate_admin_token!
      before_action :enforce_rate_limit!

      private

      def authenticate_admin_token!
        configured_token = ENV["HACKR_ADMIN_API_TOKEN"]

        unless configured_token.present?
          Rails.logger.error("[ADMIN API] HACKR_ADMIN_API_TOKEN is not configured")
          render json: {success: false, error: "Admin API is not configured"}, status: :service_unavailable
          return
        end

        auth_header = request.headers["Authorization"]
        unless auth_header&.start_with?("Bearer ")
          render json: {success: false, error: "Missing or invalid Authorization header"}, status: :unauthorized
          return
        end

        provided_token = auth_header.split(" ", 2).last
        unless ActiveSupport::SecurityUtils.secure_compare(provided_token, configured_token)
          Rails.logger.warn("[ADMIN API] Invalid token attempt from #{request.remote_ip}")
          render json: {success: false, error: "Invalid admin token"}, status: :unauthorized
        end
      end

      def resolve_hackr!
        hackr_alias = params[:hackr_alias]
        @acting_hackr = GridHackr.find_by(hackr_alias: hackr_alias)

        unless @acting_hackr
          render json: {success: false, error: "Hackr '#{hackr_alias}' not found"}, status: :not_found
        end
      end

      def enforce_rate_limit!
        limit = 125
        window_key = "admin_api_rate:#{Time.current.strftime("%Y%m%d%H%M")}"

        count = Rails.cache.increment(window_key, 1, expires_in: 2.minutes).to_i
        count = 1 if count == 0
        remaining = [limit - count, 0].max

        response.set_header("X-RateLimit-Limit", limit.to_s)
        response.set_header("X-RateLimit-Remaining", remaining.to_s)
        response.set_header("X-RateLimit-Reset", Time.current.end_of_minute.to_i.to_s)

        if count > limit
          render json: {
            success: false,
            error: "Rate limit exceeded. Try again later.",
            retry_after: (Time.current.end_of_minute - Time.current).ceil
          }, status: :too_many_requests
        end
      end
    end
  end
end
