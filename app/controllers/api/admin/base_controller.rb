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
        auth_header = request.headers["Authorization"]
        unless auth_header&.start_with?("Bearer ")
          render json: {success: false, error: "Missing or invalid Authorization header"}, status: :unauthorized
          return
        end

        credentials = auth_header.split(" ", 2).last
        hackr_alias, token = credentials.split(":", 2)

        unless hackr_alias.present? && token.present?
          render json: {success: false, error: "Invalid token format. Expected alias:token"}, status: :unauthorized
          return
        end

        hackr = GridHackr.authenticate_by_token(hackr_alias, token)
        unless hackr
          Rails.logger.warn("[ADMIN API] Invalid token attempt from #{request.remote_ip} for alias '#{hackr_alias}'")
          render json: {success: false, error: "Invalid admin token"}, status: :unauthorized
          return
        end

        unless hackr.admin?
          Rails.logger.warn("[ADMIN API] Non-admin access attempt by '#{hackr_alias}' from #{request.remote_ip}")
          render json: {success: false, error: "Admin privileges required"}, status: :forbidden
          return
        end

        @current_admin_hackr = hackr
      end

      def enforce_rate_limit!
        limit = 125
        window_key = "admin_api_rate:#{@current_admin_hackr&.hackr_alias || request.remote_ip}:#{Time.current.strftime("%Y%m%d%H%M")}"

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
