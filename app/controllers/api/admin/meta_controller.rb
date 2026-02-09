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

      # GET /api/admin/stats
      def stats
        render json: {
          success: true,
          stats: {
            online_hackrs: GridHackr.online.count,
            total_emails_sent: SentEmail.count,
            emails_sent_24h: SentEmail.where("created_at >= ?", 24.hours.ago).count,
            emails_sent_30d: SentEmail.where("created_at >= ?", 30.days.ago).count,
            artists: Artist.count,
            tracks: Track.count,
            hackr_logs: HackrLog.count,
            codex_entries: CodexEntry.count
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
