module Api
  module Admin
    class MetaController < BaseController
      # GET /api/admin/capabilities
      def capabilities
        render json: {
          success: true,
          capabilities: {
            streams: true,
            hackr_logs: true,
            pulses: true,
            uplink: true,
            grid: false,
            meta: true
          }
        }
      end

      # GET /api/admin/rate_limit
      def rate_limit
        limit = 125
        window_key = "admin_api_rate:#{Time.current.strftime("%Y%m%d%H%M")}"
        count = Rails.cache.read(window_key).to_i
        remaining = [limit - count, 0].max

        render json: {
          success: true,
          rate_limit: {
            limit: limit,
            remaining: remaining,
            used: count,
            resets_at: Time.current.end_of_minute.iso8601
          }
        }
      end
    end
  end
end
